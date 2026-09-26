import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.widgets

PanelCard {
    id: root

    implicitHeight: content.implicitHeight + 24

    property date cursor: new Date()
    property var hovered: null

    readonly property date today: new Date()
    readonly property string region: Settings.holidays

    readonly property var cells: {
        const first = new Date(cursor.getFullYear(), cursor.getMonth(), 1)
        const startDay = first.getDay()
        const daysInMonth = new Date(cursor.getFullYear(), cursor.getMonth() + 1, 0).getDate()
        let out = []
        for (let i = 0; i < startDay; i++)
            out.push(null)
        for (let d = 1; d <= daysInMonth; d++)
            out.push(new Date(cursor.getFullYear(), cursor.getMonth(), d))
        while (out.length % 7 !== 0)
            out.push(null)
        return out
    }

    function sameDay(a, b) {
        return a && b && a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate()
    }

    function shiftMonth(delta) {
        root.hovered = null
        root.cursor = new Date(root.cursor.getFullYear(), root.cursor.getMonth() + delta, 1)
    }

    readonly property string footerText: {
        if (hovered)
            return Holidays.nameFor(hovered, region)
        return Holidays.nameFor(today, region)
    }

    focus: true
    onVisibleChanged: {
        if (visible)
            forceActiveFocus()
    }
    Keys.onLeftPressed: shiftMonth(-1)
    Keys.onRightPressed: shiftMonth(1)

    ColumnLayout {
        id: content
        anchors.fill: parent
        anchors.margins: 12
        spacing: 6

        RowLayout {
            Layout.fillWidth: true

            Item {
                Layout.preferredWidth: 26
                Layout.preferredHeight: 24

                Text {
                    anchors.centerIn: parent
                    text: Theme.glyphLeft
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    color: prevMouse.containsMouse ? Theme.teal : Theme.muted
                }

                MouseArea {
                    id: prevMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: root.shiftMonth(-1)
                }
            }

            Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: Qt.formatDateTime(root.cursor, "MMMM yyyy")
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                font.bold: true
                color: Theme.fg
            }

            Item {
                Layout.preferredWidth: 26
                Layout.preferredHeight: 24

                Text {
                    anchors.centerIn: parent
                    text: Theme.glyphRight
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    color: nextMouse.containsMouse ? Theme.teal : Theme.muted
                }

                MouseArea {
                    id: nextMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: root.shiftMonth(1)
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 0

            Repeater {
                model: ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

                delegate: Text {
                    required property var modelData
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: modelData
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize - 2
                    color: Theme.muted
                }
            }
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 7

            Repeater {
                model: root.cells

                delegate: Item {
                    required property var modelData

                    Layout.fillWidth: true
                    Layout.preferredHeight: 30

                    readonly property bool isToday: root.sameDay(modelData, root.today)
                    readonly property string holiday: modelData ? Holidays.nameFor(modelData, root.region) : ""
                    readonly property bool isHoliday: holiday.length > 0

                    Rectangle {
                        anchors.centerIn: parent
                        width: 24
                        height: 24
                        radius: 12
                        color: parent.isToday ? Theme.withAlpha(Theme.teal, 0.25) : "transparent"
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: modelData !== null
                        text: modelData !== null ? modelData.getDate() : ""
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize - 1
                        color: parent.isToday ? Theme.teal : (parent.isHoliday ? Theme.warning : Theme.fg)
                        font.bold: parent.isToday || parent.isHoliday
                    }

                    Rectangle {
                        visible: parent.isHoliday
                        width: 4
                        height: 4
                        radius: 2
                        color: Theme.warning
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 2
                    }

                    HoverHandler {
                        onHoveredChanged: {
                            if (hovered)
                                root.hovered = parent.modelData
                        }
                    }
                }
            }
        }

        // Fixed height so the holiday name appearing never reflows the grid.
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 16

            Text {
                anchors.fill: parent
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: root.footerText
                elide: Text.ElideRight
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize - 2
                color: Theme.warning
            }
        }
    }

    // Wheel catcher on top. acceptedButtons: NoButton keeps it transparent to
    // clicks so the arrows and cards still work.
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        onWheel: (wheel) => {
            if (wheel.angleDelta.y > 0)
                root.shiftMonth(-1)
            else if (wheel.angleDelta.y < 0)
                root.shiftMonth(1)
        }
    }
}
