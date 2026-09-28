import QtQuick
import Quickshell.Services.Pipewire
import qs

BarButton {
    id: root
    required property var screen

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property real volume: (sink && sink.audio) ? sink.audio.volume : 0
    readonly property bool muted: (sink && sink.audio) ? sink.audio.muted : false

    glyph: (muted || volume <= 0.001) ? Theme.glyphVolumeMute : Theme.glyphVolume
    active: Panels.isOpen("sound", root.screen)
    onClicked: Panels.toggle("sound", root.screen, root)

    onScrolled: (delta) => {
        const s = Pipewire.defaultAudioSink
        if (!s || !s.audio)
            return
        const step = delta > 0 ? 0.05 : -0.05
        s.audio.volume = Math.max(0, Math.min(1, s.audio.volume + step))
    }
}
