pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

// Audio facade over the three common Linux output stacks:
//   PipeWire (Quickshell native) -> PulseAudio (pactl) -> ALSA (amixer).
// PipeWire is preferred whenever Quickshell can see it. The fallback backends
// are command clients for the system's existing server; nothing is started or
// reconfigured.
Singleton {
    id: root

    // ── PipeWire through Quickshell ───────────────────────────────────────
    readonly property bool pipewireUsable: Pipewire.ready && Pipewire.defaultAudioSink !== null
    readonly property var pipewireSink: Pipewire.defaultAudioSink

    readonly property var pipewireSinks: {
        let out = []
        const nodes = Pipewire.nodes.values
        for (let i = 0; i < nodes.length; i++) {
            const node = nodes[i]
            if (!node.isSink || node.isStream || !node.audio)
                continue
            out.push({
                id: node.name,
                description: node.description.length > 0 ? node.description : node.name,
                isDefault: node === root.pipewireSink,
                nativeNode: node
            })
        }
        return out
    }

    readonly property real pipewireVolume: (root.pipewireSink && root.pipewireSink.audio) ? root.pipewireSink.audio.volume : 0
    readonly property bool pipewireMuted: (root.pipewireSink && root.pipewireSink.audio) ? root.pipewireSink.audio.muted : false
    readonly property string pipewireSinkName: root.pipewireSink
        ? (root.pipewireSink.description.length > 0 ? root.pipewireSink.description : root.pipewireSink.name)
        : ""

    PwObjectTracker {
        objects: {
            let out = []
            const sink = Pipewire.defaultAudioSink
            if (sink)
                out.push(sink)
            const nodes = Pipewire.nodes.values
            for (let i = 0; i < nodes.length; i++) {
                const node = nodes[i]
                if (node.isSink && !node.isStream && node.audio)
                    out.push(node)
            }
            return out
        }
    }

    // ── PulseAudio / pipewire-pulse through pactl ────────────────────────
    property bool pulseAvailable: false
    property string pulseDefault: ""
    property real pulseVolume: 0
    property bool pulseMuted: false
    property var pulseSinks: []

    // ── ALSA through amixer ───────────────────────────────────────────────
    property bool alsaAvailable: false
    property string alsaControl: ""
    property real alsaVolume: 0
    property bool alsaMuted: false

    property string lastError: ""

    // ── unified state ─────────────────────────────────────────────────────
    readonly property string backend: root.pipewireUsable ? "pipewire" : (root.pulseAvailable ? "pulse" : (root.alsaAvailable ? "alsa" : "none"))
    readonly property string backendName: {
        if (root.pipewireUsable)
            return "PipeWire"
        if (root.pulseAvailable)
            return "PulseAudio"
        if (root.alsaAvailable)
            return "ALSA"
        return "No audio server"
    }

    readonly property bool available: root.backend !== "none"
    readonly property real volume: {
        if (root.pipewireUsable)
            return Math.max(0, Math.min(1, root.pipewireVolume))
        if (root.pulseAvailable)
            return Math.max(0, Math.min(1, root.pulseVolume))
        if (root.alsaAvailable)
            return Math.max(0, Math.min(1, root.alsaVolume))
        return 0
    }
    readonly property bool muted: {
        if (root.pipewireUsable)
            return root.pipewireMuted
        if (root.pulseAvailable)
            return root.pulseMuted
        return root.alsaAvailable && root.alsaMuted
    }
    readonly property string sinkName: {
        if (root.pipewireUsable)
            return root.pipewireSinkName
        if (root.pulseAvailable) {
            for (let i = 0; i < root.pulseSinks.length; i++) {
                if (root.pulseSinks[i].isDefault)
                    return root.pulseSinks[i].description
            }
            return root.pulseSinks.length > 0 ? root.pulseSinks[0].description : "No output device"
        }
        if (root.alsaAvailable)
            return root.alsaControl.length > 0 ? root.alsaControl : "Master"
        return "No output device"
    }
    readonly property var sinks: {
        if (root.pipewireUsable)
            return root.pipewireSinks
        if (root.pulseAvailable)
            return root.pulseSinks
        if (root.alsaAvailable) {
            return [{
                id: "alsa:" + root.alsaControl,
                description: root.alsaControl.length > 0 ? root.alsaControl : "Master",
                isDefault: true,
                nativeNode: null
            }]
        }
        return []
    }

    function clampVolume(value) {
        return Math.max(0, Math.min(1, Number(value)))
    }

    function setVolume(value) {
        const volume = clampVolume(value)
        root.lastError = ""

        if (root.pipewireUsable) {
            const sink = root.pipewireSink
            if (sink && sink.audio) {
                sink.audio.muted = false
                sink.audio.volume = volume
            }
            return
        }

        if (root.pulseAvailable) {
            root.pulseVolume = volume
            root.pulseMuted = false
            volumeDebounce.restart()
            return
        }

        if (root.alsaAvailable) {
            root.alsaVolume = volume
            root.alsaMuted = false
            volumeDebounce.restart()
        }
    }

    function setMuted(value) {
        root.lastError = ""

        if (root.pipewireUsable) {
            const sink = root.pipewireSink
            if (sink && sink.audio)
                sink.audio.muted = value
            return
        }

        if (root.pulseAvailable) {
            root.pulseMuted = value
            pulseMuteProc.command = ["pactl", "set-sink-mute", "@DEFAULT_SINK@", value ? "1" : "0"]
            pulseMuteProc.running = true
            return
        }

        if (root.alsaAvailable && root.alsaControl.length > 0) {
            root.alsaMuted = value
            alsaMuteProc.command = ["amixer", "-q", "sset", root.alsaControl, value ? "mute" : "unmute"]
            alsaMuteProc.running = true
        }
    }

    function toggleMuted() {
        setMuted(!root.muted)
    }

    function adjustVolume(delta) {
        setVolume(root.volume + delta)
    }

    function setDefaultSink(sink) {
        if (!sink)
            return

        if (root.pipewireUsable && sink.nativeNode) {
            Pipewire.preferredDefaultAudioSink = sink.nativeNode
            return
        }

        if (root.pulseAvailable) {
            root.pulseDefault = sink.id
            for (let i = 0; i < root.pulseSinks.length; i++) {
                const item = root.pulseSinks[i]
                if (item.id === sink.id) {
                    root.pulseVolume = item.volume
                    root.pulseMuted = item.muted
                }
            }
            pulseDefaultProc.command = ["pactl", "set-default-sink", sink.id]
            pulseDefaultProc.running = true
            pulsePollProc.running = true
        }
    }

    function applyFallbackVolume() {
        if (root.pulseAvailable) {
            pulseVolumeProc.command = ["pactl", "set-sink-volume", "@DEFAULT_SINK@", Math.round(root.pulseVolume * 100) + "%"]
            pulseVolumeProc.running = true
        } else if (root.alsaAvailable && root.alsaControl.length > 0) {
            alsaVolumeProc.command = ["amixer", "-q", "sset", root.alsaControl, Math.round(root.alsaVolume * 100) + "%", "unmute"]
            alsaVolumeProc.running = true
        }
    }

    function pollFallback() {
        if (root.pipewireUsable)
            return
        if (!pulsePollProc.running)
            pulsePollProc.running = true
        if (!root.pulseAvailable && !alsaPollProc.running)
            alsaPollProc.running = true
    }

    function pulseSinkVolume(sink) {
        const channels = sink && sink.volume ? Object.keys(sink.volume) : []
        if (channels.length === 0)
            return 0
        let total = 0
        for (let i = 0; i < channels.length; i++) {
            const channel = sink.volume[channels[i]]
            total += Number(channel && channel.value ? channel.value : 0)
        }
        return clampVolume(total / channels.length / 65536)
    }

    function parsePulse(output) {
        const sections = String(output).split("__SINKS__")
        if (sections.length < 2) {
            root.pulseAvailable = false
            root.pulseSinks = []
            return
        }

        try {
            const info = JSON.parse(sections[0].trim())
            const sinks = JSON.parse(sections[1].trim())
            root.pulseDefault = info.default_sink_name || ""
            root.pulseAvailable = true

            let records = []
            let current = null
            for (let i = 0; i < sinks.length; i++) {
                const sink = sinks[i]
                const record = {
                    id: sink.name,
                    description: sink.description && sink.description.length > 0 ? sink.description : sink.name,
                    isDefault: sink.name === root.pulseDefault,
                    volume: root.pulseSinkVolume(sink),
                    muted: !!sink.mute,
                    nativeNode: null
                }
                records.push(record)
                if (record.isDefault)
                    current = record
            }
            if (!current && records.length > 0) {
                current = records[0]
                records[0].isDefault = true
            }

            root.pulseSinks = records
            if (current) {
                root.pulseVolume = current.volume
                root.pulseMuted = current.muted
            }
        } catch (error) {
            root.pulseAvailable = false
            root.pulseSinks = []
        }
    }

    function parseAlsa(output) {
        const text = String(output)
        const name = text.match(/Simple mixer control '([^']+)'/)
        const percent = text.match(/\[(\d+)%\]/)
        if (!name || !percent) {
            root.alsaAvailable = false
            root.alsaVolume = 0
            root.alsaMuted = false
            return
        }

        root.alsaControl = name[1]
        root.alsaAvailable = true
        root.alsaVolume = clampVolume(parseInt(percent[1]) / 100)
        root.alsaMuted = /\[off\]/.test(text)
    }

    Component.onCompleted: root.pollFallback()

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: root.pollFallback()
    }

    Timer {
        id: volumeDebounce
        interval: 60
        repeat: false
        onTriggered: root.applyFallbackVolume()
    }

    Process {
        id: pulsePollProc
        command: ["sh", "-c", "command -v pactl >/dev/null 2>&1 || exit 0; timeout 4 pactl --format=json info 2>/dev/null; printf '\\n__SINKS__\\n'; timeout 6 pactl --format=json list sinks 2>/dev/null"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: root.parsePulse(text)
        }
    }

    Process {
        id: pulseVolumeProc
        running: false
        onExited: (code) => {
            if (code !== 0)
                root.lastError = "Could not set PulseAudio volume"
        }
    }

    Process {
        id: pulseMuteProc
        running: false
        onExited: (code) => {
            if (code !== 0)
                root.lastError = "Could not change PulseAudio mute"
        }
    }

    Process {
        id: pulseDefaultProc
        running: false
        onExited: (code) => {
            if (code !== 0)
                root.lastError = "Could not change the default output"
            else
                pulsePollProc.running = true
        }
    }

    Process {
        id: alsaPollProc
        command: ["sh", "-c", "command -v amixer >/dev/null 2>&1 || exit 0; amixer sget Master 2>/dev/null || amixer sget PCM 2>/dev/null || amixer sget Headphone 2>/dev/null"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: root.parseAlsa(text)
        }
    }

    Process {
        id: alsaVolumeProc
        running: false
        onExited: (code) => {
            if (code !== 0)
                root.lastError = "Could not set ALSA volume"
        }
    }

    Process {
        id: alsaMuteProc
        running: false
        onExited: (code) => {
            if (code !== 0)
                root.lastError = "Could not change ALSA mute"
        }
    }
}
