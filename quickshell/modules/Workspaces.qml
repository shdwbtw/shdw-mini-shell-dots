import QtQuick
import qs.services

// Mango tags as dots; the active tag is a pill that stretches toward the
// new tag (leading edge moves fast, trailing edge catches up).
// Every tag keeps its own delegate; hidden ones just collapse to zero width,
// so tags appearing/disappearing never rebuild or jump the others.
Item {
    id: root

    required property string monitor
    // false = only show tags that have windows (or are active/urgent)
    property bool showEmpty: true

    readonly property var tags: Mango.tagsFor(monitor)

    readonly property int dot: 7
    readonly property int activeW: 20
    readonly property int gap: 6

    function shown(t) {
        return showEmpty || t.client_count > 0 || t.is_active || t.is_urgent;
    }

    // x/width of every tag (hidden ones get width 0 at their spot)
    readonly property var layout: {
        const slots = [];
        let x = 0;
        let first = -1;
        for (let i = 0; i < tags.length; i++) {
            const t = tags[i];
            const isFirstActive = t.is_active && first < 0;
            if (isFirstActive)
                first = i;
            const visible = shown(t);
            const w = !visible ? 0 : isFirstActive ? activeW : dot;
            slots.push({ x, w, visible });
            if (visible)
                x += w + gap;
        }
        return { slots, active: first, width: Math.max(0, x - gap) };
    }

    property real leftEdge: 0
    property real rightEdge: activeW
    property bool movingRight: true

    implicitWidth: layout.width
    implicitHeight: Theme.barHeight

    readonly property real activeX: layout.active >= 0 ? layout.slots[layout.active].x : -1
    onActiveXChanged: {
        if (activeX < 0)
            return;
        movingRight = activeX > leftEdge;
        leftEdge = activeX;
        rightEdge = activeX + activeW;
    }

    Behavior on implicitWidth {
        NumberAnimation { duration: Theme.anim; easing.type: Easing.OutCubic }
    }
    Behavior on leftEdge {
        NumberAnimation { duration: root.movingRight ? Theme.anim + 80 : Theme.animFast; easing.type: Easing.OutCubic }
    }
    Behavior on rightEdge {
        NumberAnimation { duration: root.movingRight ? Theme.animFast : Theme.anim + 80; easing.type: Easing.OutCubic }
    }

    Repeater {
        model: root.tags.length

        Item {
            id: slot

            required property int index
            readonly property var tag: root.tags[index]
            readonly property var place: root.layout.slots[index] ?? { x: 0, w: 0, visible: false }
            readonly property bool active: index === root.layout.active
            readonly property bool alsoActive: !active && (tag?.is_active ?? false)
            readonly property bool urgent: tag?.is_urgent ?? false
            readonly property bool occupied: (tag?.client_count ?? 0) > 0

            x: place.x
            width: place.w
            height: parent.height
            opacity: place.visible ? 1 : 0
            visible: opacity > 0

            Behavior on x {
                NumberAnimation { duration: Theme.anim; easing.type: Easing.OutCubic }
            }
            Behavior on width {
                NumberAnimation { duration: Theme.anim; easing.type: Easing.OutCubic }
            }
            Behavior on opacity {
                NumberAnimation { duration: Theme.anim; easing.type: Easing.OutCubic }
            }

            Rectangle {
                id: dotRect
                anchors.centerIn: parent
                width: parent.width
                height: Math.min(root.dot, parent.width)
                radius: height / 2
                scale: mouse.containsMouse && !slot.active ? 1.35 : 1
                color: slot.urgent ? Theme.urgent
                     : slot.active || slot.alsoActive ? Theme.border
                     : mouse.containsMouse ? Theme.hover
                     : slot.occupied ? Theme.occupied
                     : Theme.empty

                Behavior on color {
                    ColorAnimation { duration: Theme.anim }
                }
                Behavior on scale {
                    NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutCubic }
                }

                SequentialAnimation on opacity {
                    running: slot.urgent
                    loops: Animation.Infinite
                    onRunningChanged: if (!running) dotRect.opacity = 1
                    NumberAnimation { to: 0.35; duration: 600; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 1; duration: 600; easing.type: Easing.InOutSine }
                }
            }

            MouseArea {
                id: mouse
                anchors.fill: parent
                anchors.leftMargin: -root.gap / 2
                anchors.rightMargin: -root.gap / 2
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Mango.view(slot.tag.index)
            }
        }
    }

    // Active indicator, drawn above the dots so it "swallows" them as it slides
    Rectangle {
        visible: root.layout.active >= 0
        x: root.leftEdge
        width: root.rightEdge - root.leftEdge
        height: root.dot
        anchors.verticalCenter: parent.verticalCenter
        radius: height / 2
        color: root.tags[root.layout.active]?.is_urgent ? Theme.urgent : Theme.border
    }
}
