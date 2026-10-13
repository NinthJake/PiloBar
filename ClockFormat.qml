pragma Singleton

import Quickshell
import QtQuick

// Formats the bar clock from Settings. Kept in one place so the clock widget
// and the settings preview agree on the same string.
Singleton {
    id: root

    // key -> Qt date pattern. "custom" reads Settings.clockCustomDate.
    readonly property var datePresets: [
        { key: "iso", label: "2026-10-14", pattern: "yyyy-MM-dd" },
        { key: "dmy", label: "14/10/2026", pattern: "dd/MM/yyyy" },
        { key: "mdy", label: "10/14/2026", pattern: "MM/dd/yyyy" },
        { key: "dMy", label: "14 Oct 2026", pattern: "dd MMM yyyy" },
        { key: "MdY", label: "Oct 14, 2026", pattern: "MMM d, yyyy" },
        { key: "full", label: "October 14, 2026", pattern: "MMMM d, yyyy" },
        { key: "custom", label: "Custom", pattern: "" }
    ]

    function datePattern() {
        if (Settings.clockDateFormat === "custom")
            return Settings.clockCustomDate.length > 0 ? Settings.clockCustomDate : "yyyy-MM-dd"
        for (let i = 0; i < datePresets.length; i++) {
            if (datePresets[i].key === Settings.clockDateFormat)
                return datePresets[i].pattern
        }
        return "yyyy-MM-dd"
    }

    function timePattern() {
        if (Settings.clockFormat === "12")
            return "hh:mm AP"
        if (Settings.clockFormat === "custom")
            return Settings.clockCustomFormat.length > 0 ? Settings.clockCustomFormat : "HH:mm"
        return "HH:mm"
    }

    // Custom formats using seconds need a per-second clock (see Clock.qml).
    readonly property bool wantsSeconds: timePattern().indexOf("s") !== -1

    function timeText(d) {
        return Qt.formatDateTime(d, timePattern())
    }

    function dateText(d) {
        return Qt.formatDateTime(d, datePattern())
    }

    function dayText(d) {
        return Qt.formatDateTime(d, Settings.clockDayFormat === "short" ? "ddd" : "dddd")
    }

    // What the bar shows. Order is fixed: day/date first, then the time.
    function barText(d) {
        switch (Settings.clockShow) {
        case "datetime":
            return dateText(d) + " " + timeText(d)
        case "daytime":
            return dayText(d) + " " + timeText(d)
        case "daydatetime":
            return dayText(d) + " " + dateText(d) + " " + timeText(d)
        default:
            return timeText(d)
        }
    }
}
