import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.widgets

PanelCard {
    id: root

    implicitHeight: content.implicitHeight + 28

    readonly property var sinks: Audio.sinks

    ColumnLayout {
        id: content
        anchors.fill: parent
        anchors.margins: 14
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Text {
                text: "Sound"
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                font.bold: true
                color: Theme.fg
            }

            Text {
                text: Audio.backendName
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize - 3
                color: Theme.muted
            }
        }

        Text {
            Layout.fillWidth: true
            text: Audio.sinkName
            elide: Text.ElideRight
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize - 1
            color: Theme.muted
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            enabled: Audio.available

            BarButton {
                glyph: Audio.muted ? Theme.glyphVolumeMute : Theme.glyphVolume
                active: Audio.muted
                onClicked: Audio.toggleMuted()
            }

            Slider {
                id: volumeSlider
                Layout.fillWidth: true
                value: Audio.volume
                onMoved: (v) => Audio.setVolume(v)
            }

            Text {
                Layout.preferredWidth: 36
                horizontalAlignment: Text.AlignRight
                text: Math.round(Audio.volume * 100) + "%"
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize - 1
                color: Theme.fg
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4

            Text {
                visible: root.sinks.length > 1
                text: "Output"
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize - 2
                color: Theme.muted
            }

            ListView {
                id: outList
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(outList.contentHeight, 180)
                clip: true
                spacing: 2
                model: root.sinks

                delegate: Rectangle {
                    id: sinkRow
                    required property var modelData

                    width: ListView.view.width
                    height: 30
                    radius: 5
                    color: sinkMouse.containsMouse ? Theme.withAlpha(Theme.steel, 0.25) : "transparent"

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 24
                        text: modelData.description.length > 0 ? modelData.description : modelData.id
                        elide: Text.ElideRight
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize - 1
                        color: sinkRow.modelData.isDefault ? Theme.teal : Theme.fg
                    }

                    MouseArea {
                        id: sinkMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: Audio.setDefaultSink(sinkRow.modelData)
                    }
                }
            }
        }

        Text {
            Layout.fillWidth: true
            visible: Audio.lastError.length > 0 || !Audio.available
            text: Audio.lastError.length > 0 ? Audio.lastError : "No audio server found"
            wrapMode: Text.WordWrap
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize - 2
            color: Audio.lastError.length > 0 ? Theme.error : Theme.muted
        }
    }
}
