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

    property var barScreen: null

    readonly property bool flush: Settings.chrome === "flush"
    readonly property bool centered: Settings.chrome === "centered"
    readonly property bool islands: Settings.chrome === "islands"

    // Custom chrome shapes (S-curve, Bevel) flare past the body on the docked
    // edge. They are always drawn; `attachEdges` only squares the docked
    // corners that sit on a left/right screen edge. `overhang` is how far the
    // shape reaches past the body; `sideInset` keeps the outer islands clear of
    // the window edge so a flare toward the screen edge is not clipped.
    readonly property bool customShape: !bar.flush && (Settings.shape === "s-curve" || Settings.shape === "bevel")
    readonly property real shapeRadius: Math.min(Settings.rounding, Theme.barHeight / 2)
    readonly property real overhang: !bar.customShape ? 0 : (Settings.shape === "bevel" ? Theme.barHeight : bar.shapeRadius)
    readonly property real sideInset: (bar.islands && !Settings.attachEdges) ? bar.overhang : 0

    readonly property bool onTop: Settings.edge === "top"

    // Corner radius for a rounded corner. Corners that sit on a screen edge —
    // `docked` (top/bottom) or `side` (left/right) — stay square while the bar
    // is attached to the edges, and take the radius otherwise. Corners that
    // touch no screen edge always round.
    function cornerRadius(docked, side) {
        return (!Settings.attachEdges || (!docked && !side)) ? Settings.rounding : 0
    }

    // ── auto-hide ───────────────────────────────────────────
    // When enabled the bar slides off its docked edge and reappears when the
    // pointer touches that edge (see `revealTrigger` below).
    readonly property bool autoHide: Settings.autoHide
    property bool barHidden: false

    readonly property bool hiddenNow: bar.autoHide && bar.barHidden

    // Float the bar over windows (no reserved strip) instead of pushing windows
    // down. Works with or without auto-hide.
    readonly property bool overlayWindows: Settings.overWindows

    // Offset from the docked edge; negative slides the bar fully off-screen.
    property real slide: hiddenNow ? -(Theme.barHeight + 2) : 0

    Behavior on slide {
        NumberAnimation {
            duration: Theme.durMed
            easing.type: Theme.ease
        }
    }

    function reveal() {
        bar.barHidden = false
        hideTimer.stop()
    }

    function scheduleHide() {
        if (!bar.autoHide || Panels.active !== "" || barHover.hovered)
            return
        hideTimer.restart()
    }

    // Space the bar occupies on the anchored edge. The popup overlay stops at
    // this so it never covers the bar.
    readonly property int strip: Theme.barHeight

    // Where the bar window sits on the screen. Used to place the popup
    // overlay's cards under the right widget.
    readonly property real barOriginX: 0
    readonly property real barOriginY: onTop ? 0 : (screen.height - Theme.barHeight)

    // Widget that opened the current panel, in bar-local coordinates. Panels
    // opened via IPC (no widget) center on the screen.
    readonly property real anchorCenterX: Panels.anchorValid ? (Panels.anchorX + Panels.anchorW / 2) : (bar.screen.width / 2)

    // Left and right groups must stop before the centered group so a long
    // section cannot run under the workspaces. Overflow is clipped.
    readonly property real effectiveWidth: bar.width > 0 ? bar.width : (bar.screen ? bar.screen.width : 0)
    readonly property real maxSideWidth: Math.max(0, (bar.effectiveWidth - centerGroup.width) / 2 - 6 - bar.sideInset)

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

    screen: barScreen
    color: "transparent"
    implicitHeight: Theme.barHeight
    exclusiveZone: (hiddenNow || bar.overlayWindows) ? -1 : Theme.barHeight
    mask: bar.centered ? centeredMask : null

    anchors {
        top: onTop
        bottom: !onTop
        left: true
        right: true
    }

    margins {
        top: onTop ? slide : 0
        bottom: onTop ? 0 : slide
        left: 0
        right: 0
    }

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "pilo-bar"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    HoverHandler {
        id: barHover
        onHoveredChanged: {
            if (hovered)
                bar.reveal()
            else
                bar.scheduleHide()
        }
    }

    Timer {
        id: hideTimer
        interval: Settings.autoHideDelay
        onTriggered: {
            if (bar.autoHide && Panels.active === "" && !barHover.hovered)
                bar.barHidden = true
        }
    }

    Connections {
        target: Settings
        function onAutoHideChanged() {
            if (!Settings.autoHide)
                bar.reveal()
        }
    }

    Connections {
        target: Panels
        function onActiveChanged() {
            if (Panels.active === "")
                bar.scheduleHide()
            else
                bar.reveal()
        }
    }

    // Thin strip on the docked edge that reveals the bar while it is hidden.
    PanelWindow {
        id: revealTrigger
        screen: bar.screen
        visible: bar.hiddenNow
        color: "transparent"
        exclusiveZone: -1

        anchors {
            top: bar.onTop
            bottom: !bar.onTop
            left: true
            right: true
        }

        implicitHeight: 2

        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "pilo-trigger"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onEntered: bar.reveal()
        }
    }

    // ── background ──────────────────────────────────────────
    Rectangle {
        id: bgRect
        anchors.fill: parent
        color: bar.flush ? Theme.withAlpha(Theme.bg, Settings.opacity) : "transparent"

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

    // Centered chrome: one content-sized capsule behind the three groups,
    // flush against the docked edge with the inner corners rounded. Custom
    // shapes are drawn by `centeredShape`; this stays as the input-region
    // geometry in that case.
    Rectangle {
        id: centeredBg
        visible: bar.centered && !bar.customShape
        anchors.verticalCenter: parent.verticalCenter
        height: Theme.barHeight
        x: leftGroup.x
        width: Math.max(0, (rightGroup.x + rightGroup.width) - leftGroup.x)
        topLeftRadius: bar.cornerRadius(bar.onTop, false)
        topRightRadius: bar.cornerRadius(bar.onTop, false)
        bottomLeftRadius: bar.cornerRadius(!bar.onTop, false)
        bottomRightRadius: bar.cornerRadius(!bar.onTop, false)
        color: Theme.withAlpha(Theme.bg, Settings.opacity)
    }

    // Centered chrome with a custom shape.
    BarShape {
        id: centeredShape
        visible: bar.centered && bar.customShape
        x: centeredBg.x
        y: centeredBg.y
        width: centeredBg.width
        height: Theme.barHeight
        shape: Settings.shape
        onTop: bar.onTop
        radius: bar.shapeRadius
        color: Theme.withAlpha(Theme.bg, Settings.opacity)
        topLeftRadius: bar.shapeRadius
        topRightRadius: bar.shapeRadius
        bottomLeftRadius: bar.shapeRadius
        bottomRightRadius: bar.shapeRadius
    }

    // In centered mode only the capsule is clickable; the empty sides pass
    // clicks through to whatever is behind the bar.
    Region {
        id: centeredMask
        shape: RegionShape.Rect
        x: centeredBg.x
        y: centeredBg.y
        width: centeredBg.width
        height: centeredBg.height
    }

    // ── left ────────────────────────────────────────────────
    // Custom-shaped background for the left island (drawn behind the group, so
    // it can flare past the group's bounds without being clipped by it).
    BarShape {
        id: leftShape
        visible: bar.islands && bar.customShape
        x: leftGroup.x
        y: leftGroup.y
        width: leftGroup.width
        height: leftGroup.height
        shape: Settings.shape
        onTop: bar.onTop
        radius: bar.shapeRadius
        color: Theme.withAlpha(Theme.bg, Settings.opacity)
        topLeftRadius: bar.cornerRadius(bar.onTop, true)
        topRightRadius: bar.cornerRadius(bar.onTop, false)
        bottomLeftRadius: bar.cornerRadius(!bar.onTop, true)
        bottomRightRadius: bar.cornerRadius(!bar.onTop, false)
        shapeLeftDocked: !Settings.attachEdges
        shapeRightDocked: true
    }

    Rectangle {
        id: leftGroup
        x: bar.centered ? (centerGroup.x - width - 4) : bar.sideInset
        anchors.verticalCenter: parent.verticalCenter
        width: bar.centered ? (leftRow.implicitWidth + 16) : Math.min(leftRow.implicitWidth + (bar.islands ? 12 : 16), bar.maxSideWidth)
        height: Theme.barHeight
        topLeftRadius: bar.cornerRadius(bar.onTop, true)
        topRightRadius: bar.cornerRadius(bar.onTop, false)
        bottomLeftRadius: bar.cornerRadius(!bar.onTop, true)
        bottomRightRadius: bar.cornerRadius(!bar.onTop, false)
        color: (bar.islands && !bar.customShape) ? Theme.withAlpha(Theme.bg, Settings.opacity) : "transparent"
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
    BarShape {
        id: centerShape
        visible: bar.islands && bar.customShape
        x: centerGroup.x
        y: centerGroup.y
        width: centerGroup.width
        height: centerGroup.height
        shape: Settings.shape
        onTop: bar.onTop
        radius: bar.shapeRadius
        color: Theme.withAlpha(Theme.bg, Settings.opacity)
        topLeftRadius: bar.cornerRadius(bar.onTop, false)
        topRightRadius: bar.cornerRadius(bar.onTop, false)
        bottomLeftRadius: bar.cornerRadius(!bar.onTop, false)
        bottomRightRadius: bar.cornerRadius(!bar.onTop, false)
    }

    Rectangle {
        id: centerGroup
        x: Math.round((parent.width - width) / 2)
        anchors.verticalCenter: parent.verticalCenter
        width: centerRow.implicitWidth + (bar.islands ? 12 : 16)
        height: Theme.barHeight
        topLeftRadius: bar.cornerRadius(bar.onTop, false)
        topRightRadius: bar.cornerRadius(bar.onTop, false)
        bottomLeftRadius: bar.cornerRadius(!bar.onTop, false)
        bottomRightRadius: bar.cornerRadius(!bar.onTop, false)
        color: (bar.islands && !bar.customShape) ? Theme.withAlpha(Theme.bg, Settings.opacity) : "transparent"

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
    BarShape {
        id: rightShape
        visible: bar.islands && bar.customShape
        x: rightGroup.x
        y: rightGroup.y
        width: rightGroup.width
        height: rightGroup.height
        shape: Settings.shape
        onTop: bar.onTop
        radius: bar.shapeRadius
        color: Theme.withAlpha(Theme.bg, Settings.opacity)
        topLeftRadius: bar.cornerRadius(bar.onTop, false)
        topRightRadius: bar.cornerRadius(bar.onTop, true)
        bottomLeftRadius: bar.cornerRadius(!bar.onTop, false)
        bottomRightRadius: bar.cornerRadius(!bar.onTop, true)
        shapeLeftDocked: true
        shapeRightDocked: !Settings.attachEdges
    }

    Rectangle {
        id: rightGroup
        x: bar.centered ? (centerGroup.x + centerGroup.width + 4) : (parent.width - width - bar.sideInset)
        anchors.verticalCenter: parent.verticalCenter
        width: bar.centered ? (rightRow.implicitWidth + 16) : Math.min(rightRow.implicitWidth + (bar.islands ? 12 : 16), bar.maxSideWidth)
        height: Theme.barHeight
        topLeftRadius: bar.cornerRadius(bar.onTop, false)
        topRightRadius: bar.cornerRadius(bar.onTop, true)
        bottomLeftRadius: bar.cornerRadius(!bar.onTop, false)
        bottomRightRadius: bar.cornerRadius(!bar.onTop, true)
        color: (bar.islands && !bar.customShape) ? Theme.withAlpha(Theme.bg, Settings.opacity) : "transparent"
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
            width: calendarPanel.implicitWidth
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