import QtQuick
import qs.services

// Power button that slides open shutdown / reboot / lock / logout.
// Shutdown, reboot and logout need a second click (the icon turns red) so a
// stray click can't end the session. Collapses when the cursor leaves.
Row {
    id: root

    property bool open: false
    // action waiting for its confirming click
    property string armed: ""

    height: parent.height
    spacing: 0

    onOpenChanged: if (!open) armed = ""

    HoverHandler {
        onHoveredChanged: hovered ? collapseTimer.stop() : collapseTimer.restart()
    }

    Timer {
        id: collapseTimer
        interval: 1200
        onTriggered: root.open = false
    }

    Timer {
        id: disarmTimer
        interval: 3000
        onTriggered: root.armed = ""
    }

    function run(action) {
        if (action !== "lock" && armed !== action) {
            armed = action;
            disarmTimer.restart();
            return;
        }
        open = false;
        if (action === "poweroff")
            Session.poweroff();
        else if (action === "reboot")
            Session.reboot();
        else if (action === "logout")
            Session.logout();
        else
            Session.lock();
    }

    GlyphButton {
        glyph: Theme.glyph(0xf08c7)
        color: root.open ? Theme.accentBright : Theme.fgSoft
        onClicked: root.open = !root.open
    }

    // Slides open to the right of the power icon
    Item {
        width: root.open ? actions.implicitWidth : 0
        height: parent.height
        clip: true

        Behavior on width {
            NumberAnimation { duration: Theme.anim; easing.type: Easing.OutCubic }
        }

        Row {
            id: actions

            height: parent.height
            leftPadding: 12
            spacing: 12
            opacity: root.open ? 1 : 0

            Behavior on opacity {
                NumberAnimation { duration: Theme.anim; easing.type: Easing.OutCubic }
            }

            GlyphButton {
                glyph: Theme.glyph(0xf011)
                armed: root.armed === "poweroff"
                onClicked: root.run("poweroff")
            }
            GlyphButton {
                glyph: Theme.glyph(0xf01e)
                armed: root.armed === "reboot"
                onClicked: root.run("reboot")
            }
            GlyphButton {
                glyph: Theme.glyph(0xf023)
                onClicked: root.run("lock")
            }
            GlyphButton {
                glyph: Theme.glyph(0xf08b)
                armed: root.armed === "logout"
                onClicked: root.run("logout")
            }

            // divider before the workspaces
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 1
                height: 14
                color: Theme.dim
            }
        }
    }

    component GlyphButton: Text {
        id: button

        property string glyph
        property bool armed: false
        signal clicked

        anchors.verticalCenter: parent.verticalCenter
        text: glyph
        font.family: Theme.font
        font.pixelSize: Theme.fontSize
        font.weight: Font.ExtraBold
        color: armed ? Theme.urgent : mouse.containsMouse ? Theme.hover : Theme.fgSoft
        scale: armed ? 1.2 : mouse.pressed ? 0.85 : 1

        Behavior on color {
            ColorAnimation { duration: Theme.animFast }
        }
        Behavior on scale {
            NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutCubic }
        }

        MouseArea {
            id: mouse
            anchors.fill: parent
            anchors.margins: -5
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: button.clicked()
        }
    }
}
