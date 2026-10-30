import QtQuick
import Quickshell.Widgets
import qs.services
import qs.modules

// Album art, title/artist, a seekable progress bar and transport controls
Row {
    id: root

    readonly property var player: Media.player
    readonly property real length: player?.length ?? 0
    readonly property real position: player?.position ?? 0

    spacing: 14
    height: 84

    ClippingRectangle {
        width: 84
        height: 84
        radius: 14
        color: Theme.surfaceAlt

        BarText {
            anchors.centerIn: parent
            anchors.verticalCenter: undefined
            text: Theme.glyph(0xf001)
            font.pixelSize: 28
            color: Theme.gray
            visible: art.status !== Image.Ready
        }

        Image {
            id: art
            anchors.fill: parent
            source: Media.artUrl
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            sourceSize.width: 168
            sourceSize.height: 168
            opacity: status === Image.Ready ? 1 : 0

            Behavior on opacity {
                NumberAnimation { duration: Theme.anim }
            }
        }
    }

    Column {
        width: parent.width - 84 - parent.spacing
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4

        BarText {
            anchors.verticalCenter: undefined
            width: parent.width
            text: Media.title
            elide: Text.ElideRight
            font.pixelSize: 14
            color: Theme.fgBright
        }

        BarText {
            anchors.verticalCenter: undefined
            width: parent.width
            text: Media.artist
            elide: Text.ElideRight
            font.pixelSize: 12
            font.weight: Font.Bold
            color: Theme.gray
        }

        // Progress bar; click to seek
        Item {
            width: parent.width
            height: 14

            Rectangle {
                id: track
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                height: 4
                radius: 2
                color: Theme.dim

                Rectangle {
                    width: root.length > 0 ? parent.width * Math.min(1, root.position / root.length) : 0
                    height: parent.height
                    radius: 2
                    color: Theme.accentBright

                    Behavior on width {
                        NumberAnimation { duration: 1000; easing.type: Easing.Linear }
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                enabled: root.player?.canSeek ?? false
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: mouse => root.player.position = root.length * mouse.x / width
            }
        }

        Item {
            width: parent.width
            height: controls.height

            BarText {
                anchors.left: parent.left
                text: Media.formatTime(root.position)
                font.pixelSize: 11
                color: Theme.gray
            }

            Row {
                id: controls
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 18

                ControlButton {
                    glyph: 0xf048
                    onClicked: root.player?.previous()
                }
                ControlButton {
                    glyph: root.player?.isPlaying ? 0xf04c : 0xf04b
                    onClicked: root.player?.togglePlaying()
                }
                ControlButton {
                    glyph: 0xf051
                    onClicked: root.player?.next()
                }
            }

            BarText {
                anchors.right: parent.right
                text: Media.formatTime(root.length)
                font.pixelSize: 11
                color: Theme.gray
            }
        }
    }

    component ControlButton: BarText {
        id: button

        property int glyph
        signal clicked

        anchors.verticalCenter: undefined
        text: Theme.glyph(glyph)
        font.pixelSize: 14
        color: mouse.containsMouse ? Theme.accentBright : Theme.fgSoft
        scale: mouse.pressed ? 0.85 : 1

        Behavior on scale {
            NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutCubic }
        }

        MouseArea {
            id: mouse
            anchors.fill: parent
            anchors.margins: -6
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: button.clicked()
        }
    }
}
