import QtQuick
import qs.services
import qs.modules

// Wi-Fi / Bluetooth tile: the round icon toggles power, the rest of the
// tile opens the device list underneath
Rectangle {
    id: root

    property string glyph
    property string title
    property string subtitle
    property bool on: false
    property bool expanded: false
    signal toggled
    signal expandToggled

    height: 52
    radius: 16
    color: expanded ? Theme.selected : mouse.containsMouse ? Qt.lighter(Theme.surfaceAlt, 1.15) : Theme.surfaceAlt

    Behavior on color {
        ColorAnimation { duration: Theme.animFast }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.expandToggled()
    }

    IconButton {
        id: power
        anchors.left: parent.left
        anchors.leftMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        glyph: root.glyph
        highlighted: root.on
        onClicked: root.toggled()
    }

    Column {
        anchors.left: power.right
        anchors.leftMargin: 10
        anchors.right: chevron.left
        anchors.rightMargin: 6
        anchors.verticalCenter: parent.verticalCenter

        BarText {
            anchors.verticalCenter: undefined
            width: parent.width
            text: root.title
            elide: Text.ElideRight
            color: Theme.fgBright
        }
        BarText {
            anchors.verticalCenter: undefined
            width: parent.width
            text: root.subtitle
            elide: Text.ElideRight
            font.pixelSize: 11
            font.weight: Font.Bold
            color: Theme.gray
        }
    }

    BarText {
        id: chevron
        anchors.right: parent.right
        anchors.rightMargin: 12
        text: Theme.glyph(0xf078)
        font.pixelSize: 10
        color: Theme.gray
        rotation: root.expanded ? 180 : 0

        Behavior on rotation {
            NumberAnimation { duration: Theme.anim; easing.type: Easing.OutCubic }
        }
    }
}
