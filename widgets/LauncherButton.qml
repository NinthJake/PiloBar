import QtQuick
import qs

BarButton {
    id: root
    required property var screen

    glyph: Theme.glyphLauncher
    active: Panels.isOpen("launcher", root.screen)
    onClicked: Panels.toggleLauncher(root.screen, true, root)
}
