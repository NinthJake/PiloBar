import QtQuick
import qs

// Small floating hint. The settings app shows it when a disabled SettingRow is
// clicked, explaining why the control is unavailable.
Rectangle {
    id: root

    property string text: ""
    property int maxWidth: 320

    width: Math.min(textItem.implicitWidth + 20, maxWidth)
    height: textItem.implicitHeight + 12
    radius: 6
    color: Theme.withAlpha(Theme.bg, 0.98)
    border.width: 1
    border.color: Theme.withAlpha(Theme.line, 0.9)

    Text {
        id: textItem
        x: 10
        y: 6
        width: Math.min(implicitWidth, root.maxWidth - 20)
        text: root.text
        wrapMode: Text.WordWrap
        color: Theme.fg
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize - 2
    }
}
