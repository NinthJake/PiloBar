import QtQuick
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Networking
import qs

BarButton {
    id: root
    required property var screen

    readonly property var wifi: {
        const devs = Networking.devices.values
        for (let i = 0; i < devs.length; i++) {
            if (devs[i].type === DeviceType.Wifi)
                return devs[i]
        }
        return null
    }

    readonly property bool wired: {
        const devs = Networking.devices.values
        for (let i = 0; i < devs.length; i++) {
            if (devs[i].type === DeviceType.Wired && devs[i].connected)
                return true
        }
        return false
    }

    readonly property bool bluetoothConnected: {
        const adapter = Bluetooth.defaultAdapter
        if (!adapter)
            return false
        const devs = adapter.devices.values
        for (let i = 0; i < devs.length; i++) {
            if (devs[i].connected)
                return true
        }
        return false
    }

    glyph: root.wired ? Theme.glyphEthernet : Theme.glyphWifi
    active: Panels.isOpen("network", root.screen)
    showPip: root.bluetoothConnected
    onClicked: Panels.toggle("network", root.screen)
}
