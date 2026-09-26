import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.widgets

PanelCard {
    id: root

    implicitHeight: content.implicitHeight + 28

    ColumnLayout {
        id: content
        anchors.fill: parent
        anchors.margins: 14
        spacing: 12

        Text {
            text: "Bar settings"
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            font.bold: true
            color: Theme.fg
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                Layout.preferredWidth: 110
                text: "Chrome"
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize - 1
                color: Theme.muted
            }

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

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                Layout.preferredWidth: 110
                text: "Edge"
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize - 1
                color: Theme.muted
            }

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

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                Layout.preferredWidth: 110
                text: "Opacity"
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize - 1
                color: Theme.muted
            }

            Slider {
                id: opacitySlider
                Layout.fillWidth: true
                value: (Settings.opacity - 0.6) / 0.4
                onMoved: (v) => Settings.setOpacity(Math.round((0.6 + v * 0.4) * 100) / 100)
            }

            Text {
                Layout.preferredWidth: 36
                horizontalAlignment: Text.AlignRight
                text: Math.round(Settings.opacity * 100) + "%"
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize - 1
                color: Theme.fg
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                Layout.preferredWidth: 110
                text: "Gap"
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize - 1
                color: Theme.muted
            }

            Slider {
                id: gapSlider
                Layout.fillWidth: true
                value: Settings.gap / 24
                onMoved: (v) => Settings.setGap(v * 24)
            }

            Text {
                Layout.preferredWidth: 36
                horizontalAlignment: Text.AlignRight
                text: Settings.gap + "px"
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize - 1
                color: Theme.fg
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                Layout.preferredWidth: 110
                text: "Workspaces"
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize - 1
                color: Theme.muted
            }

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

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                Layout.preferredWidth: 110
                text: "Holidays"
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize - 1
                color: Theme.muted
            }

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

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                Layout.preferredWidth: 110
                text: "Power profile"
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize - 1
                color: Theme.muted
            }

            Item { Layout.fillWidth: true }

            Segmented {
                options: {
                    let o = [{ key: "powersaver", label: "Battery" }, { key: "balanced", label: "Balanced" }]
                    if (Power.hasPerformance)
                        o.push({ key: "performance", label: "Performance" })
                    return o
                }
                value: Power.profile === "power-saver" ? "powersaver" : (Power.profile === "performance" ? "performance" : "balanced")
                onSelected: (key) => Power.setProfile(key === "powersaver" ? "power-saver" : (key === "performance" ? "performance" : "balanced"))
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                Layout.preferredWidth: 110
                text: "Launcher sort"
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize - 1
                color: Theme.muted
            }

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

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                Layout.preferredWidth: 110
                text: "File search"
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize - 1
                color: Theme.muted
            }

            Item { Layout.fillWidth: true }

            Toggle {
                checked: Settings.fileSearch
                onToggled: (v) => Settings.setFileSearch(v)
            }
        }
    }
}
