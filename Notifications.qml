import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Notifications
import Quickshell.Wayland
import qs
import qs.notifications

// Native notification daemon and its toast stack. This lives once at the
// ShellRoot, never inside a per-screen Bar: only one process may own
// org.freedesktop.Notifications.
Scope {
    id: root

    // Newest first, and latched to the monitor that was focused when the
    // notification arrived so a card does not jump screens mid-read.
    property var popups: []
    property int maxVisible: 4

    readonly property bool onTop: Settings.edge === "top"

    NotificationServer {
        id: server

        keepOnReload: true
        bodySupported: true
        bodyMarkupSupported: false
        bodyHyperlinksSupported: false
        bodyImagesSupported: false
        actionsSupported: true
        actionIconsSupported: false
        imageSupported: true
        inlineReplySupported: false
        persistenceSupported: false

        onNotification: function (notification) {
            root.adopt(notification)
        }
    }

    function focusedScreenName() {
        const monitor = Hyprland.focusedMonitor
        if (monitor)
            return monitor.name
        return Quickshell.screens.length > 0 ? Quickshell.screens[0].name : ""
    }

    function adopt(notification) {
        if (!notification)
            return

        // Quickshell discards an untracked notification as soon as the signal
        // handler returns, so take ownership before doing anything else.
        notification.tracked = true
        notification.closed.connect(function () {
            root.forget(notification)
        })

        let next = [{ notification: notification, screen: root.focusedScreenName() }]
        for (let i = 0; i < root.popups.length; i++)
            next.push(root.popups[i])

        // A full stack drops its oldest card rather than growing past the
        // screen. Expire rather than dismiss: an overflow is a timeout, not a
        // user action.
        while (next.length > root.maxVisible)
            next.pop().notification.expire()

        root.popups = next
    }

    function forget(notification) {
        let next = []
        let changed = false
        for (let i = 0; i < root.popups.length; i++) {
            const popup = root.popups[i]
            if (popup.notification === notification)
                changed = true
            else
                next.push(popup)
        }
        if (changed)
            root.popups = next
    }

    function popupsFor(screen) {
        let out = []
        for (let i = 0; i < root.popups.length; i++) {
            if (root.popups[i].screen === screen.name)
                out.push(root.popups[i])
        }
        return out
    }

    function expire(notification) {
        if (notification)
            notification.expire()
    }

    function timeoutFor(notification) {
        if (!notification)
            return 0
        // Critical notifications stay until dismissed, as the spec asks.
        if (notification.urgency === NotificationUrgency.Critical)
            return 0

        // Quickshell passes the spec's millisecond timeout through as-is.
        // 0 means "never expire"; -1 means the server default.
        const requested = Number(notification.expireTimeout)
        if (isFinite(requested)) {
            if (requested === 0)
                return 0
            if (requested > 0)
                return Math.max(1500, Math.round(requested))
        }

        return notification.urgency === NotificationUrgency.Low ? 3500 : 6000
    }

    Variants {
        model: Quickshell.screens

        delegate: PanelWindow {
            id: notificationWindow

            required property var modelData
            readonly property var items: root.popupsFor(modelData)

            screen: modelData
            visible: items.length > 0
            color: "transparent"
            exclusiveZone: -1
            implicitWidth: 380
            implicitHeight: Math.max(1, stack.implicitHeight)

            anchors {
                top: root.onTop
                bottom: !root.onTop
                right: true
            }

            margins {
                top: root.onTop ? Theme.barHeight + 8 : 0
                bottom: root.onTop ? 0 : Theme.barHeight + 8
                right: 8
            }

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "pilo-notifications"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            Column {
                id: stack
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                spacing: 8

                Repeater {
                    model: notificationWindow.items

                    delegate: NotificationCard {
                        required property var modelData
                        width: stack.width
                        notification: modelData.notification
                        timeoutMs: root.timeoutFor(modelData.notification)
                        onExpired: root.expire(modelData.notification)
                    }
                }
            }
        }
    }
}
