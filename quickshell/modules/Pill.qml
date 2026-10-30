import QtQuick
import qs.services

// Rounded bordered container, like `.modules-left` / `.modules-right` / `#mpris`.
// Content is pinned to the left so it stays still while the pill resizes;
// children animate their own size changes.
Rectangle {
    id: root

    default property alias content: row.data
    property alias spacing: row.spacing

    implicitWidth: row.implicitWidth + Theme.pillPadding * 2
    implicitHeight: Theme.barHeight
    color: Theme.bg
    border.color: Theme.border
    border.width: 1
    radius: height / 2
    clip: true

    Row {
        id: row
        anchors.left: parent.left
        anchors.leftMargin: Theme.pillPadding
        height: parent.height
        spacing: Theme.moduleSpacing
    }
}
