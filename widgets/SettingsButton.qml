import QtQuick
import qs

BarButton {
    id: root
    required property var screen

    glyph: Theme.glyphSettings
    active: SettingsApp.opened && SettingsApp.targetScreen === root.screen
    onClicked: SettingsApp.toggle(root.screen)
}