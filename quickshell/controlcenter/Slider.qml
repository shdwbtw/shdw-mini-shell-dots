import QtQuick
import qs.services

// Horizontal 0..1 slider. `value` is the source of truth; `moved` reports
// drags/clicks/scrolls and the owner writes the new value back.
Item {
    id: root

    property real value: 0
    property real wheelStep: 0.05
    signal moved(real value)

    readonly property real knob: 16
    // Follows `value` smoothly, but tracks the cursor 1:1 while dragging
    property real shown: value
    Behavior on shown {
        enabled: !mouse.pressed
        NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutCubic }
    }

    implicitHeight: 22

    function valueAt(x) {
        return Math.max(0, Math.min(1, (x - knob / 2) / (width - knob)));
    }

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 6
        radius: 3
        color: Theme.dim

        Rectangle {
            width: root.knob / 2 + root.shown * (root.width - root.knob)
            height: parent.height
            radius: 3
            color: Theme.accentBright
        }
    }

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        x: root.shown * (root.width - root.knob)
        width: root.knob
        height: root.knob
        radius: root.knob / 2
        color: Theme.fgBright
        scale: mouse.pressed ? 1.2 : mouse.containsMouse ? 1.1 : 1

        Behavior on scale {
            NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutCubic }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        preventStealing: true
        onPressed: mouse => root.moved(root.valueAt(mouse.x))
        onPositionChanged: mouse => {
            if (pressed)
                root.moved(root.valueAt(mouse.x));
        }
        onWheel: wheel => root.moved(Math.max(0, Math.min(1, root.value + (wheel.angleDelta.y > 0 ? 1 : -1) * root.wheelStep)))
    }
}
