import QtQuick
import QtQuick.Layouts
import qs

ColumnLayout {
    id: root

    property string title: ""
    property string subtitle: ""

    Layout.fillWidth: true
    spacing: 3

    Text {
        Layout.fillWidth: true
        text: root.title
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize + 5
        font.bold: true
        color: Theme.fg
    }

    Text {
        Layout.fillWidth: true
        visible: root.subtitle.length > 0
        text: root.subtitle
        wrapMode: Text.WordWrap
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize - 1
        color: Theme.muted
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.topMargin: 6
        implicitHeight: 1
        color: Theme.line
    }
}