import QtQuick
import qs.services

// tty-clock / peaclock style time: each digit is a 3x5 grid of blocks
Row {
    id: root

    property string time: "00:00"
    property int cell: 26
    property int gap: 0
    property color color: Theme.fgSoft
    // faint unlit blocks, like peaclock's inactive cells
    property color offColor: Qt.rgba(1, 1, 1, 0)

    readonly property var glyphs: ({
        "0": "111101101101111",
        "1": "001001001001001",
        "2": "111001111100111",
        "3": "111001111001111",
        "4": "101101111001001",
        "5": "111100111001111",
        "6": "111100111101111",
        "7": "111001001001001",
        "8": "111101111101111",
        "9": "111101111001111",
        ":": "000000000000000"
    })

    spacing: cell

    Repeater {
        model: root.time.length

        Grid {
            id: digit

            required property int index
            readonly property string pattern: root.glyphs[root.time[index]] ?? "000000000000000"
            readonly property bool colon: root.time[index] === ":"

            columns: 3
            spacing: root.gap

            Repeater {
                model: 15

                Rectangle {
                    required property int index
                    readonly property bool lit: digit.pattern[index] === "1"

                    // the colon only uses its middle column
                    visible: !digit.colon || index % 3 === 1
                    width: root.cell
                    height: root.cell
                    radius: 0
                    color: lit ? root.color : digit.colon ? "transparent" : root.offColor

                    Behavior on color {
                        ColorAnimation { duration: Theme.anim; easing.type: Easing.OutCubic }
                    }
                }
            }
        }
    }
}
