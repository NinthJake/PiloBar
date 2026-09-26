import QtQuick
import qs

Item {
    id: root

    property real value: 0

    signal moved(real value)

    implicitHeight: 22
    implicitWidth: 200

    readonly property real clamped: Math.max(0, Math.min(1, value))

    Rectangle {
        id: track
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 4
        radius: 2
        color: Theme.line
    }

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: root.clamped * track.width
        height: 4
        radius: 2
        color: Theme.teal
    }

    Rectangle {
        width: 12
        height: 12
        radius: 6
        color: Theme.teal
        anchors.verticalCenter: parent.verticalCenter
        x: root.clamped * (track.width - width)
    }

    MouseArea {
        anchors.fill: parent

        function apply(x) {
            root.moved(Math.max(0, Math.min(1, x / track.width)))
        }

        onClicked: (mouse) => apply(mouse.x)
        onPositionChanged: (mouse) => {
            if (pressed)
                apply(mouse.x)
        }
    }
}
