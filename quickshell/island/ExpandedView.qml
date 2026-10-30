import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.services
import qs.modules

// Hovered island. Three tabs picked from the bar at the bottom:
// larp button | media + time/date/calendar | notification history
IslandView {
    id: root

    property date date
    // 0 = larp, 1 = home, 2 = notifications
    property int tab: 1
    signal larpLaunched

    readonly property var pageItems: [larpPage, homePage, notifPage]
    readonly property int pad: 18

    // larp tab: showing the program settings instead of the button
    property bool larpSettingsOpen: false

    function reset() {
        calendar.offset = 0;
        tab = 1;
        larpSettingsOpen = false;
    }

    implicitWidth: 420
    implicitHeight: pad + pages.height + 14 + tabBar.height + 12

    // Opening the notifications tab marks everything as read
    readonly property bool viewingNotifs: active && tab === 2
    onViewingNotifsChanged: if (viewingNotifs) Notifs.markRead()
    Connections {
        target: Notifs
        function onUnreadCountChanged() {
            if (root.viewingNotifs)
                Notifs.markRead();
        }
    }

    Item {
        id: pages

        x: root.pad
        y: root.pad
        width: root.implicitWidth - root.pad * 2
        height: root.pageItems[root.tab].implicitHeight
        clip: true

        Page {
            id: larpPage
            index: 0

            Item {
                width: parent.width
                implicitHeight: root.larpSettingsOpen ? larpSettings.implicitHeight : larpMain.implicitHeight
                height: implicitHeight

                // launcher view
                Item {
                    id: larpMain

                    width: parent.width
                    implicitHeight: larpColumn.implicitHeight
                    visible: !root.larpSettingsOpen

                    Column {
                        id: larpColumn
                        anchors.horizontalCenter: parent.horizontalCenter
                        topPadding: 10
                        bottomPadding: 10
                        spacing: 12

                        Rectangle {
                            id: larpButton

                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 200
                            height: 56
                            radius: 28
                            color: larpMouse.containsMouse ? Theme.accentBright : Theme.accent
                            scale: larpMouse.pressed ? 0.94 : 1

                            Behavior on color {
                                ColorAnimation { duration: Theme.animFast }
                            }
                            Behavior on scale {
                                NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutCubic }
                            }

                            BarText {
                                anchors.centerIn: parent
                                anchors.verticalCenter: undefined
                                text: `${Theme.glyph(0xf120)}  larp`
                                font.pixelSize: 18
                                color: Theme.surface
                            }

                            MouseArea {
                                id: larpMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    Larp.launch();
                                    root.larpLaunched();
                                }
                            }
                        }

                        BarText {
                            anchors.verticalCenter: undefined
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: larpMain.width - 80
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                            text: Larp.names()
                            font.pixelSize: 11
                            font.weight: Font.Bold
                            color: Theme.gray
                        }
                    }

                    // opens the settings
                    Rectangle {
                        anchors.right: parent.right
                        anchors.top: parent.top
                        width: 28
                        height: 28
                        radius: 14
                        color: gearMouse.containsMouse ? Theme.selected : Theme.surfaceAlt

                        BarText {
                            anchors.centerIn: parent
                            anchors.verticalCenter: undefined
                            text: Theme.glyph(0xf013)
                            font.pixelSize: 12
                            color: Theme.fgSoft
                        }

                        MouseArea {
                            id: gearMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.larpSettingsOpen = true
                        }
                    }
                }

                LarpSettings {
                    id: larpSettings
                    width: parent.width
                    visible: root.larpSettingsOpen
                    onBack: root.larpSettingsOpen = false
                }
            }
        }

        Page {
            id: homePage
            index: 1

            Column {
                width: parent.width
                spacing: 16

                MediaCard {
                    width: parent.width
                    visible: Media.hasTrack
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: Theme.dim
                    visible: Media.hasTrack
                }

                Row {
                    width: parent.width
                    spacing: 16

                    Column {
                        width: parent.width - calendar.width - parent.spacing
                        spacing: 2

                        BarText {
                            anchors.verticalCenter: undefined
                            text: Qt.formatDateTime(root.date, "HH:mm")
                            font.pixelSize: 40
                            color: Theme.fgBright
                        }
                        BarText {
                            anchors.verticalCenter: undefined
                            text: Qt.formatDateTime(root.date, "dddd")
                            font.pixelSize: 15
                            color: Theme.accentBright
                        }
                        BarText {
                            anchors.verticalCenter: undefined
                            text: Qt.formatDateTime(root.date, "d MMMM yyyy")
                            color: Theme.gray
                            font.weight: Font.Bold
                        }
                    }

                    Calendar {
                        id: calendar
                        today: root.date
                    }
                }
            }
        }

        Page {
            id: notifPage
            index: 2

            Column {
                width: parent.width
                spacing: 10

                Item {
                    width: parent.width
                    height: 30

                    BarText {
                        text: Notifs.history.length > 0 ? `Notifications · ${Notifs.history.length}` : "Notifications"
                        color: Theme.fgSoft
                    }

                    SmallButton {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        glyph: Theme.glyph(0xf1f8)
                        visible: Notifs.history.length > 0
                        hoverColor: Theme.urgent
                        onClicked: Notifs.clearAll()
                    }
                }

                BarText {
                    anchors.verticalCenter: undefined
                    width: parent.width
                    height: 60
                    visible: Notifs.history.length === 0
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    text: `${Theme.glyph(0xf1f6)}  No notifications`
                    color: Theme.gray
                    font.weight: Font.Bold
                }

                ListView {
                    id: history

                    width: parent.width
                    height: Math.min(contentHeight, 340)
                    visible: count > 0
                    spacing: 8
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    model: Notifs.history

                    delegate: NotifCard {
                        width: ListView.view.width
                        now: root.date
                    }
                }
            }
        }
    }

    // Tab switcher
    Item {
        id: tabBar

        readonly property int tabWidth: 44
        readonly property int spacing: 6

        anchors.horizontalCenter: parent.horizontalCenter
        y: pages.y + pages.height + 14
        width: tabWidth * 3 + spacing * 2
        height: 28

        // sliding highlight behind the current tab
        Rectangle {
            x: root.tab * (tabBar.tabWidth + tabBar.spacing)
            width: tabBar.tabWidth
            height: tabBar.height
            radius: height / 2
            color: Theme.surfaceAlt

            Behavior on x {
                NumberAnimation { duration: Theme.anim; easing.type: Easing.OutCubic }
            }
        }

        Row {
            spacing: tabBar.spacing

            TabButton { index: 0; glyph: Theme.glyph(0xf120) }
            TabButton { index: 1; glyph: Theme.glyph(0xf017) }
            TabButton {
                index: 2
                glyph: Theme.glyph(0xf0f3)
                badge: Notifs.unreadCount
            }
        }
    }

    // A tab's content; slides sideways relative to the current tab
    component Page: Item {
        required property int index
        default property alias content: holder.data

        x: (index - root.tab) * (pages.width + root.pad * 2)
        width: pages.width
        implicitHeight: holder.childrenRect.height
        height: implicitHeight
        opacity: index === root.tab ? 1 : 0

        Behavior on x {
            NumberAnimation { duration: Theme.anim; easing.type: Easing.OutCubic }
        }
        Behavior on opacity {
            NumberAnimation { duration: Theme.anim; easing.type: Easing.OutCubic }
        }

        Item {
            id: holder
            width: parent.width
        }
    }

    component TabButton: Item {
        id: tabButton

        required property int index
        property string glyph
        property int badge: 0

        width: tabBar.tabWidth
        height: tabBar.height

        BarText {
            anchors.centerIn: parent
            anchors.verticalCenter: undefined
            text: tabButton.glyph
            color: root.tab === tabButton.index ? Theme.accentBright : tabMouse.containsMouse ? Theme.fgSoft : Theme.gray
        }

        Rectangle {
            visible: tabButton.badge > 0
            x: parent.width / 2 + 4
            y: 2
            width: Math.max(14, badgeText.implicitWidth + 6)
            height: 14
            radius: 7
            color: Theme.urgent

            BarText {
                id: badgeText
                anchors.centerIn: parent
                anchors.verticalCenter: undefined
                text: tabButton.badge
                font.pixelSize: 9
                color: Theme.urgentFg
            }
        }

        MouseArea {
            id: tabMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.tab = tabButton.index
        }
    }

    component SmallButton: Rectangle {
        id: smallButton

        property string glyph
        property color hoverColor: Theme.selected
        signal clicked

        width: 28
        height: 28
        radius: 14
        color: smallMouse.containsMouse ? hoverColor : Theme.surfaceAlt

        Behavior on color {
            ColorAnimation { duration: Theme.animFast }
        }

        BarText {
            anchors.centerIn: parent
            anchors.verticalCenter: undefined
            text: smallButton.glyph
            font.pixelSize: 12
            color: Theme.fgSoft
        }

        MouseArea {
            id: smallMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: smallButton.clicked()
        }
    }
}
