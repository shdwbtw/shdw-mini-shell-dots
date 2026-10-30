import QtQuick
import qs.services

Text {
    color: Theme.fg
    font.family: Theme.font
    font.pixelSize: Theme.fontSize
    font.weight: Font.ExtraBold
    verticalAlignment: Text.AlignVCenter
    anchors.verticalCenter: parent?.verticalCenter

    Behavior on color {
        ColorAnimation { duration: Theme.anim }
    }
}
