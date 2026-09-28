import QtQuick
import QtQuick.Layouts
import qs

Rectangle {
    id: root

    property string glyph: ""
    property string label: ""
    property bool danger: false

    signal triggered()

    implicitWidth: content.implicitWidth + 20
    implicitHeight: 32
    radius: 6
    opacity: root.enabled ? 1 : 0.4
    color: mouse.containsMouse ? Theme.withAlpha(root.danger ? Theme.error : Theme.steel, 0.25) : "transparent"
    Behavior on color {
        ColorAnimation { duration: Theme.durFast }
    }

    RowLayout {
        id: content
        anchors.centerIn: parent
        spacing: 6

        Text {
            visible: root.glyph.length > 0
            text: root.glyph
            font.family: Theme.fontFamily
            font.pixelSize: 13
            color: root.danger ? Theme.error : Theme.fg
        }

        Text {
            text: root.label
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize - 1
            color: root.danger ? Theme.error : Theme.fg
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.triggered()
    }
}
