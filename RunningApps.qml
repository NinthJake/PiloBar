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

    Component.onCompleted: refresh()

    function refresh() {
        if (!clientsProc.running)
            clientsProc.running = true
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
            g.icon = (entry && entry.icon && entry.icon.length > 0) ? Quickshell.iconPath(entry.icon, "application-x-executable") : Quickshell.iconPath(g.key.toLowerCase(), "application-x-executable")
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
