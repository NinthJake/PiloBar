import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs

// Compact select: shows the current option and opens a list to pick another.
// The list is a Popup, so it renders above the settings Flickable instead of
// being clipped by it.
Item {
    id: root

    property var options: []
    property string value: ""
    property string placeholder: "—"

    signal selected(string key)

    implicitWidth: 132
    implicitHeight: 30

    readonly property var current: {
        for (let i = 0; i < options.length; i++) {
            if (options[i].key === value)
                return options[i]
        }
        return null
    }

    Rectangle {
        id: field
        anchors.fill: parent
        radius: 5
        color: Theme.withAlpha(Theme.line, 0.5)
        border.width: 1
        border.color: popup.visible ? Theme.steel : (fieldMouse.containsMouse ? Theme.withAlpha(Theme.steel, 0.6) : "transparent")

        Behavior on border.color {
            ColorAnimation { duration: Theme.durFast }
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 7
            spacing: 4

            Text {
                Layout.fillWidth: true
                text: root.current ? root.current.label : root.placeholder
                elide: Text.ElideRight
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize - 1
                color: Theme.fg
            }

            Text {
                text: Theme.glyphChevronDown
                font.family: Theme.fontFamily
                font.pixelSize: 11
                color: Theme.muted
            }
        }

        MouseArea {
            id: fieldMouse
            anchors.fill: parent
            hoverEnabled: true
            onClicked: popup.visible ? popup.close() : popup.open()
        }
    }

    Popup {
        id: popup
        x: 0
        y: field.height + 4
        width: field.width
        padding: 4
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        background: Rectangle {
            radius: 6
            color: Theme.withAlpha(Theme.bg, 0.98)
            border.width: 1
            border.color: Theme.line
        }

        contentItem: ListView {
            implicitHeight: Math.min(contentHeight, 240)
            clip: true
            model: root.options
            boundsBehavior: Flickable.StopAtBounds

            delegate: Rectangle {
                required property var modelData
                readonly property bool isCurrent: modelData.key === root.value

                width: ListView.view.width
                height: 28
                radius: 4
                color: isCurrent ? Theme.withAlpha(Theme.teal, 0.85) : (itemMouse.containsMouse ? Theme.withAlpha(Theme.steel, 0.22) : "transparent")

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 8
                    anchors.right: parent.right
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    text: modelData.label
                    elide: Text.ElideRight
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize - 1
                    color: isCurrent ? Theme.bg : Theme.fg
                }

                MouseArea {
                    id: itemMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        root.selected(modelData.key)
                        popup.close()
                    }
                }
            }
        }
    }
}
