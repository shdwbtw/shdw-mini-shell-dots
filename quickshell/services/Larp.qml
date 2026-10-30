pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Larp program list, shared with scripts/larp.py through larp.json.
// Each program: { command, min: [cols, rows], max: [cols, rows] }, where a
// null dimension means no limit. `{track}` in a command is a random file
// from ~/Music/larp.
Singleton {
    id: root

    property var programs: []

    function launch() {
        Quickshell.execDetached(["python3", Quickshell.shellPath("scripts/larp.py")]);
    }

    // Every edit goes through here and is written to disk straight away
    function update(index, changes) {
        const next = programs.slice();
        next[index] = Object.assign({}, next[index], changes);
        save(next);
    }

    function setSize(index, key, dim, value) {
        const size = (programs[index][key] ?? [null, null]).slice();
        const n = parseInt(value);
        size[dim] = n > 0 ? n : null;
        update(index, { [key]: size });
    }

    function add() {
        save([...programs, { command: "", min: [null, null], max: [null, null] }]);
    }

    function remove(index) {
        save(programs.filter((_, i) => i !== index));
    }

    function save(next) {
        programs = next;
        file.setText(JSON.stringify({ programs: next }, null, 2) + "\n");
    }

    // Short label for the larp tab: the program names without arguments
    function names() {
        return programs.map(p => (p.command.split(/\s+/)[0] ?? "").split("/").pop())
            .filter(n => n !== "")
            .join(" · ");
    }

    FileView {
        id: file

        path: Quickshell.shellPath("larp.json")
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                root.programs = JSON.parse(text()).programs ?? [];
            } catch (e) {
                console.warn("larp: can't parse larp.json:", e);
            }
        }
    }
}
