import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications
import qs.services
import qs.modules

// Notification popup. Grows with the amount of text; left click runs the
// default action (or dismisses), right click dismisses.
IslandView {
    id: root

    // Keep showing the last one while fading out
    property Notification notif: null
    readonly property Notification current: Notifs.current
    onCurrentChanged: if (current) notif = current

    readonly property bool critical: notif?.urgency === NotificationUrgency.Critical
    readonly property var actions: (notif?.actions ?? []).filter(a => a.identifier !== "default")
    readonly property string iconSource: {
        if (!notif)
            return "";
        if (notif.image)
            return notif.image;
        if (notif.appIcon)
            return notif.appIcon.startsWith("/") || notif.appIcon.startsWith("file:") ? notif.appIcon : Quickshell.iconPath(notif.appIcon, true);
        return "";
    }

    implicitWidth: 400
    implicitHeight: content.implicitHeight + 28

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => {
            const n = root.notif;
            if (!n)
                return;
            const def = n.actions.find(a => a.identifier === "default");
            if (mouse.button === Qt.LeftButton && def)
                def.invoke();
            Notifs.dismiss(n);
        }
    }

    Column {
        id: content

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 14
        spacing: 10

        Row {
            width: parent.width
            spacing: 12

            ClippingRectangle {
                id: icon
                width: 44
                height: 44
                radius: 12
                color: Theme.surfaceAlt

                BarText {
                    anchors.centerIn: parent
                    anchors.verticalCenter: undefined
                    text: Theme.glyph(0xf0f3)
                    font.pixelSize: 18
                    color: root.critical ? Theme.urgent : Theme.accentBright
                    visible: image.status !== Image.Ready
                }

                Image {
                    id: image
                    anchors.fill: parent
                    source: root.iconSource
                    fillMode: Image.PreserveAspectCrop
                    sourceSize.width: 88
                    sourceSize.height: 88
                    asynchronous: true
                }
            }

            Column {
                width: parent.width - icon.width - parent.spacing
                spacing: 3

                Row {
                    width: parent.width
                    spacing: 6

                    BarText {
                        anchors.verticalCenter: undefined
                        width: parent.width - more.width
                        text: root.notif?.appName ?? ""
                        elide: Text.ElideRight
                        font.pixelSize: 11
                        font.weight: Font.Bold
                        color: root.critical ? Theme.urgentFg : Theme.gray
                    }

                    // "+N" when more popups are waiting
                    BarText {
                        id: more
                        anchors.verticalCenter: undefined
                        text: Notifs.queue.length > 1 ? `+${Notifs.queue.length - 1}` : ""
                        font.pixelSize: 11
                        color: Theme.accentBright
                    }
                }

                BarText {
                    anchors.verticalCenter: undefined
                    width: parent.width
                    text: root.notif?.summary ?? ""
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                    color: Theme.fgBright
                }

                BarText {
                    anchors.verticalCenter: undefined
                    width: parent.width
                    visible: text !== ""
                    text: root.notif?.body ?? ""
                    textFormat: Text.StyledText
                    wrapMode: Text.Wrap
                    maximumLineCount: 5
                    elide: Text.ElideRight
                    font.pixelSize: 12
                    font.weight: Font.Bold
                    color: Theme.fgSoft
                }
            }
        }

        Row {
            anchors.right: parent.right
            spacing: 8
            visible: root.actions.length > 0

            Repeater {
                model: root.actions

                Rectangle {
                    id: action

                    required property NotificationAction modelData

                    width: label.implicitWidth + 24
                    height: 26
                    radius: 13
                    color: mouse.containsMouse ? Theme.selected : Theme.surfaceAlt

                    Behavior on color {
                        ColorAnimation { duration: Theme.animFast }
                    }

                    BarText {
                        id: label
                        anchors.centerIn: parent
                        anchors.verticalCenter: undefined
                        text: action.modelData.text
                        font.pixelSize: 12
                        color: Theme.fgBright
                    }

                    MouseArea {
                        id: mouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            const n = root.notif;
                            action.modelData.invoke();
                            Notifs.dismiss(n);
                        }
                    }
                }
            }
        }
    }
}
