import QtQuick
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import qs.services
import qs.modules

// Collapsed control center: volume, brightness and battery icons.
// Hovering slides out the percentages and the tray icons; clicking a status
// icon opens the panel, while tray icons act on their own.
CCView {
    id: root

    property bool expanded: false
    property var window
    signal openRequested

    implicitWidth: row.implicitWidth + Theme.pillPadding * 2
    implicitHeight: Theme.barHeight

    Row {
        id: row

        anchors.right: parent.right
        anchors.rightMargin: Theme.pillPadding
        height: parent.height
        spacing: 12

        // Tray, revealed on hover
        Item {
            width: root.expanded && SystemTray.items.values.length > 0 ? tray.implicitWidth : 0
            height: parent.height
            visible: width > 0
            clip: true

            Behavior on width {
                NumberAnimation { duration: Theme.anim; easing.type: Easing.OutCubic }
            }

            Row {
                id: tray

                height: parent.height
                spacing: 8
                opacity: root.expanded ? 1 : 0

                Behavior on opacity {
                    NumberAnimation { duration: Theme.anim; easing.type: Easing.OutCubic }
                }

                Repeater {
                    model: SystemTray.items

                    MouseArea {
                        id: trayItem

                        required property SystemTrayItem modelData

                        width: 16
                        height: parent.height
                        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        onClicked: mouse => {
                            if (mouse.button === Qt.LeftButton && !modelData.onlyMenu) {
                                modelData.activate();
                            } else if (mouse.button === Qt.MiddleButton) {
                                modelData.secondaryActivate();
                            } else if (modelData.hasMenu) {
                                const p = mapToItem(null, 0, height + 6);
                                modelData.display(root.window, p.x, p.y);
                            }
                        }
                        onWheel: wheel => modelData.scroll(wheel.angleDelta.y / 120, false)

                        IconImage {
                            anchors.centerIn: parent
                            implicitSize: 16
                            source: trayItem.modelData.icon
                            scale: trayItem.containsMouse ? 1.15 : 1

                            Behavior on scale {
                                NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutCubic }
                            }
                        }
                    }
                }

                // divider before the status icons
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 1
                    height: 14
                    color: Theme.dim
                }
            }
        }

        StatusItem {
            icon: Audio.icon
            label: Audio.muted ? "muted" : `${Audio.percent}%`
            opacity: Audio.muted ? 0.55 : 1
            onScrolled: dir => Audio.step(dir * 0.05)
        }

        StatusItem {
            visible: Brightness.available
            icon: Brightness.icon
            label: `${Brightness.percent}%`
            onScrolled: dir => Brightness.step(dir * 5)
        }

        // only while caffeine is on, so it's not forgotten
        StatusItem {
            visible: Idle.caffeine
            icon: Idle.caffeineIcon
            iconColor: Theme.accentBright
            label: "awake"
        }

        StatusItem {
            visible: Power.hasBattery
            icon: Power.icon
            iconColor: Power.color
            label: `${Power.capacity}%`
        }
    }

    component StatusItem: Item {
        id: item

        property string icon
        property string label
        property color iconColor: Theme.fg
        signal scrolled(int dir)

        implicitWidth: iconText.implicitWidth + (root.expanded ? 6 + labelText.implicitWidth : 0)
        width: implicitWidth
        height: parent.height
        clip: true

        Behavior on implicitWidth {
            NumberAnimation { duration: Theme.anim; easing.type: Easing.OutCubic }
        }
        Behavior on opacity {
            NumberAnimation { duration: Theme.anim }
        }

        BarText {
            id: iconText
            text: item.icon
            color: item.iconColor
        }

        BarText {
            id: labelText
            x: iconText.implicitWidth + 6
            text: item.label
            opacity: root.expanded ? 1 : 0

            Behavior on opacity {
                NumberAnimation { duration: Theme.anim; easing.type: Easing.OutCubic }
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.openRequested()
            onWheel: wheel => item.scrolled(wheel.angleDelta.y > 0 ? 1 : -1)
        }
    }
}
