import QtQuick
import QtQuick.Layouts
import qs
import qs.widgets

ColumnLayout {
    id: root
    spacing: 16

    CategoryHeading {
        title: "Calendar"
        subtitle: "Holiday marks shown in the clock calendar."
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
}