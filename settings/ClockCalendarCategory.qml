import QtQuick
import QtQuick.Layouts
import qs
import qs.widgets

ColumnLayout {
    id: root
    spacing: 16

    readonly property bool showDate: Settings.clockShow === "datetime" || Settings.clockShow === "daydatetime"
    readonly property bool showDay: Settings.clockShow === "daytime" || Settings.clockShow === "daydatetime"

    CategoryHeading {
        title: "Clock / Calendar"
        subtitle: "How the bar clock reads, and options for the calendar panel."
    }

    // ── Clock ───────────────────────────────────────────────
    Text {
        text: "Clock"
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        font.bold: true
        color: Theme.fg
    }

    SettingRow {
        label: "Time format"
        hint: "24-hour, 12-hour with AM/PM, or your own format."

        Item { Layout.fillWidth: true }

        Segmented {
            options: [
                { key: "24", label: "24h" },
                { key: "12", label: "12h" },
                { key: "custom", label: "Custom" }
            ]
            value: Settings.clockFormat
            onSelected: (key) => Settings.setClockFormat(key)
        }
    }

    SettingRow {
        visible: Settings.clockFormat === "custom"
        label: "Time format string"
        hint: "Qt pattern, e.g. \"hh:mm AP\", \"h:mm ap\", or \"HH:mm:ss\"."

        TextField {
            Layout.fillWidth: true
            placeholder: "hh:mm AP"
            text: Settings.clockCustomFormat
            onTextChanged: Settings.setClockCustomFormat(text)
        }
    }

    SettingRow {
        label: "Show on bar"
        hint: "What the clock widget displays (day and date come before the time)."

        Item { Layout.fillWidth: true }

        Segmented {
            options: [
                { key: "time", label: "Clock" },
                { key: "datetime", label: "Date + clock" },
                { key: "daytime", label: "Day + clock" },
                { key: "daydatetime", label: "Day + date + clock" }
            ]
            value: Settings.clockShow
            onSelected: (key) => Settings.setClockShow(key)
        }
    }

    SettingRow {
        visible: root.showDate
        label: "Date format"
        hint: "The order and style of the date."

        Item { Layout.fillWidth: true }

        Dropdown {
            Layout.preferredWidth: 210
            options: ClockFormat.datePresets
            value: Settings.clockDateFormat
            onSelected: (key) => Settings.setClockDateFormat(key)
        }
    }

    SettingRow {
        visible: root.showDate && Settings.clockDateFormat === "custom"
        label: "Date format string"
        hint: "Qt pattern, e.g. \"ddd d MMM\" or \"d MMMM yyyy\"."

        TextField {
            Layout.fillWidth: true
            placeholder: "yyyy-MM-dd"
            text: Settings.clockCustomDate
            onTextChanged: Settings.setClockCustomDate(text)
        }
    }

    SettingRow {
        visible: root.showDay
        label: "Day format"
        hint: "How long the day name is."

        Item { Layout.fillWidth: true }

        Segmented {
            options: [
                { key: "full", label: "Monday" },
                { key: "short", label: "Mon" }
            ]
            value: Settings.clockDayFormat
            onSelected: (key) => Settings.setClockDayFormat(key)
        }
    }

    // ── Calendar ────────────────────────────────────────────
    Text {
        Layout.topMargin: 4
        text: "Calendar"
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        font.bold: true
        color: Theme.fg
    }

    SettingRow {
        label: "Holidays"
        hint: "Highlight public holidays in the month grid."

        Item { Layout.fillWidth: true }

        Segmented {
            options: [
                { key: "none", label: "None" },
                { key: "se", label: "Sweden" }
            ]
            value: Settings.holidays
            onSelected: (key) => Settings.setHolidays(key)
        }
    }

    SettingRow {
        label: "First day of week"
        hint: "Which weekday starts each row."

        Item { Layout.fillWidth: true }

        Segmented {
            options: [
                { key: "monday", label: "Monday" },
                { key: "sunday", label: "Sunday" }
            ]
            value: Settings.calendarWeekStart
            onSelected: (key) => Settings.setCalendarWeekStart(key)
        }
    }

    SettingRow {
        label: "Week numbers"
        hint: "Show the ISO week number beside each row."

        Item { Layout.fillWidth: true }

        Toggle {
            checked: Settings.calendarWeekNumbers
            onToggled: (v) => Settings.setCalendarWeekNumbers(v)
        }
    }

    SettingRow {
        label: "Holiday name"
        hint: "Show the hovered day's holiday in the footer."

        Item { Layout.fillWidth: true }

        Toggle {
            checked: Settings.calendarHolidayFooter
            onToggled: (v) => Settings.setCalendarHolidayFooter(v)
        }
    }
}
