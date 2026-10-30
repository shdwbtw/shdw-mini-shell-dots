import QtQuick
import Quickshell
import qs.services
import qs.modules

// Reserves the bar's space and holds the workspaces. The clock/media island
// and the right-hand control center live in their own windows on top.
PanelWindow {
    id: root

    required property ShellScreen modelData

    screen: modelData
    color: "transparent"
    implicitHeight: Theme.barHeight

    anchors {
        top: true
        left: true
        right: true
    }
    margins {
        top: 7
        left: 12
        right: 12
    }

    Pill {
        anchors.left: parent.left
        anchors.leftMargin: 6
        anchors.verticalCenter: parent.verticalCenter

        PowerMenu {}

        Workspaces {
            monitor: root.screen.name
            showEmpty: false
        }
    }
}
