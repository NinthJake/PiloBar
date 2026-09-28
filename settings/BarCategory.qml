import QtQuick
import QtQuick.Layouts
import qs
import qs.widgets

ColumnLayout {
    id: root
    spacing: 16

    CategoryHeading {
        title: "Bar"
        subtitle: "Shape, edge, transparency, and what the bar reserves."
    }

    SettingRow {
        label: "Chrome"
        hint: "Flush to the edge, a floating pill, or separate islands."

        Item { Layout.fillWidth: true }

        Segmented {
            options: [
                { key: "flush", label: "Flush" },
                { key: "pill", label: "Pill" },
                { key: "islands", label: "Islands" }
            ]
            value: Settings.chrome
            onSelected: (key) => Settings.setChrome(key)
        }
    }

    SettingRow {
        label: "Edge"
        hint: "Which screen edge the bar sits on."

        Item { Layout.fillWidth: true }

        Segmented {
            options: [
                { key: "top", label: "Top" },
                { key: "bottom", label: "Bottom" }
            ]
            value: Settings.edge
            onSelected: (key) => Settings.setEdge(key)
        }
    }

    SettingRow {
        label: "Opacity"
        hint: "Bar and panel fill transparency."

        Slider {
            Layout.fillWidth: true
            value: (Settings.opacity - 0.6) / 0.4
            onMoved: (v) => Settings.setOpacity(Math.round((0.6 + v * 0.4) * 100) / 100)
        }

        Text {
            Layout.preferredWidth: 40
            horizontalAlignment: Text.AlignRight
            text: Math.round(Settings.opacity * 100) + "%"
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize - 1
            color: Theme.fg
        }
    }

    SettingRow {
        label: "Gap"
        hint: "Distance from the screen edge in Pill and Islands modes."

        Slider {
            Layout.fillWidth: true
            value: Settings.gap / 24
            onMoved: (v) => Settings.setGap(v * 24)
        }

        Text {
            Layout.preferredWidth: 40
            horizontalAlignment: Text.AlignRight
            text: Settings.gap + "px"
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize - 1
            color: Theme.fg
        }
    }

    SettingRow {
        label: "Workspaces"
        hint: "Show all ten workspaces, or only the occupied ones."

        Item { Layout.fillWidth: true }

        Segmented {
            options: [
                { key: "all", label: "All" },
                { key: "occupied", label: "Occupied" }
            ]
            value: Settings.workspaceMode
            onSelected: (key) => Settings.setWorkspaceMode(key)
        }
    }
}