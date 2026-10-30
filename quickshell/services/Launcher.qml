pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Open state for the app launcher; toggled by `qs ipc call launcher toggle`
Singleton {
    id: root

    property bool open: false

    // Applications from .desktop files, sorted by name (rofi drun)
    readonly property var apps: DesktopEntries.applications.values
        .filter(e => !e.noDisplay)
        .sort((a, b) => a.name.localeCompare(b.name))

    // rofi config: matching regex, drun-match-fields name
    function search(query) {
        if (query === "")
            return apps;
        let re;
        try {
            re = new RegExp(query, "i");
        } catch (e) {
            re = new RegExp(query.replace(/[.*+?^${}()|[\]\\]/g, "\\$&"), "i");
        }
        const q = query.toLowerCase();
        const hits = apps.filter(e => re.test(e.name));
        // names that start with the query first
        return [...hits.filter(e => e.name.toLowerCase().startsWith(q)), ...hits.filter(e => !e.name.toLowerCase().startsWith(q))];
    }

    function launch(entry) {
        entry.execute();
        open = false;
    }

    IpcHandler {
        target: "launcher"

        function toggle(): void {
            root.open = !root.open;
        }
        function show(): void {
            root.open = true;
        }
        function hide(): void {
            root.open = false;
        }
    }
}
