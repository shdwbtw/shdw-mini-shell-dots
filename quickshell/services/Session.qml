pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam

// Lock / power actions. Locking first screenshots every output with grim so
// the lockscreen can show a blurred copy of the desktop.
Singleton {
    id: root

    // Idle locking lives in Idle.qml

    property bool locked: false
    // Right after an idle lock: any input unlocks without a password
    property bool graceActive: false
    property bool authenticating: false
    // bumped per lock so the lockscreen reloads the fresh screenshots
    property int captureId: 0
    property string pendingPassword: ""

    signal authFailed

    readonly property string shotDir: Quickshell.env("XDG_RUNTIME_DIR") || "/tmp"

    function shotFor(screenName) {
        return `file://${shotDir}/qs-lock-${screenName}.png?${captureId}`;
    }

    // withGrace: idle locks give Idle.graceSeconds to come back without a password
    function lock(withGrace) {
        if (locked || capture.running)
            return;
        pendingGrace = withGrace === true;
        const cmds = Quickshell.screens.map(s => `grim -o '${s.name}' '${shotDir}/qs-lock-${s.name}.png'`);
        capture.command = ["sh", "-c", cmds.join(" & ") + "; wait"];
        capture.running = true;
    }

    property bool pendingGrace: false

    // Input during the grace period
    function graceUnlock() {
        if (!locked || !graceActive)
            return;
        graceActive = false;
        graceTimer.stop();
        locked = false;
    }

    onLockedChanged: if (!locked) {
        graceActive = false;
        graceTimer.stop();
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

    Process {
        id: capture
        onExited: {
            root.captureId++;
            root.locked = true;
            if (root.pendingGrace && Idle.graceSeconds > 0) {
                root.graceActive = true;
                graceTimer.restart();
            }
        }
    }

    Timer {
        id: graceTimer
        interval: Idle.graceSeconds * 1000
        onTriggered: root.graceActive = false
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
            Idle.lockMinutes = minutes;
        }
    }
}
