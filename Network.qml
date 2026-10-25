pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Networking

// Distro-neutral network state for the bar.
//
// Quickshell.Networking only speaks to NetworkManager. On systems that use
// iwd (with systemd-networkd, dhcpcd, NetworkManager-as-iwd-client, …) that
// backend is simply absent, so this singleton falls back to:
//   1. NetworkManager through Quickshell when its backend is live;
//   2. iwd through iwctl for Wi-Fi discovery/connect/disconnect and radio power;
//   3. /proc/net/route + /sys/class/net for connected/interface state.
//
// The last fallback is read-only but works on any distribution. Nothing here
// starts, stops, or reconfigures the system's network manager.
Singleton {
    id: root

    // ── NetworkManager through Quickshell ─────────────────────────────────
    readonly property bool networkManager: Networking.backend === NetworkBackendType.NetworkManager

    readonly property var networkManagerWifi: {
        const devices = Networking.devices.values
        for (let i = 0; i < devices.length; i++) {
            if (devices[i].type === DeviceType.Wifi)
                return devices[i]
        }
        return null
    }

    readonly property bool networkManagerWifiConnected: networkManagerWifi ? networkManagerWifi.connected : false

    readonly property bool networkManagerWiredConnected: {
        const devices = Networking.devices.values
        for (let i = 0; i < devices.length; i++) {
            if (devices[i].type === DeviceType.Wired && devices[i].connected)
                return true
        }
        return false
    }

    readonly property var networkManagerNetworks: {
        let out = []
        if (!root.networkManagerWifi)
            return out
        const networks = root.networkManagerWifi.networks.values
        for (let i = 0; i < networks.length; i++) {
            const network = networks[i]
            out.push({
                name: network.name,
                signal: root.normalizeSignal(network.signalStrength),
                secured: network.security !== WifiSecurityType.Open,
                known: network.known,
                connected: network.connected,
                nativeNetwork: network
            })
        }
        return out
    }

    // ── iwd / generic fallback state ──────────────────────────────────────
    property string iwdAdapter: ""
    property bool iwdPowered: false
    property string iwdStation: ""
    property string iwdState: ""
    property string iwdSsid: ""
    property int iwdRssi: 0
    property var iwdKnown: []
    property var iwdNetworks: []

    property bool connmanDetected: false
    property bool connmanWifiPresent: false
    property bool connmanWifiEnabled: false
    property bool connmanWifiConnected: false
    property string connmanWifiName: ""
    property var connmanNetworks: []

    property string wpaInterface: ""
    property string wpaState: ""
    property string wpaSsid: ""
    property var wpaKnown: []
    property var wpaNetworks: []

    property bool linkConnected: false
    property string linkIface: ""
    property bool linkWifi: false
    property var wifiInterfaces: []

    property string lastError: ""

    // ── unified state ─────────────────────────────────────────────────────
    readonly property bool iwdDetected: iwdAdapter.length > 0
    readonly property bool wpaDetected: wpaInterface.length > 0

    readonly property string activeBackend: {
        if (root.networkManager)
            return "networkmanager"
        if (root.iwdDetected)
            return "iwd"
        if (root.connmanDetected)
            return "connman"
        if (root.wpaDetected)
            return "wpa"
        return "generic"
    }

    readonly property bool wifiPresent: {
        if (root.activeBackend === "networkmanager")
            return root.networkManagerWifi !== null
        if (root.activeBackend === "iwd")
            return root.iwdDetected || root.wifiInterfaces.length > 0
        if (root.activeBackend === "connman")
            return root.connmanWifiPresent
        return root.wifiInterfaces.length > 0 || root.wpaDetected
    }
    readonly property bool wifiConnected: {
        if (root.activeBackend === "networkmanager")
            return root.networkManagerWifiConnected || (root.linkConnected && root.linkWifi)
        if (root.activeBackend === "iwd")
            return root.iwdState === "connected" || (root.linkConnected && root.linkWifi)
        if (root.activeBackend === "connman")
            return root.connmanWifiConnected || (root.linkConnected && root.linkWifi)
        if (root.activeBackend === "wpa")
            return root.wpaState === "COMPLETED" || (root.linkConnected && root.linkWifi)
        return root.linkConnected && root.linkWifi
    }
    readonly property bool wiredConnected: root.activeBackend === "networkmanager" ? root.networkManagerWiredConnected : (root.linkConnected && !root.linkWifi)
    readonly property bool connected: root.wifiConnected || root.wiredConnected

    readonly property string wifiName: {
        if (root.activeBackend === "networkmanager") {
            if (root.networkManagerWifi && root.networkManagerWifi.connected)
                return root.networkManagerWifi.name.length > 0 ? root.networkManagerWifi.name : "Connected"
            return ""
        }
        if (root.activeBackend === "iwd" && root.iwdState === "connected" && root.iwdSsid.length > 0)
            return root.iwdSsid
        if (root.activeBackend === "connman" && root.connmanWifiName.length > 0)
            return root.connmanWifiName
        if (root.activeBackend === "wpa" && root.wpaState === "COMPLETED" && root.wpaSsid.length > 0)
            return root.wpaSsid
        return root.wifiConnected ? "Connected" : ""
    }

    readonly property string statusText: {
        if (root.wiredConnected)
            return "Ethernet"
        if (root.wifiConnected)
            return root.wifiName
        return "Disconnected"
    }

    readonly property bool wifiEnabled: {
        if (root.activeBackend === "networkmanager")
            return Networking.wifiEnabled
        if (root.activeBackend === "iwd")
            return root.iwdPowered
        if (root.activeBackend === "connman")
            return root.connmanWifiEnabled
        return root.wifiPresent
    }
    readonly property bool wifiToggleable: {
        if (root.activeBackend === "networkmanager")
            return root.networkManagerWifi !== null
        if (root.activeBackend === "iwd")
            return root.iwdDetected
        if (root.activeBackend === "connman")
            return root.connmanWifiPresent
        return false
    }
    readonly property bool canScan: {
        if (root.activeBackend === "iwd")
            return root.iwdStation.length > 0
        if (root.activeBackend === "connman")
            return root.connmanWifiPresent && root.connmanWifiEnabled
        if (root.activeBackend === "wpa")
            return root.wpaInterface.length > 0
        return false
    }
    readonly property var networks: {
        if (root.activeBackend === "networkmanager")
            return root.networkManagerNetworks
        if (root.activeBackend === "iwd")
            return root.iwdNetworks
        if (root.activeBackend === "connman")
            return root.connmanNetworks
        if (root.activeBackend === "wpa")
            return root.wpaNetworks
        return []
    }

    readonly property string backendName: {
        if (root.activeBackend === "networkmanager")
            return "NetworkManager"
        if (root.activeBackend === "iwd")
            return "iwd"
        if (root.activeBackend === "connman")
            return "ConnMan"
        if (root.activeBackend === "wpa")
            return "wpa_supplicant"
        return "link status"
    }

    readonly property string note: {
        if (root.activeBackend === "networkmanager")
            return ""
        if (root.activeBackend === "iwd") {
            if (!root.iwdPowered)
                return "Wi-Fi is off"
            if (!root.iwdStation)
                return "The iwd Wi-Fi station is unavailable"
            if (root.iwdNetworks.length === 0)
                return "No Wi-Fi networks found"
            return ""
        }
        if (root.activeBackend === "connman") {
            if (!root.connmanWifiPresent)
                return "ConnMan reports no Wi-Fi technology"
            if (!root.connmanWifiEnabled)
                return "Wi-Fi is off"
            if (root.connmanNetworks.length === 0)
                return "No Wi-Fi networks found"
            return ""
        }
        if (root.activeBackend === "wpa") {
            if (root.wpaNetworks.length === 0)
                return "No Wi-Fi networks found"
            return ""
        }
        if (root.wifiPresent)
            return "Wi-Fi controls unavailable: no supported network manager is running"
        return ""
    }

    function normalizeSignal(value) {
        const signal = Number(value)
        if (!isFinite(signal))
            return 0
        return Math.max(0, Math.min(100, Math.round(signal <= 1 ? signal * 100 : signal)))
    }

    function signalFromDbm(value) {
        const raw = Number(value)
        if (!isFinite(raw))
            return 0
        // iwctl rssi-dbms prints centi-dBm (-2900 = -29 dBm).
        const dbm = Math.abs(raw) > 200 ? raw / 100 : raw
        if (dbm < 0)
            return Math.max(0, Math.min(100, Math.round(2 * (dbm + 100))))
        return Math.max(0, Math.min(100, Math.round(dbm)))
    }

    function stripAnsi(value) {
        return String(value).replace(/\x1b\[[0-9;]*[A-Za-z]/g, "")
    }

    function knownNetwork(name) {
        for (let i = 0; i < root.iwdKnown.length; i++) {
            if (root.iwdKnown[i] === name)
                return true
        }
        return false
    }

    function refresh() {
        poll()
        runDetails()
    }

    // Cheap link/topology poll. Details (SSID, network list, known networks)
    // refresh less often so the open panel's list does not churn.
    function poll() {
        if (!root.networkManager && !iwdTopologyProc.running)
            iwdTopologyProc.running = true
        if (!root.networkManager && !root.iwdDetected) {
            if (!connmanPollProc.running)
                connmanPollProc.running = true
            if (!wpaPollProc.running)
                wpaPollProc.running = true
        }
        if (!routeProc.running)
            routeProc.running = true
    }

    function runDetails() {
        if (root.activeBackend === "iwd") {
            runIwdDetails()
        } else if (root.activeBackend === "connman") {
            if (!connmanPollProc.running)
                connmanPollProc.running = true
        } else if (root.activeBackend === "wpa") {
            if (!wpaPollProc.running)
                wpaPollProc.running = true
        }
    }

    function sameNetworks(left, right) {
        if (left.length !== right.length)
            return false
        for (let i = 0; i < left.length; i++) {
            if (left[i].name !== right[i].name
                    || left[i].signal !== right[i].signal
                    || left[i].secured !== right[i].secured
                    || left[i].known !== right[i].known
                    || left[i].connected !== right[i].connected)
                return false
        }
        return true
    }

    function runIwdDetails() {
        if (!root.iwdStation)
            return
        if (!iwdStatusProc.running)
            iwdStatusProc.running = true
        if (!iwdKnownProc.running)
            iwdKnownProc.running = true
        if (!iwdNetworksProc.running)
            iwdNetworksProc.running = true
    }

    function scan() {
        if (root.activeBackend === "iwd" && root.iwdStation && !iwdScanProc.running) {
            root.lastError = ""
            iwdScanProc.running = true
        } else if (root.activeBackend === "connman" && root.connmanWifiPresent && root.connmanWifiEnabled && !connmanScanProc.running) {
            root.lastError = ""
            connmanScanProc.running = true
        } else if (root.activeBackend === "wpa" && root.wpaInterface && !wpaScanProc.running) {
            root.lastError = ""
            wpaScanProc.running = true
        }
    }

    function setWifiEnabled(value) {
        if (root.activeBackend === "networkmanager") {
            Networking.wifiEnabled = value
            return
        }
        if (root.activeBackend === "iwd") {
            if (!root.iwdAdapter || iwdPowerProc.running)
                return

            root.lastError = ""
            iwdPowerProc.command = ["timeout", "10", "iwctl", "--dont-ask", "adapter", root.iwdAdapter, "set-property", "Powered", value ? "on" : "off"]
            iwdPowerProc.running = true
            root.iwdPowered = value
            if (!value) {
                root.iwdStation = ""
                root.iwdState = ""
                root.iwdSsid = ""
                root.iwdNetworks = []
            }
            return
        }
        if (root.activeBackend === "connman" && root.connmanWifiPresent && !connmanPowerProc.running) {
            root.lastError = ""
            connmanPowerProc.command = ["timeout", "10", "connmanctl", value ? "enable" : "disable", "wifi"]
            connmanPowerProc.running = true
            root.connmanWifiEnabled = value
            if (!value) {
                root.connmanWifiConnected = false
                root.connmanWifiName = ""
                root.connmanNetworks = []
            }
        }
    }

    function connectNetwork(network, psk) {
        if (!network)
            return

        root.lastError = ""

        if (root.networkManager && network.nativeNetwork) {
            if (psk && psk.length > 0)
                network.nativeNetwork.connectWithPsk(psk)
            else
                network.nativeNetwork.connect()
            return
        }

        if (root.activeBackend === "iwd") {
            if (!root.iwdStation || iwdConnectProc.running) {
                if (!root.iwdStation)
                    root.lastError = "Wi-Fi is unavailable"
                return
            }

            const command = ["timeout", "30", "iwctl", "--dont-ask"]
            if (psk && psk.length > 0)
                command.push("--passphrase", psk)
            command.push("station", root.iwdStation, "connect", network.name)
            iwdConnectProc.command = command
            iwdConnectProc.running = true
            return
        }

        if (root.activeBackend === "connman") {
            if (!network.id || connmanConnectProc.running)
                return
            if (network.secured && !network.known) {
                root.lastError = "ConnMan needs its interactive agent for a new passphrase"
                return
            }
            connmanConnectProc.command = ["timeout", "25", "connmanctl", "connect", network.id]
            connmanConnectProc.running = true
            return
        }

        if (root.activeBackend === "wpa") {
            if (!root.wpaInterface || wpaConnectProc.running)
                return
            if (network.known && network.id !== undefined && network.id !== "") {
                // Known profiles live in wpa_supplicant already.
                wpaConnectProc.command = ["sh", "-c", "wpa_cli -i \"$1\" enable_network \"$2\" >/dev/null 2>&1; wpa_cli -i \"$1\" select_network \"$2\" >/dev/null", "pilo-wpa", root.wpaInterface, String(network.id)]
            } else {
                const script = "iface=\"$1\"; ssid=\"$2\"; psk=\"$3\"; id=$(wpa_cli -i \"$iface\" add_network 2>/dev/null | tail -n1); case \"$id\" in ''|*[!0-9]*) exit 1;; esac; wpa_cli -i \"$iface\" set_network \"$id\" ssid \"\\\"$ssid\\\"\" >/dev/null || exit 1; if [ -n \"$psk\" ]; then wpa_cli -i \"$iface\" set_network \"$id\" psk \"\\\"$psk\\\"\" >/dev/null || exit 1; else wpa_cli -i \"$iface\" set_network \"$id\" key_mgmt NONE >/dev/null || exit 1; fi; wpa_cli -i \"$iface\" enable_network \"$id\" >/dev/null || exit 1; wpa_cli -i \"$iface\" select_network \"$id\" >/dev/null || exit 1; wpa_cli -i \"$iface\" save_config >/dev/null 2>&1 || true"
                wpaConnectProc.command = ["sh", "-c", script, "pilo-wpa", root.wpaInterface, network.name, psk || ""]
            }
            wpaConnectProc.running = true
        }
    }

    function disconnectNetwork(network) {
        if (!network)
            return

        root.lastError = ""

        if (root.networkManager && network.nativeNetwork) {
            network.nativeNetwork.disconnect()
            return
        }

        if (root.activeBackend === "iwd") {
            if (!root.iwdStation || iwdDisconnectProc.running) {
                if (!root.iwdStation)
                    root.lastError = "Wi-Fi is unavailable"
                return
            }
            iwdDisconnectProc.running = true
            return
        }

        if (root.activeBackend === "connman") {
            if (!network.id || connmanDisconnectProc.running)
                return
            connmanDisconnectProc.command = ["timeout", "20", "connmanctl", "disconnect", network.id]
            connmanDisconnectProc.running = true
            return
        }

        if (root.activeBackend === "wpa" && root.wpaInterface && !wpaDisconnectProc.running)
            wpaDisconnectProc.running = true
    }

    // ── iwd parsing ──────────────────────────────────────────────────────
    function parseIwdTopology(output) {
        const clean = stripAnsi(output)
        const sections = clean.split("__STATIONS__")
        const adapterText = sections.length > 1 ? sections[0] : ""
        const stationText = sections.length > 1 ? sections[1] : ""

        let adapter = ""
        let powered = false
        const adapterLines = adapterText.split("\n")
        for (let i = 0; i < adapterLines.length; i++) {
            const match = adapterLines[i].match(/^\s{2,}(\S+)\s{2,}(on|off)\b/)
            if (match) {
                adapter = match[1]
                powered = match[2] === "on"
                break
            }
        }

        let station = ""
        const stationLines = stationText.split("\n")
        for (let i = 0; i < stationLines.length; i++) {
            const match = stationLines[i].match(/^\s{2,}(\S+)\s{2,}(connected|disconnected|connecting|disconnecting|aborted)\b/)
            if (match) {
                station = match[1]
                break
            }
        }

        const oldStation = root.iwdStation
        root.iwdAdapter = adapter
        root.iwdPowered = powered
        root.iwdStation = station

        if (!adapter) {
            root.iwdState = ""
            root.iwdSsid = ""
            root.iwdKnown = []
            root.iwdNetworks = []
        } else if (!station) {
            root.iwdState = powered ? "" : "disconnected"
            root.iwdSsid = ""
            root.iwdNetworks = []
        } else if (station !== oldStation) {
            root.iwdState = ""
            root.iwdSsid = ""
            root.runIwdDetails()
        }
    }

    function parseIwdStatus(output) {
        const clean = stripAnsi(output)
        const state = clean.match(/^\s*State\s+(\S+)/m)
        const ssid = clean.match(/^\s*Connected network\s+(.+?)\s*$/m)
        const rssi = clean.match(/^\s*RSSI\s+(-?\d+)/m)

        root.iwdState = state ? state[1] : ""
        root.iwdSsid = ssid ? ssid[1].trim() : ""
        root.iwdRssi = rssi ? parseInt(rssi[1]) : 0
    }

    function parseIwdKnown(output) {
        const clean = stripAnsi(output)
        let known = []
        const re = /^\s{2,}(.+?)\s{2,}(?:psk|open|8021x|sae|owe|wep|none)\b.*$/gm
        let match
        while ((match = re.exec(clean)) !== null) {
            const name = match[1].trim()
            if (name.length > 0 && name !== "Name" && known.indexOf(name) === -1)
                known.push(name)
        }
        root.iwdKnown = known

        // Known list and network list arrive independently. Re-apply the
        // known flag to networks that were parsed before this completed.
        let next = []
        for (let i = 0; i < root.iwdNetworks.length; i++) {
            const network = root.iwdNetworks[i]
            next.push({
                name: network.name,
                signal: network.signal,
                secured: network.secured,
                known: known.indexOf(network.name) !== -1,
                connected: network.connected,
                nativeNetwork: null
            })
        }
        if (!sameNetworks(root.iwdNetworks, next))
            root.iwdNetworks = next
    }

    function parseIwdNetworks(output) {
        const clean = stripAnsi(output)
        let networks = []
        const re = /^(\s*>\s+|\s{2,})(.+?)\s{2,}(open|psk|8021x|sae|owe|wep|none)\s{2,}(-?\d+)\s*$/gm
        let match
        while ((match = re.exec(clean)) !== null) {
            const name = match[2].trim()
            if (name.length === 0)
                continue
            const connected = match[1].indexOf(">") !== -1 || name === root.iwdSsid
            const secured = ["open", "owe", "none"].indexOf(match[3]) === -1
            networks.push({
                name: name,
                signal: root.signalFromDbm(match[4]),
                secured: secured,
                known: root.knownNetwork(name),
                connected: connected,
                nativeNetwork: null
            })
        }

        networks.sort((a, b) => {
            if (a.connected !== b.connected)
                return a.connected ? -1 : 1
            return b.signal - a.signal
        })
        if (!sameNetworks(root.iwdNetworks, networks))
            root.iwdNetworks = networks
    }

    // ── ConnMan parsing ──────────────────────────────────────────────────
    function parseConnman(output) {
        const clean = String(output)
        const stateText = (clean.split("__TECH__")[0] || "")
        const state = stateText.match(/State\s*=\s*(\w+)/)
        root.connmanDetected = state !== null

        if (!state) {
            root.connmanWifiPresent = false
            root.connmanWifiEnabled = false
            root.connmanWifiConnected = false
            root.connmanWifiName = ""
            root.connmanNetworks = []
            return
        }

        const techText = (clean.split("__TECH__")[1] || "").split("__SERVICES__")[0]
        let wifiBlock = ""
        const blocks = techText.split(/^\/net\/connman\/technology\//m)
        for (let i = 0; i < blocks.length; i++) {
            if (/\b(?:Name|Type)\s*=\s*wifi\b/.test(blocks[i])) {
                wifiBlock = blocks[i]
                break
            }
        }
        root.connmanWifiPresent = wifiBlock.length > 0
        const powered = wifiBlock.match(/Powered\s*=\s*(True|False)/i)
        root.connmanWifiEnabled = powered ? powered[1].toLowerCase() === "true" : false

        const servicesText = clean.split("__SERVICES__")[1] || ""
        let networks = []
        let currentName = ""
        const re = /^\s*([*A-Z]*)\s+(.+?)\s{2,}([A-Za-z0-9_]+)\s*$/gm
        let match
        while ((match = re.exec(servicesText)) !== null) {
            const id = match[3]
            if (id.indexOf("wifi_") !== 0)
                continue
            const flags = match[1]
            const connected = flags.indexOf("O") !== -1 || flags.indexOf("R") !== -1
            const name = match[2].trim()
            if (connected && currentName.length === 0)
                currentName = name
            networks.push({
                name: name,
                id: id,
                signal: 0,
                secured: !/_none$/.test(id),
                known: flags.indexOf("*") !== -1,
                connected: connected,
                nativeNetwork: null
            })
        }

        networks.sort((a, b) => {
            if (a.connected !== b.connected)
                return a.connected ? -1 : 1
            if (a.known !== b.known)
                return a.known ? -1 : 1
            return a.name.localeCompare(b.name)
        })

        root.connmanWifiConnected = currentName.length > 0
        root.connmanWifiName = currentName
        root.connmanNetworks = networks
    }

    // ── wpa_supplicant parsing ───────────────────────────────────────────
    function parseWpa(output) {
        const clean = String(output)
        const ifaceMatch = clean.match(/^__IFACE__(.+)$/m)
        if (!ifaceMatch) {
            root.wpaInterface = ""
            root.wpaState = ""
            root.wpaSsid = ""
            root.wpaKnown = []
            root.wpaNetworks = []
            return
        }
        root.wpaInterface = ifaceMatch[1].trim()

        const statusText = (clean.split("__STATUS__")[1] || "").split("__LIST__")[0]
        const listText = (clean.split("__LIST__")[1] || "").split("__SCAN__")[0]
        const scanText = clean.split("__SCAN__")[1] || ""

        const state = statusText.match(/^wpa_state=(\S+)/m)
        if (!state) {
            root.wpaInterface = ""
            root.wpaState = ""
            root.wpaSsid = ""
            root.wpaKnown = []
            root.wpaNetworks = []
            return
        }
        root.wpaState = state[1]
        const ssid = statusText.match(/^ssid=(.*)$/m)
        root.wpaSsid = ssid ? ssid[1].trim() : ""

        let known = []
        const listLines = listText.split("\n")
        for (let i = 0; i < listLines.length; i++) {
            const line = listLines[i].trim()
            if (line.length === 0 || line.indexOf("network id") === 0)
                continue
            const fields = listLines[i].split("\t")
            if (fields.length < 4 || !/^\d+$/.test(fields[0].trim()))
                continue
            known.push({ id: fields[0].trim(), ssid: fields[1].trim() })
        }
        root.wpaKnown = known

        let bySsid = {}
        const scanLines = scanText.split("\n")
        for (let i = 0; i < scanLines.length; i++) {
            const line = scanLines[i].trim()
            if (line.length === 0 || line.indexOf("bssid /") === 0)
                continue
            const fields = scanLines[i].split("\t")
            if (fields.length < 5)
                continue
            const name = fields[4].trim()
            const level = parseInt(fields[2])
            if (name.length === 0 || !isFinite(level))
                continue
            const existing = bySsid[name]
            if (existing && existing.level >= level)
                continue
            bySsid[name] = {
                name: name,
                level: level,
                flags: fields[3]
            }
        }

        if (root.wpaState === "COMPLETED" && root.wpaSsid.length > 0 && !bySsid[root.wpaSsid]) {
            bySsid[root.wpaSsid] = {
                name: root.wpaSsid,
                level: -55,
                flags: ""
            }
        }

        let networks = []
        for (const name in bySsid) {
            const found = bySsid[name]
            let knownId = ""
            for (let i = 0; i < known.length; i++) {
                if (known[i].ssid === name) {
                    knownId = known[i].id
                    break
                }
            }
            networks.push({
                name: name,
                id: knownId,
                signal: root.signalFromDbm(found.level),
                secured: /WPA|RSN|WEP|SAE/i.test(found.flags),
                known: knownId.length > 0,
                connected: root.wpaState === "COMPLETED" && root.wpaSsid === name,
                nativeNetwork: null
            })
        }

        networks.sort((a, b) => {
            if (a.connected !== b.connected)
                return a.connected ? -1 : 1
            if (a.known !== b.known)
                return a.known ? -1 : 1
            return b.signal - a.signal
        })
        root.wpaNetworks = networks
    }

    // ── generic link parsing ─────────────────────────────────────────────
    function parseGenericLinks(output) {
        const sections = String(output).split("__LINKS__")
        const route = (sections.length > 1 ? sections[0] : "").trim()
        const iface = route.length > 0 ? route.split(/\s+/)[0] : ""
        const lines = (sections.length > 1 ? sections[1] : "").split("\n")

        let wifis = []
        for (let i = 0; i < lines.length; i++) {
            const fields = lines[i].trim().split(/\s+/)
            if (fields.length < 2 || fields[0] === "")
                continue
            if (fields[1] === "wifi")
                wifis.push(fields[0])
        }

        root.linkConnected = iface.length > 0
        root.linkIface = iface
        root.linkWifi = wifis.indexOf(iface) !== -1
        root.wifiInterfaces = wifis
    }

    // ── polling and actions ──────────────────────────────────────────────
    Component.onCompleted: root.refresh()

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: root.poll()
    }

    Timer {
        interval: 15000
        running: true
        repeat: true
        onTriggered: root.runDetails()
    }

    Connections {
        target: Panels
        function onActiveChanged() {
            if (Panels.active === "network") {
                root.refresh()
                root.scan()
            }
        }
    }

    Process {
        id: routeProc
        command: ["sh", "-c", "while read iface dest rest; do if [ \"$dest\" = \"00000000\" ]; then printf '%s\\n' \"$iface\"; break; fi; done < /proc/net/route; printf '__LINKS__\\n'; for i in /sys/class/net/*; do n=${i##*/}; [ \"$n\" = lo ] && continue; if [ -d \"$i/wireless\" ]; then t=wifi; else t=wired; fi; s=$(cat \"$i/operstate\" 2>/dev/null); printf '%s %s %s\\n' \"$n\" \"$t\" \"$s\"; done"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: root.parseGenericLinks(text)
        }
    }

    Process {
        id: iwdTopologyProc
        command: ["sh", "-c", "command -v iwctl >/dev/null 2>&1 || exit 0; printf '__ADAPTERS__\\n'; timeout 3 iwctl --dont-ask adapter list 2>/dev/null; printf '__STATIONS__\\n'; timeout 3 iwctl --dont-ask station list 2>/dev/null"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: root.parseIwdTopology(text)
        }
    }

    Process {
        id: iwdStatusProc
        command: ["timeout", "4", "iwctl", "--dont-ask", "station", root.iwdStation, "show"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: root.parseIwdStatus(text)
        }
    }

    Process {
        id: iwdKnownProc
        command: ["timeout", "4", "iwctl", "--dont-ask", "known-networks", "list"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: root.parseIwdKnown(text)
        }
    }

    Process {
        id: iwdNetworksProc
        command: ["timeout", "6", "iwctl", "--dont-ask", "station", root.iwdStation, "get-networks", "rssi-dbms"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: root.parseIwdNetworks(text)
        }
    }

    Process {
        id: iwdScanProc
        command: ["timeout", "15", "iwctl", "--dont-ask", "station", root.iwdStation, "scan"]
        running: false
        onExited: (code) => {
            if (code !== 0)
                root.lastError = "Wi-Fi scan failed"
            refreshSoon.restart()
        }
    }

    Process {
        id: iwdConnectProc
        running: false
        onExited: (code) => {
            root.lastError = code === 0 ? "" : "Could not connect to the network"
            refreshSoon.restart()
        }
    }

    Process {
        id: iwdDisconnectProc
        command: root.iwdStation.length > 0 ? ["timeout", "10", "iwctl", "--dont-ask", "station", root.iwdStation, "disconnect"] : []
        running: false
        onExited: (code) => {
            root.lastError = code === 0 ? "" : "Could not disconnect"
            refreshSoon.restart()
        }
    }

    Process {
        id: iwdPowerProc
        running: false
        onExited: (code) => {
            root.lastError = code === 0 ? "" : "Could not change Wi-Fi power"
            refreshSoon.restart()
        }
    }

    Process {
        id: connmanPollProc
        command: ["sh", "-c", "command -v connmanctl >/dev/null 2>&1 || exit 0; state=$(timeout 4 connmanctl state 2>/dev/null) || exit 0; [ -n \"$state\" ] || exit 0; printf '__STATE__\\n%s\\n' \"$state\"; printf '__TECH__\\n'; timeout 4 connmanctl technologies 2>/dev/null; printf '__SERVICES__\\n'; timeout 6 connmanctl services 2>/dev/null"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: root.parseConnman(text)
        }
    }

    Process {
        id: connmanScanProc
        command: ["timeout", "20", "connmanctl", "scan", "wifi"]
        running: false
        onExited: (code) => {
            root.lastError = code === 0 ? "" : "Wi-Fi scan failed"
            refreshSoon.restart()
        }
    }

    Process {
        id: connmanPowerProc
        running: false
        onExited: (code) => {
            root.lastError = code === 0 ? "" : "Could not change Wi-Fi power"
            refreshSoon.restart()
        }
    }

    Process {
        id: connmanConnectProc
        running: false
        onExited: (code) => {
            root.lastError = code === 0 ? "" : "Could not connect to the network"
            refreshSoon.restart()
        }
    }

    Process {
        id: connmanDisconnectProc
        running: false
        onExited: (code) => {
            root.lastError = code === 0 ? "" : "Could not disconnect"
            refreshSoon.restart()
        }
    }

    Process {
        id: wpaPollProc
        command: ["sh", "-c", "command -v wpa_cli >/dev/null 2>&1 || exit 0; iface=\"$1\"; if [ -n \"$iface\" ] && ! timeout 2 wpa_cli -i \"$iface\" status >/dev/null 2>&1; then iface=\"\"; fi; if [ -z \"$iface\" ]; then for d in /run/wpa_supplicant /var/run/wpa_supplicant; do [ -d \"$d\" ] || continue; for s in \"$d\"/*; do [ -S \"$s\" ] || continue; i=${s##*/}; if timeout 2 wpa_cli -i \"$i\" status >/dev/null 2>&1; then iface=\"$i\"; break 2; fi; done; done; fi; [ -n \"$iface\" ] || exit 0; printf '__IFACE__%s\\n' \"$iface\"; printf '__STATUS__\\n'; timeout 3 wpa_cli -i \"$iface\" status 2>/dev/null; printf '__LIST__\\n'; timeout 3 wpa_cli -i \"$iface\" list_networks 2>/dev/null; printf '__SCAN__\\n'; timeout 3 wpa_cli -i \"$iface\" scan_results 2>/dev/null", "pilo-wpa", root.wpaInterface]
        running: false
        stdout: StdioCollector {
            onStreamFinished: root.parseWpa(text)
        }
    }

    Process {
        id: wpaScanProc
        command: root.wpaInterface.length > 0 ? ["timeout", "12", "wpa_cli", "-i", root.wpaInterface, "scan"] : []
        running: false
        onExited: (code) => {
            root.lastError = code === 0 ? "" : "Wi-Fi scan failed"
            refreshSoon.restart()
        }
    }

    Process {
        id: wpaConnectProc
        running: false
        onExited: (code) => {
            root.lastError = code === 0 ? "" : "Could not connect to the network"
            refreshSoon.restart()
        }
    }

    Process {
        id: wpaDisconnectProc
        command: root.wpaInterface.length > 0 ? ["timeout", "10", "wpa_cli", "-i", root.wpaInterface, "disconnect"] : []
        running: false
        onExited: (code) => {
            root.lastError = code === 0 ? "" : "Could not disconnect"
            refreshSoon.restart()
        }
    }

    Timer {
        id: refreshSoon
        interval: 2500
        repeat: false
        onTriggered: root.refresh()
    }
}
