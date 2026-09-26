import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Networking
import qs
import qs.widgets

PanelCard {
    id: root

    implicitHeight: content.implicitHeight + 28

    property string pskTarget: ""
    property string psk: ""

    readonly property var wifi: {
        const devs = Networking.devices.values
        for (let i = 0; i < devs.length; i++) {
            if (devs[i].type === DeviceType.Wifi)
                return devs[i]
        }
        return null
    }

    readonly property var networks: wifi ? wifi.networks.values : []

    readonly property var adapter: Bluetooth.defaultAdapter

    readonly property var pairedDevices: {
        if (!adapter)
            return []
        let out = []
        const devs = adapter.devices.values
        for (let i = 0; i < devs.length; i++) {
            if (devs[i].paired || devs[i].bonded)
                out.push(devs[i])
        }
        return out
    }

    readonly property string currentNetwork: {
        if (wifi && wifi.connected)
            return wifi.name && wifi.name.length > 0 ? wifi.name : "Connected"
        return "Disconnected"
    }

    function signalText(s) {
        const v = s <= 1 ? s * 100 : s
        return Math.round(v) + "%"
    }

    function pickNetwork(net) {
        if (net.connected) {
            net.disconnect()
        } else if (net.known) {
            net.connect()
        } else if (net.security === WifiSecurityType.Open) {
            net.connect()
        } else {
            root.pskTarget = net.name
            root.psk = ""
        }
    }

    function submitPsk() {
        const nets = root.networks
        for (let i = 0; i < nets.length; i++) {
            if (nets[i].name === root.pskTarget) {
                nets[i].connectWithPsk(root.psk)
                break
            }
        }
        root.pskTarget = ""
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
                checked: Networking.wifiEnabled
                onToggled: (v) => Networking.wifiEnabled = v
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
                readonly property bool secured: modelData.security !== WifiSecurityType.Open

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
                    text: (netRow.secured ? "\uf023  " : "") + root.signalText(netRow.modelData.signalStrength)
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
            visible: root.pskTarget.length > 0
            spacing: 6

            Text {
                text: root.pskTarget
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
                    focus: root.pskTarget.length > 0
                    onTextChanged: root.psk = text
                    onAccepted: root.submitPsk()
                }
            }

            ActionButton {
                label: "Connect"
                onTriggered: root.submitPsk()
            }
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

            Item { Layout.fillWidth: true }

            Text {
                text: root.adapter ? (root.adapter.enabled ? "On" : "Off") : "Unavailable"
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize - 1
                color: Theme.muted
            }

            Toggle {
                checked: root.adapter ? root.adapter.enabled : false
                enabled: root.adapter !== null
                onToggled: (v) => {
                    if (root.adapter)
                        root.adapter.enabled = v
                }
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
                    text: btRow.modelData.name.length > 0 ? btRow.modelData.name : btRow.modelData.deviceName
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
                    onClicked: {
                        if (btRow.modelData.connected)
                            btRow.modelData.disconnect()
                        else
                            btRow.modelData.connect()
                    }
                }
            }
        }
    }
}
