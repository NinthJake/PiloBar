import QtQuick
import qs

Item {
    id: root

    property string glyph: ""
    property color baseColor: Theme.muted
    property color hoverColor: Theme.teal
    property bool enabled: true

    signal clicked()

    implicitWidth: 26
    implicitHeight: 26
    opacity: root.enabled ? 1 : 0.35

    Rectangle {
        anchors.fill: parent
        radius: 5
        color: Theme.withAlpha(Theme.steel, (root.enabled && mouse.containsMouse) ? 0.25 : 0)
        Behavior on color {
            ColorAnimation { duration: Theme.durFast }
        }
    }

    Text {
        anchors.centerIn: parent
        text: root.glyph
        font.family: Theme.fontFamily
        font.pixelSize: 12
        color: (root.enabled && mouse.containsMouse) ? root.hoverColor : root.baseColor
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        enabled: root.enabled
        onClicked: root.clicked()
    }
}