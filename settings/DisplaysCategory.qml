import QtQuick
import QtQuick.Layouts
import qs
import qs.widgets

// Monitor arrangement and settings. The canvas lays displays out to scale at
// their real (logical) resolution; drag one to move it in 2D. Edges and corners
// snap to other displays and overlapping is rejected. "Identify" flashes the
// display's number on the screen itself.
ColumnLayout {
    id: root

    // Local arrangement copy, shown while dragging before it is applied.
    property var preview: ({})
    property bool dragging: false
    property string dragName: ""
    property real dragGrabX: 0
    property real dragGrabY: 0
    property real dragStartX: 0
    property real dragStartY: 0
    // Transform frozen at drag start so the canvas does not rescale under the
    // pointer while a display moves.
    property var frozenView: null

    readonly property real previewPad: 24
    readonly property real previewMaxH: 300
    readonly property real previewMaxScale: 0.2
    // Visual gap between displays in the preview (does not affect positions).
    readonly property real previewGap: 3

    readonly property var view: frozenView !== null ? frozenView : liveView
    readonly property var liveView: computeView()

    spacing: 16

    Component.onCompleted: {
        Displays.refresh()
        root.preview = Displays.arrangement
    }

    Connections {
        target: Displays
        function onArrangementChanged() {
            if (!root.dragging)
                root.preview = Displays.arrangement
        }
    }

    function previewRect(name) {
        const p = root.preview[name]
        const m = Displays.monitorByName(name)
        if (!p || !m || m.disabled)
            return null
        return {
            x: p.x,
            y: p.y,
            w: m.width / Displays.effectiveScale(name),
            h: m.height / Displays.effectiveScale(name)
        }
    }

    function bounds() {
        let minX = 0, minY = 0, maxX = 1, maxY = 1, first = true
        for (const name in root.preview) {
            const r = root.previewRect(name)
            if (!r)
                continue
            if (first) {
                minX = r.x
                minY = r.y
                maxX = r.x + r.w
                maxY = r.y + r.h
                first = false
            } else {
                minX = Math.min(minX, r.x)
                minY = Math.min(minY, r.y)
                maxX = Math.max(maxX, r.x + r.w)
                maxY = Math.max(maxY, r.y + r.h)
            }
        }
        return { x: minX, y: minY, w: Math.max(1, maxX - minX), h: Math.max(1, maxY - minY) }
    }

    function computeView() {
        const b = bounds()
        const availW = Math.max(120, canvas.width - previewPad * 2)
        const scale = Math.min(availW / Math.max(1, b.w), previewMaxH / Math.max(1, b.h), previewMaxScale)
        return { bx: b.x, by: b.y, scale: scale, w: b.w, h: b.h }
    }

    // Monitor under a canvas point, or "" if none. Uses the same geometry the
    // preview draws (including the readability gap).
    function monitorAt(px, py) {
        let hit = ""
        for (let i = 0; i < Displays.monitors.length; i++) {
            const name = Displays.monitors[i].name
            const r = root.previewRect(name)
            if (!r)
                continue
            const x = root.previewPad + (r.x - root.view.bx) * root.view.scale + root.previewGap
            const y = root.previewPad + (r.y - root.view.by) * root.view.scale + root.previewGap
            const w = Math.max(1, r.w * root.view.scale - root.previewGap * 2)
            const h = Math.max(1, r.h * root.view.scale - root.previewGap * 2)
            if (px >= x && px <= x + w && py >= y && py <= y + h)
                hit = name
        }
        return hit
    }

    function beginDrag(name, cx, cy) {
        const p = root.preview[name]
        if (!p)
            return
        root.frozenView = root.liveView
        root.dragName = name
        root.dragGrabX = cx
        root.dragGrabY = cy
        root.dragStartX = p.x
        root.dragStartY = p.y
        root.dragging = true
    }

    function updateDrag(name, cx, cy) {
        if (!root.dragging || root.dragName !== name || root.frozenView === null)
            return
        const scale = root.frozenView.scale
        const nx = root.dragStartX + (cx - root.dragGrabX) / scale
        const ny = root.dragStartY + (cy - root.dragGrabY) / scale
        const tol = 8 / scale
        const snapped = Displays.snapPosition(name, nx, ny, tol)
        let next = {}
        for (const k in root.preview)
            next[k] = root.preview[k]
        next[name] = { x: snapped.x, y: snapped.y }
        root.preview = next
    }

    function endDrag() {
        if (!root.dragging)
            return
        const name = root.dragName
        const dropped = root.preview[name]
        const dx = dropped ? dropped.x - root.dragStartX : 0
        const dy = dropped ? dropped.y - root.dragStartY : 0
        const axis = Math.abs(dx) >= Math.abs(dy) ? "x" : "y"
        const delta = axis === "x" ? dx : dy
        root.dragging = false
        root.frozenView = null
        root.dragName = ""
        // Let the other displays move out of the way if they overlap. Keep a
        // horizontal drag horizontal (and a vertical drag vertical) even when
        // the dropped display fully covers another one.
        Displays.applyArrangement(Displays.resolveOverlaps(root.preview, name, axis, delta))
    }

    CategoryHeading {
        title: "Displays"
        subtitle: "Drag a display to position it; edges snap and dropped displays slot in. Use the switch on a card to disable an output."
    }

    // ── arrangement canvas ──────────────────────────────────
    Item {
        id: canvas
        Layout.fillWidth: true
        implicitHeight: Math.max(140, root.view.h * root.view.scale + root.previewPad * 2)
        clip: true

        Rectangle {
            anchors.fill: parent
            radius: 8
            color: Theme.withAlpha(Theme.line, 0.22)
        }

        Repeater {
            model: Displays.monitors

            delegate: Rectangle {
                id: monBox
                required property var modelData

                readonly property string name: modelData.name
                readonly property var rect: root.previewRect(name)

                visible: rect !== null
                x: rect === null ? 0 : root.previewPad + (rect.x - root.view.bx) * root.view.scale + root.previewGap
                y: rect === null ? 0 : root.previewPad + (rect.y - root.view.by) * root.view.scale + root.previewGap
                width: rect === null ? 1 : Math.max(1, rect.w * root.view.scale - root.previewGap * 2)
                height: rect === null ? 1 : Math.max(1, rect.h * root.view.scale - root.previewGap * 2)
                radius: 6
                clip: true
                color: root.dragName === name ? Theme.withAlpha(Theme.teal, 0.28) : Theme.withAlpha(Theme.steel, 0.18)
                border.width: root.dragName === name ? 2 : 1
                border.color: root.dragName === name ? Theme.teal : Theme.withAlpha(Theme.steel, 0.5)

                Behavior on color {
                    ColorAnimation { duration: Theme.durFast }
                }

                Column {
                    anchors.centerIn: parent
                    width: parent.width - 8
                    spacing: 1

                    Text {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                        text: "Display " + Displays.idFor(monBox.name)
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                        font.bold: true
                        color: Theme.teal
                    }

                    Text {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                        text: monBox.name
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize - 2
                        color: Theme.fg
                    }

                    Text {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                        visible: parent.width > 130
                        text: Displays.resolutionKey(monBox.name)
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize - 2
                        color: Theme.muted
                    }
                }

            }
        }

        MouseArea {
            id: canvasDrag
            anchors.fill: parent
            preventStealing: true

            onPressed: (mouse) => {
                const name = root.monitorAt(mouse.x, mouse.y)
                if (name !== "")
                    root.beginDrag(name, mouse.x, mouse.y)
            }
            onPositionChanged: (mouse) => {
                if (root.dragging && pressed)
                    root.updateDrag(root.dragName, mouse.x, mouse.y)
            }
            onReleased: root.endDrag()
            onCanceled: root.endDrag()
        }
    }

    // ── actions ─────────────────────────────────────────────
    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        ActionButton {
            glyph: Theme.glyphMonitor
            label: "Identify"
            onTriggered: Displays.identify()
        }

        Item { Layout.fillWidth: true }

        ActionButton {
            glyph: Theme.glyphRefresh
            label: "Reset"
            onTriggered: Displays.resetAll()
        }
    }

    // ── per-monitor settings ────────────────────────────────
    // Boxes wrap into a grid so the page scales to many screens.
    Flow {
        id: boxesFlow
        Layout.fillWidth: true
        spacing: boxGap

        readonly property real boxGap: 12

        Repeater {
            model: Displays.stableOrder

            delegate: Rectangle {
                id: box
                required property string modelData
                required property int index

                readonly property var mon: Displays.monitorByName(modelData)

                width: {
                    const avail = Math.max(200, boxesFlow.width)
                    const cols = Math.max(1, Math.floor((avail + boxesFlow.boxGap) / (280 + boxesFlow.boxGap)))
                    return Math.floor((avail - (cols - 1) * boxesFlow.boxGap) / cols)
                }
                implicitHeight: 174
                visible: mon !== null
                opacity: mon && mon.disabled ? 0.65 : 1
                radius: 8
                color: Theme.withAlpha(Theme.line, 0.3)
                border.width: 1
                border.color: Theme.withAlpha(Theme.line, 0.7)

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Text {
                            text: "Display " + Displays.idFor(box.modelData)
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize - 1
                            font.bold: true
                            color: Theme.teal
                        }

                        Text {
                            Layout.fillWidth: true
                            text: box.modelData
                            elide: Text.ElideRight
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize - 1
                            color: Theme.fg
                        }

                        Text {
                            text: "Enabled"
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize - 2
                            color: Theme.muted
                        }

                        Toggle {
                            checked: box.mon ? !box.mon.disabled : false
                            enabled: box.mon ? Displays.canSetEnabled(box.modelData) : false
                            onToggled: (value) => Displays.setEnabled(box.modelData, value)
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Text {
                            Layout.preferredWidth: 66
                            text: "Resolution"
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize - 1
                            color: Theme.muted
                        }

                        Dropdown {
                            Layout.fillWidth: true
                            options: box.mon ? Displays.resolutionOptions(box.modelData) : []
                            value: Displays.resolutionKey(box.modelData)
                            onSelected: (key) => Displays.setResolution(box.modelData, key)
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Text {
                            Layout.preferredWidth: 66
                            text: "Refresh"
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize - 1
                            color: Theme.muted
                        }

                        Dropdown {
                            Layout.fillWidth: true
                            options: box.mon ? Displays.refreshOptions(box.modelData) : []
                            value: Displays.refreshKey(box.modelData)
                            onSelected: (key) => Displays.setRefresh(box.modelData, key)
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        Text {
                            text: "Scale"
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize - 1
                            color: Theme.muted
                        }

                        Pills {
                            Layout.fillWidth: true
                            options: Displays.scaleOptions
                            value: Displays.scaleKey(box.modelData)
                            onSelected: (key) => Displays.setScale(box.modelData, key)
                        }
                    }
                }
            }
        }
    }
}
