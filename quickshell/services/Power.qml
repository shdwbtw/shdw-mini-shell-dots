pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.UPower

// Battery state and power-profiles-daemon profile
Singleton {
    id: root

    readonly property UPowerDevice battery: UPower.displayDevice
    readonly property bool hasBattery: battery?.isLaptopBattery ?? false
    readonly property int capacity: Math.round((battery?.percentage ?? 0) * 100)
    readonly property bool charging: battery?.state === UPowerDeviceState.Charging
    readonly property bool full: battery?.state === UPowerDeviceState.FullyCharged

    readonly property var dischargingIcons: [0xf244, 0xf243, 0xf242, 0xf241, 0xf240]
    readonly property var chargingIcons: [0xf244, 0xf243, 0xf242, 0xf241, 0xf240]

    readonly property string icon: {
        const icons = charging ? chargingIcons : dischargingIcons;
        return Theme.glyph(icons[Math.min(icons.length - 1, Math.round(capacity / 100 * (icons.length - 1)))]);
    }

    // Discharging at or below this is shown in red
    property int lowThreshold: 20
    readonly property bool low: !charging && !full && capacity <= lowThreshold
    readonly property color color: charging ? Theme.green : low ? Theme.red : Theme.fg

    readonly property string status: {
        if (full)
            return "Fully charged";
        if (charging)
            return battery.timeToFull > 0 ? `Charging · ${formatDuration(battery.timeToFull)} until full` : "Charging";
        return battery?.timeToEmpty > 0 ? `${formatDuration(battery.timeToEmpty)} remaining` : "On battery";
    }

    readonly property int profile: PowerProfiles.profile
    readonly property bool hasPerformance: PowerProfiles.hasPerformanceProfile

    function setProfile(p) {
        PowerProfiles.profile = p;
    }

    function formatDuration(seconds) {
        const h = Math.floor(seconds / 3600);
        const m = Math.floor(seconds % 3600 / 60);
        return h > 0 ? `${h}h ${m}m` : `${m}m`;
    }
}
