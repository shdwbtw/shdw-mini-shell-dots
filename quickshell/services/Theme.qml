pragma Singleton
import QtQuick
import Quickshell

// Colors and sizes. Colors come from the wallpaper's matugen scheme once one
// has been picked (services/Wallpaper.qml); until then, the gruvbox colors
// ported from the waybar style.css / rofi theme are used.
Singleton {
    id: root

    // false = always use the gruvbox colors below
    property bool useWallpaperColors: true

    readonly property var scheme: useWallpaperColors ? Wallpaper.colors : ({})

    function pick(name, fallback) {
        return scheme[name] ?? fallback;
    }

    property color bg: Qt.alpha(pick("surface", "#282828"), 0.99)
    property color border: pick("primary", "#ebdbb2")
    property color fg: pick("on_surface", "#ebdbb2")
    property color dim: pick("surface_container_highest", "#3c3836")
    property color empty: pick("outline_variant", "#504945")
    property color occupied: pick("outline", "#a89984")
    property color hover: pick("tertiary", "#D8B982")
    property color urgent: pick("error_container", "#8C4A3A")
    property color urgentFg: pick("on_error_container", "#F0D6A3")

    property color surface: pick("surface_container", "#32302f")
    property color surfaceAlt: pick("surface_container_high", "#3c3836")
    property color selected: pick("secondary_container", "#665c54")
    property color fgBright: pick("on_surface", "#fbf1c7")
    property color fgSoft: pick("on_surface_variant", "#ebdbb2")
    property color gray: pick("outline", "#a89984")
    property color accent: pick("primary", "#d79921")
    property color accentBright: pick("primary_fixed", "#fabd2f")
    // status colors stay fixed so low battery always reads as red
    readonly property color red: "#fb4934"
    readonly property color green: "#b8bb26"

    // Fade everything to the new palette when the wallpaper changes
    Behavior on bg { ColorAnimation { duration: root.animTheme } }
    Behavior on border { ColorAnimation { duration: root.animTheme } }
    Behavior on fg { ColorAnimation { duration: root.animTheme } }
    Behavior on dim { ColorAnimation { duration: root.animTheme } }
    Behavior on empty { ColorAnimation { duration: root.animTheme } }
    Behavior on occupied { ColorAnimation { duration: root.animTheme } }
    Behavior on hover { ColorAnimation { duration: root.animTheme } }
    Behavior on urgent { ColorAnimation { duration: root.animTheme } }
    Behavior on urgentFg { ColorAnimation { duration: root.animTheme } }
    Behavior on surface { ColorAnimation { duration: root.animTheme } }
    Behavior on surfaceAlt { ColorAnimation { duration: root.animTheme } }
    Behavior on selected { ColorAnimation { duration: root.animTheme } }
    Behavior on fgBright { ColorAnimation { duration: root.animTheme } }
    Behavior on fgSoft { ColorAnimation { duration: root.animTheme } }
    Behavior on gray { ColorAnimation { duration: root.animTheme } }
    Behavior on accent { ColorAnimation { duration: root.animTheme } }
    Behavior on accentBright { ColorAnimation { duration: root.animTheme } }

    readonly property string font: "JetBrainsMono Nerd Font"
    readonly property int fontSize: 13

    readonly property int barHeight: 28
    readonly property int pillPadding: 12
    readonly property int moduleSpacing: 12

    readonly property int animFast: 180
    readonly property int anim: 320
    readonly property int animIsland: 480
    readonly property int animTheme: 800

    function glyph(codepoint) {
        return String.fromCodePoint(codepoint);
    }
}
