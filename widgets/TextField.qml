import QtQuick
import qs

Rectangle {
    id: root

    property alias text: input.text
    property string placeholder: ""

    signal accepted()

    implicitWidth: 200
    implicitHeight: 30
    radius: 5
    color: Theme.withAlpha(Theme.line, 0.5)
    border.width: 1
    border.color: input.activeFocus ? Theme.steel : "transparent"

    TextInput {
        id: input
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        verticalAlignment: TextInput.AlignVCenter
        color: Theme.fg
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize - 1
        selectByMouse: true
        clip: true
        onAccepted: root.accepted()

        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: input.text.length === 0
            text: root.placeholder
            font: input.font
            color: Theme.muted
        }
    }
}