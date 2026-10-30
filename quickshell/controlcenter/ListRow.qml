import QtQuick
import qs.services
import qs.modules

// One entry in the Wi-Fi / Bluetooth lists
Rectangle {
    id: root

    property string glyph
    property string text
    property string detail
    property bool current: false
    property bool busy: false
    property real strength: 1
    signal clicked

    width: ListView.view?.width ?? parent.width
    height: 36
    radius: 12
    color: mouse.containsMouse ? Theme.surfaceAlt : "transparent"

    Behavior on color {
        ColorAnimation { duration: Theme.animFast }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }

    BarText {
        id: icon
        anchors.left: parent.left
        anchors.leftMargin: 10
        width: 18
        text: root.glyph
        color: root.current ? Theme.accentBright : Theme.fgSoft
        opacity: 0.4 + 0.6 * root.strength
    }

    BarText {
        anchors.left: icon.right
        anchors.leftMargin: 8
        anchors.right: detailText.left
        anchors.rightMargin: 8
        text: root.text
        elide: Text.ElideRight
        font.weight: root.current ? Font.ExtraBold : Font.Bold
        color: root.current ? Theme.fgBright : Theme.fgSoft
    }

    BarText {
        id: detailText
        anchors.right: parent.right
        anchors.rightMargin: 10
        text: root.busy ? Theme.glyph(0xf110) : root.detail
        font.pixelSize: 11
        color: root.current ? Theme.accentBright : Theme.gray

        RotationAnimation on rotation {
            running: root.busy
            loops: Animation.Infinite
            from: 0
            to: 360
            duration: 1000
            onRunningChanged: if (!running) detailText.rotation = 0
        }
    }
}
