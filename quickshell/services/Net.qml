pragma Singleton
import QtQuick
import Quickshell
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
