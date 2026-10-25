import QtQuick
import Quickshell
import qs

BarButton {
    id: root
    required property var screen

    glyph: Network.wiredConnected ? Theme.glyphEthernet : Theme.glyphWifi
    baseColor: Network.connected ? Theme.fg : Theme.error
    active: Panels.isOpen("network", root.screen)
    showPip: BluetoothManager.connected
    onClicked: Panels.toggle("network", root.screen, root)
}
