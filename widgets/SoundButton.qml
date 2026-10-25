import QtQuick
import qs

BarButton {
    id: root
    required property var screen

    glyph: (Audio.muted || Audio.volume <= 0.001) ? Theme.glyphVolumeMute : Theme.glyphVolume
    active: Panels.isOpen("sound", root.screen)
    onClicked: Panels.toggle("sound", root.screen, root)

    onScrolled: (delta) => Audio.adjustVolume(delta > 0 ? 0.05 : -0.05)
}
