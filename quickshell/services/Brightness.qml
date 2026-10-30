pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Backlight level from sysfs, changed through brightnessctl
Singleton {
    id: root

    property string device: "amdgpu_bl1"

    readonly property bool available: maxFile.loaded
    readonly property real max: parseInt(maxFile.text()) || 1
    readonly property int actual: Math.round((parseInt(currentFile.text()) || 0) / max * 100)
    // While dragging a slider show the requested value, not the lagging sysfs one
    property int pending: -1
    readonly property int percent: pending >= 0 ? pending : actual

    // Same icons as the waybar backlight module
    readonly property string icon: percent < 50 ? Theme.glyph(0xf00de) : Theme.glyph(0xf00e0)

    function set(p) {
        pending = Math.max(1, Math.min(100, Math.round(p)));
        applyTimer.restart();
    }

    function step(delta) {
        set(percent + delta);
    }

    // Coalesce rapid slider/scroll changes into one brightnessctl call
    Timer {
        id: applyTimer
        interval: 40
        onTriggered: {
            Quickshell.execDetached(["brightnessctl", "-q", "-d", root.device, "set", `${root.pending}%`]);
            settleTimer.restart();
        }
    }

    Timer {
        id: settleTimer
        interval: 400
        onTriggered: {
            currentFile.reload();
            root.pending = -1;
        }
    }

    FileView {
        id: maxFile
        path: `/sys/class/backlight/${root.device}/max_brightness`
    }

    FileView {
        id: currentFile
        path: `/sys/class/backlight/${root.device}/brightness`
        watchChanges: true
        onFileChanged: reload()
    }

    // sysfs doesn't always emit change events (e.g. brightness keys handled by the kernel)
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: currentFile.reload()
    }
}
