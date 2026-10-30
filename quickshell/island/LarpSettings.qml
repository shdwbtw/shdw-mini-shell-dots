import QtQuick
import qs.services
import qs.modules

// Larp tab settings: the programs larp opens and their window size limits
// in terminal cells (cols × rows; empty = no limit). Changes save on Enter
// or when a field loses focus.
Column {
    id: root

    signal back

    spacing: 10

    Item {
        width: parent.width
        height: 28

        Rectangle {
            id: backButton

            width: 28
            height: 28
            radius: 14
            color: backMouse.containsMouse ? Theme.selected : Theme.surfaceAlt

            BarText {
                anchors.centerIn: parent
                anchors.verticalCenter: undefined
                text: Theme.glyph(0xf053)
                font.pixelSize: 11
                color: Theme.fgSoft
            }

            MouseArea {
                id: backMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.back()
            }
        }

        BarText {
            anchors.left: backButton.right
            anchors.leftMargin: 10
            text: `Larp programs · ${Larp.programs.length}`
            color: Theme.fgSoft
        }
    }

    ListView {
        id: list

        width: parent.width
        height: Math.min(contentHeight, 300)
        spacing: 8
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        model: Larp.programs

        delegate: Rectangle {
            id: card

            required property var modelData
            required property int index

            width: ListView.view.width
            height: cardContent.implicitHeight + 20
            radius: 12
            color: Theme.surface

            Column {
                id: cardContent

                x: 10
                y: 10
                width: parent.width - 20
                spacing: 8

                Row {
                    width: parent.width
                    spacing: 8

                    // command
                    Rectangle {
                        width: parent.width - remove.width - parent.spacing
                        height: 28
                        radius: 8
                        color: command.activeFocus ? Theme.selected : Theme.surfaceAlt
                        border.width: command.activeFocus ? 1 : 0
                        border.color: Theme.accentBright

                        TextInput {
                            id: command

                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            verticalAlignment: TextInput.AlignVCenter
                            text: card.modelData.command
                            color: Theme.fgBright
                            selectByMouse: true
                            font.family: Theme.font
                            font.pixelSize: 12
                            font.weight: Font.Bold
                            clip: true

                            onEditingFinished: {
                                if (text !== card.modelData.command)
                                    Larp.update(card.index, { command: text });
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: command.text === "" && !command.activeFocus
                                text: "command, e.g. cmatrix -b"
                                color: Theme.gray
                                font: command.font
                            }
                        }
                    }

                    Rectangle {
                        id: remove

                        width: 28
                        height: 28
                        radius: 14
                        color: removeMouse.containsMouse ? Theme.urgent : Theme.surfaceAlt

                        Behavior on color {
                            ColorAnimation { duration: Theme.animFast }
                        }

                        BarText {
                            anchors.centerIn: parent
                            anchors.verticalCenter: undefined
                            text: Theme.glyph(0xf1f8)
                            font.pixelSize: 11
                            color: removeMouse.containsMouse ? Theme.urgentFg : Theme.fgSoft
                        }

                        MouseArea {
                            id: removeMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Larp.remove(card.index)
                        }
                    }
                }

                // window size limits
                Row {
                    spacing: 6

                    BarText {
                        width: 30
                        text: "min"
                        font.pixelSize: 11
                        color: Theme.gray
                    }
                    NumField {
                        value: card.modelData.min?.[0] ?? null
                        placeholder: "cols"
                        onCommitted: text => Larp.setSize(card.index, "min", 0, text)
                    }
                    BarText {
                        text: "×"
                        color: Theme.gray
                    }
                    NumField {
                        value: card.modelData.min?.[1] ?? null
                        placeholder: "rows"
                        onCommitted: text => Larp.setSize(card.index, "min", 1, text)
                    }

                    Item { width: 10; height: 1 }

                    BarText {
                        width: 30
                        text: "max"
                        font.pixelSize: 11
                        color: Theme.gray
                    }
                    NumField {
                        value: card.modelData.max?.[0] ?? null
                        placeholder: "cols"
                        onCommitted: text => Larp.setSize(card.index, "max", 0, text)
                    }
                    BarText {
                        text: "×"
                        color: Theme.gray
                    }
                    NumField {
                        value: card.modelData.max?.[1] ?? null
                        placeholder: "rows"
                        onCommitted: text => Larp.setSize(card.index, "max", 1, text)
                    }
                }
            }
        }
    }

    Item {
        width: parent.width
        height: 30

        Rectangle {
            id: addButton

            width: addLabel.implicitWidth + 28
            height: 30
            radius: 15
            color: addMouse.containsMouse ? Theme.accentBright : Theme.accent

            BarText {
                id: addLabel
                anchors.centerIn: parent
                anchors.verticalCenter: undefined
                text: `${Theme.glyph(0xf067)}  Add program`
                font.pixelSize: 12
                color: Theme.surface
            }

            MouseArea {
                id: addMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    Larp.add();
                    list.positionViewAtEnd();
                }
            }
        }

        BarText {
            anchors.left: addButton.right
            anchors.leftMargin: 12
            anchors.right: parent.right
            text: "{track} = random song from ~/Music/larp"
            elide: Text.ElideRight
            font.pixelSize: 10
            font.weight: Font.Bold
            color: Theme.gray
        }
    }
}
