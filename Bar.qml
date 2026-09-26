import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs
import qs.widgets
import qs.panels

PanelWindow {
    id: bar

    required property var modelData

    readonly property bool pill: Settings.chrome === "pill"
    readonly property bool islands: Settings.chrome === "islands"
    readonly property bool flush: Settings.chrome === "flush"
    readonly property bool onTop: Settings.edge === "top"
    readonly property int outer: (pill || islands) ? Settings.gap : 0

    // Space the bar occupies on the anchored edge, including the pill/islands
    // margin. The popup overlay stops at this so it never covers the bar.
    readonly property int strip: Theme.barHeight + outer

    // Where the bar window sits on the screen. Used to place the popup
    // overlay's cards under the right widget.
    readonly property real barOriginX: outer
    readonly property real barOriginY: onTop ? outer : (screen.height - Theme.barHeight - outer)

    function clampX(value, w) {
        return Math.round(Math.max(8, Math.min(bar.screen.width - w - 8, value)))
    }

    function clampY(value, h) {
        return Math.round(Math.max(8, Math.min(bar.screen.height - h - 8, value)))
    }

    screen: modelData
    color: "transparent"
    implicitHeight: Theme.barHeight
    exclusiveZone: Theme.barHeight + outer

    anchors {
        top: onTop
        bottom: !onTop
        left: true
        right: true
    }

    margins {
        top: onTop ? outer : 0
        bottom: onTop ? 0 : outer
        left: outer
        right: outer
    }

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "pilo-bar"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    // ── background ──────────────────────────────────────────
    Rectangle {
        id: bgRect
        anchors.fill: parent
        radius: bar.pill ? Theme.radius : 0
        color: (bar.flush || bar.pill) ? Theme.withAlpha(Theme.bg, Settings.opacity) : "transparent"

        Rectangle {
            visible: bar.flush
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: bar.onTop ? parent.bottom : undefined
            anchors.top: bar.onTop ? undefined : parent.top
            height: 2
            color: Theme.line
        }
    }

    // ── left ────────────────────────────────────────────────
    Rectangle {
        id: leftGroup
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: leftRow.implicitWidth + (bar.islands ? 12 : 16)
        height: Theme.barHeight
        radius: bar.islands ? Theme.radius : 0
        color: bar.islands ? Theme.withAlpha(Theme.bg, Settings.opacity) : "transparent"

        RowLayout {
            id: leftRow
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            spacing: 4

            LauncherButton {
                id: launcherBtn
                screen: bar.screen
            }

            Taskbar {
                id: taskbar
                screen: bar.screen
            }
        }
    }

    // ── center ──────────────────────────────────────────────
    Rectangle {
        id: centerGroup
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        width: workspaces.implicitWidth + (bar.islands ? 12 : 16)
        height: Theme.barHeight
        radius: bar.islands ? Theme.radius : 0
        color: bar.islands ? Theme.withAlpha(Theme.bg, Settings.opacity) : "transparent"

        Workspaces {
            id: workspaces
            screen: bar.screen
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    // ── right ───────────────────────────────────────────────
    Rectangle {
        id: rightGroup
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: rightRow.implicitWidth + (bar.islands ? 12 : 16)
        height: Theme.barHeight
        radius: bar.islands ? Theme.radius : 0
        color: bar.islands ? Theme.withAlpha(Theme.bg, Settings.opacity) : "transparent"

        RowLayout {
            id: rightRow
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            spacing: 2

            Clock {
                id: clockWidget
                screen: bar.screen
            }

            MonitorsButton {
                id: monitorsBtn
                screen: bar.screen
            }

            NetworkButton {
                id: networkBtn
                screen: bar.screen
            }

            SoundButton {
                id: soundBtn
                screen: bar.screen
            }

            SettingsButton {
                id: settingsBtn
                screen: bar.screen
            }
        }
    }

    // ── popup overlay ───────────────────────────────────────
    // One full-screen layer surface per screen hosts the anchored panels.
    // This avoids xdg_popup focus grabs, which under Hyprland dismissed the
    // panel on the first click instead of letting the widgets receive it.
    PanelWindow {
        id: popupOverlay
        screen: bar.screen
        visible: Panels.ownerScreen === bar.screen && Panels.active !== "" && (Panels.active !== "launcher" || Panels.launcherAnchored)
        color: "transparent"
        exclusiveZone: -1
        focusable: true

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        // Leave the bar's strip uncovered so the bar stays clickable while a
        // panel is open.
        margins {
            top: bar.onTop ? bar.strip : 0
            bottom: bar.onTop ? 0 : bar.strip
            left: 0
            right: 0
        }

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "pilo-popup"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

        MouseArea {
            anchors.fill: parent
            onClicked: Panels.close()
        }

        CalendarPanel {
            id: calendarPanel
            visible: Panels.isOpen("calendar", bar.screen)
            width: 320
            height: calendarPanel.implicitHeight

            readonly property point origin: (bar.contentItem && bar.width > 0) ? clockWidget.mapToItem(bar.contentItem, 0, 0) : Qt.point(0, 0)

            x: bar.clampX(bar.barOriginX + origin.x + clockWidget.width / 2 - width / 2, width)
            y: bar.onTop ? Math.round(origin.y + 6) : bar.clampY(bar.barOriginY + origin.y - height - 6, height)
        }

        NetworkPanel {
            id: networkPanel
            visible: Panels.isOpen("network", bar.screen)
            width: 340
            height: networkPanel.implicitHeight

            readonly property point origin: (bar.contentItem && bar.width > 0) ? networkBtn.mapToItem(bar.contentItem, 0, 0) : Qt.point(0, 0)

            x: bar.clampX(bar.barOriginX + origin.x + networkBtn.width / 2 - width / 2, width)
            y: bar.onTop ? Math.round(origin.y + 6) : bar.clampY(bar.barOriginY + origin.y - height - 6, height)
        }

        SoundPanel {
            id: soundPanel
            visible: Panels.isOpen("sound", bar.screen)
            width: 380
            height: soundPanel.implicitHeight

            readonly property point origin: (bar.contentItem && bar.width > 0) ? soundBtn.mapToItem(bar.contentItem, 0, 0) : Qt.point(0, 0)

            x: bar.clampX(bar.barOriginX + origin.x + soundBtn.width / 2 - width / 2, width)
            y: bar.onTop ? Math.round(origin.y + 6) : bar.clampY(bar.barOriginY + origin.y - height - 6, height)
        }

        SettingsPanel {
            id: settingsPanel
            visible: Panels.isOpen("settings", bar.screen)
            width: 400
            height: settingsPanel.implicitHeight

            readonly property point origin: (bar.contentItem && bar.width > 0) ? settingsBtn.mapToItem(bar.contentItem, 0, 0) : Qt.point(0, 0)

            x: bar.clampX(bar.barOriginX + origin.x + settingsBtn.width / 2 - width / 2, width)
            y: bar.onTop ? Math.round(origin.y + 6) : bar.clampY(bar.barOriginY + origin.y - height - 6, height)
        }

        MonitorsPanel {
            id: monitorsPanel
            visible: Panels.isOpen("monitors", bar.screen)
            width: 460
            height: monitorsPanel.implicitHeight

            readonly property point origin: (bar.contentItem && bar.width > 0) ? monitorsBtn.mapToItem(bar.contentItem, 0, 0) : Qt.point(0, 0)

            x: bar.clampX(bar.barOriginX + origin.x + monitorsBtn.width / 2 - width / 2, width)
            y: bar.onTop ? Math.round(origin.y + 6) : bar.clampY(bar.barOriginY + origin.y - height - 6, height)
        }

        WindowsMenu {
            id: windowsMenu
            visible: Panels.isOpen("windows", bar.screen)
            width: 320
            height: windowsMenu.implicitHeight

            x: bar.clampX(bar.barOriginX + Panels.menuAnchorX + Panels.menuAnchorW / 2 - width / 2, width)
            y: bar.onTop ? 6 : bar.clampY(bar.barOriginY - height - 6, height)
        }

        // Anchored launcher, opened by the bar icon.
        AppLauncher {
            id: anchoredLauncher
            visible: Panels.isOpen("launcher", bar.screen) && Panels.launcherAnchored
            width: 460
            height: 520

            readonly property point origin: (bar.contentItem && bar.width > 0) ? launcherBtn.mapToItem(bar.contentItem, 0, 0) : Qt.point(0, 0)

            x: bar.clampX(bar.barOriginX + origin.x + launcherBtn.width / 2 - width / 2, width)
            y: bar.onTop ? Math.round(origin.y + 6) : bar.clampY(bar.barOriginY + origin.y - height - 6, height)
        }
    }

    // ── launcher overlay ────────────────────────────────────
    PanelWindow {
        id: launcherWindow
        screen: bar.screen
        visible: Panels.isOpen("launcher", bar.screen) && !Panels.launcherAnchored
        color: "transparent"
        exclusiveZone: -1
        focusable: true

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "pilo-launcher"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        MouseArea {
            anchors.fill: parent
            onClicked: Panels.close()
        }

        // Centered launcher, opened by Super / IPC.
        AppLauncher {
            id: launcher
            visible: Panels.isOpen("launcher", bar.screen) && !Panels.launcherAnchored
            anchors.centerIn: parent
            width: Math.min(680, parent.width - 40)
            height: Math.min(560, parent.height - 40)
        }
    }
}
