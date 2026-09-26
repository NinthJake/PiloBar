import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs
import qs.widgets

// Arrange monitors left/right, change refresh rate and scale. Live-applies via
// `hyprctl keyword monitor` and persists by rewriting monitors.lua, which
// hyprland.lua loads with require().
PanelCard {
    id: root

    implicitHeight: content.implicitHeight + 28

    property var monitors: []
    property var order: []
    property var refreshPick: ({})
    property var scalePick: ({})
    property var fileScales: ({})

    readonly property string monitorsPath: String(Quickshell.env("HOME")) + "/.config/hypr/monitors.lua"

    readonly property var scaleOptions: [
        { key: "auto", label: "Auto" },
        { key: "1", label: "1x" },
        { key: "1.25", label: "1.25x" },
        { key: "1.5", label: "1.5x" },
        { key: "1.75", label: "1.75x" },
        { key: "2", label: "2x" }
    ]

    function monitorByName(name) {
        for (let i = 0; i < monitors.length; i++) {
            if (monitors[i].name === name)
                return monitors[i]
        }
        return null
    }

    function roundRefresh(v) {
        return Math.round(v)
    }

    // Unique refresh rates available at the monitor's current resolution.
    function refreshOptions(name) {
        const m = monitorByName(name)
        if (!m)
            return []
        const needle = m.width + "x" + m.height + "@"
        const seen = {}
        let out = []
        for (let i = 0; i < m.availableModes.length; i++) {
            const mode = m.availableModes[i]
            if (mode.indexOf(needle) !== 0)
                continue
            const hz = parseFloat(mode.substring(needle.length))
            if (isNaN(hz))
                continue
            const key = String(Math.round(hz * 100) / 100)
            if (seen[key])
                continue
            seen[key] = true
            out.push({ key: key, label: key })
        }
        out.sort((a, b) => parseFloat(b.key) - parseFloat(a.key))
        return out
    }

    function refreshKey(name) {
        const m = monitorByName(name)
        if (refreshPick[name] !== undefined)
            return String(refreshPick[name])
        return m ? String(roundRefresh(m.refreshRate)) : ""
    }

    function scaleKey(name) {
        if (scalePick[name] !== undefined)
            return String(scalePick[name])
        if (fileScales[name] !== undefined)
            return String(fileScales[name])
        const m = monitorByName(name)
        return m ? String(m.scale) : "1"
    }

    function effectiveScale(name) {
        const key = scaleKey(name)
        if (key !== "auto" && !isNaN(parseFloat(key)))
            return parseFloat(key)
        const m = monitorByName(name)
        return m ? m.scale : 1
    }

    function layoutPositions() {
        // Keep the existing origin so a refresh-only change does not move the
        // desktop; re-anchor to the leftmost monitor when arranging.
        let base = null
        for (let i = 0; i < order.length; i++) {
            const m = monitorByName(order[i])
            if (m && (base === null || m.x < base))
                base = m.x
        }
        if (base === null)
            base = 0

        let x = base
        let pos = {}
        for (let i = 0; i < order.length; i++) {
            const name = order[i]
            const m = monitorByName(name)
            if (!m)
                continue
            pos[name] = Math.round(x)
            x += Math.round(m.width / effectiveScale(name))
        }
        return pos
    }

    function buildLua(pos) {
        let lines = [
            "-- Monitor configuration.",
            "--",
            "-- Managed by the pilo bar's Monitors widget. It can be edited by hand;",
            "-- the widget rewrites it when monitors are arranged, or their scale or",
            "-- refresh rate is changed. hyprland.lua loads it with require().",
            "--",
            "-- Fields match hl.monitor(): output, mode (\"WxH@Hz\"), position (\"XxY\"),",
            "-- scale (\"auto\" or a number).",
            "return {"
        ]
        for (let i = 0; i < order.length; i++) {
            const name = order[i]
            const m = monitorByName(name)
            if (!m)
                continue
            const mode = m.width + "x" + m.height + "@" + refreshKey(name)
            lines.push('    { output = "' + name + '", mode = "' + mode + '", position = "' + pos[name] + 'x0", scale = "' + scaleKey(name) + '" },')
        }
        lines.push("}")
        return lines.join("\n") + "\n"
    }

    function applyAll() {
        if (order.length === 0)
            return
        const pos = layoutPositions()
        let script = ""
        for (let i = 0; i < order.length; i++) {
            const name = order[i]
            const m = monitorByName(name)
            if (!m)
                continue
            const spec = name + "," + m.width + "x" + m.height + "@" + refreshKey(name) + "," + pos[name] + "x0," + scaleKey(name)
            script += "hyprctl keyword monitor '" + spec + "' ; "
        }
        if (script.length > 0) {
            applyProc.command = ["sh", "-c", script]
            applyProc.running = true
        }
        Quickshell.execDetached(["sh", "-c", "cat > '" + monitorsPath + "' <<'PILO_EOF'\n" + buildLua(pos) + "PILO_EOF"])
    }

    function resetAll() {
        refreshPick = ({})
        scalePick = ({})
        for (let i = 0; i < order.length; i++) {
            const name = order[i]
            const m = monitorByName(name)
            if (!m)
                continue
            // preferred mode, auto position, automatic scale
            Quickshell.execDetached(["hyprctl", "keyword", "monitor", name + ",preferred,auto,auto"])
        }
        Quickshell.execDetached(["sh", "-c", "cat > '" + monitorsPath + "' <<'PILO_EOF'\n" + buildLuaFromPreferred() + "PILO_EOF"])
    }

    function buildLuaFromPreferred() {
        let lines = [
            "-- Monitor configuration.",
            "--",
            "-- Managed by the pilo bar's Monitors widget.",
            "return {"
        ]
        for (let i = 0; i < order.length; i++) {
            lines.push('    { output = "' + order[i] + '", mode = "preferred", position = "auto", scale = "auto" },')
        }
        lines.push("}")
        return lines.join("\n") + "\n"
    }

    function move(name, dir) {
        const i = order.indexOf(name)
        const j = i + dir
        if (i < 0 || j < 0 || j >= order.length)
            return
        let next = order.slice()
        const tmp = next[i]
        next[i] = next[j]
        next[j] = tmp
        order = next
        applyAll()
    }

    function setRefresh(name, key) {
        let pick = {}
        for (const k in refreshPick)
            pick[k] = refreshPick[k]
        pick[name] = key
        refreshPick = pick
        applyAll()
    }

    function setScale(name, key) {
        let pick = {}
        for (const k in scalePick)
            pick[k] = scalePick[k]
        pick[name] = key
        scalePick = pick
        applyAll()
    }

    function parseMonitors(text) {
        let arr
        try {
            arr = JSON.parse(text)
        } catch (e) {
            return
        }
        let list = []
        for (let i = 0; i < arr.length; i++) {
            const m = arr[i]
            list.push({
                name: m.name,
                width: m.width,
                height: m.height,
                refreshRate: m.refreshRate,
                scale: m.scale,
                x: m.x,
                y: m.y,
                availableModes: m.availableModes || []
            })
        }
        monitors = list

        const byX = list.slice().sort((a, b) => a.x - b.x).map(m => m.name)
        let next = []
        for (let i = 0; i < order.length; i++) {
            if (byX.indexOf(order[i]) !== -1 && next.indexOf(order[i]) === -1)
                next.push(order[i])
        }
        for (let i = 0; i < byX.length; i++) {
            if (next.indexOf(byX[i]) === -1)
                next.push(byX[i])
        }
        order = next
    }

    function parseFileScales(text) {
        let map = {}
        const re = /output\s*=\s*"([^"]+)"[^\n]*?scale\s*=\s*"([^"]+)"/g
        let m
        while ((m = re.exec(text)) !== null)
            map[m[1]] = m[2]
        fileScales = map
    }

    onVisibleChanged: {
        if (visible) {
            monitorsProc.running = true
            fileProc.running = true
        }
    }

    Process {
        id: monitorsProc
        command: ["hyprctl", "monitors", "-j"]
        stdout: StdioCollector {
            onStreamFinished: root.parseMonitors(text)
        }
    }

    Process {
        id: fileProc
        command: ["cat", root.monitorsPath]
        stdout: StdioCollector {
            onStreamFinished: root.parseFileScales(text)
        }
    }

    Process {
        id: applyProc
        stdout: StdioCollector {
            onStreamFinished: monitorsProc.running = true
        }
    }

    Timer {
        id: refreshTimer
        interval: 400
        repeat: false
        onTriggered: monitorsProc.running = true
    }

    ColumnLayout {
        id: content
        anchors.fill: parent
        anchors.margins: 14
        spacing: 10

        RowLayout {
            Layout.fillWidth: true

            Text {
                text: "Monitors"
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                font.bold: true
                color: Theme.fg
            }

            Item { Layout.fillWidth: true }

            ActionButton {
                glyph: Theme.glyphRefresh
                label: "Reset"
                onTriggered: root.resetAll()
            }
        }

       Text {
            Layout.fillWidth: true
            text: "Drag-free arrangement: move a monitor left or right. Changes apply immediately and are saved to monitors.lua."
            wrapMode: Text.WordWrap
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize - 2
            color: Theme.muted
        }

        ListView {
            id: list
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(list.contentHeight, 460)
            clip: true
            spacing: 8
            model: root.order

            delegate: Rectangle {
                id: card
                required property var modelData
                readonly property var mon: root.monitorByName(modelData)

                width: ListView.view.width
                height: mon ? 108 : 0
                visible: mon !== null
                radius: 6
                color: Theme.withAlpha(Theme.line, 0.35)

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 6

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        BarButton {
                            glyph: Theme.glyphArrowLeft
                            implicitHeight: 24
                            implicitWidth: 26
                            onClicked: root.move(card.modelData, -1)
                        }

                        Text {
                            Layout.fillWidth: true
                            text: card.mon ? card.modelData + "   " + card.mon.width + "x" + card.mon.height : card.modelData
                            elide: Text.ElideRight
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize
                            font.bold: true
                            color: Theme.fg
                        }

                        Text {
                            text: card.mon ? root.roundRefresh(card.mon.refreshRate) + " Hz" : ""
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize - 1
                            color: Theme.muted
                        }

                        BarButton {
                            glyph: Theme.glyphArrowRight
                            implicitHeight: 24
                            implicitWidth: 26
                            onClicked: root.move(card.modelData, 1)
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Text {
                            Layout.preferredWidth: 56
                            text: "Refresh"
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize - 1
                            color: Theme.muted
                        }

                        Item { Layout.fillWidth: true }

                        Segmented {
                            options: card.mon ? root.refreshOptions(card.modelData) : []
                            value: root.refreshKey(card.modelData)
                            onSelected: (key) => root.setRefresh(card.modelData, key)
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Text {
                            Layout.preferredWidth: 56
                            text: "Scale"
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize - 1
                            color: Theme.muted
                        }

                        Item { Layout.fillWidth: true }

                        Segmented {
                            options: root.scaleOptions
                            value: root.scaleKey(card.modelData)
                            onSelected: (key) => root.setScale(card.modelData, key)
                        }
                    }
                }
            }
        }
    }
}
