pragma Singleton

import Quickshell
import Quickshell.Hyprland
import QtQuick

Singleton {
    id: root

    // "" | launcher | calendar | network | sound | settings | monitors | windows
    property string active: ""
    property var ownerScreen: null
    property real openedAt: 0

    // Window menu (running apps taskbar): which app keys to list, anchored to
    // the clicked icon's x/width within the bar.
    property var windowsMenuApps: []
    property real menuAnchorX: 0
    property real menuAnchorW: 0

    // Launcher has two presentations: anchored under the bar icon (bar button)
    // or centered spotlight (Super / IPC).
    property bool launcherAnchored: true

    function focusedScreen() {
        const screens = Quickshell.screens
        for (let i = 0; i < screens.length; i++) {
            const mon = Hyprland.monitorFor(screens[i])
            if (mon && mon.focused)
                return screens[i]
        }
        return screens.length > 0 ? screens[0] : null
    }

    function isOpen(name, screen) {
        return root.active === name && root.ownerScreen === screen
    }

    function open(name, screen) {
        root.active = name
        root.ownerScreen = screen
        root.openedAt = Date.now()
    }

    function close() {
        root.active = ""
        root.ownerScreen = null
    }

    // HyprlandFocusGrab can report a clear while the popup is still mapping.
    // Only honor a clear for the panel that is currently open, and only after
    // it has had a moment to settle.
    function handleCleared(name) {
        if (root.active === name && Date.now() - root.openedAt > 250)
            close()
    }

    function toggle(name, screen) {
        if (isOpen(name, screen))
            close()
        else
            open(name, screen)
    }

    function openWindowsMenu(apps, anchorX, anchorW, screen) {
        root.windowsMenuApps = apps
        root.menuAnchorX = anchorX
        root.menuAnchorW = anchorW
        open("windows", screen)
    }

    function toggleLauncher(screen, anchored) {
        if (isOpen("launcher", screen) && root.launcherAnchored === anchored)
            close()
        else {
            root.launcherAnchored = anchored
            open("launcher", screen)
        }
    }
}
