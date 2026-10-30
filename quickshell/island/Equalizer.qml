import QtQuick
import qs.services

// Three little bouncing bars, shown next to the track title
Row {
    id: root

    property bool running: true
    property color color: Theme.accentBright

    spacing: 2
    height: 12

    Repeater {
        model: [420, 300, 520]

        Rectangle {
            id: bar

            required property int modelData

            anchors.bottom: parent.bottom
            width: 3
            radius: 1.5
            height: 4
            color: root.color

            SequentialAnimation on height {
                running: root.running
                loops: Animation.Infinite
                onRunningChanged: if (!running) bar.height = 4
                NumberAnimation { to: 12; duration: bar.modelData; easing.type: Easing.InOutSine }
                NumberAnimation { to: 3; duration: bar.modelData; easing.type: Easing.InOutSine }
            }
        }
    }
}
