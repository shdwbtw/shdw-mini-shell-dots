import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import qs.services

// Session lock: blurred screenshot of the desktop, a block clock and a
// password field. Locked via Session.lock() (power menu or IPC).
WlSessionLock {
    locked: Session.locked

    WlSessionLockSurface {
        id: surface

        color: Theme.surface

        SystemClock {
            id: clock
            precision: SystemClock.Seconds
        }

        Image {
            id: shot
            anchors.fill: parent
            source: Session.shotFor(surface.screen?.name ?? "")
            cache: false
            asynchronous: false
            visible: false
        }

        MultiEffect {
            anchors.fill: parent
            source: shot
            visible: shot.status === Image.Ready
            autoPaddingEnabled: false
            blurEnabled: true
            blur: 1
            blurMax: 64
            brightness: -0.12
        }

        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.25)
        }

        Column {
            id: content

            anchors.centerIn: parent
            spacing: 36
            opacity: 0
            scale: 0.96

            Component.onCompleted: intro.start()
            ParallelAnimation {
                id: intro
                NumberAnimation { target: content; property: "opacity"; to: 1; duration: 600; easing.type: Easing.OutCubic }
                NumberAnimation { target: content; property: "scale"; to: 1; duration: 600; easing.type: Easing.OutCubic }
            }

            BlockClock {
                anchors.horizontalCenter: parent.horizontalCenter
                time: Qt.formatDateTime(clock.date, "HH:mm")
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatDateTime(clock.date, "dddd, d MMMM")
                color: Theme.gray
                font.family: Theme.font
                font.pixelSize: 16
                font.weight: Font.Bold
            }

            Rectangle {
                id: field

                anchors.horizontalCenter: parent.horizontalCenter
                width: 280
                height: 42
                radius: 21
                color: Theme.bg
                border.width: 1
                border.color: failed ? Theme.urgent : Session.authenticating ? Theme.accentBright : Theme.border

                property bool failed: false

                Behavior on border.color {
                    ColorAnimation { duration: Theme.anim }
                }

                transform: Translate {
                    id: shakeOffset
                }

                SequentialAnimation {
                    id: shake
                    NumberAnimation { target: shakeOffset; property: "x"; to: -10; duration: 50 }
                    NumberAnimation { target: shakeOffset; property: "x"; to: 10; duration: 70 }
                    NumberAnimation { target: shakeOffset; property: "x"; to: -6; duration: 60 }
                    NumberAnimation { target: shakeOffset; property: "x"; to: 0; duration: 60; easing.type: Easing.OutCubic }
                }

                Timer {
                    id: failReset
                    interval: 1200
                    onTriggered: field.failed = false
                }

                Connections {
                    target: Session
                    function onAuthFailed() {
                        field.failed = true;
                        failReset.restart();
                        shake.restart();
                        input.text = "";
                    }
                }

                TextInput {
                    id: input

                    anchors.fill: parent
                    anchors.leftMargin: 20
                    anchors.rightMargin: 20
                    verticalAlignment: TextInput.AlignVCenter
                    horizontalAlignment: TextInput.AlignHCenter
                    echoMode: TextInput.Password
                    passwordCharacter: "•"
                    color: Theme.fgBright
                    font.family: Theme.font
                    font.pixelSize: 16
                    font.weight: Font.Bold
                    readOnly: Session.authenticating
                    focus: true
                    clip: true

                    onAccepted: Session.unlock(text)
                    Keys.onEscapePressed: text = ""

                    Text {
                        anchors.centerIn: parent
                        visible: input.text === ""
                        text: field.failed ? "Wrong password" : Session.authenticating ? "Checking…" : "Password"
                        color: field.failed ? Theme.urgentFg : Theme.gray
                        font.family: Theme.font
                        font.pixelSize: 14
                        font.weight: Font.Bold
                    }
                }
            }
        }
    }
}
