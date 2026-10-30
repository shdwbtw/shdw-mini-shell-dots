pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

// Default sink volume (what the waybar "wireplumber" module showed)
Singleton {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false
    readonly property int percent: Math.round(volume * 100)

    readonly property string kind: {
        const s = `${sink?.description ?? ""} ${sink?.name ?? ""} ${sink?.properties?.["device.form-factor"] ?? ""}`.toLowerCase();
        return s.includes("headset") ? "headset" : s.includes("headphone") ? "headphones" : "default";
    }
    readonly property string icon: {
        if (muted)
            return Theme.glyph(0xf075f);
        if (kind === "headset")
            return Theme.glyph(0xf02ce);
        if (kind === "headphones")
            return Theme.glyph(0xf02cb);
        const icons = [0xf057f, 0xf0580, 0xf057e];
        return Theme.glyph(icons[Math.min(icons.length - 1, Math.floor(volume * icons.length))]);
    }

    // Hardware outputs/inputs (no app streams) for the device picker
    readonly property PwNode source: Pipewire.defaultAudioSource
    readonly property var sinks: Pipewire.nodes.values.filter(n => n.audio && n.isSink && !n.isStream)
    readonly property var sources: Pipewire.nodes.values.filter(n => n.audio && !n.isSink && !n.isStream)

    // Apps currently playing audio, for the mixer. (Playback streams count as
    // sinks here; their properties only fill in once tracked below.)
    readonly property var streams: Pipewire.nodes.values.filter(n => n.audio && n.isStream && n.isSink)

    function streamName(n) {
        const p = n?.properties ?? {};
        return p["application.name"] || n?.description || p["media.name"] || n?.name || "";
    }

    function streamIcon(n) {
        const p = n?.properties ?? {};
        const name = p["application.icon-name"] || (p["application.process.binary"] ?? "").toLowerCase() || (p["application.name"] ?? "").toLowerCase();
        return Quickshell.iconPath(name, "audio-x-generic");
    }

    function nodeName(n) {
        return n?.nickname || n?.description || n?.name || "";
    }

    function setSink(n) {
        Pipewire.preferredDefaultAudioSink = n;
    }

    function setSource(n) {
        Pipewire.preferredDefaultAudioSource = n;
    }

    function setVolume(v) {
        if (!sink?.audio)
            return;
        sink.audio.muted = false;
        sink.audio.volume = Math.max(0, Math.min(1, v));
    }

    function step(delta) {
        setVolume(volume + delta);
    }

    function toggleMute() {
        if (sink?.audio)
            sink.audio.muted = !sink.audio.muted;
    }

    PwObjectTracker {
        objects: [root.sink, root.source, ...(root.streams ?? [])].filter(o => o)
    }
}
