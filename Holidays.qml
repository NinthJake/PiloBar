pragma Singleton

import QtQuick
import Quickshell

// Holiday dates. Currently only Sweden ("se"); the region switch and the
// forYear() shape are set up so more regions can be added later without
// touching the calendar.
Singleton {
    id: root

    // Anonymous Gregorian computus.
    function _easter(year) {
        const a = year % 19
        const b = Math.floor(year / 100)
        const c = year % 100
        const d = Math.floor(b / 4)
        const e = b % 4
        const f = Math.floor((b + 8) / 25)
        const g = Math.floor((b - f + 1) / 3)
        const h = (19 * a + b - d - g + 15) % 30
        const i = Math.floor(c / 4)
        const k = c % 4
        const l = (32 + 2 * e + 2 * i - h - k) % 7
        const m = Math.floor((a + 11 * h + 22 * l) / 451)
        const month = Math.floor((h + l - 7 * m + 114) / 31)
        const day = ((h + l - 7 * m + 114) % 31) + 1
        return new Date(year, month - 1, day)
    }

    function _shift(base, days) {
        const d = new Date(base.getFullYear(), base.getMonth(), base.getDate())
        d.setDate(d.getDate() + days)
        return d
    }

    // First given weekday (0=Sun) on or after a date.
    function _weekdayOnOrAfter(year, month, day, weekday) {
        const d = new Date(year, month, day)
        const forward = (weekday - d.getDay() + 7) % 7
        d.setDate(d.getDate() + forward)
        return d
    }

    function _sweden(year) {
        const easter = _easter(year)
        const midsummerEve = _weekdayOnOrAfter(year, 5, 19, 5) // Friday, Jun 19-25
        const allSaints = _weekdayOnOrAfter(year, 9, 31, 6) // Saturday, Oct 31-Nov 6

        return [
            { month: 0, day: 1, name: "Nyårsdagen" },
            { month: 0, day: 6, name: "Trettondedag jul" },
            { month: 4, day: 1, name: "Första maj" },
            { month: 5, day: 6, name: "Nationaldagen" },
            { month: 11, day: 24, name: "Julafton" },
            { month: 11, day: 25, name: "Juldagen" },
            { month: 11, day: 26, name: "Annandag jul" },
            { month: 11, day: 31, name: "Nyårsafton" },
            { month: _shift(easter, -2).getMonth(), day: _shift(easter, -2).getDate(), name: "Långfredagen" },
            { month: easter.getMonth(), day: easter.getDate(), name: "Påskdagen" },
            { month: _shift(easter, 1).getMonth(), day: _shift(easter, 1).getDate(), name: "Annandag påsk" },
            { month: _shift(easter, 39).getMonth(), day: _shift(easter, 39).getDate(), name: "Kristi himmelsfärdsdag" },
            { month: midsummerEve.getMonth(), day: midsummerEve.getDate(), name: "Midsommarafton" },
            { month: _shift(midsummerEve, 1).getMonth(), day: _shift(midsummerEve, 1).getDate(), name: "Midsommardagen" },
            { month: allSaints.getMonth(), day: allSaints.getDate(), name: "Alla helgons dag" }
        ]
    }

    function forYear(year, region) {
        if (region === "se")
            return _sweden(year)
        return []
    }

    // "" when the day is not a holiday for the region.
    function nameFor(date, region) {
        if (!date || region === "none" || !region)
            return ""
        const list = forYear(date.getFullYear(), region)
        for (let i = 0; i < list.length; i++) {
            if (list[i].month === date.getMonth() && list[i].day === date.getDate())
                return list[i].name
        }
        return ""
    }

    function isHoliday(date, region) {
        return nameFor(date, region).length > 0
    }
}
