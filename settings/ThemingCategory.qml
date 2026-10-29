import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs
import qs.widgets

// Theme picker. Each card previews a scheme's own colours (not the active
// theme's), so the whole palette reads before you commit to it. Selecting one
// writes Settings.theme; Theme.qml re-resolves and the bar repaints live.
// Hyprland's own settings are deliberately owned by HyprMod; Pilo only offers
// a launcher for it.
ColumnLayout {
    id: root
    spacing: 16

    property string hyprmodPath: ""
    readonly property bool hyprmodAvailable: hyprmodPath.length > 0

    Process {
        id: hyprmodProbe
        command: ["sh", "-c", "p=$(command -v hyprmod 2>/dev/null); if [ -n \"$p\" ]; then printf '%s\\n' \"$p\"; elif [ -x \"$HOME/.local/bin/hyprmod\" ]; then printf '%s\\n' \"$HOME/.local/bin/hyprmod\"; fi"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.hyprmodPath = text.trim().split("\n")[0]
        }
    }

    CategoryHeading {
        title: "Theming"
        subtitle: "The bar's colour scheme, also used by KDE apps like Dolphin and the foot terminal. Hyprland's own look and feel is managed by HyprMod (below)."
    }

    Flow {
        Layout.fillWidth: true
        spacing: 12

        Repeater {
            model: Themes.presets

            delegate: Rectangle {
                id: card
                required property var modelData

                readonly property bool selected: Settings.theme === card.modelData.id

                width: 216
                height: 96
                radius: Theme.radius
                color: card.modelData.bg
                border.width: card.selected ? 2 : 1
                border.color: card.selected ? card.modelData.teal : Theme.withAlpha(Theme.line, 0.9)

                Behavior on border.color {
                    ColorAnimation { duration: Theme.durFast }
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 6

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Text {
                            Layout.fillWidth: true
                            text: card.modelData.name
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize
                            font.bold: true
                            color: card.modelData.fg
                        }

                        Rectangle {
                            visible: card.selected
                            width: 8
                            height: 8
                            radius: 4
                            color: card.modelData.teal
                        }
                    }

                    // A token strip: accent, secondary, foreground, muted on the
                    // theme's own line colour.
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 22
                        radius: 5
                        color: card.modelData.line

                        Row {
                            anchors.fill: parent
                            anchors.margins: 4
                            spacing: 4

                            Repeater {
                                model: [card.modelData.teal, card.modelData.steel, card.modelData.fg, card.modelData.muted]

                                delegate: Rectangle {
                                    required property var modelData
                                    width: (parent.width - 12) / 4
                                    height: parent.height
                                    radius: 3
                                    color: modelData
                                }
                            }
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: card.modelData.id === "vague" ? "Default" : " "
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize - 3
                        color: card.modelData.muted
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Settings.setTheme(card.modelData.id)
                }
            }
        }
    }

    Text {
        Layout.fillWidth: true
        text: "The choice is saved to the settings file and restored on login."
        wrapMode: Text.WordWrap
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize - 2
        color: Theme.muted
    }

    CategoryHeading {
        title: "Look and feel"
        subtitle: "Hyprland's gaps, borders, rounding, blur, animations, and compositor colours are managed by HyprMod."
    }

    SettingRow {
        available: root.hyprmodAvailable
        disabledReason: "HyprMod is not installed or not on PATH. Install it from https://github.com/BlueManCZ/hyprmod."
        label: "Hyprland settings"
        hint: root.hyprmodAvailable
            ? "HyprMod writes its own hyprland-gui.lua and applies changes live. Pilo no longer edits Hyprland's look and feel."
            : "HyprMod is not installed; Hyprland settings are unchanged."

        ActionButton {
            glyph: Theme.glyphOpen
            label: "Open HyprMod"
            onTriggered: Quickshell.execDetached([root.hyprmodPath])
        }
    }
}
