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
        hint: "Flush to the edge, a centered capsule, or separate islands."

        Item { Layout.fillWidth: true }

        Segmented {
            options: [
                { key: "flush", label: "Flush" },
                { key: "centered", label: "Centered" },
                { key: "islands", label: "Islands" }
            ]
            value: Settings.chrome
            onSelected: (key) => Settings.setChrome(key)
        }
    }

    SettingRow {
        available: Settings.chrome !== "flush"
        disabledReason: "Only used by the Centered and Islands chrome."
        label: "Shape"
        hint: "How the bar meets the screen edge in Centered and Islands modes."

        Item { Layout.fillWidth: true }

        Segmented {
            options: [
                { key: "rounded", label: "Rounded" },
                { key: "s-curve", label: "S-curve" },
                { key: "bevel", label: "Bevel" }
            ]
            value: Settings.shape
            onSelected: (key) => Settings.setShape(key)
        }
    }

    SettingRow {
        available: Settings.chrome !== "flush"
        disabledReason: "Only used by the Centered and Islands chrome."
        label: "Rounding"
        hint: "Corner radius, on the corners that do not touch a screen edge, or on every corner with Attach off."

        Slider {
            Layout.fillWidth: true
            value: Settings.rounding / 24
            onMoved: (v) => Settings.setRounding(v * 24)
        }

        Text {
            Layout.preferredWidth: 40
            horizontalAlignment: Text.AlignRight
            text: Settings.rounding + "px"
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize - 1
            color: Theme.fg
        }
    }

    SettingRow {
        available: Settings.chrome !== "flush"
        disabledReason: "Only used by the Centered and Islands chrome."
        label: "Attach to screen edges"
        hint: "Square off corners that meet a screen edge. For S-curve and Bevel this squares only the left/right edge corners, keeping the shape on the top."

        Item { Layout.fillWidth: true }

        Toggle {
            checked: Settings.attachEdges
            onToggled: (value) => Settings.setAttachEdges(value)
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
            value: (Settings.opacity - 0.5) / 0.5
            onMoved: (v) => Settings.setOpacity(Math.round((0.5 + v * 0.5) * 100) / 100)
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
        label: "Auto-hide"
        hint: "Slide the bar off its edge and reveal it on edge hover."

        Item { Layout.fillWidth: true }

        Toggle {
            checked: Settings.autoHide
            onToggled: (value) => Settings.setAutoHide(value)
        }
    }

    SettingRow {
        available: Settings.autoHide
        disabledReason: "Turn on Auto-hide to set a delay."
        label: "Hide delay"
        hint: "How long the pointer must be away before the bar hides."

        Slider {
            Layout.fillWidth: true
            value: (Settings.autoHideDelay - 100) / 1900
            onMoved: (v) => Settings.setAutoHideDelay(100 + v * 1900)
        }

        Text {
            Layout.preferredWidth: 40
            horizontalAlignment: Text.AlignRight
            text: (Math.round(Settings.autoHideDelay / 100) / 10) + "s"
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize - 1
            color: Theme.fg
        }
    }

    SettingRow {
        label: "Over windows"
        hint: "Float the bar over windows instead of reserving space for it. Works with or without Auto-hide."

        Item { Layout.fillWidth: true }

        Toggle {
            checked: Settings.overWindows
            onToggled: (value) => Settings.setOverWindows(value)
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
