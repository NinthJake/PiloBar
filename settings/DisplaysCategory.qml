import QtQuick
import QtQuick.Layouts
import qs
import qs.widgets

// Monitor arrangement and settings. Cards are laid out left to right and can be
// dragged to reorder; each monitor also has refresh rate and scale controls.
// "Identify" flashes the display's number on the screen itself.
ColumnLayout {
    id: root

    readonly property real cardH: 86
    readonly property real cardGap: 8
    // Shrink the arrangement cards to fit the row, so many screens still show.
    readonly property real cardW: {
        const n = Math.max(1, Displays.order.length)
        const avail = Math.max(120, arrangeArea.width - 24)
        return Math.max(64, Math.min(150, Math.floor((avail - (n - 1) * cardGap) / n)))
    }
    readonly property bool compactCards: cardW < 110

    // Setting-box grid: aim for ~280px boxes and fill each row.
    readonly property real boxGap: 12
    readonly property real boxW: {
        const avail = Math.max(200, boxesFlow.width)
        const cols = Math.max(1, Math.floor((avail + boxGap) / (280 + boxGap)))
        return Math.floor((avail - (cols - 1) * boxGap) / cols)
    }

    property bool dragActive: false
    property int dragFromIndex: -1
    property string dragKey: ""
    property real dragX: 0
    property real dragY: 0
    property int hoverIndex: -1

    property bool pendingActive: false
    property string pendingKey: ""
    property int pendingFromIndex: -1
    property real pendingX: 0
    property real pendingY: 0

    property bool indicatorVisible: false
    property real indicatorX: 0

    spacing: 16

    Component.onCompleted: Displays.refresh()

    function beginPending(key, index, x, y) {
        pendingActive = true
        pendingKey = key
        pendingFromIndex = index
        pendingX = x
        pendingY = y
    }

    function maybeStartDrag(x, y) {
        if (!pendingActive)
            return
        if (!dragActive && Math.abs(x - pendingX) + Math.abs(y - pendingY) < 6)
            return
        if (!dragActive) {
            dragActive = true
            dragKey = pendingKey
            dragFromIndex = pendingFromIndex
        }
        updateDrag(x, y)
    }

    function updateDrag(x, y) {
        dragX = x
        dragY = y

        const origin = arrangeRow.x
        let idx = 0
        for (let i = 0; i < Displays.order.length; i++) {
            const center = origin + i * (cardW + cardGap) + cardW / 2
            if (x > center)
                idx = i + 1
        }
        hoverIndex = idx
        indicatorVisible = true
        indicatorX = origin + idx * (cardW + cardGap) - cardGap / 2 - 1
    }

    function endDrag() {
        if (dragActive && dragFromIndex >= 0)
            Displays.reorder(dragFromIndex, hoverIndex)
        dragActive = false
        pendingActive = false
        indicatorVisible = false
        hoverIndex = -1
    }

    CategoryHeading {
        title: "Displays"
        subtitle: "Drag a display left or right to set the physical arrangement. Refresh rate and scale apply immediately and are saved to monitors.lua."
    }

    // ── arrangement ─────────────────────────────────────────
    Item {
        id: arrangeArea
        Layout.fillWidth: true
        implicitHeight: cardH + 24

        Rectangle {
            anchors.fill: parent
            radius: 8
            color: Theme.withAlpha(Theme.line, 0.22)
        }

        Row {
            id: arrangeRow
            anchors.centerIn: parent
            spacing: root.cardGap

            Repeater {
                model: Displays.order

                delegate: Rectangle {
                    id: card
                    required property string modelData
                    required property int index

                    readonly property var mon: Displays.monitorByName(modelData)

                    width: root.cardW
                    height: root.cardH
                    radius: 8
                    color: Theme.withAlpha(Theme.steel, 0.18)
                    border.width: 1
                    border.color: Theme.withAlpha(Theme.steel, 0.5)
                    opacity: root.dragActive && root.dragFromIndex === card.index ? 0.4 : 1

                    Column {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.verticalCenter: parent.verticalCenter
                        width: card.width - 10
                        spacing: 2

                        Text {
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                            text: root.compactCards ? String(card.index + 1) : "Display " + (card.index + 1)
                            font.family: Theme.fontFamily
                            font.pixelSize: root.compactCards ? Theme.fontSize + 3 : Theme.fontSize + 2
                            font.bold: true
                            color: Theme.teal
                        }

                        Text {
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                            text: card.modelData
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize - 1
                            color: Theme.fg
                        }

                        Text {
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                            visible: !root.compactCards
                            text: card.mon ? card.mon.width + "x" + card.mon.height : ""
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize - 2
                            color: Theme.muted
                        }
                    }

                    MouseArea {
                        id: cardDrag
                        anchors.fill: parent
                        preventStealing: true

                        onPressed: (mouse) => {
                            const p = mapToItem(arrangeArea, mouse.x, mouse.y)
                            root.beginPending(card.modelData, card.index, p.x, p.y)
                        }
                        onPositionChanged: (mouse) => {
                            if (!pressed)
                                return
                            const p = mapToItem(arrangeArea, mouse.x, mouse.y)
                            root.maybeStartDrag(p.x, p.y)
                        }
                        onReleased: root.endDrag()
                        onCanceled: root.endDrag()
                    }
                }
            }
        }

        Rectangle {
            visible: root.indicatorVisible
            z: 5
            x: root.indicatorX
            y: 6
            width: 2
            height: arrangeArea.height - 12
            radius: 1
            color: Theme.teal
        }

        Rectangle {
            visible: root.dragActive
            z: 6
            x: Math.round(root.dragX - width / 2)
            y: Math.round(root.dragY - height / 2)
            width: proxyText.implicitWidth + 24
            height: 34
            radius: 8
            color: Theme.withAlpha(Theme.teal, 0.92)

            Text {
                id: proxyText
                anchors.centerIn: parent
                text: {
                    const id = Displays.idFor(root.dragKey)
                    return id > 0 ? "Display " + id : root.dragKey
                }
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                font.bold: true
                color: Theme.bg
            }
        }
    }

    // ── actions ─────────────────────────────────────────────
    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        ActionButton {
            glyph: Theme.glyphMonitor
            label: "Identify"
            onTriggered: Displays.identify()
        }

        Item { Layout.fillWidth: true }

        ActionButton {
            glyph: Theme.glyphRefresh
            label: "Reset"
            onTriggered: Displays.resetAll()
        }
    }

    // ── per-monitor settings ────────────────────────────────
    // Boxes wrap into a grid so the page scales to many screens.
    Flow {
        id: boxesFlow
        Layout.fillWidth: true
        spacing: root.boxGap

        Repeater {
            model: Displays.order

            delegate: Rectangle {
                id: box
                required property string modelData
                required property int index

                readonly property var mon: Displays.monitorByName(modelData)

                width: root.boxW
                implicitHeight: 124
                visible: mon !== null
                radius: 8
                color: Theme.withAlpha(Theme.line, 0.3)
                border.width: 1
                border.color: Theme.withAlpha(Theme.line, 0.7)

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Text {
                            text: "Display " + (box.index + 1)
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize - 1
                            font.bold: true
                            color: Theme.teal
                        }

                        Text {
                            Layout.fillWidth: true
                            text: box.modelData
                            elide: Text.ElideRight
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize - 1
                            color: Theme.fg
                        }

                        Text {
                            text: box.mon ? box.mon.width + "x" + box.mon.height : ""
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize - 2
                            color: Theme.muted
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Text {
                            Layout.preferredWidth: 52
                            text: "Refresh"
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize - 1
                            color: Theme.muted
                        }

                        Dropdown {
                            Layout.fillWidth: true
                            options: box.mon ? Displays.refreshOptions(box.modelData) : []
                            value: Displays.refreshKey(box.modelData)
                            onSelected: (key) => Displays.setRefresh(box.modelData, key)
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Text {
                            Layout.preferredWidth: 52
                            text: "Scale"
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize - 1
                            color: Theme.muted
                        }

                        Dropdown {
                            Layout.fillWidth: true
                            options: Displays.scaleOptions
                            value: Displays.scaleKey(box.modelData)
                            onSelected: (key) => Displays.setScale(box.modelData, key)
                        }
                    }
                }
            }
        }
    }
}