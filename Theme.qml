pragma Singleton

import Quickshell
import QtQuick

Singleton {
    id: root

    // palette — resolved from the active scheme (Themes.qml), persisted in
    // Settings.theme. The token names are stable so every widget is unchanged.
    readonly property var scheme: Themes.find(Settings.theme)
    readonly property color bg: scheme.bg
    readonly property color fg: scheme.fg
    readonly property color line: scheme.line
    readonly property color muted: scheme.muted
    readonly property color teal: scheme.teal
    readonly property color steel: scheme.steel
    readonly property color error: scheme.error
    readonly property color warning: scheme.warning
    readonly property color plus: scheme.plus

    readonly property string fontFamily: "FiraCode Nerd Font"
    readonly property int fontSize: 13
    readonly property int iconSize: 15

    readonly property int barHeight: 32
    readonly property int outerMargin: 8
    readonly property int radius: 14
    readonly property int panelRadius: 8
    readonly property int panelWidth: 340

    readonly property int durFast: 160
    readonly property int durMed: 200
    readonly property int ease: Easing.OutCubic

    // nerd font glyphs
    readonly property string glyphLauncher: "\uf00a"
    readonly property string glyphWifi: "\uf1eb"
    readonly property string glyphEthernet: "\uf1e6"
    readonly property string glyphBluetooth: "\uf293"
    readonly property string glyphVolume: "\uf028"
    readonly property string glyphVolumeMute: "\uf026"
    readonly property string glyphSettings: "\uf013"
    readonly property string glyphShutdown: "\uf011"
    readonly property string glyphReboot: "\uf021"
    readonly property string glyphSignout: "\uf08b"
    readonly property string glyphSuspend: "\uf186"
    readonly property string glyphSearch: "\uf002"
    readonly property string glyphClose: "\uf00d"
    readonly property string glyphLeft: "\uf053"
    readonly property string glyphRight: "\uf054"
    readonly property string glyphBolt: "\uf0e7"
    readonly property string glyphFile: "\uf15b"
    readonly property string glyphApps: "\uf009"
    readonly property string glyphMonitor: "\uf108"
    readonly property string glyphArrowLeft: "\uf060"
    readonly property string glyphArrowRight: "\uf061"
    readonly property string glyphRefresh: "\uf021"
    readonly property string glyphChevronUp: "\uf077"
    readonly property string glyphChevronDown: "\uf078"
    readonly property string glyphPlus: "\uf067"
    readonly property string glyphMinus: "\uf068"
    readonly property string glyphTrash: "\uf1f8"
    readonly property string glyphLayout: "\uf00a"
    readonly property string glyphCalendar: "\uf073"
    readonly property string glyphTheme: "\uf53f"
    readonly property string glyphOpen: "\uf08e"
    readonly property string glyphNotifications: "\uf0f3"

    function withAlpha(c, a) {
        return Qt.rgba(c.r, c.g, c.b, a)
    }
}
