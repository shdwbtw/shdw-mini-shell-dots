import QtQuick
import qs.services

// One face of the compact island; slides in from below (or above)
Row {
    property bool current: false
    property bool above: false

    anchors.horizontalCenter: parent.horizontalCenter
    height: parent.height
    spacing: 8
    y: current ? 0 : above ? -parent.height : parent.height
    opacity: current ? 1 : 0

    Behavior on y {
        NumberAnimation { duration: Theme.anim + 100; easing.type: Easing.OutCubic }
    }
    Behavior on opacity {
        NumberAnimation { duration: Theme.anim }
    }
}
