import QtQuick
import qs.services
import qs.modules

// Month grid, Sunday first. Scroll to move between months.
Column {
    id: root

    property date today
    property int offset: 0

    readonly property int cell: 28
    readonly property date month: new Date(today.getFullYear(), today.getMonth() + offset, 1)
    // index of the 1st in a Sunday-first week
    readonly property int lead: month.getDay()
    readonly property int daysInMonth: new Date(month.getFullYear(), month.getMonth() + 1, 0).getDate()

    spacing: 4

    BarText {
        anchors.verticalCenter: undefined
        anchors.horizontalCenter: parent.horizontalCenter
        text: Qt.formatDateTime(root.month, "MMMM yyyy")
        color: Theme.fgSoft
    }

    Row {
        Repeater {
            model: ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]

            BarText {
                required property string modelData
                anchors.verticalCenter: undefined
                width: root.cell
                horizontalAlignment: Text.AlignHCenter
                text: modelData
                font.pixelSize: 11
                color: Theme.gray
            }
        }
    }

    Grid {
        id: grid
        columns: 7

        Repeater {
            model: 42

            Item {
                id: day

                required property int index
                readonly property date value: new Date(root.month.getFullYear(), root.month.getMonth(), index - root.lead + 1)
                readonly property bool inMonth: index >= root.lead && index < root.lead + root.daysInMonth
                readonly property bool isToday: value.toDateString() === root.today.toDateString()

                width: root.cell
                height: root.cell - 4
                visible: index < 35 || root.lead + root.daysInMonth > 35

                Rectangle {
                    anchors.centerIn: parent
                    width: root.cell - 4
                    height: width - 4
                    radius: height / 2
                    color: Theme.accent
                    scale: day.isToday ? 1 : 0
                    Behavior on scale {
                        NumberAnimation { duration: Theme.anim; easing.type: Easing.OutCubic }
                    }
                }

                BarText {
                    anchors.centerIn: parent
                    anchors.verticalCenter: undefined
                    text: day.value.getDate()
                    font.pixelSize: 12
                    font.weight: day.isToday ? Font.ExtraBold : Font.Bold
                    color: day.isToday ? Theme.surface : day.inMonth ? Theme.fgSoft : Theme.selected
                }
            }
        }
    }

    WheelHandler {
        onWheel: event => root.offset += event.angleDelta.y > 0 ? -1 : 1
    }
}
