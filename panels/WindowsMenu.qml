import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs
import qs.widgets

// Per-app / overflow window menu: focus, close, or force kill each window,
// plus the application's own Desktop Entry actions (jump list), e.g. Steam's
// Store / Library / Friends.
PanelCard {
    id: root

    implicitHeight: content.implicitHeight + 20

    // Every row carries the same keys so the delegate never reads undefined.
    function row(overrides) {
        return Object.assign({
            type: "",
            label: "",
            appName: "",
            icon: "",
            title: "",
            address: "",
            monitor: "",
            workspaceId: -1,
            action: null
        }, overrides)
    }

    readonly property var entries: {
        let out = []
        const keys = Panels.windowsMenuApps
        const single = keys.length === 1

        for (let i = 0; i < keys.length; i++) {
            const g = RunningApps.group(keys[i])
            if (!g)
                continue

            if (!single)
                out.push(row({ type: "app", label: g.name }))

            for (let j = 0; j < g.windows.length; j++) {
                const w = g.windows[j]
                out.push(row({
                    type: "window",
                    appName: g.name,
                    icon: g.icon,
                    title: w.title,
                    address: w.address,
                    monitor: w.monitor,
                    workspaceId: w.workspaceId
                }))
            }

            if (single && g.actions && g.actions.length > 0) {
                out.push(row({ type: "header", label: "Actions" }))
                for (let k = 0; k < g.actions.length; k++) {
                    const a = g.actions[k]
                    out.push(row({
                        type: "action",
                        label: a.name,
                        icon: (a.icon && a.icon.length > 0) ? Quickshell.iconPath(a.icon, "application-x-executable") : "",
                        action: a
                    }))
                }
            }
        }
        return out
    }

    readonly property string title: {
        if (Panels.windowsMenuApps.length === 1) {
            const g = RunningApps.group(Panels.windowsMenuApps[0])
            if (g)
                return g.name
        }
        return "More windows"
    }

    ColumnLayout {
        id: content
        anchors.fill: parent
        anchors.margins: 10
        spacing: 6

        Text {
            Layout.fillWidth: true
            text: root.title
            elide: Text.ElideRight
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            font.bold: true
            color: Theme.fg
        }

        ListView {
            id: list
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(list.contentHeight, 400)
            clip: true
            spacing: 2
            model: root.entries

            delegate: Rectangle {
                id: row
                required property var modelData

                width: ListView.view.width
                height: modelData.type === "window" ? 40 : (modelData.type === "action" ? 32 : 22)
                radius: 5
                color: "transparent"

                // Section / app header
                Text {
                    visible: row.modelData.type === "header" || row.modelData.type === "app"
                    anchors.left: parent.left
                    anchors.leftMargin: 6
                    anchors.verticalCenter: parent.verticalCenter
                    text: row.modelData.label
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize - 2
                    font.bold: row.modelData.type === "app"
                    color: row.modelData.type === "app" ? Theme.fg : Theme.muted
                }

                // Desktop Entry action
                RowLayout {
                    visible: row.modelData.type === "action"
                    anchors.fill: parent
                    anchors.leftMargin: 6
                    anchors.rightMargin: 6
                    spacing: 8

                    IconImage {
                        visible: row.modelData.icon.length > 0
                        implicitSize: 18
                        Layout.preferredWidth: 18
                        Layout.preferredHeight: 18
                        source: row.modelData.icon
                    }

                    Text {
                        visible: row.modelData.icon.length === 0
                        Layout.preferredWidth: 18
                        horizontalAlignment: Text.AlignHCenter
                        text: Theme.glyphArrowRight
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        color: Theme.muted
                    }

                    Text {
                        Layout.fillWidth: true
                        text: row.modelData.label
                        elide: Text.ElideRight
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize - 1
                        color: actionMouse.containsMouse ? Theme.teal : Theme.fg
                    }
                }

                MouseArea {
                    id: actionMouse
                    anchors.fill: parent
                    enabled: row.modelData.type === "action"
                    hoverEnabled: true
                    onClicked: {
                        row.modelData.action.execute()
                        Panels.close()
                    }
                }

                // Window row
                RowLayout {
                    visible: row.modelData.type === "window"
                    anchors.fill: parent
                    anchors.leftMargin: 4
                    anchors.rightMargin: 2
                    spacing: 4

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: "transparent"

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 6
                            anchors.rightMargin: 6
                            spacing: 8

                            IconImage {
                                implicitSize: 20
                                source: row.modelData.icon
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0

                                Text {
                                    Layout.fillWidth: true
                                    text: row.modelData.title.length > 0 ? row.modelData.title : row.modelData.appName
                                    elide: Text.ElideRight
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSize - 1
                                    color: Theme.fg
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: "ws " + row.modelData.workspaceId + (row.modelData.monitor.length > 0 ? "  ·  " + row.modelData.monitor : "")
                                    elide: Text.ElideRight
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSize - 2
                                    color: Theme.muted
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                RunningApps.focusWindow(row.modelData.address)
                                Panels.close()
                            }
                        }
                    }

                    ActionButton {
                        label: "Close"
                        onTriggered: RunningApps.closeWindow(row.modelData.address)
                    }

                    ActionButton {
                        label: "Kill"
                        danger: true
                        onTriggered: RunningApps.killWindow(row.modelData.address)
                    }
                }
            }
        }
    }
}
