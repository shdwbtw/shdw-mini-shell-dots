import QtQuick
import qs.services

// Base for the island's states: cross-fades in/out and reports its size
// through implicitWidth/implicitHeight so the island can morph to it
Item {
    id: root

    property bool active: false

    anchors.top: parent.top
    anchors.horizontalCenter: parent.horizontalCenter
    width: implicitWidth
    height: implicitHeight

    opacity: active ? 1 : 0
    scale: active ? 1 : 0.94
    visible: opacity > 0
    enabled: active

    Behavior on opacity {
        NumberAnimation { duration: root.active ? Theme.anim : Theme.animFast; easing.type: Easing.OutCubic }
    }
    Behavior on scale {
        NumberAnimation { duration: Theme.anim; easing.type: Easing.OutCubic }
    }
}
