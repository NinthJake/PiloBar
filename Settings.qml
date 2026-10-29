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
        onLoaded: root.migrate()

        JsonAdapter {
            id: store
            property string theme: Themes.defaultId
            property string chrome: "flush"
            property string shape: "rounded"
            property string edge: "top"
            property real opacity: 0.92
            property int rounding: 14
            property bool attachEdges: true
            property bool autoHide: false
            property int autoHideDelay: 300
            property bool overWindows: false
            property string workspaceMode: "all"
            property string launcherSort: "frequent"
            property bool fileSearch: true
            property string holidays: "se"
            // Clock (bar widget).
            property string clockFormat: "24"
            property string clockCustomFormat: "hh:mm AP"
            property string clockShow: "time"
            property string clockDateFormat: "iso"
            property string clockCustomDate: "yyyy-MM-dd"
            property string clockDayFormat: "full"
            // Calendar panel.
            property string calendarWeekStart: "monday"
            property bool calendarWeekNumbers: false
            property bool calendarHolidayFooter: true
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

    readonly property alias theme: store.theme
    readonly property alias chrome: store.chrome
    readonly property alias shape: store.shape
    readonly property alias edge: store.edge
    readonly property alias opacity: store.opacity
    readonly property alias rounding: store.rounding
    readonly property alias attachEdges: store.attachEdges
    readonly property alias autoHide: store.autoHide
    readonly property alias autoHideDelay: store.autoHideDelay
    readonly property alias overWindows: store.overWindows
    readonly property alias workspaceMode: store.workspaceMode
    readonly property alias launcherSort: store.launcherSort
    readonly property alias fileSearch: store.fileSearch
    readonly property alias holidays: store.holidays
    readonly property alias clockFormat: store.clockFormat
    readonly property alias clockCustomFormat: store.clockCustomFormat
    readonly property alias clockShow: store.clockShow
    readonly property alias clockDateFormat: store.clockDateFormat
    readonly property alias clockCustomDate: store.clockCustomDate
    readonly property alias clockDayFormat: store.clockDayFormat
    readonly property alias calendarWeekStart: store.calendarWeekStart
    readonly property alias calendarWeekNumbers: store.calendarWeekNumbers
    readonly property alias calendarHolidayFooter: store.calendarHolidayFooter
    readonly property alias layout: store.layout

    function setTheme(v) { store.theme = Themes.has(v) ? v : Themes.defaultId }
    function setChrome(v) { store.chrome = v }
    function setShape(v) { store.shape = v }
    function setEdge(v) { store.edge = v }
    function setOpacity(v) { store.opacity = v }
    function setRounding(v) { store.rounding = Math.max(0, Math.min(24, Math.round(v))) }
    function setAttachEdges(v) { store.attachEdges = v }
    function setAutoHide(v) { store.autoHide = v }
    function setAutoHideDelay(v) { store.autoHideDelay = Math.max(100, Math.min(2000, Math.round(v))) }
    function setOverWindows(v) { store.overWindows = v }
    function setWorkspaceMode(v) { store.workspaceMode = v }
    function setLauncherSort(v) { store.launcherSort = v }
    function setFileSearch(v) { store.fileSearch = v }
    function setHolidays(v) { store.holidays = v }
    function setClockFormat(v) { store.clockFormat = (v === "12" || v === "custom") ? v : "24" }
    function setClockCustomFormat(v) { store.clockCustomFormat = v }
    function setClockShow(v) { store.clockShow = (["time", "datetime", "daytime", "daydatetime"].indexOf(v) !== -1) ? v : "time" }
    function setClockDateFormat(v) { store.clockDateFormat = v }
    function setClockCustomDate(v) { store.clockCustomDate = v }
    function setClockDayFormat(v) { store.clockDayFormat = (v === "short") ? "short" : "full" }
    function setCalendarWeekStart(v) { store.calendarWeekStart = (v === "sunday") ? "sunday" : "monday" }
    function setCalendarWeekNumbers(v) { store.calendarWeekNumbers = v }
    function setCalendarHolidayFooter(v) { store.calendarHolidayFooter = v }

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

    function migrate() {
        if (!file.loaded)
            return
        // Theme ids come from Themes.qml; a removed scheme falls back to default.
        if (!Themes.has(store.theme))
            store.theme = Themes.defaultId
        // "pill" chrome was replaced by "centered".
        if (store.chrome === "pill")
            store.chrome = "centered"
        else if (store.chrome !== "flush" && store.chrome !== "centered" && store.chrome !== "islands")
            store.chrome = "flush"
        if (store.shape !== "rounded" && store.shape !== "s-curve" && store.shape !== "bevel")
            store.shape = "rounded"
        // Clock / calendar values.
        if (store.clockFormat !== "24" && store.clockFormat !== "12" && store.clockFormat !== "custom")
            store.clockFormat = "24"
        if (["time", "datetime", "daytime", "daydatetime"].indexOf(store.clockShow) === -1)
            store.clockShow = "time"
        if (store.clockDayFormat !== "short" && store.clockDayFormat !== "full")
            store.clockDayFormat = "full"
        if (store.calendarWeekStart !== "monday" && store.calendarWeekStart !== "sunday")
            store.calendarWeekStart = "monday"
        migrateLayout()
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
        store.theme = Themes.defaultId
        store.chrome = "flush"
        store.shape = "rounded"
        store.edge = "top"
        store.opacity = 0.92
        store.rounding = 14
        store.attachEdges = true
        store.autoHide = false
        store.autoHideDelay = 300
        store.overWindows = false
        store.workspaceMode = "all"
        store.launcherSort = "frequent"
        store.fileSearch = true
        store.holidays = "se"
        store.clockFormat = "24"
        store.clockCustomFormat = "hh:mm AP"
        store.clockShow = "time"
        store.clockDateFormat = "iso"
        store.clockCustomDate = "yyyy-MM-dd"
        store.clockDayFormat = "full"
        store.calendarWeekStart = "monday"
        store.calendarWeekNumbers = false
        store.calendarHolidayFooter = true
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
