import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications
import qs.services
import qs.modules

// A notification in the island's history tab. Click runs the default action
// (if any) and dismisses; the × just dismisses.
Rectangle {
    id: root

    required property Notification modelData
    property date now

    readonly property string iconSource: {
        const n = modelData;
        if (n.image)
            return n.image;
        if (n.appIcon)
            return n.appIcon.startsWith("/") || n.appIcon.startsWith("file:") ? n.appIcon : Quickshell.iconPath(n.appIcon, true);
        return "";
    }

    height: content.implicitHeight + 20
    radius: 14
    color: mouse.containsMouse ? Theme.surfaceAlt : Theme.surface

    Behavior on color {
        ColorAnimation { duration: Theme.animFast }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            const def = root.modelData.actions.find(a => a.identifier === "default");
            def?.invoke();
            Notifs.dismiss(root.modelData);
        }
    }

    Row {
        id: content

        x: 10
        y: 10
        width: parent.width - 20
        spacing: 10

        ClippingRectangle {
            id: icon
            width: 32
            height: 32
            radius: 9
            color: Theme.surfaceAlt

            BarText {
                anchors.centerIn: parent
                anchors.verticalCenter: undefined
                text: Theme.glyph(0xf0f3)
                font.pixelSize: 13
                color: Theme.accentBright
                visible: image.status !== Image.Ready
            }

            Image {
                id: image
                anchors.fill: parent
                source: root.iconSource
                fillMode: Image.PreserveAspectCrop
                sourceSize.width: 64
                sourceSize.height: 64
                asynchronous: true
            }
        }

        Column {
            width: parent.width - icon.width - parent.spacing
            spacing: 2

            Item {
                width: parent.width
                height: appName.implicitHeight

                BarText {
                    id: appName
                    anchors.verticalCenter: undefined
                    width: parent.width - when.implicitWidth - close.width - 12
                    text: root.modelData.appName
                    elide: Text.ElideRight
                    font.pixelSize: 11
                    font.weight: Font.Bold
                    color: Theme.gray
                }

                BarText {
                    id: when
                    anchors.verticalCenter: undefined
                    anchors.right: close.left
                    anchors.rightMargin: 8
                    text: Notifs.timeAgo(root.modelData, root.now.getTime())
                    font.pixelSize: 10
                    font.weight: Font.Bold
                    color: Theme.selected
                }

                BarText {
                    id: close
                    anchors.verticalCenter: undefined
                    anchors.right: parent.right
                    text: Theme.glyph(0xf00d)
                    font.pixelSize: 11
                    color: closeMouse.containsMouse ? Theme.urgentFg : Theme.gray
                    opacity: mouse.containsMouse || closeMouse.containsMouse ? 1 : 0.5

                    MouseArea {
                        id: closeMouse
                        anchors.fill: parent
                        anchors.margins: -6
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Notifs.dismiss(root.modelData)
                    }
                }
            }

            BarText {
                anchors.verticalCenter: undefined
                width: parent.width
                text: root.modelData.summary
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
                font.pixelSize: 13
                color: Theme.fgBright
            }

            BarText {
                anchors.verticalCenter: undefined
                width: parent.width
                visible: text !== ""
                text: root.modelData.body
                textFormat: Text.StyledText
                wrapMode: Text.Wrap
                maximumLineCount: 3
                elide: Text.ElideRight
                font.pixelSize: 12
                font.weight: Font.Bold
                color: Theme.fgSoft
            }
        }
    }
}
