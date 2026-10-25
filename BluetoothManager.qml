pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth

// Bluetooth facade. Quickshell.Bluetooth is the preferred backend, but it can
// be unavailable if Quickshell could not attach to BlueZ even though the
// system's bluetoothd is running. In that case use bluetoothctl, which talks
// to the same BlueZ daemon. BlueZ is the standard Linux Bluetooth stack; this
// is a transport fallback, not a replacement daemon.
Singleton {
    id: root

    readonly property bool nativeAvailable: Bluetooth.defaultAdapter !== null
    readonly property var nativeAdapter: Bluetooth.defaultAdapter

    readonly property var nativeDevices: {
        const adapter = root.nativeAdapter
        if (!adapter)
            return []
        let out = []
        const devices = adapter.devices.values
        for (let i = 0; i < devices.length; i++) {
            const device = devices[i]
            if (device.paired || device.bonded) {
                out.push({
                    name: device.name.length > 0 ? device.name : device.address,
                    address: device.address,
                    connected: device.connected,
                    nativeDevice: device
                })
            }
        }
        return out
    }

    property bool fallbackAvailable: false
    property bool fallbackPowered: false
    property var fallbackDevices: []
    property string lastError: ""

    readonly property bool available: root.nativeAvailable || root.fallbackAvailable
    readonly property bool enabled: root.nativeAvailable ? (root.nativeAdapter ? root.nativeAdapter.enabled : false) : (root.fallbackAvailable ? root.fallbackPowered : false)
    readonly property var devices: root.nativeAvailable ? root.nativeDevices : root.fallbackDevices
    readonly property string backendName: root.nativeAvailable ? "BlueZ" : (root.fallbackAvailable ? "bluetoothctl" : "unavailable")

    readonly property bool connected: {
        const list = root.devices
        for (let i = 0; i < list.length; i++) {
            if (list[i].connected)
                return true
        }
        return false
    }

    function refresh() {
        if (root.nativeAvailable || pollProc.running)
            return
        pollProc.running = true
    }

    function setEnabled(value) {
        root.lastError = ""
        if (root.nativeAvailable) {
            if (root.nativeAdapter)
                root.nativeAdapter.enabled = value
            return
        }
        if (!root.fallbackAvailable || powerProc.running)
            return
        powerProc.command = ["timeout", "8", "bluetoothctl", "power", value ? "on" : "off"]
        powerProc.running = true
        root.fallbackPowered = value
    }

    function toggleDevice(device) {
        if (!device)
            return

        root.lastError = ""

        if (root.nativeAvailable && device.nativeDevice) {
            if (device.connected)
                device.nativeDevice.disconnect()
            else
                device.nativeDevice.connect()
            return
        }

        if (!device.address || deviceProc.running)
            return
        deviceProc.command = ["timeout", "20", "bluetoothctl", device.connected ? "disconnect" : "connect", device.address]
        deviceProc.running = true
    }

    function parse(output) {
        const clean = String(output)
        const sections = clean.split("__PAIRED__")
        const showText = sections.length > 1 ? sections[0] : ""
        const rest = sections.length > 1 ? sections[1] : ""
        const pairSections = rest.split("__CONNECTED__")
        const pairedText = pairSections.length > 1 ? pairSections[0] : ""
        const connectedText = pairSections.length > 1 ? pairSections[1] : ""

        const controller = showText.match(/Controller\s+([0-9A-Fa-f:]{17})/)
        const powered = showText.match(/Powered:\s+(yes|no)/i)
        root.fallbackAvailable = controller !== null
        root.fallbackPowered = powered ? powered[1].toLowerCase() === "yes" : false

        let connected = []
        const connectedRe = /^Device\s+([0-9A-Fa-f:]{17})\s+(.+)$/gm
        let match
        while ((match = connectedRe.exec(connectedText)) !== null)
            connected.push(match[1].toUpperCase())

        let devices = []
        const pairedRe = /^Device\s+([0-9A-Fa-f:]{17})\s+(.+)$/gm
        while ((match = pairedRe.exec(pairedText)) !== null) {
            const address = match[1].toUpperCase()
            devices.push({
                name: match[2].trim(),
                address: address,
                connected: connected.indexOf(address) !== -1,
                nativeDevice: null
            })
        }
        root.fallbackDevices = devices
    }

    Component.onCompleted: root.refresh()

    Timer {
        interval: 10000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    Timer {
        id: refreshSoon
        interval: 1200
        repeat: false
        onTriggered: root.refresh()
    }

    Process {
        id: pollProc
        command: ["sh", "-c", "command -v bluetoothctl >/dev/null 2>&1 || exit 0; printf '__SHOW__\\n'; timeout 4 bluetoothctl show 2>/dev/null; printf '__PAIRED__\\n'; timeout 4 bluetoothctl devices Paired 2>/dev/null; printf '__CONNECTED__\\n'; timeout 4 bluetoothctl devices Connected 2>/dev/null"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: root.parse(text)
        }
    }

    Process {
        id: powerProc
        running: false
        onExited: (code) => {
            root.lastError = code === 0 ? "" : "Could not change Bluetooth power"
            refreshSoon.restart()
        }
    }

    Process {
        id: deviceProc
        running: false
        onExited: (code) => {
            root.lastError = code === 0 ? "" : "Bluetooth device action failed"
            refreshSoon.restart()
        }
    }
}
