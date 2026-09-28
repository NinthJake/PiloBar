import QtQuick
import QtQuick.Layouts
import qs
import qs.widgets

// Cross-category search: a static index of settings that jumps to the owning
// category when picked.
ColumnLayout {
    id: root

    readonly property var index: [
        { category: "bar", label: "Chrome", keywords: "shape flush pill islands attached" },
        { category: "bar", label: "Edge", keywords: "top bottom screen placement" },
        { category: "bar", label: "Opacity", keywords: "transparency alpha" },
        { category: "bar", label: "Gap", keywords: "margin spacing distance" },
        { category: "bar", label: "Workspaces", keywords: "all occupied numbers" },
        { category: "widgets", label: "Bar layout", keywords: "widgets arrange order move sections left center right" },
        { category: "displays", label: "Monitor arrangement", keywords: "displays monitors position left right drag identify order" },
        { category: "displays", label: "Identify displays", keywords: "number id screen label which monitor" },
        { category: "displays", label: "Refresh rate and scale", keywords: "hz resolution monitor reset" },
        { category: "launcher", label: "Launcher sort", keywords: "name recent frequent order" },
        { category: "launcher", label: "File search", keywords: "plocate files scope" },
        { category: "calendar", label: "Holidays", keywords: "sweden dates calendar" },
        { category: "system", label: "Power profile", keywords: "battery balanced performance powerprofilesctl" },
        { category: "advanced", label: "Settings file", keywords: "path export import backup reset defaults json" }
    ]

    function categoryLabel(key) {
        if (key === "bar") return "Bar"
        if (key === "displays") return "Displays"
        if (key === "widgets") return "Widgets"
        if (key === "launcher") return "Launcher"
        if (key === "calendar") return "Calendar"
        if (key === "system") return "System"
        if (key === "advanced") return "Advanced"
        return key
    }

    readonly property var results: {
        const q = SettingsApp.search.trim().toLowerCase()
        if (q.length === 0)
            return []
        let out = []
        for (let i = 0; i < root.index.length; i++) {
            const e = root.index[i]
            const hay = (e.label + " " + (e.keywords || "") + " " + root.categoryLabel(e.category)).toLowerCase()
            if (hay.indexOf(q) !== -1)
                out.push(e)
        }
        return out
    }

    spacing: 12

    CategoryHeading {
        title: "Search"
        subtitle: "\"" + SettingsApp.search + "\""
    }

    Text {
        Layout.fillWidth: true
        visible: root.results.length === 0
        text: "No settings match."
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        color: Theme.muted
    }

    Repeater {
        model: root.results

        delegate: Rectangle {
            id: resultRow
            required property var modelData

            Layout.fillWidth: true
            implicitHeight: 40
            radius: 6
            color: resultMouse.containsMouse ? Theme.withAlpha(Theme.steel, 0.2) : "transparent"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 8

                Text {
                    Layout.fillWidth: true
                    text: resultRow.modelData.label
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                    color: Theme.fg
                }

                Text {
                    text: root.categoryLabel(resultRow.modelData.category)
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize - 1
                    color: Theme.muted
                }
            }

            MouseArea {
                id: resultMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: SettingsApp.openAt(SettingsApp.targetScreen, resultRow.modelData.category)
            }
        }
    }
}