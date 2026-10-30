import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services

// Dynamic island in the middle of the bar. The window covers the whole
// screen but only the island itself takes input (see `mask`).
PanelWindow {
    id: win

    required property ShellScreen modelData

    readonly property bool focusedScreen: Mango.focusedMonitor === ""
        ? Quickshell.screens[0] === modelData
        : Mango.focusedMonitor === modelData.name
    readonly property bool launcherActive: Launcher.open && focusedScreen
    readonly property bool wallpaperActive: Wallpaper.pickerOpen && focusedScreen
    property bool hovered: false
    // The larp and notifications tabs stay open without hover; switching
    // back to the home tab lets the island collapse again
    readonly property bool pinned: expanded.tab !== 1

    // Highest priority first
    readonly property string mode: launcherActive ? "launcher"
        : wallpaperActive ? "wallpaper"
        : Osd.visible && focusedScreen ? "osd"
        : Notifs.current ? "notification"
        : hovered || pinned ? "expanded"
        : "compact"

    // The larp and notifications tabs close on a click anywhere outside the island
    readonly property bool pinnedOpen: mode === "expanded" && pinned
    readonly property bool catchOutsideClicks: launcherActive || wallpaperActive || pinnedOpen

    // Back to the compact clock, even if the cursor is still on the island
    function collapse() {
        expanded.tab = 1;
        unhoverTimer.stop();
        hovered = false;
    }

    readonly property Item view: mode === "launcher" ? launcher
        : mode === "wallpaper" ? wallpaper
        : mode === "osd" ? osd
        : mode === "notification" ? notification
        : mode === "expanded" ? expanded
        : compact

    screen: modelData
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    WlrLayershell.namespace: "quickshell-island"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: launcherActive || wallpaperActive ? WlrKeyboardFocus.Exclusive
        // typing in the larp settings fields
        : mode === "expanded" && expanded.larpSettingsOpen ? WlrKeyboardFocus.OnDemand
        : WlrKeyboardFocus.None

    // While the launcher, wallpaper picker or a pinned tab is open the whole
    // screen catches clicks (to close it)
    mask: Region {
        item: win.catchOutsideClicks ? backdrop : island
    }

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    MouseArea {
        id: backdrop
        anchors.fill: parent
        enabled: win.catchOutsideClicks
        onClicked: {
            if (win.launcherActive)
                Launcher.open = false;
            else if (win.wallpaperActive)
                Wallpaper.pickerOpen = false;
            else
                win.collapse();
        }
    }

    // Collapse after a short grace period so brushing the edge doesn't flicker
    Timer {
        id: unhoverTimer
        interval: 250
        onTriggered: win.hovered = false
    }

    onModeChanged: if (mode === "compact") expanded.reset()

    Rectangle {
        id: island

        anchors.top: parent.top
        anchors.topMargin: 7
        anchors.horizontalCenter: parent.horizontalCenter

        width: win.view.implicitWidth
        height: win.view.implicitHeight
        radius: Math.min(height / 2, 24)
        color: Theme.bg
        border.color: Theme.border
        border.width: 1
        clip: true

        Behavior on width {
            NumberAnimation { duration: Theme.animIsland; easing.type: Easing.OutCubic }
        }
        Behavior on height {
            NumberAnimation { duration: Theme.animIsland; easing.type: Easing.OutCubic }
        }

        HoverHandler {
            onHoveredChanged: {
                Notifs.paused = hovered;
                if (hovered) {
                    unhoverTimer.stop();
                    win.hovered = true;
                } else {
                    unhoverTimer.restart();
                }
            }
        }

        CompactView {
            id: compact
            active: win.mode === "compact"
            date: clock.date
        }

        ExpandedView {
            id: expanded
            active: win.mode === "expanded"
            date: clock.date
            onLarpLaunched: win.collapse()
        }

        NotificationView {
            id: notification
            active: win.mode === "notification"
        }

        LauncherView {
            id: launcher
            active: win.mode === "launcher"
        }

        WallpaperView {
            id: wallpaper
            active: win.mode === "wallpaper"
        }

        OsdView {
            id: osd
            active: win.mode === "osd"
        }
    }
}
