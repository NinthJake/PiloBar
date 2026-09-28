pragma Singleton

import Quickshell

// Registry of the building blocks the bar can render, and the default
// left/center/right arrangement. The settings app's Widgets category edits the
// layout; Bar.qml turns each stored key into a component.
Singleton {
    id: root

    readonly property var available: [
        { key: "launcher", label: "Launcher" },
        { key: "taskbar", label: "Running apps" },
        { key: "workspaces", label: "Workspaces" },
        { key: "clock", label: "Clock" },
        { key: "network", label: "Network & Bluetooth" },
        { key: "sound", label: "Sound" },
        { key: "settings", label: "Settings" },
        { key: "spacer", label: "Spacer" }
    ]

    readonly property var sections: [
        { key: "left", label: "Left" },
        { key: "center", label: "Center" },
        { key: "right", label: "Right" }
    ]

    function meta(key) {
        for (let i = 0; i < available.length; i++) {
            if (available[i].key === key)
                return available[i]
        }
        return { key: key, label: key }
    }

    function label(key) {
        return meta(key).label
    }

    function known(key) {
        for (let i = 0; i < available.length; i++) {
            if (available[i].key === key)
                return true
        }
        return false
    }

    // A fresh copy each call so mutations never touch the shared default.
    function defaultLayout() {
        return {
            left: ["launcher", "taskbar"],
            center: ["workspaces"],
            right: ["clock", "network", "sound", "settings"]
        }
    }
}
