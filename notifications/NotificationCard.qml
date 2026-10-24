import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import qs

// One notification toast. The server owns the Notification; this card only
// presents it and reports its timeout back to Notifications.qml.
Rectangle {
    id: root

    required property var notification
    property int timeoutMs: 0

    signal expired()

    readonly property color accent: {
        if (root.notification.urgency === NotificationUrgency.Critical)
            return Theme.error
        if (root.notification.urgency === NotificationUrgency.Low)
            return Theme.muted
        return Theme.teal
    }

    readonly property var defaultAction: {
        const actions = root.notification.actions
        for (let i = 0; i < actions.length; i++) {
            if (actions[i].identifier === "default")
                return actions[i]
        }
        return null
    }

    // notify-send in particular puts `-i <name>` in the image-path hint rather
    // than app_icon, and Quickshell turns that into image://icon/<name>. Treat
    // that as an icon, with the checked iconPath() variant so a missing theme
    // icon falls back to our glyph instead of Qt's magenta placeholder.
    readonly property bool imageIsIcon: String(root.notification.image || "").indexOf("image://icon/") === 0
    readonly property string mediaSource: imageIsIcon ? "" : resolveImage(root.notification.image)
    readonly property string iconSource: imageIsIcon ? resolveImage(root.notification.image) : resolveImage(root.notification.appIcon)

    function resolveImage(value) {
        const source = String(value || "")
        if (source.length === 0)
            return ""
        if (source.indexOf("image://icon/") === 0) {
            const name = decodeURIComponent(source.slice("image://icon/".length))
            return Quickshell.iconPath(name, true)
        }
        if (source.indexOf("image://") === 0)
            return source
        if (source.indexOf("file://") === 0)
            return source
        if (source.charAt(0) === "/")
            return "file://" + source
        return Quickshell.iconPath(source, true)
    }

    implicitHeight: layout.implicitHeight + 24
    radius: 10
    color: Theme.withAlpha(Theme.bg, 0.97)
    border.width: 1
    border.color: Theme.withAlpha(root.accent, root.notification.urgency === NotificationUrgency.Critical ? 0.75 : 0.35)
    clip: true

    // Fade in without relying on the compositor's slow layer fade.
    opacity: 0
    Component.onCompleted: enter.start()

    ParallelAnimation {
        id: enter
        NumberAnimation {
            target: root
            property: "opacity"
            from: 0
            to: 1
            duration: Theme.durMed
            easing.type: Theme.ease
        }
    }

    HoverHandler {
        id: hover
        onHoveredChanged: {
            if (!life.running && !life.pausedByHover)
                return
            if (hovered) {
                life.pausedByHover = true
                life.stop()
            } else if (life.pausedByHover) {
                life.pausedByHover = false
                if (root.timeoutMs > 0)
                    life.restart()
            }
        }
    }

    Timer {
        id: life
        interval: root.timeoutMs
        running: root.timeoutMs > 0
        repeat: false
        property bool pausedByHover: false
        onTriggered: root.expired()
    }

    // Accent rail. Critical notifications are visibly louder.
    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 3
        color: root.accent
    }

    // Clicking the body invokes the app's default action when one exists;
    // otherwise it dismisses the toast.
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton) {
                root.notification.dismiss()
            } else if (root.defaultAction) {
                root.defaultAction.invoke()
            } else {
                root.notification.dismiss()
            }
        }
    }

    ColumnLayout {
        id: layout
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: 15
        anchors.rightMargin: 12
        anchors.topMargin: 12
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Item {
                Layout.preferredWidth: 34
                Layout.preferredHeight: 34

                Rectangle {
                    anchors.fill: parent
                    radius: 7
                    color: Theme.withAlpha(root.accent, 0.12)
                }

                Text {
                    anchors.centerIn: parent
                    visible: root.iconSource.length === 0
                    text: Theme.glyphNotifications
                    font.family: Theme.fontFamily
                    font.pixelSize: 16
                    color: root.accent
                }

                // Kept always visible on top of the glyph fallback: binding
                // visibility to Image.status leaves a blank slot on this Qt
                // version even after the icon reaches Image.Ready.
                Image {
                    anchors.centerIn: parent
                    width: 22
                    height: 22
                    asynchronous: true
                    source: root.iconSource
                    sourceSize.width: 44
                    sourceSize.height: 44
                    fillMode: Image.PreserveAspectFit
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    Layout.fillWidth: true
                    text: root.notification.appName.length > 0 ? root.notification.appName : "Notification"
                    elide: Text.ElideRight
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize - 2
                    font.bold: true
                    color: root.accent
                }

                Text {
                    Layout.fillWidth: true
                    text: root.notification.summary
                    textFormat: Text.PlainText
                    wrapMode: Text.WordWrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                    font.bold: true
                    color: Theme.fg
                }
            }

            Item {
                Layout.preferredWidth: 22
                Layout.preferredHeight: 22

                Text {
                    anchors.centerIn: parent
                    text: Theme.glyphClose
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    color: closeMouse.containsMouse ? Theme.error : Theme.muted
                }

                MouseArea {
                    id: closeMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: root.notification.dismiss()
                }
            }
        }

        Text {
            Layout.fillWidth: true
            visible: text.length > 0
            text: root.notification.body
            textFormat: Text.PlainText
            wrapMode: Text.WordWrap
            maximumLineCount: 4
            elide: Text.ElideRight
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize - 1
            color: Theme.muted
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 120
            visible: root.mediaSource.length > 0
            radius: 6
            clip: true
            color: Theme.withAlpha(Theme.line, 0.4)

            Image {
                anchors.fill: parent
                source: root.mediaSource
                sourceSize.width: 712
                sourceSize.height: 240
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: false
            }
        }

        Flow {
            Layout.fillWidth: true
            Layout.preferredHeight: implicitHeight
            visible: actions.count > 0
            spacing: 6

            Repeater {
                id: actions
                model: root.notification.actions

                delegate: Rectangle {
                    id: actionChip
                    required property var modelData

                    width: actionLabel.implicitWidth + 18
                    height: 24
                    radius: 5
                    color: actionMouse.containsMouse ? Theme.withAlpha(root.accent, 0.28) : Theme.withAlpha(root.accent, 0.12)
                    border.width: 1
                    border.color: Theme.withAlpha(root.accent, 0.45)

                    Text {
                        id: actionLabel
                        anchors.centerIn: parent
                        text: actionChip.modelData.text
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize - 2
                        color: Theme.fg
                    }

                    MouseArea {
                        id: actionMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: actionChip.modelData.invoke()
                    }
                }
            }
        }
    }
}
