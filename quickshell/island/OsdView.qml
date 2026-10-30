import QtQuick
import qs.services
import qs.modules

// Island popup for volume / brightness changes: icon, level bar, percent
IslandView {
    id: root

    implicitWidth: 300
    implicitHeight: 40

    Row {
        anchors.centerIn: parent
        spacing: 12

        BarText {
            width: 18
            horizontalAlignment: Text.AlignHCenter
            text: Osd.icon
            color: Osd.muted ? Theme.gray : Theme.accentBright
        }

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 190
            height: 6
            radius: 3
            color: Theme.dim

            Rectangle {
                width: parent.width * Math.max(0, Math.min(1, Osd.muted ? 0 : Osd.value))
                height: parent.height
                radius: 3
                color: Theme.accentBright

                Behavior on width {
                    NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutCubic }
                }
            }
        }

        BarText {
            width: 44
            horizontalAlignment: Text.AlignRight
            text: Osd.muted ? "muted" : `${Math.round(Osd.value * 100)}%`
            font.pixelSize: 12
        }
    }
}
