import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services

// Right side of the bar: an icon pill that morphs into the control panel.
// Like the island, the window covers the screen but only the pill (or, while
// open, the whole screen so a click outside closes it) takes input.
PanelWindow {
    id: win

    required property ShellScreen modelData
    property bool open: false
    property bool hovered: false

    readonly property Item view: open ? panel : pill

    screen: modelData
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    WlrLayershell.namespace: "quickshell-controlcenter"
    WlrLayershell.layer: WlrLayer.Top
    // OnDemand so the Wi-Fi password field can take typing
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    mask: Region {
        item: win.open ? backdrop : container
    }

    // Only animate the container while switching pill <-> panel; inside the
    // pill the items animate their own widths
    property bool morphing: false
    onViewChanged: {
        morphing = true;
        morphTimer.restart();
    }
    Timer {
        id: morphTimer
        interval: Theme.animIsland
        onTriggered: win.morphing = false
    }

    MouseArea {
        id: backdrop
        anchors.fill: parent
        enabled: win.open
        onClicked: win.open = false
    }

    Rectangle {
        id: container

        anchors.top: parent.top
        anchors.topMargin: 7
        anchors.right: parent.right
        anchors.rightMargin: 18

        width: win.view.implicitWidth
        height: win.view.implicitHeight
        radius: Math.min(height / 2, 22)
        color: Theme.bg
        border.color: Theme.border
        border.width: 1
        clip: true

        Behavior on width {
            enabled: win.morphing
            NumberAnimation { duration: Theme.animIsland; easing.type: Easing.OutCubic }
        }
        Behavior on height {
            enabled: win.morphing
            NumberAnimation { duration: Theme.animIsland; easing.type: Easing.OutCubic }
        }

        HoverHandler {
            onHoveredChanged: {
                if (hovered) {
                    unhoverTimer.stop();
                    win.hovered = true;
                } else {
                    unhoverTimer.restart();
                }
            }
        }

        // Grace period so brushing the edge on the way to a tray icon doesn't collapse it
        Timer {
            id: unhoverTimer
            interval: 300
            onTriggered: win.hovered = false
        }

        StatusPill {
            id: pill
            active: !win.open
            expanded: win.hovered
            window: win
            onOpenRequested: win.open = true
        }

        Panel {
            id: panel
            active: win.open
            window: win
            onCloseRequested: win.open = false
        }
    }
}
