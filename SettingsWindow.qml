import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.widgets
import qs.settings

// Standalone settings window. The Settings singleton stays the single source of
// truth, so edits here update the bar live.
FloatingWindow {
    id: root

    readonly property var categories: [
        { key: "bar", label: "Bar", glyph: Theme.glyphLayout },
        { key: "displays", label: "Displays", glyph: Theme.glyphMonitor },
        { key: "widgets", label: "Widgets", glyph: Theme.glyphApps },
        { key: "launcher", label: "Launcher", glyph: Theme.glyphSearch },
        { key: "calendar", label: "Calendar", glyph: Theme.glyphCalendar },
        { key: "system", label: "System", glyph: Theme.glyphBolt },
        { key: "advanced", label: "Advanced", glyph: Theme.glyphSettings }
    ]

    function categoryComponent(key) {
        if (key === "displays")
            return compDisplays
        if (key === "widgets")
            return compWidgets
        if (key === "launcher")
            return compLauncher
        if (key === "calendar")
            return compCalendar
        if (key === "system")
            return compSystem
        if (key === "advanced")
            return compAdvanced
        return compBar
    }

    visible: SettingsApp.opened
    title: "Pilo Settings"
    screen: SettingsApp.targetScreen
    color: Theme.bg
    implicitWidth: 940
    implicitHeight: 640
    minimumSize: Qt.size(720, 440)

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // ── sidebar ─────────────────────────────────────────
        Rectangle {
            Layout.preferredWidth: 210
            Layout.fillHeight: true
            color: Theme.withAlpha(Theme.line, 0.35)

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 10

                Text {
                    text: "Pilo Settings"
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize + 3
                    font.bold: true
                    color: Theme.fg
                }

                TextField {
                    Layout.fillWidth: true
                    placeholder: "Search settings"
                    text: SettingsApp.search
                    onTextChanged: {
                        if (SettingsApp.search !== text)
                            SettingsApp.search = text
                    }
                }

                Repeater {
                    model: root.categories

                    delegate: Rectangle {
                        id: categoryRow
                        required property var modelData

                        readonly property bool selected: SettingsApp.search.length === 0 && SettingsApp.category === categoryRow.modelData.key

                        Layout.fillWidth: true
                        implicitHeight: 34
                        radius: 6
                        color: categoryRow.selected ? Theme.withAlpha(Theme.teal, 0.85) : (categoryMouse.containsMouse ? Theme.withAlpha(Theme.steel, 0.2) : "transparent")

                        Behavior on color {
                            ColorAnimation { duration: Theme.durFast }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 8

                            Text {
                                text: categoryRow.modelData.glyph
                                font.family: Theme.fontFamily
                                font.pixelSize: 13
                                color: categoryRow.selected ? Theme.bg : Theme.muted
                            }

                            Text {
                                Layout.fillWidth: true
                                text: categoryRow.modelData.label
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize - 1
                                color: categoryRow.selected ? Theme.bg : Theme.fg
                            }
                        }

                        MouseArea {
                            id: categoryMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                SettingsApp.search = ""
                                SettingsApp.category = categoryRow.modelData.key
                            }
                        }
                    }
                }

                Item { Layout.fillHeight: true }

                Text {
                    Layout.fillWidth: true
                    text: "Changes apply instantly."
                    wrapMode: Text.WordWrap
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize - 2
                    color: Theme.muted
                }
            }
        }

        // ── content ─────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "transparent"

            Flickable {
                id: flick
                anchors.fill: parent
                anchors.margins: 24
                contentWidth: width
                contentHeight: contentColumn.implicitHeight + 16
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                ColumnLayout {
                    id: contentColumn
                    width: flick.width
                    spacing: 18

                    Loader {
                        Layout.fillWidth: true
                        sourceComponent: SettingsApp.search.length > 0 ? compSearch : root.categoryComponent(SettingsApp.category)
                    }
                }
            }
        }
    }

    Component { id: compBar; BarCategory {} }
    Component { id: compDisplays; DisplaysCategory {} }
    Component { id: compWidgets; WidgetsCategory {} }
    Component { id: compLauncher; LauncherCategory {} }
    Component { id: compCalendar; CalendarCategory {} }
    Component { id: compSystem; SystemCategory {} }
    Component { id: compAdvanced; AdvancedCategory {} }
    Component { id: compSearch; SettingsSearch {} }
}