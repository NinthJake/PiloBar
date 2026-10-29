import QtQuick
import Quickshell
import Quickshell.Io

ShellRoot {
    id: root

    // One bar per screen. The bar window is recreated when the edge changes
    // (Settings -> Bar -> Edge) instead of re-anchoring the live layer surface
    // in place: re-anchoring leaves the surface without a fresh configure on
    // Hyprland, so it stops repainting (opacity changes stop showing) until
    // the shell is restarted. A fresh window gets a fresh surface.
    Component {
        id: barComponent
        Bar {}
    }

    Variants {
        model: Quickshell.screens
        delegate: Loader {
            id: barLoader
            required property var modelData
            sourceComponent: barComponent
            active: true
            onLoaded: item.barScreen = modelData

            Connections {
                target: Settings
                function onEdgeChanged() {
                    barLoader.active = false
                    barRecreateTimer.start()
                }
            }

            Timer {
                id: barRecreateTimer
                interval: 60
                onTriggered: barLoader.active = true
            }
        }
    }

    SettingsWindow {}

    // One native notification daemon for the whole shell. It owns
    // org.freedesktop.Notifications and draws its own toasts.
    Notifications {}

    // Instantiate the KDE and terminal theme owners and apply once at start;
    // they re-apply on theme changes via their own Connections. Hyprland's own
    // look and feel is owned by HyprMod, not by the bar.
    Component.onCompleted: {
        KdeTheme.apply()
        FootTheme.apply()
    }

    IpcHandler {
        target: "pilo"

        function toggle(panel: string) {
            const screen = Panels.focusedScreen()
            if (!screen)
                return
            if (panel === "launcher")
                Panels.toggleLauncher(screen, false)
            else if (panel === "settings")
                SettingsApp.toggle(screen)
            else if (panel === "monitors" || panel === "displays")
                SettingsApp.openAt(screen, "displays")
            else
                Panels.toggle(panel, screen)
        }

        function close() {
            Panels.close()
            SettingsApp.close()
        }
    }
}
