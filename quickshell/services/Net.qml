pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Networking
import Quickshell.Bluetooth

// Wi-Fi (NetworkManager) and Bluetooth (BlueZ) state for the control panel
Singleton {
    id: root

    // --- Wi-Fi ---
    readonly property var devices: Networking.devices.values
    readonly property var wifi: devices.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var wired: devices.find(d => d.type === DeviceType.Wired && d.connected) ?? null
    readonly property bool wifiEnabled: Networking.wifiEnabled
    readonly property var networks: (wifi?.networks.values ?? [])
        .filter(n => n.name !== "")
        .sort((a, b) => (b.connected - a.connected) || (b.known - a.known) || (b.signalStrength - a.signalStrength))
    readonly property var activeNetwork: networks.find(n => n.connected) ?? null

    readonly property string wifiStatus: !wifiEnabled ? "Off"
        : activeNetwork ? activeNetwork.name
        : wired ? "Ethernet"
        : "Not connected"

    function toggleWifi() {
        Networking.wifiEnabled = !Networking.wifiEnabled;
    }

    function setScanning(on) {
        if (wifi)
            wifi.scannerEnabled = on;
    }

    function isSecured(n) {
        return n.security !== WifiSecurityType.Open && n.security !== WifiSecurityType.Unknown;
    }

    // Saved-connection details Quickshell doesn't expose, looked up with
    // nmcli for the network a menu is open on
    property string savedSsid: ""
    property string savedUuid: ""
    property bool savedAutoconnect: true
    readonly property bool savedReady: savedUuid !== "" && savedSsid !== ""

    function inspectSaved(ssid) {
        savedSsid = ssid;
        savedUuid = "";
        savedAutoconnect = true;
        savedLookup.running = false;
        savedLookup.command = ["sh", "-c", `
            for u in $(nmcli -t -e no -g UUID,TYPE connection show | awk -F: '$2 == "802-11-wireless" { print $1 }'); do
                if [ "$(nmcli -e no -g 802-11-wireless.ssid connection show uuid "$u")" = "$1" ]; then
                    echo "$u"
                    nmcli -e no -g connection.autoconnect connection show uuid "$u"
                    exit
                fi
            done`, "sh", ssid];
        savedLookup.running = true;
    }

    function setAutoconnect(on) {
        if (!savedReady)
            return;
        savedAutoconnect = on;
        Quickshell.execDetached(["nmcli", "connection", "modify", "uuid", savedUuid, "connection.autoconnect", on ? "yes" : "no"]);
    }

    function copyPassword() {
        if (!savedReady)
            return;
        Quickshell.execDetached(["sh", "-c", `
            psk=$(nmcli -s -e no -g 802-11-wireless-security.psk connection show uuid "$1")
            if [ -n "$psk" ]; then
                printf %s "$psk" | wl-copy
                notify-send -a Wi-Fi "Password copied" "$2"
            else
                notify-send -a Wi-Fi "No password saved" "$2"
            fi`, "sh", savedUuid, savedSsid]);
    }

    function editSaved() {
        if (savedReady)
            Quickshell.execDetached(["nm-connection-editor", `--edit=${savedUuid}`]);
    }

    function copyText(text, what) {
        Quickshell.execDetached(["sh", "-c", 'printf %s "$1" | wl-copy && notify-send -a Bluetooth "$2 copied" "$1"', "sh", text, what]);
    }

    Process {
        id: savedLookup
        stdout: StdioCollector {
            onStreamFinished: {
                const [uuid, auto] = text.trim().split("\n");
                root.savedUuid = uuid ?? "";
                root.savedAutoconnect = auto !== "no";
            }
        }
    }

    // --- Bluetooth ---
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool btEnabled: adapter?.enabled ?? false
    readonly property var btDevices: (adapter?.devices.values ?? [])
        .filter(d => d.name !== "" && d.name !== d.address.replace(/:/g, "-"))
        .sort((a, b) => (b.connected - a.connected) || (b.paired - a.paired) || a.name.localeCompare(b.name))
    readonly property var btConnected: btDevices.filter(d => d.connected)

    readonly property string btStatus: !adapter ? "Unavailable"
        : !btEnabled ? "Off"
        : btConnected.length === 1 ? btConnected[0].name
        : btConnected.length > 1 ? `${btConnected.length} devices`
        : "On"

    function toggleBluetooth() {
        if (adapter)
            adapter.enabled = !adapter.enabled;
    }

    function setDiscovering(on) {
        if (adapter && adapter.enabled)
            adapter.discovering = on;
    }
}
