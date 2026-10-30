import QtQuick
import qs.services
import qs.modules

// Collapsed island: the clock. Can also cycle with the current track, and
// periodically flashes "x new notifications" while there are unread ones.
IslandView {
    id: root

    property date date
    property int maxLength: 36

    // Alternate between the clock and the playing track
    property bool cycleMusic: true
    property int musicInterval: 20000
    // How often / how long the unread reminder shows
    property int noticeInterval: 15000
    property int noticeDuration: 4000

    // "clock", "music" or "notice"
    property string showing: "clock"

    readonly property Item shown: showing === "music" ? music : showing === "notice" ? notice : clockLabel

    implicitWidth: shown.implicitWidth + 32
    implicitHeight: Theme.barHeight

    onActiveChanged: if (!active) showing = "clock"

    Timer {
        interval: root.musicInterval
        repeat: true
        running: root.active && root.cycleMusic && Media.playing
        onTriggered: {
            if (root.showing !== "notice")
                root.showing = root.showing === "music" ? "clock" : "music";
        }
        onRunningChanged: if (!running && root.showing === "music") root.showing = "clock"
    }

    Timer {
        interval: root.noticeInterval
        repeat: true
        triggeredOnStart: true
        running: root.active && Notifs.unreadCount > 0
        onTriggered: {
            root.showing = "notice";
            noticeHide.restart();
        }
        onRunningChanged: if (!running && root.showing === "notice") root.showing = "clock"
    }

    Timer {
        id: noticeHide
        interval: root.noticeDuration
        onTriggered: if (root.showing === "notice") root.showing = "clock"
    }

    Item {
        anchors.fill: parent
        clip: true

        // The clock leaves upwards, everything else comes in from below
        SlideFace {
            id: clockLabel
            current: root.showing === "clock"
            above: true

            BarText {
                text: Qt.formatDateTime(root.date, "HH:mm")
            }
        }

        SlideFace {
            id: music
            current: root.showing === "music"

            Equalizer {
                anchors.verticalCenter: parent.verticalCenter
                running: Media.playing && music.current
            }

            BarText {
                text: Media.title.length > root.maxLength ? Media.title.slice(0, root.maxLength - 1) + "…" : Media.title
            }
        }

        SlideFace {
            id: notice
            current: root.showing === "notice"

            BarText {
                text: Theme.glyph(0xf0f3)
                color: Theme.accentBright
            }

            BarText {
                text: `${Notifs.unreadCount} new notification${Notifs.unreadCount === 1 ? "" : "s"}`
            }
        }
    }
}
