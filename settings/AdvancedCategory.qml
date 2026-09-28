import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.widgets

ColumnLayout {
    id: root

    property string exportPath: ""
    property string importPath: ""
    property bool confirmReset: false

    readonly property string settingsDir: Settings.path.substring(0, Settings.path.lastIndexOf("/"))

    spacing: 16

    CategoryHeading {
        title: "Advanced"
        subtitle: "Settings file location, backups, and reset."
    }

    SettingRow {
        label: "Settings file"
        hint: Settings.path

        Item { Layout.fillWidth: true }

        ActionButton {
            glyph: Theme.glyphFile
            label: "Open"
            onTriggered: Quickshell.execDetached(["xdg-open", Settings.path])
        }

        ActionButton {
            label: "Folder"
            onTriggered: Quickshell.execDetached(["xdg-open", root.settingsDir])
        }
    }

    SettingRow {
        label: "Export to"
        hint: "Copy the settings file to a path."

        TextField {
            Layout.fillWidth: true
            placeholder: "~/pilo-settings.json"
            onTextChanged: root.exportPath = text
        }

        ActionButton {
            label: "Export"
            enabled: root.exportPath.length > 0
            onTriggered: Settings.exportTo(root.exportPath)
        }
    }

    SettingRow {
        label: "Import from"
        hint: "Replace the current settings from a backup."

        TextField {
            Layout.fillWidth: true
            placeholder: "~/pilo-settings.json"
            onTextChanged: root.importPath = text
        }

        ActionButton {
            label: "Import"
            danger: true
            enabled: root.importPath.length > 0
            onTriggered: Settings.importFrom(root.importPath)
        }
    }

    SettingRow {
        visible: !root.confirmReset
        label: "Reset"
        hint: "Restore every bar setting to its default."

        Item { Layout.fillWidth: true }

        ActionButton {
            glyph: Theme.glyphRefresh
            label: "Reset to defaults"
            danger: true
            onTriggered: root.confirmReset = true
        }
    }

    RowLayout {
        visible: root.confirmReset
        Layout.fillWidth: true
        spacing: 8

        Text {
            Layout.fillWidth: true
            text: "Reset every setting to its default?"
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            color: Theme.fg
        }

        ActionButton {
            label: "Cancel"
            onTriggered: root.confirmReset = false
        }

        ActionButton {
            label: "Reset"
            danger: true
            onTriggered: {
                Settings.resetAll()
                root.confirmReset = false
            }
        }
    }
}