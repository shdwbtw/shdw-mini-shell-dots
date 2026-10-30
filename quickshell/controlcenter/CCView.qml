import QtQuick
import qs.services

// Base for the control center's states: pinned to the top-right corner,
// cross-fades in/out and reports its size so the container can morph to it
Item {
    id: root

    property bool active: false

    anchors.top: parent.top
    anchors.right: parent.right
    width: implicitWidth
    height: implicitHeight

    opacity: active ? 1 : 0
    visible: opacity > 0
    enabled: active

    Behavior on opacity {
        NumberAnimation { duration: root.active ? Theme.anim : Theme.animFast; easing.type: Easing.OutCubic }
    }
}
