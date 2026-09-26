pragma Singleton

import Quickshell
import QtQuick

Singleton {
    id: root

    // palette — vague.nvim, matches waybar
    readonly property color bg: "#141415"
    readonly property color fg: "#cdcdcd"
    readonly property color line: "#252530"
    readonly property color muted: "#606079"
    readonly property color teal: "#b4d4cf"
    readonly property color steel: "#6e94b2"
    readonly property color error: "#d8647e"
    readonly property color warning: "#f3be7c"
    readonly property color plus: "#7fa563"

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

    function withAlpha(c, a) {
        return Qt.rgba(c.r, c.g, c.b, a)
    }
}
