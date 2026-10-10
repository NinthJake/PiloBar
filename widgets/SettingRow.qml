import QtQuick
import QtQuick.Layouts
import qs

// Label + hint on the left, a control slot on the right. When `available` is
// false the row is dimmed, the control is disabled, and clicking it shows a
// tooltip with `disabledReason`.
RowLayout {
    id: root

    property string label: ""
    property string hint: ""
    property bool available: true
    property string disabledReason: ""
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
            color: root.available ? Theme.fg : Theme.muted
            wrapMode: Text.WordWrap
        }

        Text {
            Layout.fillWidth: true
            visible: root.hint.length > 0
            text: root.hint
            wrapMode: Text.WordWrap
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize - 2
            color: root.available ? Theme.muted : Theme.withAlpha(Theme.muted, 0.5)
        }
    }

    RowLayout {
        id: controlSlot
        Layout.fillWidth: true
        spacing: 8
        enabled: root.available
        opacity: root.available ? 1 : 0.4
    }

    // Catches clicks on the disabled row and explains why it is unavailable.
    TapHandler {
        enabled: !root.available && root.disabledReason.length > 0
        onTapped: (eventPoint) => SettingsApp.showTip(root.disabledReason, eventPoint.scenePosition.x, eventPoint.scenePosition.y)
    }
}
