import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import qs
import qs.widgets

PanelCard {
    id: root

    implicitHeight: content.implicitHeight + 28

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var sinks: {
        let out = []
        const nodes = Pipewire.nodes.values
        for (let i = 0; i < nodes.length; i++) {
            const n = nodes[i]
            if (n.isSink && !n.isStream && n.audio)
                out.push(n)
        }
        return out
    }

    ColumnLayout {
        id: content
        anchors.fill: parent
        anchors.margins: 14
        spacing: 12

        Text {
            text: "Sound"
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            font.bold: true
            color: Theme.fg
        }

        Text {
            Layout.fillWidth: true
            text: root.sink ? (root.sink.description.length > 0 ? root.sink.description : root.sink.name) : "No output device"
            elide: Text.ElideRight
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize - 1
            color: Theme.muted
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            BarButton {
                glyph: (root.sink && root.sink.audio && root.sink.audio.muted) ? Theme.glyphVolumeMute : Theme.glyphVolume
                active: root.sink && root.sink.audio && root.sink.audio.muted
                onClicked: {
                    if (root.sink && root.sink.audio)
                        root.sink.audio.muted = !root.sink.audio.muted
                }
            }

            Slider {
                id: volumeSlider
                Layout.fillWidth: true
                value: (root.sink && root.sink.audio) ? root.sink.audio.volume : 0
                onMoved: (v) => {
                    if (root.sink && root.sink.audio) {
                        root.sink.audio.muted = false
                        root.sink.audio.volume = v
                    }
                }
            }

            Text {
                Layout.preferredWidth: 36
                horizontalAlignment: Text.AlignRight
                text: Math.round(volumeSlider.value * 100) + "%"
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
                    readonly property bool isDefault: modelData === Pipewire.defaultAudioSink

                    width: ListView.view.width
                    height: 30
                    radius: 5
                    color: sinkMouse.containsMouse ? Theme.withAlpha(Theme.steel, 0.25) : "transparent"

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 24
                        text: modelData.description.length > 0 ? modelData.description : modelData.name
                        elide: Text.ElideRight
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize - 1
                        color: sinkRow.isDefault ? Theme.teal : Theme.fg
                    }

                    MouseArea {
                        id: sinkMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: Pipewire.preferredDefaultAudioSink = sinkRow.modelData
                    }
                }
            }
        }

    }
}
