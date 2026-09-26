import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

ShellRoot {
    id: root

    Variants {
        model: Quickshell.screens
        Bar {}
    }

    // Bind the audio nodes we display so their volume/mute properties stay live.
    PwObjectTracker {
        objects: {
            let out = []
            const sink = Pipewire.defaultAudioSink
            if (sink)
                out.push(sink)
            const nodes = Pipewire.nodes.values
            for (let i = 0; i < nodes.length; i++) {
                const n = nodes[i]
                if (n.isSink && !n.isStream && n.audio)
                    out.push(n)
            }
            return out
        }
    }

    IpcHandler {
        target: "pilo"

        function toggle(panel: string) {
            const screen = Panels.focusedScreen()
            if (!screen)
                return
            if (panel === "launcher")
                Panels.toggleLauncher(screen, false)
            else
                Panels.toggle(panel, screen)
        }

        function close() {
            Panels.close()
        }
    }
}
