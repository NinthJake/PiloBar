import QtQuick
import qs

BarButton {
    id: root
    required property var screen

    glyph: Theme.glyphSettings
    active: Panels.isOpen("settings", root.screen)
    onClicked: Panels.toggle("settings", root.screen)
}
