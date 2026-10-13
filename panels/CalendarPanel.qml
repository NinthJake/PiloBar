import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.widgets

PanelCard {
    id: root

    property date cursor: new Date()
    property var hovered: null

    readonly property date today: new Date()
    readonly property string region: Settings.holidays
    readonly property bool showWeeks: Settings.calendarWeekNumbers
    readonly property bool showFooter: Settings.calendarHolidayFooter
    // 0 = Sunday, 1 = Monday.
    readonly property int weekStartIndex: Settings.calendarWeekStart === "sunday" ? 0 : 1
    readonly property real weekColWidth: 26

    implicitHeight: content.implicitHeight + 24
    implicitWidth: showWeeks ? 352 : 320

    readonly property var dayNames: weekStartIndex === 1 ? ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"] : ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    // ISO-8601 week number for a date.
    function isoWeek(d) {
        const date = new Date(Date.UTC(d.getFullYear(), d.getMonth(), d.getDate()))
        const dayNum = (date.getUTCDay() + 6) % 7
        date.setUTCDate(date.getUTCDate() - dayNum + 3)
        const firstThursday = new Date(Date.UTC(date.getUTCFullYear(), 0, 4))
        const firstDayNum = (firstThursday.getUTCDay() + 6) % 7
        firstThursday.setUTCDate(firstThursday.getUTCDate() - firstDayNum + 3)
        return 1 + Math.round((date - firstThursday) / (7 * 24 * 3600 * 1000))
    }

    readonly property var weeks: {
        const year = root.cursor.getFullYear()
        const month = root.cursor.getMonth()
        const first = new Date(year, month, 1)
        const daysInMonth = new Date(year, month + 1, 0).getDate()
        const lead = (first.getDay() - root.weekStartIndex + 7) % 7
        let cells = []
        for (let i = 0; i < lead; i++)
            cells.push(null)
        for (let d = 1; d <= daysInMonth; d++)
            cells.push(new Date(year, month, d))
        while (cells.length % 7 !== 0)
            cells.push(null)

        let rows = []
        for (let i = 0; i < cells.length; i += 7) {
            const days = cells.slice(i, i + 7)
            let ref = null
            for (let j = 0; j < 7; j++) {
                if (days[j]) {
                    ref = days[j]
                    break
                }
            }
            rows.push({ week: ref ? root.isoWeek(ref) : 0, days: days })
        }
        return rows
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

        // Weekday header, rotated to the configured first day of week.
        RowLayout {
            Layout.fillWidth: true
            spacing: 0

            Item {
                visible: root.showWeeks
                Layout.preferredWidth: root.showWeeks ? root.weekColWidth : 0
                Layout.preferredHeight: 1
            }

            Repeater {
                model: root.dayNames

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

        // One row per week, with an optional ISO week number column.
        Repeater {
            model: root.weeks

            delegate: RowLayout {
                id: weekRow
                required property var modelData

                Layout.fillWidth: true
                spacing: 0

                Text {
                    visible: root.showWeeks
                    Layout.preferredWidth: root.showWeeks ? root.weekColWidth : 0
                    Layout.fillHeight: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    text: weekRow.modelData.week
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize - 3
                    color: Theme.muted
                }

                Repeater {
                    model: weekRow.modelData.days

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
                                    root.hovered = modelData
                            }
                        }
                    }
                }
            }
        }

        // Fixed height so the holiday name appearing never reflows the grid.
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: root.showFooter ? 16 : 0
            visible: root.showFooter

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
