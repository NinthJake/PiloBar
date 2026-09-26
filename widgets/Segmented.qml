import QtQuick
import QtQuick.Layouts
import qs

Item {
    id: root

    property var options: []
    property string value: ""

    signal selected(string key)

    implicitWidth: row.implicitWidth + 4
    implicitHeight: 28

    Rectangle {
        anchors.fill: parent
        radius: 6
        color: Theme.withAlpha(Theme.line, 0.6)
    }

    RowLayout {
        id: row
        anchors.fill: parent
        anchors.margins: 2
        spacing: 2

        Repeater {
            model: root.options

            delegate: Rectangle {
                id: chip
                required property var modelData
                readonly property bool selected: root.value === modelData.key

                Layout.fillHeight: true
                Layout.preferredWidth: label.implicitWidth + 14
                radius: 4
                color: selected ? Theme.withAlpha(Theme.teal, 0.9) : (chipMouse.containsMouse ? Theme.withAlpha(Theme.steel, 0.25) : "transparent")
                Behavior on color {
                    ColorAnimation { duration: Theme.durFast }
                }

                Text {
                    id: label
                    anchors.centerIn: parent
                    text: chip.modelData.label
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize - 1
                    color: chip.selected ? Theme.bg : Theme.fg
                }

                MouseArea {
                    id: chipMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: root.selected(chip.modelData.key)
                }
            }
        }
    }
}
