import QtQuick
import qs.services
import qs.modules

// Round glyph button
Rectangle {
    id: root

    property string glyph
    property bool highlighted: false
    property int size: 32
    signal clicked

    width: size
    height: size
    radius: size / 2
    color: highlighted ? Theme.accent : mouse.containsMouse ? Theme.selected : Theme.surfaceAlt

    Behavior on color {
        ColorAnimation { duration: Theme.animFast }
    }

    BarText {
        anchors.centerIn: parent
        anchors.verticalCenter: undefined
        text: root.glyph
        color: root.highlighted ? Theme.surface : Theme.fgSoft
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
