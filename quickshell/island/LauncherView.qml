import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.services
import qs.modules

// App launcher, modelled on the rofi config: "Launch:" prompt, 6 rows,
// regex matching on app names, gruvbox-dark-soft colors
IslandView {
    id: root

    property int lines: 6
    readonly property int rowHeight: 38
    readonly property var results: Launcher.search(input.text)

    implicitWidth: 500
    implicitHeight: 14 + inputBar.height + 10 + list.height + 14

    onActiveChanged: {
        if (active) {
            input.text = "";
            list.currentIndex = 0;
            input.forceActiveFocus();
        }
    }

    Rectangle {
        id: inputBar

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 14
        height: 38
        radius: 19
        color: Theme.surfaceAlt

        Row {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            spacing: 8

            BarText {
                text: `${Theme.glyph(0xf002)}  Launch:`
                color: Theme.accentBright
            }

            TextInput {
                id: input

                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - x
                color: Theme.fgBright
                selectionColor: Theme.selected
                font.family: Theme.font
                font.pixelSize: Theme.fontSize
                font.weight: Font.Bold
                clip: true

                onTextChanged: list.currentIndex = 0

                Keys.onPressed: event => {
                    const ctrl = event.modifiers & Qt.ControlModifier;
                    if (event.key === Qt.Key_Escape) {
                        Launcher.open = false;
                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        if (root.results.length > 0)
                            Launcher.launch(root.results[list.currentIndex]);
                    } else if (event.key === Qt.Key_Down || event.key === Qt.Key_Tab || (ctrl && event.key === Qt.Key_J)) {
                        list.incrementCurrentIndex();
                    } else if (event.key === Qt.Key_Up || event.key === Qt.Key_Backtab || (ctrl && event.key === Qt.Key_K)) {
                        list.decrementCurrentIndex();
                    } else {
                        return;
                    }
                    event.accepted = true;
                }
            }
        }
    }

    ListView {
        id: list

        anchors.top: inputBar.bottom
        anchors.topMargin: 10
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        height: Math.max(1, Math.min(root.lines, count)) * root.rowHeight
        clip: true
        model: root.results
        boundsBehavior: Flickable.StopAtBounds
        highlightMoveDuration: Theme.animFast
        highlightResizeDuration: 0
        keyNavigationWraps: true

        Behavior on height {
            NumberAnimation { duration: Theme.anim; easing.type: Easing.OutCubic }
        }

        highlight: Rectangle {
            radius: 12
            color: Theme.selected
        }

        delegate: Item {
            id: row

            required property var modelData
            required property int index

            width: ListView.view.width
            height: root.rowHeight

            Row {
                anchors.fill: parent
                anchors.leftMargin: 10
                spacing: 10

                IconImage {
                    anchors.verticalCenter: parent.verticalCenter
                    implicitSize: 22
                    source: Quickshell.iconPath(row.modelData.icon, "application-x-executable")
                }

                BarText {
                    text: row.modelData.name
                    color: row.ListView.isCurrentItem ? Theme.fgBright : Theme.fgSoft
                    font.weight: row.ListView.isCurrentItem ? Font.ExtraBold : Font.Bold
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: list.currentIndex = row.index
                onClicked: Launcher.launch(row.modelData)
            }
        }

        BarText {
            anchors.centerIn: parent
            anchors.verticalCenter: undefined
            visible: list.count === 0
            text: "No matches"
            color: Theme.gray
        }
    }
}
