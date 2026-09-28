import QtQuick
import QtQuick.Layouts
import qs
import qs.widgets

ColumnLayout {
    id: root
    spacing: 16

    CategoryHeading {
        title: "Launcher"
        subtitle: "Search scope and how results are ordered."
    }

    SettingRow {
        label: "Launcher sort"
        hint: "Default ordering of application results."

        Item { Layout.fillWidth: true }

        Segmented {
            options: [
                { key: "name", label: "Name" },
                { key: "recent", label: "Recent" },
                { key: "frequent", label: "Frequent" }
            ]
            value: Settings.launcherSort
            onSelected: (key) => Settings.setLauncherSort(key)
        }
    }

    SettingRow {
        label: "File search"
        hint: "Search files with plocate alongside applications."

        Item { Layout.fillWidth: true }

        Toggle {
            checked: Settings.fileSearch
            onToggled: (v) => Settings.setFileSearch(v)
        }
    }
}