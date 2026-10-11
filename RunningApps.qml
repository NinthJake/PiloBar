pragma Singleton

import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick

// Shared model + actions for the running-apps taskbar and its window menu.
// Windows come from `hyprctl clients -j` (all workspaces and monitors),
// grouped by class. The list is rebuilt on Hyprland events.
Singleton {
    id: root

    property var groups: []

    // Custom per-app icons in assets/icons/<class>.svg, matched by window class
    // (or the last dotted segment of it). Apps without a custom icon fall back
    // to their desktop-entry icon.
    readonly property string iconsDir: Qt.resolvedUrl("assets/icons").toString().replace("file://", "")
    property var customIcons: []

    Process {
        id: iconsProc
        command: ["sh", "-c", "ls -1 '" + root.iconsDir + "' 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                let names = []
                const lines = text.split("\n")
                for (let i = 0; i < lines.length; i++) {
                    const n = lines[i].trim()
                    if (n.toLowerCase().endsWith(".svg"))
                        names.push(n.substring(0, n.length - 4))
                }
                root.customIcons = names
                root.refresh()
            }
        }
    }

    Process {
        id: clientsProc
        command: ["hyprctl", "clients", "-j"]
        stdout: StdioCollector {
            onStreamFinished: root.parseClients(text)
        }
    }

    Timer {
        id: refreshTimer
        interval: 150
        repeat: false
        onTriggered: root.refresh()
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            refreshTimer.restart()
        }
    }

    Connections {
        target: DesktopEntries
        function onApplicationsChanged() {
            root.refresh()
        }
    }

    Component.onCompleted: {
        refresh()
        iconsProc.running = true
    }

    function refresh() {
        if (!clientsProc.running)
            clientsProc.running = true
    }

    // Resolve an app's icon: a custom asset if one exists for the class, else
    // the desktop-entry icon, else a generic fallback.
    function iconFor(key, entry) {
        const keyLc = key.toLowerCase()
        const dot = keyLc.lastIndexOf(".")
        const last = dot !== -1 ? keyLc.substring(dot + 1) : keyLc
        const custom = root.customIcons
        for (let i = 0; i < custom.length; i++) {
            const c = custom[i].toLowerCase()
            if (c === keyLc || c === last)
                return Qt.resolvedUrl("assets/icons/" + custom[i] + ".svg").toString()
        }
        if (entry && entry.icon && entry.icon.length > 0)
            return Quickshell.iconPath(entry.icon, "application-x-executable")
        return Quickshell.iconPath(keyLc, "application-x-executable")
    }

    function monitorName(id) {
        const mons = Hyprland.monitors.values
        for (let i = 0; i < mons.length; i++) {
            if (mons[i].id === id)
                return mons[i].name
        }
        return ""
    }

    function parseClients(text) {
        let clients
        try {
            clients = JSON.parse(text)
        } catch (e) {
            return
        }

        const map = {}
        const order = []
        for (let i = 0; i < clients.length; i++) {
            const c = clients[i]
            if (c.mapped === false)
                continue
            const key = (c.class && c.class.length > 0) ? String(c.class) : "unknown"
            if (!map[key]) {
                map[key] = { key: key, windows: [], count: 0, active: false }
                order.push(key)
            }
            const g = map[key]
            const active = c.focusHistoryID === 0
            g.windows.push({
                address: String(c.address),
                title: String(c.title),
                activated: active,
                workspaceId: (c.workspace && c.workspace.id !== undefined) ? c.workspace.id : -1,
                monitor: monitorName(c.monitor)
            })
            g.count += 1
            if (active)
                g.active = true
        }

        order.sort((a, b) => a.localeCompare(b))

        let out = []
        for (let i = 0; i < order.length; i++) {
            const g = map[order[i]]
            const entry = DesktopEntries.heuristicLookup(g.key)
            g.icon = root.iconFor(g.key, entry)
            g.name = (entry && entry.name && entry.name.length > 0) ? entry.name : g.key
            // Desktop Entry actions (jump list): Store/Library/etc. for Steam.
            g.actions = (entry && entry.actions) ? entry.actions : []
            out.push(g)
        }

        groups = out
    }

    function group(key) {
        const list = groups
        for (let i = 0; i < list.length; i++) {
            if (list[i].key === key)
                return list[i]
        }
        return null
    }

    function _dispatch(request) {
        Quickshell.execDetached(["hyprctl", "dispatch", request])
    }

    function focusWindow(address) {
        _dispatch('hl.dsp.focus({ window = "address:' + address + '" })')
    }

    function closeWindow(address) {
        _dispatch('hl.dsp.window.close({ window = "address:' + address + '" })')
    }

    function killWindow(address) {
        _dispatch('hl.dsp.window.kill({ window = "address:' + address + '" })')
    }
}
