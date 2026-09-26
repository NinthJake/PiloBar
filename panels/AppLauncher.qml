import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import qs
import qs.widgets

Item {
    id: root

    property string query: ""
    property string mode: "apps"
    property int currentIndex: 0
    property var fileResults: []
    property string confirm: ""
    property bool locateAvailable: false

    readonly property var apps: DesktopEntries.applications.values

    readonly property var scopes: Settings.fileSearch ? [{ key: "apps", label: "Apps" }, { key: "files", label: "Files" }] : [{ key: "apps", label: "Apps" }]

    readonly property var results: {
        if (mode === "files" && Settings.fileSearch) {
            let files = []
            for (let i = 0; i < fileResults.length; i++)
                files.push({ kind: "file", path: fileResults[i] })
            return files
        }

        const q = query.trim().toLowerCase()
        let list = []
        for (let i = 0; i < apps.length; i++) {
            const a = apps[i]
            if (a.noDisplay)
                continue
            if (q.length > 0) {
                const hay = (a.name + " " + (a.genericName || "") + " " + (a.keywords || []).join(" ")).toLowerCase()
                if (hay.indexOf(q) === -1)
                    continue
            }
            list.push(a)
        }

        const sort = Settings.launcherSort
        list.sort((a, b) => {
            if (sort === "recent") {
                const la = Settings.usageFor(a.id).last || 0
                const lb = Settings.usageFor(b.id).last || 0
                if (la !== lb)
                    return lb - la
            } else if (sort === "frequent") {
                const ca = Settings.usageFor(a.id).count || 0
                const cb = Settings.usageFor(b.id).count || 0
                if (ca !== cb)
                    return cb - ca
            }
            return a.name.localeCompare(b.name)
        })

        let out = []
        for (let i = 0; i < list.length; i++)
            out.push({ kind: "app", entry: list[i] })
        return out
    }

    function focusSearch() {
        search.forceActiveFocus()
    }

    // Called when the launcher closes so it reopens clean.
    function reset() {
        search.text = ""
        query = ""
        currentIndex = 0
        fileResults = []
        confirm = ""
    }

    onVisibleChanged: {
        if (visible)
            Qt.callLater(focusSearch)
        else
            reset()
    }

    function toggleScope() {
        if (!Settings.fileSearch)
            return
        root.mode = root.mode === "files" ? "apps" : "files"
        search.forceActiveFocus()
    }

    Connections {
        target: Settings
        function onFileSearchChanged() {
            if (!Settings.fileSearch && root.mode === "files")
                root.mode = "apps"
        }
    }

    function move(delta) {
        if (results.length === 0)
            return
        currentIndex = Math.max(0, Math.min(results.length - 1, currentIndex + delta))
        list.positionViewAtIndex(currentIndex, ListView.Contain)
    }

    function activate(index) {
        const r = results[index]
        if (!r)
            return
        if (r.kind === "app") {
            Settings.recordLaunch(r.entry.id)
            r.entry.execute()
        } else {
            Quickshell.execDetached(["xdg-open", r.path])
        }
        Panels.close()
    }

    function signOut() {
        Quickshell.execDetached(["hyprctl", "dispatch", "hl.dsp.exit()"])
        Panels.close()
    }

    function confirmAction() {
        const action = confirm
        if (action === "shutdown")
            Quickshell.execDetached(["systemctl", "poweroff"])
        else if (action === "reboot")
            Quickshell.execDetached(["systemctl", "reboot"])
        else if (action === "suspend")
            Quickshell.execDetached(["systemctl", "suspend"])
        confirm = ""
        Panels.close()
    }

    onQueryChanged: {
        currentIndex = 0
        if (mode === "files") {
            if (query.length >= 2 && locateAvailable)
                locateDebounce.restart()
            else
                fileResults = []
        }
    }

    onModeChanged: {
        currentIndex = 0
        if (mode === "files" && query.length >= 2 && locateAvailable)
            locateDebounce.restart()
    }

    Process {
        id: locateProbe
        command: ["sh", "-c", "command -v plocate >/dev/null 2>&1 && echo yes"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.locateAvailable = text.trim() === "yes"
        }
    }

    Process {
        id: locate
        command: ["plocate", "-i", "-l", "60", root.query]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.split("\n")
                let out = []
                for (let i = 0; i < lines.length; i++) {
                    if (lines[i].length > 0)
                        out.push(lines[i])
                }
                root.fileResults = out
            }
        }
    }

    Timer {
        id: locateDebounce
        interval: 250
        repeat: false
        onTriggered: locate.running = true
    }

    // Swallow clicks on empty parts of the card so they don't reach the
    // dismiss-on-click backdrop behind it.
    MouseArea {
        anchors.fill: parent
    }

    PanelCard {
        anchors.fill: parent

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 10

            // ── search ──────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 42
                radius: 6
                color: Theme.withAlpha(Theme.line, 0.5)

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 10
                    spacing: 8

                    Text {
                        text: Theme.glyphSearch
                        font.family: Theme.fontFamily
                        font.pixelSize: 14
                        color: Theme.muted
                    }

                    TextInput {
                        id: search
                        Layout.fillWidth: true
                        verticalAlignment: TextInput.AlignVCenter
                        color: Theme.fg
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize + 1
                        selectByMouse: true
                        focus: true
                        onTextChanged: root.query = text
                        onAccepted: root.activate(root.currentIndex)

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: search.text.length === 0
                            text: root.mode === "files" ? "Search files" : "Search applications"
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize + 1
                            color: Theme.muted
                        }

                        Keys.onDownPressed: root.move(1)
                        Keys.onUpPressed: root.move(-1)
                        Keys.onTabPressed: root.toggleScope()
                        Keys.onEscapePressed: Panels.close()
                    }

                    Text {
                        visible: search.text.length > 0
                        text: Theme.glyphClose
                        font.family: Theme.fontFamily
                        font.pixelSize: 13
                        color: clearMouse.containsMouse ? Theme.teal : Theme.muted

                        MouseArea {
                            id: clearMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                search.text = ""
                                search.forceActiveFocus()
                            }
                        }
                    }
                }
            }

            // ── chips ───────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                // Apps | Files on the left.
                Segmented {
                    options: root.scopes
                    value: root.mode
                    onSelected: (key) => {
                        if (key === "files" && !Settings.fileSearch)
                            return
                        root.mode = key
                    }
                }

                Item { Layout.fillWidth: true }

                Text {
                    visible: root.mode === "files" && !root.locateAvailable
                    text: "plocate not installed"
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize - 2
                    color: Theme.warning
                }

                Text {
                    visible: root.mode === "apps"
                    text: root.results.length + " apps"
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize - 2
                    color: Theme.muted
                }

                // Sorting on the right.
                Segmented {
                    options: [
                        { key: "name", label: "Name" },
                        { key: "recent", label: "Recent" },
                        { key: "frequent", label: "Frequent" }
                    ]
                    value: Settings.launcherSort
                    visible: root.mode === "apps"
                    onSelected: (key) => Settings.setLauncherSort(key)
                }
            }

            // ── results ─────────────────────────────────────
            ListView {
                id: list
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 2
                model: root.results
                currentIndex: root.currentIndex

                delegate: Rectangle {
                    id: row
                    required property var modelData
                    required property int index
                    readonly property bool selected: index === root.currentIndex

                    width: ListView.view.width
                    height: 44
                    radius: 6
                    color: selected ? Theme.withAlpha(Theme.steel, 0.3) : (rowMouse.containsMouse ? Theme.withAlpha(Theme.steel, 0.15) : "transparent")
                    Behavior on color {
                        ColorAnimation { duration: Theme.durFast }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 10

                        IconImage {
                            visible: row.modelData.kind === "app"
                            Layout.preferredWidth: 26
                            Layout.preferredHeight: 26
                            implicitSize: 26
                            source: row.modelData.kind === "app" ? Quickshell.iconPath(row.modelData.entry.icon, "application-x-executable") : ""
                        }

                        Text {
                            visible: row.modelData.kind === "file"
                            Layout.preferredWidth: 26
                            horizontalAlignment: Text.AlignHCenter
                            text: Theme.glyphFile
                            font.family: Theme.fontFamily
                            font.pixelSize: 16
                            color: Theme.muted
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            Text {
                                Layout.fillWidth: true
                                text: row.modelData.kind === "app" ? row.modelData.entry.name : row.modelData.path.split("/").pop()
                                elide: Text.ElideRight
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize
                                color: Theme.fg
                            }

                            Text {
                                Layout.fillWidth: true
                                text: row.modelData.kind === "app" ? (row.modelData.entry.genericName || row.modelData.entry.comment || "") : row.modelData.path
                                elide: Text.ElideMiddle
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize - 2
                                color: Theme.muted
                            }
                        }
                    }

                    MouseArea {
                        id: rowMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: root.currentIndex = row.index
                        onClicked: root.activate(row.index)
                    }
                }
            }

            // ── footer ──────────────────────────────────────
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 34

                RowLayout {
                    anchors.fill: parent
                    visible: root.confirm.length === 0
                    spacing: 4

                    ActionButton {
                        glyph: Theme.glyphShutdown
                        label: "Shutdown"
                        onTriggered: root.confirm = "shutdown"
                    }

                    ActionButton {
                        glyph: Theme.glyphReboot
                        label: "Reboot"
                        onTriggered: root.confirm = "reboot"
                    }

                    ActionButton {
                        glyph: Theme.glyphSignout
                        label: "Sign out"
                        onTriggered: root.signOut()
                    }

                    ActionButton {
                        glyph: Theme.glyphSuspend
                        label: "Suspend"
                        onTriggered: root.confirm = "suspend"
                    }

                    Item { Layout.fillWidth: true }
                }

                RowLayout {
                    anchors.fill: parent
                    visible: root.confirm.length > 0
                    spacing: 8

                    Text {
                        text: "Confirm " + root.confirm + "?"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                        color: Theme.fg
                    }

                    Item { Layout.fillWidth: true }

                    ActionButton {
                        label: "Cancel"
                        onTriggered: root.confirm = ""
                    }

                    ActionButton {
                        label: root.confirm
                        danger: true
                        onTriggered: root.confirmAction()
                    }
                }
            }
        }
    }
}
