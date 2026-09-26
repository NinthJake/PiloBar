pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    FileView {
        id: file
        path: Quickshell.statePath("settings.json")
        watchChanges: false
        onAdapterUpdated: writeAdapter()

        JsonAdapter {
            id: store
            property string chrome: "flush"
            property string edge: "top"
            property real opacity: 0.92
            property int gap: 8
            property string workspaceMode: "all"
            property string launcherSort: "frequent"
            property bool fileSearch: true
            property string holidays: "se"
            property var usage: ({})
        }
    }

    Process {
        command: ["mkdir", "-p", Quickshell.stateDir]
        running: true
    }

    readonly property alias chrome: store.chrome
    readonly property alias edge: store.edge
    readonly property alias opacity: store.opacity
    readonly property alias gap: store.gap
    readonly property alias workspaceMode: store.workspaceMode
    readonly property alias launcherSort: store.launcherSort
    readonly property alias fileSearch: store.fileSearch
    readonly property alias holidays: store.holidays

    function setChrome(v) { store.chrome = v }
    function setEdge(v) { store.edge = v }
    function setOpacity(v) { store.opacity = v }
    function setGap(v) { store.gap = Math.max(0, Math.min(24, Math.round(v))) }
    function setWorkspaceMode(v) { store.workspaceMode = v }
    function setLauncherSort(v) { store.launcherSort = v }
    function setFileSearch(v) { store.fileSearch = v }
    function setHolidays(v) { store.holidays = v }

    function usageFor(id) {
        const u = store.usage
        if (u && u[id])
            return u[id]
        return { count: 0, last: 0 }
    }

    function recordLaunch(id) {
        let u = {}
        const current = store.usage
        if (current) {
            for (const k in current)
                u[k] = current[k]
        }
        const rec = u[id] ? u[id] : { count: 0, last: 0 }
        rec.count = (rec.count || 0) + 1
        rec.last = Date.now()
        u[id] = rec
        store.usage = u
    }
}
