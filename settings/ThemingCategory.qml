import QtQuick
import QtQuick.Layouts
import qs
import qs.widgets

// Theme picker. Each card previews a scheme's own colours (not the active
// theme's), so the whole palette reads before you commit to it. Selecting one
// writes Settings.theme; Theme.qml re-resolves and the bar repaints live.
ColumnLayout {
    id: root
    spacing: 16

    CategoryHeading {
        title: "Theming"
        subtitle: "The bar's colour scheme. Hyprland's borders, gaps, rounding, and blur follow too (see below), as do KDE apps like Dolphin and the foot terminal."
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
        subtitle: "Hyprland's window gaps, border, rounding, and blur. Applied to the compositor live."
    }

    SettingRow {
        label: "Inner gaps"
        hint: "Space between tiled windows."

        Slider {
            Layout.fillWidth: true
            value: Settings.hyprGapsIn / 30
            onMoved: (v) => Settings.setHyprGapsIn(v * 30)
        }

        Text {
            Layout.preferredWidth: 40
            horizontalAlignment: Text.AlignRight
            text: Settings.hyprGapsIn + "px"
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize - 1
            color: Theme.fg
        }
    }

    SettingRow {
        label: "Outer gaps"
        hint: "Space between windows and the screen edge."

        Slider {
            Layout.fillWidth: true
            value: Settings.hyprGapsOut / 50
            onMoved: (v) => Settings.setHyprGapsOut(v * 50)
        }

        Text {
            Layout.preferredWidth: 40
            horizontalAlignment: Text.AlignRight
            text: Settings.hyprGapsOut + "px"
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize - 1
            color: Theme.fg
        }
    }

    SettingRow {
        label: "Border size"
        hint: "Width of the window border."

        Slider {
            Layout.fillWidth: true
            value: Settings.hyprBorderSize / 10
            onMoved: (v) => Settings.setHyprBorderSize(v * 10)
        }

        Text {
            Layout.preferredWidth: 40
            horizontalAlignment: Text.AlignRight
            text: Settings.hyprBorderSize + "px"
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize - 1
            color: Theme.fg
        }
    }

    SettingRow {
        label: "Window rounding"
        hint: "Corner radius of windows."

        Slider {
            Layout.fillWidth: true
            value: Settings.hyprRounding / 24
            onMoved: (v) => Settings.setHyprRounding(v * 24)
        }

        Text {
            Layout.preferredWidth: 40
            horizontalAlignment: Text.AlignRight
            text: Settings.hyprRounding + "px"
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize - 1
            color: Theme.fg
        }
    }

    SettingRow {
        label: "Blur"
        hint: "Frost translucent windows."

        Item { Layout.fillWidth: true }

        Toggle {
            checked: Settings.hyprBlurEnabled
            onToggled: (value) => Settings.setHyprBlurEnabled(value)
        }
    }

    SettingRow {
        available: Settings.hyprBlurEnabled
        disabledReason: "Turn on Blur to set its size."
        label: "Blur size"
        hint: "Higher is softer and costs more GPU."

        Slider {
            Layout.fillWidth: true
            value: (Settings.hyprBlurSize - 1) / 19
            onMoved: (v) => Settings.setHyprBlurSize(1 + v * 19)
        }

        Text {
            Layout.preferredWidth: 40
            horizontalAlignment: Text.AlignRight
            text: Settings.hyprBlurSize + "px"
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize - 1
            color: Theme.fg
        }
    }
}
