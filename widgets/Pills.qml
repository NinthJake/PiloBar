import QtQuick
import qs

// Wrapping group of rounded pill toggles. Like Segmented, but fully rounded and
// it wraps to fit narrow containers such as the Displays setting boxes.
Flow {
    id: root

    property var options: []
    property string value: ""

    signal selected(string key)

    spacing: 4

    Repeater {
        model: root.options

        delegate: Rectangle {
            id: pill
            required property var modelData
            readonly property bool selected: root.value === modelData.key

            width: pillLabel.implicitWidth + 14
            height: 26
            radius: height / 2
            color: pill.selected ? Theme.withAlpha(Theme.teal, 0.9) : (pillMouse.containsMouse ? Theme.withAlpha(Theme.steel, 0.25) : Theme.withAlpha(Theme.line, 0.55))

            Behavior on color {
                ColorAnimation { duration: Theme.durFast }
            }

            Text {
                id: pillLabel
                anchors.centerIn: parent
                text: pill.modelData.label
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize - 1
                color: pill.selected ? Theme.bg : Theme.fg
            }

            MouseArea {
                id: pillMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: root.selected(pill.modelData.key)
            }
        }
    }
}
