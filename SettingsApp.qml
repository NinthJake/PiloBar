pragma Singleton

import Quickshell

// Transient state for the standalone settings window: open/closed, which
// screen it targets, the selected category, and the search query.
Singleton {
    id: root

    property bool opened: false
    property var targetScreen: null
    property string category: "bar"
    property string search: ""

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