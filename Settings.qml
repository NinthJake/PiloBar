pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    readonly property string path: Quickshell.statePath("settings.json")

    FileView {
        id: file
        path: root.path
        watchChanges: false
        onAdapterUpdated: writeAdapter()
        onLoaded: root.migrateLayout()

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
            property var layout: BarWidgets.defaultLayout()
            property var usage: ({})
        }
    }

    Process {
        command: ["mkdir", "-p", Quickshell.stateDir]
        running: true
    }

    Process {
        id: importProc
        onExited: (code) => {
            if (code === 0)
                file.reload()
        }
    }

    readonly property alias chrome: store.chrome
    readonly property alias edge: store.edge
    readonly property alias opacity: store.opacity
    readonly property alias gap: store.gap
    readonly property alias workspaceMode: store.workspaceMode
    readonly property alias launcherSort: store.launcherSort
    readonly property alias fileSearch: store.fileSearch
    readonly property alias holidays: store.holidays
    readonly property alias layout: store.layout

    function setChrome(v) { store.chrome = v }
    function setEdge(v) { store.edge = v }
    function setOpacity(v) { store.opacity = v }
    function setGap(v) { store.gap = Math.max(0, Math.min(24, Math.round(v))) }
    function setWorkspaceMode(v) { store.workspaceMode = v }
    function setLauncherSort(v) { store.launcherSort = v }
    function setFileSearch(v) { store.fileSearch = v }
    function setHolidays(v) { store.holidays = v }

    function sectionList(section) {
        const l = store.layout
        if (l && l[section])
            return l[section]
        return []
    }

    function _cloneLayout() {
        const l = store.layout
        return {
            left: (l && l.left) ? l.left.slice() : [],
            center: (l && l.center) ? l.center.slice() : [],
            right: (l && l.right) ? l.right.slice() : []
        }
    }

    function setSection(section, list) {
        let l = _cloneLayout()
        l[section] = list.slice()
        store.layout = l
    }

    function addWidget(section, key) {
        let l = _cloneLayout()
        l[section].push(key)
        store.layout = l
    }

    function insertWidget(section, index, key) {
        let l = _cloneLayout()
        const list = l[section]
        const i = Math.max(0, Math.min(list.length, index))
        list.splice(i, 0, key)
        store.layout = l
    }

    function moveWidgetTo(fromSection, fromIndex, toSection, toIndex) {
        let l = _cloneLayout()
        const from = l[fromSection]
        if (fromIndex < 0 || fromIndex >= from.length)
            return
        const key = from.splice(fromIndex, 1)[0]
        const dest = l[toSection]
        let idx = toIndex
        if (fromSection === toSection && toIndex > fromIndex)
            idx -= 1
        idx = Math.max(0, Math.min(dest.length, idx))
        dest.splice(idx, 0, key)
        store.layout = l
    }

    function removeWidget(section, index) {
        let l = _cloneLayout()
        if (index >= 0 && index < l[section].length) {
            l[section].splice(index, 1)
            store.layout = l
        }
    }

    function moveWidget(section, index, delta) {
        let l = _cloneLayout()
        const list = l[section]
        const to = index + delta
        if (index < 0 || index >= list.length || to < 0 || to >= list.length)
            return
        const tmp = list[index]
        list[index] = list[to]
        list[to] = tmp
        store.layout = l
    }

    function resetLayout() {
        store.layout = BarWidgets.defaultLayout()
    }

    // Drop layout entries for widgets that no longer exist (e.g. the removed
    // monitors widget) so they don't linger in the editor. Guarded on `loaded`
    // so a hot reload cannot rewrite the file from the adapter's defaults
    // before the stored values are applied.
    function migrateLayout() {
        if (!file.loaded)
            return
        const l = store.layout
        if (!l)
            return
        let changed = false
        let next = { left: [], center: [], right: [] }
        const sections = ["left", "center", "right"]
        for (let s = 0; s < sections.length; s++) {
            const list = l[sections[s]]
            if (!list)
                continue
            for (let i = 0; i < list.length; i++) {
                if (BarWidgets.known(list[i]))
                    next[sections[s]].push(list[i])
                else
                    changed = true
            }
        }
        if (changed)
            store.layout = next
    }

    function resetAll() {
        store.chrome = "flush"
        store.edge = "top"
        store.opacity = 0.92
        store.gap = 8
        store.workspaceMode = "all"
        store.launcherSort = "frequent"
        store.fileSearch = true
        store.holidays = "se"
        store.layout = BarWidgets.defaultLayout()
    }

    function exportTo(dest) {
        if (!dest || dest.length === 0)
            return
        Quickshell.execDetached(["cp", "-f", root.path, dest])
    }

    function importFrom(src) {
        if (!src || src.length === 0)
            return
        importProc.command = ["cp", "-f", src, root.path]
        importProc.running = true
    }

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
