import QtQuick
import QtQuick.Layouts
import qs

// Label + hint on the left, a control slot on the right.
RowLayout {
    id: root

    property string label: ""
    property string hint: ""
    default property alias controlData: controlSlot.data

    Layout.fillWidth: true
    spacing: 16

    ColumnLayout {
        Layout.preferredWidth: 220
        Layout.alignment: Qt.AlignTop
        spacing: 2

        Text {
            Layout.fillWidth: true
            text: root.label
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            color: Theme.fg
            wrapMode: Text.WordWrap
        }

        Text {
            Layout.fillWidth: true
            visible: root.hint.length > 0
            text: root.hint
            wrapMode: Text.WordWrap
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize - 2
            color: Theme.muted
        }
    }

    RowLayout {
        id: controlSlot
        Layout.fillWidth: true
        spacing: 8
    }
}