pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Mpris

// Picks the player the island shows: a playing one (spotifast first), else
// spotifast, else whatever is around
Singleton {
    id: root

    property string preferred: "spotifast"

    readonly property var players: Mpris.players.values
    readonly property MprisPlayer player: players.find(p => p.isPlaying && p.dbusName.endsWith(preferred))
        ?? players.find(p => p.isPlaying)
        ?? players.find(p => p.dbusName.endsWith(preferred))
        ?? players[0]
        ?? null

    readonly property bool hasTrack: player !== null && (player.trackTitle ?? "") !== ""
    readonly property bool playing: hasTrack && player.isPlaying
    readonly property string title: player?.trackTitle ?? ""
    readonly property string artist: player?.trackArtist ?? ""
    readonly property string artUrl: player?.trackArtUrl ?? ""

    // Mpris position isn't pushed; poke it so bindings refresh
    Timer {
        running: root.playing
        interval: 1000
        repeat: true
        onTriggered: root.player.positionChanged()
    }

    function formatTime(seconds) {
        const s = Math.max(0, Math.floor(seconds));
        return `${Math.floor(s / 60)}:${String(s % 60).padStart(2, "0")}`;
    }
}
