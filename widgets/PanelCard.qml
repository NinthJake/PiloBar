import QtQuick
import qs

Rectangle {
    color: Theme.withAlpha(Theme.bg, 0.94)
    radius: Theme.panelRadius
    border.color: Theme.line
    border.width: 1

    // Consume clicks on empty card space so they don't reach the overlay's
    // dismiss-on-click backdrop behind it.
    MouseArea {
        anchors.fill: parent
    }
}
