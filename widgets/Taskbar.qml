import QtQuick
import Quickshell
import Quickshell.Widgets
import qs

// Running applications, grouped by app. Left-click focuses (or opens the menu
// when the app has several windows); right-click opens the window menu. Extra
// apps beyond maxVisible collapse into a "+N" chip.
Item {
    id: root
    required property var screen

    readonly property int maxVisible: 6
    readonly property var groups: RunningApps.groups
    readonly property var visibleGroups: groups.slice(0, maxVisible)
    readonly property int hiddenCount: Math.max(0, groups.length - maxVisible)

    implicitHeight: Theme.barHeight
    implicitWidth: row.implicitWidth

    function openMenu(apps, item) {
        const p = item.mapToItem(null, 0, 0)
        Panels.openWindowsMenu(apps, p.x, item.width, root.screen)
    }

    function trigger(group, item, button) {
        // Right-click always opens the menu; left-click focuses a lone window
        // or opens the menu when the app has several.
        if (button === Qt.RightButton || group.count > 1) {
            root.openMenu([group.key], item)
        } else if (group.windows.length > 0) {
            RunningApps.focusWindow(group.windows[0].address)
        }
    }

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        Repeater {
            model: root.visibleGroups

            delegate: Item {
                id: cell
                required property var modelData

                width: 30
                height: Theme.barHeight

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 3
                    radius: 6
                    color: Theme.withAlpha(Theme.steel, mouse.containsMouse ? 0.25 : 0)
                    Behavior on color {
                        ColorAnimation { duration: Theme.durFast }
                    }
                }

                IconImage {
                    anchors.centerIn: parent
                    implicitSize: 20
                    source: cell.modelData.icon
                }

                Rectangle {
                    visible: cell.modelData.active
                    width: 16
                    height: 2
                    radius: 1
                    color: Theme.teal
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 3
                }

                MouseArea {
                    id: mouse
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: (event) => root.trigger(cell.modelData, cell, event.button)
                }
            }
        }

        Item {
            id: overflow
            visible: root.hiddenCount > 0
            width: 30
            height: Theme.barHeight

            Rectangle {
                anchors.fill: parent
                anchors.margins: 3
                radius: 6
                color: Theme.withAlpha(Theme.steel, overflowMouse.containsMouse ? 0.25 : 0)
                Behavior on color {
                    ColorAnimation { duration: Theme.durFast }
                }
            }

            Text {
                anchors.centerIn: parent
                text: "+" + root.hiddenCount
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize - 1
                color: overflowMouse.containsMouse ? Theme.teal : Theme.fg
            }

            MouseArea {
                id: overflowMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                    let hidden = []
                    for (let i = root.maxVisible; i < root.groups.length; i++)
                        hidden.push(root.groups[i].key)
                    root.openMenu(hidden, overflow)
                }
            }
        }
    }
}
