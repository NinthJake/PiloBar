import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs

Item {
    id: root
    required property var screen

    readonly property var monitor: Hyprland.monitorFor(root.screen)
    readonly property int activeId: (monitor && monitor.activeWorkspace) ? monitor.activeWorkspace.id : -1

    readonly property var occupiedIds: {
        let ids = []
        const ws = Hyprland.workspaces.values
        for (let i = 0; i < ws.length; i++) {
            const w = ws[i]
            if (w.id >= 1 && w.toplevels.values.length > 0)
                ids.push(w.id)
        }
        if (activeId >= 1 && ids.indexOf(activeId) === -1)
            ids.push(activeId)
        ids.sort((a, b) => a - b)
        return ids
    }

    readonly property var list: Settings.workspaceMode === "occupied" ? occupiedIds : [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]

    readonly property int itemWidth: 22
    readonly property int itemSpacing: 2
    readonly property int activePos: list.indexOf(activeId)

    implicitWidth: list.length * itemWidth + Math.max(0, list.length - 1) * itemSpacing
    implicitHeight: Theme.barHeight

    // Under a Lua Hyprland config the classic "workspace N" dispatcher is
    // rejected, so dispatch through hl.dsp.focus via hyprctl instead.
    function focusWorkspace(id) {
        Quickshell.execDetached(["hyprctl", "dispatch", "hl.dsp.focus({ workspace = " + id + " })"])
    }

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: root.itemSpacing

        Repeater {
            model: root.list

            delegate: Item {
                id: cell
                required property var modelData
                readonly property int wsId: modelData
                readonly property var hyprWs: {
                    const ws = Hyprland.workspaces.values
                    for (let i = 0; i < ws.length; i++) {
                        if (ws[i].id === wsId)
                            return ws[i]
                    }
                    return null
                }
                readonly property bool isActive: wsId === root.activeId
                readonly property bool isOccupied: hyprWs !== null && hyprWs.toplevels.values.length > 0
                readonly property bool isUrgent: hyprWs !== null && hyprWs.urgent

                width: root.itemWidth
                height: Theme.barHeight

                Text {
                    anchors.centerIn: parent
                    text: cell.wsId
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                    color: cell.isActive ? Theme.teal : (cell.isUrgent ? Theme.error : (cell.isOccupied ? Theme.fg : Theme.muted))
                    Behavior on color {
                        ColorAnimation { duration: Theme.durFast }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: root.focusWorkspace(cell.wsId)
                }
            }
        }
    }

    Rectangle {
        id: mark
        visible: root.activePos >= 0
        height: 2
        radius: 1
        color: Theme.teal
        x: row.x + root.activePos * (root.itemWidth + root.itemSpacing)
        y: row.y + row.height - 2
        width: root.itemWidth
        Behavior on x {
            NumberAnimation {
                duration: Theme.durFast
                easing: Theme.ease
            }
        }
        Behavior on width {
            NumberAnimation {
                duration: Theme.durFast
                easing: Theme.ease
            }
        }
    }
}
