pragma Singleton

import Quickshell
import QtQuick

// Transient state for the standalone settings window: open/closed, which
// screen it targets, the selected category, and the search query.
Singleton {
    id: root

    property bool opened: false
    property var targetScreen: null
    property string category: "bar"
    property string search: ""

    // Transient tooltip shown when a disabled setting row is clicked.
    property string tipText: ""
    property real tipX: 0
    property real tipY: 0
    property bool tipVisible: false

    function showTip(text, x, y) {
        root.tipText = text
        root.tipX = x
        root.tipY = y
        root.tipVisible = true
        tipTimer.restart()
    }

    Timer {
        id: tipTimer
        interval: 3000
        onTriggered: root.tipVisible = false
    }

    function open(screen, cat) {
        if (screen)
            root.targetScreen = screen
        if (cat)
            root.category = cat
        root.opened = true
    }

    function openAt(screen, cat) {
        root.category = cat
        root.search = ""
        open(screen)
    }

    function close() {
        root.opened = false
        root.search = ""
    }

    function toggle(screen) {
        if (root.opened)
            close()
        else
            open(screen)
    }
}