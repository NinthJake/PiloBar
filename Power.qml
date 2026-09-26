pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Quickshell 0.3.1's UPower PowerProfiles setter updates its own value but
// never reaches power-profiles-daemon, so drive it through powerprofilesctl
// and read the real state back.
Singleton {
    id: root

    // "power-saver" | "balanced" | "performance"
    property string profile: "balanced"
    property bool hasPerformance: true

    Process {
        id: getProc
        command: ["powerprofilesctl", "get"]
        stdout: StdioCollector {
            onStreamFinished: {
                const value = text.trim()
                if (value.length > 0)
                    root.profile = value
            }
        }
    }

    Process {
        id: listProc
        command: ["powerprofilesctl", "list"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.hasPerformance = text.indexOf("performance:") !== -1
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: getProc.running = true
    }

    Timer {
        id: refresh
        interval: 350
        onTriggered: getProc.running = true
    }

    function setProfile(value) {
        root.profile = value
        Quickshell.execDetached(["powerprofilesctl", "set", value])
        refresh.restart()
    }
}
