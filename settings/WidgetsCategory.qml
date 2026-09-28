import QtQuick
import QtQuick.Layouts
import qs
import qs.widgets

// Layout editor: three columns (Left, Center, Right) plus a palette of
// available widgets at the bottom. Drag from the palette into a column to add,
// drag a row to reorder or move it between columns, or drag it back to the
// palette to remove it. Each column also has a "+" menu.
Item {
    id: root

    // Widget rows are 32px tall with 4px spacing.
    readonly property int rowPitch: 36

    // Drag state. Kept as flat properties so bindings on the proxy/indicator
    // update (mutating a JS object in place would not notify).
    property bool dragActive: false
    property string dragKey: ""
    property string dragFromSection: ""   // "" means the palette
    property int dragFromIndex: -1
    property real dragX: 0
    property real dragY: 0

    property bool pendingActive: false
    property string pendingKey: ""
    property string pendingFromSection: ""
    property int pendingFromIndex: -1
    property real pendingX: 0
    property real pendingY: 0

    property string hoverSection: ""
    property int hoverIndex: -1
    property bool paletteHover: false
    property bool indicatorVisible: false
    property real indicatorX: 0
    property real indicatorY: 0
    property real indicatorWidth: 0

    // "+" menu.
    property bool menuOpen: false
    property string menuSection: ""
    property real menuX: 0
    property real menuY: 0

    implicitHeight: content.implicitHeight

    function startPending(key, fromSection, fromIndex, x, y) {
        pendingActive = true
        pendingKey = key
        pendingFromSection = fromSection
        pendingFromIndex = fromIndex
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
            dragFromSection = pendingFromSection
            dragFromIndex = pendingFromIndex
            menuOpen = false
        }
        updateDrag(x, y)
    }

    function sectionItem(key) {
        for (let i = 0; i < sectionsRepeater.count; i++) {
            const d = sectionsRepeater.itemAt(i)
            if (d && d.sectionKey === key)
                return d
        }
        return null
    }

    function updateDrag(x, y) {
        dragX = x
        dragY = y

        let found = ""
        let idx = -1
        for (let i = 0; i < sectionsRepeater.count; i++) {
            const d = sectionsRepeater.itemAt(i)
            if (!d || !d.listArea)
                continue
            const tl = d.listArea.mapToItem(root, 0, 0)
            const w = d.listArea.width
            const h = d.listArea.height
            if (x >= tl.x - 6 && x <= tl.x + w + 6 && y >= tl.y - 10 && y <= tl.y + h + 24) {
                found = d.sectionKey
                const count = Settings.sectionList(found).length
                const localY = y - tl.y - 4
                idx = Math.max(0, Math.min(count, Math.round(localY / root.rowPitch)))
                indicatorX = tl.x
                indicatorY = tl.y + 4 + idx * root.rowPitch - 2
                indicatorWidth = w
            }
        }

        hoverSection = found
        hoverIndex = idx
        indicatorVisible = found !== ""
        paletteHover = overPalette(x, y)
    }

    function overPalette(x, y) {
        if (!paletteFlow)
            return false
        const tl = paletteFlow.mapToItem(root, 0, 0)
        return x >= tl.x - 20 && x <= tl.x + paletteFlow.width + 20 && y >= tl.y - 20 && y <= tl.y + paletteFlow.height + 20
    }

    function endDrag() {
        if (!dragActive) {
            pendingActive = false
            return
        }

        if (hoverSection !== "") {
            if (dragFromSection === "")
                Settings.insertWidget(hoverSection, hoverIndex, dragKey)
            else
                Settings.moveWidgetTo(dragFromSection, dragFromIndex, hoverSection, hoverIndex)
        } else if (paletteHover && dragFromSection !== "") {
            Settings.removeWidget(dragFromSection, dragFromIndex)
        }

        dragActive = false
        pendingActive = false
        hoverSection = ""
        indicatorVisible = false
        paletteHover = false
    }

    function openMenu(section, item) {
        const p = item.mapToItem(root, 0, 0)
        menuSection = section
        menuX = Math.max(8, Math.min(root.width - 220, p.x))
        menuY = p.y + item.height + 4
        menuOpen = true
    }

    ColumnLayout {
        id: content
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: 16

        CategoryHeading {
            title: "Widgets"
            subtitle: "Drag a widget from the bottom palette into a column, drag a row to reorder or move it, or use a column's + to add."
        }

        RowLayout {
            id: columnsRow
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
            spacing: 12

            Repeater {
                id: sectionsRepeater
                model: BarWidgets.sections

                delegate: ColumnLayout {
                    id: sectionDelegate
                    required property var modelData

                    readonly property string sectionKey: modelData.key
                    readonly property int count: Settings.sectionList(sectionKey).length
                    property Item listArea: listBg

                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                    Layout.minimumWidth: 0
                    Layout.alignment: Qt.AlignTop
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        Text {
                            Layout.fillWidth: true
                            text: sectionDelegate.modelData.label
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize
                            font.bold: true
                            color: Theme.fg
                        }

                        IconButton {
                            id: addButton
                            glyph: Theme.glyphPlus
                            onClicked: root.openMenu(sectionDelegate.sectionKey, addButton)
                        }
                    }

                    Rectangle {
                        id: listBg
                        Layout.fillWidth: true
                        Layout.preferredWidth: 0
                        Layout.minimumWidth: 0
                        implicitHeight: Math.max(listColumn.implicitHeight + 8, 44)
                        radius: 6
                        color: root.hoverSection === sectionDelegate.sectionKey ? Theme.withAlpha(Theme.steel, 0.12) : Theme.withAlpha(Theme.line, 0.22)
                        border.width: root.hoverSection === sectionDelegate.sectionKey ? 1 : 0
                        border.color: Theme.steel

                        ColumnLayout {
                            id: listColumn
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 4
                            spacing: 4

                            Repeater {
                                model: Settings.sectionList(sectionDelegate.sectionKey)

                                delegate: Rectangle {
                                    id: widgetRow
                                    required property string modelData
                                    required property int index

                                    readonly property string key: modelData
                                    readonly property int rowIndex: index

                                    Layout.fillWidth: true
                                    Layout.preferredWidth: 0
                                    Layout.minimumWidth: 0
                                    implicitHeight: 32
                                    radius: 6
                                    color: Theme.withAlpha(Theme.line, 0.55)
                                    opacity: root.dragActive && root.dragFromSection === sectionDelegate.sectionKey && root.dragFromIndex === widgetRow.rowIndex ? 0.4 : 1

                                    MouseArea {
                                        id: rowDrag
                                        anchors.fill: parent
                                        preventStealing: true

                                        onPressed: (mouse) => {
                                            const p = mapToItem(root, mouse.x, mouse.y)
                                            root.startPending(widgetRow.key, sectionDelegate.sectionKey, widgetRow.rowIndex, p.x, p.y)
                                        }
                                        onPositionChanged: (mouse) => {
                                            if (!pressed)
                                                return
                                            const p = mapToItem(root, mouse.x, mouse.y)
                                            root.maybeStartDrag(p.x, p.y)
                                        }
                                        onReleased: root.endDrag()
                                        onCanceled: root.endDrag()
                                    }

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 10
                                        anchors.rightMargin: 4
                                        spacing: 2

                                        Text {
                                            Layout.fillWidth: true
                                            text: BarWidgets.label(widgetRow.key)
                                            elide: Text.ElideRight
                                            font.family: Theme.fontFamily
                                            font.pixelSize: Theme.fontSize - 1
                                            color: Theme.fg
                                        }

                                        IconButton {
                                            glyph: Theme.glyphChevronUp
                                            enabled: widgetRow.rowIndex > 0
                                            onClicked: Settings.moveWidget(sectionDelegate.sectionKey, widgetRow.rowIndex, -1)
                                        }

                                        IconButton {
                                            glyph: Theme.glyphChevronDown
                                            enabled: widgetRow.rowIndex < sectionDelegate.count - 1
                                            onClicked: Settings.moveWidget(sectionDelegate.sectionKey, widgetRow.rowIndex, 1)
                                        }

                                        IconButton {
                                            glyph: Theme.glyphTrash
                                            hoverColor: Theme.error
                                            onClicked: Settings.removeWidget(sectionDelegate.sectionKey, widgetRow.rowIndex)
                                        }
                                    }
                                }
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            visible: sectionDelegate.count === 0 && !root.dragActive
                            text: "Drop here"
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize - 2
                            color: Theme.muted
                        }
                    }
                }
            }
        }

        // ── palette ─────────────────────────────────────────
        ColumnLayout {
            Layout.fillWidth: true
            Layout.topMargin: 4
            spacing: 6

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    Layout.fillWidth: true
                    text: "Available widgets"
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                    font.bold: true
                    color: Theme.fg
                }

                ActionButton {
                    glyph: Theme.glyphRefresh
                    label: "Reset layout"
                    onTriggered: Settings.resetLayout()
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: paletteFlow.implicitHeight + 16
                radius: 6
                color: root.paletteHover ? Theme.withAlpha(Theme.steel, 0.15) : Theme.withAlpha(Theme.line, 0.22)
                border.width: root.paletteHover ? 1 : 0
                border.color: Theme.steel

                Flow {
                    id: paletteFlow
                    x: 8
                    y: 8
                    width: parent.width - 16
                    spacing: 6

                    Repeater {
                        model: BarWidgets.available

                        delegate: Rectangle {
                            id: chip
                            required property var modelData

                            width: chipLabel.implicitWidth + 18
                            height: 30
                            radius: 6
                            color: chipMouse.containsMouse ? Theme.withAlpha(Theme.teal, 0.28) : Theme.withAlpha(Theme.line, 0.6)
                            border.width: 1
                            border.color: Theme.line

                            Behavior on color {
                                ColorAnimation { duration: Theme.durFast }
                            }

                            Text {
                                id: chipLabel
                                anchors.centerIn: parent
                                text: chip.modelData.label
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize - 1
                                color: Theme.fg
                            }

                            MouseArea {
                                id: chipMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                preventStealing: true

                                onPressed: (mouse) => {
                                    const p = mapToItem(root, mouse.x, mouse.y)
                                    root.startPending(chip.modelData.key, "", -1, p.x, p.y)
                                }
                                onPositionChanged: (mouse) => {
                                    if (!pressed)
                                        return
                                    const p = mapToItem(root, mouse.x, mouse.y)
                                    root.maybeStartDrag(p.x, p.y)
                                }
                                onReleased: root.endDrag()
                                onCanceled: root.endDrag()
                            }
                        }
                    }
                }
            }
        }
    }

    // ── drag overlay ────────────────────────────────────────
    Rectangle {
        visible: root.dragActive
        z: 1000
        x: root.dragX - width / 2
        y: root.dragY - height / 2
        width: proxyLabel.implicitWidth + 20
        height: 30
        radius: 6
        color: Theme.withAlpha(Theme.teal, 0.92)
        opacity: 0.95

        Text {
            id: proxyLabel
            anchors.centerIn: parent
            text: root.dragKey.length > 0 ? BarWidgets.label(root.dragKey) : ""
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize - 1
            color: Theme.bg
        }
    }

    Rectangle {
        visible: root.indicatorVisible
        z: 1000
        x: root.indicatorX
        y: root.indicatorY
        width: root.indicatorWidth
        height: 2
        radius: 1
        color: Theme.teal
    }

    // ── "+" menu ────────────────────────────────────────────
    MouseArea {
        anchors.fill: parent
        visible: root.menuOpen
        z: 1001
        onClicked: root.menuOpen = false
    }

    Rectangle {
        id: menuCard
        visible: root.menuOpen
        z: 1002
        x: root.menuX
        y: root.menuY
        width: 210
        height: menuColumn.implicitHeight + 12
        radius: 8
        color: Theme.withAlpha(Theme.bg, 0.98)
        border.width: 1
        border.color: Theme.line

        ColumnLayout {
            id: menuColumn
            anchors.fill: parent
            anchors.margins: 6
            spacing: 2

            Repeater {
                model: BarWidgets.available

                delegate: Rectangle {
                    id: menuItem
                    required property var modelData

                    Layout.fillWidth: true
                    implicitHeight: 30
                    radius: 5
                    color: menuItemMouse.containsMouse ? Theme.withAlpha(Theme.steel, 0.25) : "transparent"

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        text: menuItem.modelData.label
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize - 1
                        color: Theme.fg
                    }

                    MouseArea {
                        id: menuItemMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            Settings.addWidget(root.menuSection, menuItem.modelData.key)
                            root.menuOpen = false
                        }
                    }
                }
            }
        }
    }
}