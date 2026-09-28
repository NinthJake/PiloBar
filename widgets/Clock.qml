import QtQuick
import Quickshell
import qs

Item {
    id: root
    required property var screen

    implicitWidth: label.implicitWidth + 24
    implicitHeight: Theme.barHeight

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

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
        id: label
        anchors.centerIn: parent
        text: Qt.formatDateTime(clock.date, "HH:mm")
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        font.bold: true
        color: Theme.teal
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        onClicked: Panels.toggle("calendar", root.screen, root)
    }
}
