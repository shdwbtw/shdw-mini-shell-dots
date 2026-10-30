pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

// Notification daemon. New notifications pop up one at a time in the island;
// ones that time out (instead of being dismissed) stay in `history` until
// dismissed or cleared from the island's notifications tab.
Singleton {
    id: root

    property int defaultTimeout: 5000
    property var queue: []
    readonly property Notification current: queue.length > 0 ? queue[0] : null

    // Newest first
    readonly property var history: [...server.trackedNotifications.values].reverse()
    // Arrived since the notifications tab was last opened
    property var unread: []
    readonly property int unreadCount: unread.length
    // notification id -> arrival time
    property var times: ({})

    // Set by the island while hovered, so a popup doesn't vanish mid-read
    property bool paused: false

    function remove(n) {
        queue = queue.filter(q => q !== n);
    }

    function dismiss(n) {
        remove(n);
        n?.dismiss();
    }

    function clearAll() {
        queue = [];
        for (const n of history)
            n.dismiss();
    }

    function markRead() {
        if (unread.length > 0)
            unread = [];
    }

    function timeAgo(n, now) {
        const t = times[n.id];
        if (!t)
            return "";
        const mins = Math.floor((now - t) / 60000);
        if (mins < 1)
            return "now";
        if (mins < 60)
            return `${mins}m ago`;
        const hours = Math.floor(mins / 60);
        return hours < 24 ? `${hours}h ago` : `${Math.floor(hours / 24)}d ago`;
    }

    onCurrentChanged: expireTimer.restart()

    NotificationServer {
        id: server

        keepOnReload: true
        actionsSupported: true
        imageSupported: true
        bodySupported: true
        bodyMarkupSupported: true

        onNotification: n => {
            n.tracked = true;
            root.times = Object.assign({}, root.times, { [n.id]: Date.now() });
            n.closed.connect(() => {
                root.remove(n);
                root.unread = root.unread.filter(u => u !== n);
            });
            // Kept across a config reload: back into the history, no popup
            if (n.lastGeneration)
                return;
            // Replacements (same id) update in place; new ones go to the back
            if (!root.queue.includes(n))
                root.queue = [...root.queue, n];
            if (!root.unread.includes(n))
                root.unread = [...root.unread, n];
        }
    }

    Timer {
        id: expireTimer

        readonly property int timeout: {
            const n = root.current;
            if (!n || n.urgency === NotificationUrgency.Critical)
                return 0;
            return n.expireTimeout > 0 ? n.expireTimeout * 1000 : root.defaultTimeout;
        }

        interval: Math.max(1, timeout)
        running: timeout > 0 && !root.paused
        // Only hide the popup; the notification stays in the history
        onTriggered: root.remove(root.current)
    }
}
