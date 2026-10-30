pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam
import Quickshell.Wayland

// Lock / power actions. Locking first screenshots every output with grim so
// the lockscreen can show a blurred copy of the desktop.
Singleton {
    id: root

    // Lock after this many minutes without input; 0 turns it off.
    // Apps that inhibit idle (e.g. a playing video) hold it off.
    property real idleLockMinutes: 5

    property bool locked: false
    property bool authenticating: false
    // bumped per lock so the lockscreen reloads the fresh screenshots
    property int captureId: 0
    property string pendingPassword: ""

    signal authFailed

    readonly property string shotDir: Quickshell.env("XDG_RUNTIME_DIR") || "/tmp"

    function shotFor(screenName) {
        return `file://${shotDir}/qs-lock-${screenName}.png?${captureId}`;
    }

    function lock() {
        if (locked || capture.running)
            return;
        const cmds = Quickshell.screens.map(s => `grim -o '${s.name}' '${shotDir}/qs-lock-${s.name}.png'`);
        capture.command = ["sh", "-c", cmds.join(" & ") + "; wait"];
        capture.running = true;
    }

    function unlock(password) {
        if (!locked || pam.active || password === "")
            return;
        pendingPassword = password;
        authenticating = true;
        if (!pam.start()) {
            authenticating = false;
            authFailed();
        }
    }

    function poweroff() {
        Quickshell.execDetached(["systemctl", "poweroff"]);
    }

    function reboot() {
        Quickshell.execDetached(["systemctl", "reboot"]);
    }

    // Quits mango (same as `bind=SUPER,m,quit`)
    function logout() {
        Quickshell.execDetached(["mmsg", "dispatch", "quit"]);
    }

    IdleMonitor {
        enabled: root.idleLockMinutes > 0 && !root.locked
        timeout: root.idleLockMinutes * 60
        respectInhibitors: true
        onIsIdleChanged: if (isIdle) root.lock()
    }

    Process {
        id: capture
        onExited: {
            root.captureId++;
            root.locked = true;
        }
    }

    PamContext {
        id: pam

        configDirectory: Quickshell.shellPath("pam")
        config: "password.conf"

        onPamMessage: {
            if (responseRequired) {
                respond(root.pendingPassword);
                root.pendingPassword = "";
            }
        }
        onCompleted: result => {
            root.authenticating = false;
            if (result === PamResult.Success)
                root.locked = false;
            else
                root.authFailed();
        }
        onError: {
            root.authenticating = false;
            root.pendingPassword = "";
            root.authFailed();
        }
    }

    // e.g. `bind=SUPER,l,spawn,qs ipc call session lock`
    IpcHandler {
        target: "session"

        function lock(): void {
            root.lock();
        }
        // `qs ipc call session setIdle 5` (0 = off); resets on restart
        function setIdle(minutes: real): void {
            root.idleLockMinutes = minutes;
        }
    }
}
