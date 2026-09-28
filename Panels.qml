pragma Singleton

import Quickshell
import Quickshell.Hyprland
import QtQuick

Singleton {
    id: root

    // "" | launcher | calendar | network | sound | windows
    property string active: ""
    property var ownerScreen: null
    property real openedAt: 0

    // Window menu (running apps taskbar): which app keys to list.
    property var windowsMenuApps: []

    // Anchor of the widget that opened the current panel, in bar-local
    // coordinates. -1 means no widget (opened via IPC), so the panel centers.
    property real anchorX: -1
    property real anchorW: 0
    readonly property bool anchorValid: anchorX >= 0

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

    function open(name, screen, item) {
        root.active = name
        root.ownerScreen = screen
        root.openedAt = Date.now()
        setAnchor(item)
    }

    function setAnchor(item) {
        if (item && item.width !== undefined) {
            const p = item.mapToItem(null, 0, 0)
            root.anchorX = p.x
            root.anchorW = item.width
        } else {
            root.anchorX = -1
            root.anchorW = 0
        }
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

    function toggle(name, screen, item) {
        if (isOpen(name, screen))
            close()
        else
            open(name, screen, item)
    }

    function openWindowsMenu(apps, anchorX, anchorW, screen) {
        root.windowsMenuApps = apps
        open("windows", screen)
        root.anchorX = anchorX
        root.anchorW = anchorW
    }

    function toggleLauncher(screen, anchored, item) {
        if (isOpen("launcher", screen) && root.launcherAnchored === anchored)
            close()
        else {
            root.launcherAnchored = anchored
            open("launcher", screen, item)
        }
    }
}
