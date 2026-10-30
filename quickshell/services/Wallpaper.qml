pragma Singleton
import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io

// Wallpaper switcher backend: lists `dir`, sets the wallpaper with awww and
// generates the shell's colors from it with matugen. The chosen wallpaper and
// its colors are saved to the state dir so the theme survives restarts.
Singleton {
    id: root

    property string dir: Quickshell.env("HOME") + "/Pictures/Wallpaper"
    // matugen options
    property string mode: "dark"
    property string prefer: "saturation"
    property string scheme: "scheme-tonal-spot"
    property string matugenConfig: Quickshell.env("HOME") + "/.config/matugen/config.toml"

    property bool pickerOpen: false

    // Image paths in `dir`, sorted by name
    readonly property var wallpapers: {
        const out = [];
        for (let i = 0; i < folder.count; i++)
            out.push(folder.get(i, "filePath"));
        return out;
    }

    property string current: ""
    // matugen color name -> "#rrggbb"; empty until a wallpaper has been picked
    property var colors: ({})
    property bool generating: false

    function set(path) {
        if (!path)
            return;
        current = path;
        Quickshell.execDetached(["awww", "img", path, "--transition-type", "grow", "--transition-pos", "top", "--transition-duration", "1.2", "--transition-fps", "60"]);
        generating = true;
        // Also renders the templates in matugenConfig (e.g. the Discord theme)
        matugen.command = ["matugen", "image", path, "-c", matugenConfig, "--json", "hex", "--prefer", prefer, "-m", mode, "-t", scheme];
        matugen.running = true;
    }

    FolderListModel {
        id: folder
        folder: "file://" + root.dir
        nameFilters: ["*.png", "*.jpg", "*.jpeg", "*.webp", "*.gif", "*.bmp"]
        showDirs: false
        sortField: FolderListModel.Name
    }

    Process {
        id: matugen

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    // Template hooks can print after the JSON; keep only the
                    // object that ends at the first "}" in column 0
                    const end = text.search(/^\}/m);
                    const data = JSON.parse(end >= 0 ? text.slice(0, end + 1) : text);
                    const next = {};
                    for (const [name, value] of Object.entries(data.colors))
                        next[name] = value[root.mode]?.color ?? value.default.color;
                    root.colors = next;
                    state.setText(JSON.stringify({ wallpaper: root.current, colors: next }));
                } catch (e) {
                    console.warn("wallpaper: could not read matugen output:", e);
                }
            }
        }
        onExited: root.generating = false
    }

    FileView {
        id: state

        path: Quickshell.statePath("wallpaper.json")
        printErrors: false
        onLoaded: {
            try {
                const saved = JSON.parse(text());
                root.current = saved.wallpaper ?? "";
                root.colors = saved.colors ?? {};
            } catch (e) {}
        }
    }

    // `bind=SUPER,m,spawn,qs ipc call wallpaper toggle`
    IpcHandler {
        target: "wallpaper"

        function toggle(): void {
            root.pickerOpen = !root.pickerOpen;
        }
        function set(path: string): void {
            root.set(path);
        }
    }
}
