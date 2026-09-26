import QtQuick
import qs

Item {
    id: root

    property string glyph: ""
    property color baseColor: Theme.fg
    property bool active: false
    property bool showPip: false
    readonly property alias containsMouse: mouse.containsMouse

    signal clicked()
    signal scrolled(int delta)

    implicitWidth: 26
    implicitHeight: Theme.barHeight

    Rectangle {
        anchors.fill: parent
        anchors.margins: 3
        radius: 6
        color: Theme.withAlpha(Theme.steel, mouse.containsMouse ? 0.25 : 0)
        Behavior on color {
            ColorAnimation { duration: Theme.durFast }
        }
    }

    Text {
        anchors.centerIn: parent
        text: root.glyph
        font.family: Theme.fontFamily
        font.pixelSize: Theme.iconSize
        color: root.active ? Theme.teal : (mouse.containsMouse ? Theme.teal : root.baseColor)
        Behavior on color {
            ColorAnimation { duration: Theme.durFast }
        }
    }

    Rectangle {
        visible: root.showPip
        width: 5
        height: 5
        radius: 2.5
        color: Theme.teal
        anchors.right: parent.right
        anchors.rightMargin: 3
        anchors.top: parent.top
        anchors.topMargin: 3
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.clicked()
        onWheel: (wheel) => root.scrolled(wheel.angleDelta.y)
    }
}
