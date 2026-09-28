import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
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

    // Widget that opened the current panel, in bar-local coordinates. Panels
    // opened via IPC (no widget) center on the screen.
    readonly property real anchorCenterX: Panels.anchorValid ? (Panels.anchorX + Panels.anchorW / 2) : ((bar.screen.width - 2 * outer) / 2)

    // Left and right groups must stop before the centered group so a long
    // section cannot run under the workspaces. Overflow is clipped.
    readonly property real effectiveWidth: bar.width > 0 ? bar.width : (bar.screen ? Math.max(0, bar.screen.width - 2 * outer) : 0)
    readonly property real maxSideWidth: Math.max(0, (bar.effectiveWidth - centerGroup.width) / 2 - 6)

    // Identify overlay (settings app -> Displays).
    readonly property string identifyName: {
        const mon = Hyprland.monitorFor(bar.screen)
        return mon ? mon.name : ""
    }
    readonly property int identifyId: Displays.idFor(bar.identifyName)
    readonly property string identifyResolution: {
        const mon = Displays.monitorByName(bar.identifyName)
        return mon ? (mon.width + "x" + mon.height) : ""
    }

    function clampX(value, w) {
        return Math.round(Math.max(8, Math.min(bar.screen.width - w - 8, value)))
    }

    function clampY(value, h) {
        return Math.round(Math.max(8, Math.min(bar.screen.height - h - 8, value)))
    }

    function panelX(w) {
        return bar.clampX(bar.barOriginX + bar.anchorCenterX - w / 2, w)
    }

    function panelY(h) {
        return bar.onTop ? 6 : bar.clampY(bar.barOriginY - h - 6, h)
    }

    // Layout keys from Settings -> widget components. Components are declared
    // below; their screens bind to this bar.
    function componentFor(key) {
        if (key === "launcher")
            return compLauncher
        if (key === "taskbar")
            return compTaskbar
        if (key === "workspaces")
            return compWorkspaces
        if (key === "clock")
            return compClock
        if (key === "network")
            return compNetwork
        if (key === "sound")
            return compSound
        if (key === "settings")
            return compSettings
        if (key === "spacer")
            return compSpacer
        return null
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
        width: Math.min(leftRow.implicitWidth + (bar.islands ? 12 : 16), bar.maxSideWidth)
        height: Theme.barHeight
        radius: bar.islands ? Theme.radius : 0
        color: bar.islands ? Theme.withAlpha(Theme.bg, Settings.opacity) : "transparent"
        clip: true

        Row {
            id: leftRow
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            spacing: 4

            Repeater {
                model: Settings.sectionList("left")
                delegate: Loader {
                    required property string modelData
                    sourceComponent: bar.componentFor(modelData)
                }
            }
        }
    }

    // ── center ──────────────────────────────────────────────
    Rectangle {
        id: centerGroup
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        width: centerRow.implicitWidth + (bar.islands ? 12 : 16)
        height: Theme.barHeight
        radius: bar.islands ? Theme.radius : 0
        color: bar.islands ? Theme.withAlpha(Theme.bg, Settings.opacity) : "transparent"

        Row {
            id: centerRow
            anchors.centerIn: parent
            spacing: 4

            Repeater {
                model: Settings.sectionList("center")
                delegate: Loader {
                    required property string modelData
                    sourceComponent: bar.componentFor(modelData)
                }
            }
        }
    }

    // ── right ───────────────────────────────────────────────
    Rectangle {
        id: rightGroup
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: Math.min(rightRow.implicitWidth + (bar.islands ? 12 : 16), bar.maxSideWidth)
        height: Theme.barHeight
        radius: bar.islands ? Theme.radius : 0
        color: bar.islands ? Theme.withAlpha(Theme.bg, Settings.opacity) : "transparent"
        clip: true

        Row {
            id: rightRow
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            spacing: 2

            Repeater {
                model: Settings.sectionList("right")
                delegate: Loader {
                    required property string modelData
                    sourceComponent: bar.componentFor(modelData)
                }
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
            x: bar.panelX(width)
            y: bar.panelY(height)
        }

        NetworkPanel {
            id: networkPanel
            visible: Panels.isOpen("network", bar.screen)
            width: 340
            height: networkPanel.implicitHeight
            x: bar.panelX(width)
            y: bar.panelY(height)
        }

        SoundPanel {
            id: soundPanel
            visible: Panels.isOpen("sound", bar.screen)
            width: 380
            height: soundPanel.implicitHeight
            x: bar.panelX(width)
            y: bar.panelY(height)
        }

        WindowsMenu {
            id: windowsMenu
            visible: Panels.isOpen("windows", bar.screen)
            width: 320
            height: windowsMenu.implicitHeight
            x: bar.panelX(width)
            y: bar.panelY(height)
        }

        // Anchored launcher, opened by the bar icon.
        AppLauncher {
            id: anchoredLauncher
            visible: Panels.isOpen("launcher", bar.screen) && Panels.launcherAnchored
            width: 460
            height: 520
            x: bar.panelX(width)
            y: bar.panelY(height)
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

    // ── identify overlay ────────────────────────────────────
    // Shown while the settings app's Displays category identifies monitors.
    PanelWindow {
        id: identifyOverlay
        screen: bar.screen
        visible: Displays.identifyActive
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
        WlrLayershell.namespace: "pilo-identify"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        MouseArea {
            anchors.fill: parent
            onClicked: Displays.stopIdentify()
        }

        Rectangle {
            anchors.centerIn: parent
            width: 260
            height: 180
            radius: 20
            color: Theme.withAlpha(Theme.bg, 0.94)
            border.width: 2
            border.color: Theme.teal

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 2

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: bar.identifyId > 0 ? String(bar.identifyId) : "?"
                    font.family: Theme.fontFamily
                    font.pixelSize: 72
                    font.bold: true
                    color: Theme.teal
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: bar.identifyName
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize + 2
                    color: Theme.fg
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: bar.identifyResolution
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize - 1
                    color: Theme.muted
                }
            }
        }
    }

    // ── widget components ───────────────────────────────────
    Component {
        id: compLauncher
        LauncherButton { screen: bar.screen }
    }

    Component {
        id: compTaskbar
        Taskbar { screen: bar.screen }
    }

    Component {
        id: compWorkspaces
        Workspaces { screen: bar.screen }
    }

    Component {
        id: compClock
        Clock { screen: bar.screen }
    }

    Component {
        id: compNetwork
        NetworkButton { screen: bar.screen }
    }

    Component {
        id: compSound
        SoundButton { screen: bar.screen }
    }

    Component {
        id: compSettings
        SettingsButton { screen: bar.screen }
    }

    Component {
        id: compSpacer
        BarSpacer {}
    }
}