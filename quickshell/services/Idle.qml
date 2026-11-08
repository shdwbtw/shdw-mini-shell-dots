pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Wayland

// Idle handling: dim the backlight, then lock (only while nothing is playing
// audio), then turn the screens off. Caffeine turns all of it off.
// Apps that inhibit idle (e.g. a fullscreen video) hold every stage off.
Singleton {
    id: root

    // Minutes without input before each stage; 0 turns a stage off
    property real dimMinutes: 4
    property real lockMinutes: 5
    property real screenOffMinutes: 10

    // Backlight level while dimmed, as a fraction of the current level
    property real dimFactor: 0.3
    // After an idle lock, input within this many seconds unlocks without a password
    property int graceSeconds: 5
    // While audio keeps the lock off, check again this often
    property int audioRecheckSeconds: 30

    property bool caffeine: false
    readonly property string caffeineIcon: caffeine ? Theme.glyph(0xf0176) : Theme.glyph(0xf06ca)

    readonly property bool dimmed: dimMonitor.isIdle && dimMonitor.enabled
    readonly property bool screensOff: offMonitor.isIdle && offMonitor.enabled

    function toggleCaffeine() {
        caffeine = !caffeine;
    }

    // --- dim ---------------------------------------------------------------

    IdleMonitor {
        id: dimMonitor
        enabled: !root.caffeine && root.dimMinutes > 0
        timeout: root.dimMinutes * 60
        respectInhibitors: true
        onIsIdleChanged: isIdle ? Brightness.dim(root.dimFactor) : Brightness.undim()
        onEnabledChanged: if (!enabled) Brightness.undim()
    }

    // --- lock --------------------------------------------------------------

    IdleMonitor {
        id: lockMonitor
        enabled: !root.caffeine && root.lockMinutes > 0 && !Session.locked
        timeout: root.lockMinutes * 60
        respectInhibitors: true
        onIsIdleChanged: {
            if (isIdle) {
                audioCheck.running = true;
            } else {
                recheck.stop();
                audioCheck.running = false;
            }
        }
    }

    // Counts output streams pipewire is actually running (paused players
    // leave their stream idle/suspended, so they don't count)
    Process {
        id: audioCheck

        command: ["sh", "-c", "pw-dump | jq '[.[] | select(.type == \"PipeWire:Interface:Node\" and .info.props[\"media.class\"] == \"Stream/Output/Audio\" and .info.state == \"running\")] | length'"]

        stdout: StdioCollector {
            onStreamFinished: {
                const streams = parseInt(text);
                // fall back to MPRIS if pw-dump/jq failed
                const playing = isNaN(streams) ? Mpris.players.values.some(p => p.isPlaying) : streams > 0;
                if (!lockMonitor.isIdle || !lockMonitor.enabled)
                    return;
                if (playing)
                    recheck.restart();
                else
                    Session.lock(true);
            }
        }
    }

    Timer {
        id: recheck
        interval: root.audioRecheckSeconds * 1000
        onTriggered: if (lockMonitor.isIdle && lockMonitor.enabled) audioCheck.running = true
    }

    // --- screen off --------------------------------------------------------

    IdleMonitor {
        id: offMonitor
        enabled: !root.caffeine && root.screenOffMinutes > 0
        timeout: root.screenOffMinutes * 60
        respectInhibitors: true
        onIsIdleChanged: root.setScreens(!isIdle)
        onEnabledChanged: if (!enabled) root.setScreens(true)
    }

    function setScreens(on) {
        for (const s of Quickshell.screens)
            Quickshell.execDetached(["mmsg", "dispatch", `${on ? "wakeup" : "sleep"}_monitor,${s.name}`]);
    }

    // `qs ipc call idle caffeine` toggles; settings reset on restart
    IpcHandler {
        target: "idle"

        function caffeine(): void {
            root.toggleCaffeine();
        }
        function setCaffeine(on: bool): void {
            root.caffeine = on;
        }
        function setDim(minutes: real): void {
            root.dimMinutes = minutes;
        }
        function setLock(minutes: real): void {
            root.lockMinutes = minutes;
        }
        function setScreenOff(minutes: real): void {
            root.screenOffMinutes = minutes;
        }
    }
}
