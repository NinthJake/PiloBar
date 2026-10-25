import QtQuick
import qs

Item {
    id: root

    property bool checked: false

    signal toggled(bool value)

    implicitWidth: 40
    implicitHeight: 22
    opacity: root.enabled ? 1 : 0.35

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: root.checked ? Theme.withAlpha(Theme.teal, 0.9) : Theme.line
        Behavior on color {
            ColorAnimation { duration: Theme.durFast }
        }
    }

    Rectangle {
        width: 16
        height: 16
        radius: 8
        color: root.checked ? Theme.bg : Theme.muted
        anchors.verticalCenter: parent.verticalCenter
        x: root.checked ? parent.width - width - 3 : 3
        Behavior on x {
            NumberAnimation {
                duration: Theme.durFast
                easing: Theme.ease
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.enabled
        onClicked: root.toggled(!root.checked)
    }
}
