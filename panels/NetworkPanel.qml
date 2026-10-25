import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.widgets

PanelCard {
    id: root

    implicitHeight: content.implicitHeight + 28

    property var pskNetwork: null
    property string psk: ""

    readonly property var networks: Network.networks

    readonly property var pairedDevices: BluetoothManager.devices

    readonly property string currentNetwork: Network.statusText

    onVisibleChanged: {
        if (!visible) {
            root.pskNetwork = null
            root.psk = ""
        }
    }

    function signalText(s) {
        return Math.round(s) + "%"
    }

    function pickNetwork(net) {
        if (net.connected) {
            Network.disconnectNetwork(net)
        } else if (net.known || !net.secured) {
            Network.connectNetwork(net, "")
        } else {
            root.pskNetwork = net
            root.psk = ""
        }
    }

    function submitPsk() {
        if (root.pskNetwork)
            Network.connectNetwork(root.pskNetwork, root.psk)
        root.pskNetwork = null
        root.psk = ""
    }

    ColumnLayout {
        id: content
        anchors.fill: parent
        anchors.margins: 14
        spacing: 10

        // ── network ─────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: "Network"
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                font.bold: true
                color: Theme.fg
            }

            Text {
                visible: !Network.networkManager
                text: Network.backendName
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize - 3
                color: Theme.muted
            }

            Item { Layout.fillWidth: true }

            Text {
                text: root.currentNetwork
                elide: Text.ElideRight
                Layout.maximumWidth: 150
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize - 1
                color: Theme.muted
            }

            Toggle {
                checked: Network.wifiEnabled
                enabled: Network.wifiToggleable
                onToggled: (v) => Network.setWifiEnabled(v)
            }
        }

        ListView {
            id: netList
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(netList.contentHeight, 220)
            clip: true
            spacing: 2
            model: root.networks

            delegate: Rectangle {
                id: netRow
                required property var modelData

                width: ListView.view.width
                height: 32
                radius: 5
                color: netMouse.containsMouse ? Theme.withAlpha(Theme.steel, 0.25) : "transparent"

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 70
                    text: netRow.modelData.name
                    elide: Text.ElideRight
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize - 1
                    color: netRow.modelData.connected ? Theme.teal : Theme.fg
                }

                Text {
                    anchors.right: parent.right
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    text: (netRow.modelData.secured ? "\uf023  " : "") + (netRow.modelData.signal > 0 ? root.signalText(netRow.modelData.signal) : "")
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize - 2
                    color: netRow.modelData.connected ? Theme.teal : Theme.muted
                }

                MouseArea {
                    id: netMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: root.pickNetwork(netRow.modelData)
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            visible: root.pskNetwork !== null
            spacing: 6

            Text {
                text: root.pskNetwork ? root.pskNetwork.name : ""
                elide: Text.ElideRight
                Layout.fillWidth: true
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize - 1
                color: Theme.fg
            }

            Rectangle {
                Layout.preferredWidth: 150
                height: 28
                radius: 5
                color: Theme.withAlpha(Theme.line, 0.6)

                TextInput {
                    id: pskInput
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    verticalAlignment: TextInput.AlignVCenter
                    echoMode: TextInput.Password
                    color: Theme.fg
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize - 1
                    selectByMouse: true
                    focus: root.pskNetwork !== null
                    onTextChanged: root.psk = text
                    onAccepted: root.submitPsk()
                }
            }

            ActionButton {
                label: "Connect"
                onTriggered: root.submitPsk()
            }
        }

        RowLayout {
            Layout.fillWidth: true
            visible: Network.canScan
            spacing: 6

            Item { Layout.fillWidth: true }

            ActionButton {
                glyph: Theme.glyphRefresh
                label: "Scan"
                onTriggered: Network.scan()
            }
        }

        Text {
            Layout.fillWidth: true
            visible: text.length > 0
            text: Network.lastError.length > 0 ? Network.lastError : Network.note
            wrapMode: Text.WordWrap
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize - 2
            color: Network.lastError.length > 0 ? Theme.error : Theme.muted
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Theme.line
        }

        // ── bluetooth ───────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: "Bluetooth"
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                font.bold: true
                color: Theme.fg
            }

            Text {
                visible: BluetoothManager.available
                text: BluetoothManager.backendName
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize - 3
                color: Theme.muted
            }

            Item { Layout.fillWidth: true }

            Text {
                text: BluetoothManager.available ? (BluetoothManager.enabled ? "On" : "Off") : "Unavailable"
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize - 1
                color: Theme.muted
            }

            Toggle {
                checked: BluetoothManager.enabled
                enabled: BluetoothManager.available
                onToggled: (v) => BluetoothManager.setEnabled(v)
            }
        }

        ListView {
            id: btList
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(btList.contentHeight, 180)
            clip: true
            spacing: 2
            model: root.pairedDevices

            delegate: Rectangle {
                id: btRow
                required property var modelData

                width: ListView.view.width
                height: 32
                radius: 5
                color: btMouse.containsMouse ? Theme.withAlpha(Theme.steel, 0.25) : "transparent"

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 90
                    text: btRow.modelData.name.length > 0 ? btRow.modelData.name : btRow.modelData.address
                    elide: Text.ElideRight
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize - 1
                    color: btRow.modelData.connected ? Theme.teal : Theme.fg
                }

                Text {
                    anchors.right: parent.right
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    text: btRow.modelData.connected ? "Connected" : "Disconnected"
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize - 2
                    color: btRow.modelData.connected ? Theme.teal : Theme.muted
                }

                MouseArea {
                    id: btMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: BluetoothManager.toggleDevice(btRow.modelData)
                }
            }
        }

        Text {
            Layout.fillWidth: true
            visible: BluetoothManager.lastError.length > 0
            text: BluetoothManager.lastError
            wrapMode: Text.WordWrap
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize - 2
            color: Theme.error
        }
    }
}
