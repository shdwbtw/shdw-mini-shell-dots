pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Tag + monitor state, streamed from `mmsg watch ...`
Singleton {
    id: root

    // monitor name -> [{ index, is_active, is_urgent, client_count, layout }]
    property var monitors: ({})
    // name of the monitor mango currently has focused
    property string focusedMonitor: ""

    function tagsFor(monitor) {
        return monitors[monitor] ?? [];
    }

    // Tags are 1-based, same as `bind=SUPER,1,view,1,0`
    function view(index) {
        Quickshell.execDetached(["mmsg", "dispatch", `view,${index},0`]);
    }

    MmsgStream {
        args: ["watch", "all-tags"]
        onEvent: data => {
            const next = {};
            for (const m of data.all_tags ?? [])
                next[m.monitor] = m.tags;
            root.monitors = next;
        }
    }

    MmsgStream {
        args: ["watch", "all-monitors"]
        onEvent: data => {
            const active = (data.monitors ?? []).find(m => m.active);
            if (active)
                root.focusedMonitor = active.name;
        }
    }

    component MmsgStream: Process {
        id: proc

        required property list<string> args
        signal event(var data)

        command: ["mmsg", ...args]
        running: true

        stdout: SplitParser {
            onRead: line => {
                try {
                    proc.event(JSON.parse(line));
                } catch (e) {
                    console.warn("mango: could not parse event:", line);
                }
            }
        }

        // Reconnect if the compositor restarts or the stream drops
        onExited: restartTimer.start()

        property Timer restartTimer: Timer {
            interval: 1000
            onTriggered: proc.running = true
        }
    }
}
