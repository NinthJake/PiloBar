import QtQuick
import qs

BarButton {
    id: root
    required property var screen

    glyph: Theme.glyphMonitor
    active: Panels.isOpen("monitors", root.screen)
    onClicked: Panels.toggle("monitors", root.screen)
}
