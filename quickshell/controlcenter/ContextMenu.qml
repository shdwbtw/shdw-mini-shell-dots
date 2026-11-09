import QtQuick
import qs.services
import qs.modules

// Right-click menu drawn inside the panel. Fill the parent with it; it
// catches clicks outside the menu to close itself.
// items: [{ text, glyph, action, danger?, confirm?, enabled?, checked? }]
//   confirm: needs a second click (the entry asks "Click again to …")
//   checked: shows a check mark (true) or an empty box (false) on the right
Item {
    id: root

    property var items: []
    property string title
    readonly property bool opened: visible

    // Entry waiting for its confirming second click
    property int armed: -1

    anchors.fill: parent
    visible: false
    z: 100

    function show(x, y) {
        armed = -1;
        visible = true;
        menu.opacity = 0;
        menu.scale = 0.94;
        // keep it inside the panel; flip above the cursor if there's no room below
        const below = y + 4;
        const above = y - menu.implicitHeight - 4;
        menu.x = Math.max(8, Math.min(x, width - menu.width - 8));
        menu.y = below + menu.implicitHeight <= height - 8 ? below : Math.max(8, above);
        intro.restart();
    }

    function close() {
        visible = false;
        armed = -1;
    }

    Keys.onEscapePressed: close()

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        onPressed: root.close()
        onWheel: root.close()
    }

    ParallelAnimation {
        id: intro
        NumberAnimation { target: menu; property: "opacity"; to: 1; duration: Theme.animFast; easing.type: Easing.OutCubic }
        NumberAnimation { target: menu; property: "scale"; to: 1; duration: Theme.animFast; easing.type: Easing.OutCubic }
    }

    Rectangle {
        id: menu

        width: 220
        implicitHeight: column.implicitHeight + 12
        height: implicitHeight
        radius: 14
        color: Theme.surface
        border.width: 1
        border.color: Theme.dim
        transformOrigin: Item.TopLeft

        // swallow clicks on the menu's padding
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
        }

        Column {
            id: column

            x: 6
            y: 6
            width: parent.width - 12

            BarText {
                visible: root.title !== ""
                anchors.verticalCenter: undefined
                width: parent.width
                height: 26
                leftPadding: 10
                verticalAlignment: Text.AlignVCenter
                text: root.title
                elide: Text.ElideRight
                font.pixelSize: 11
                font.weight: Font.Bold
                color: Theme.gray
            }

            Repeater {
                model: root.items

                Rectangle {
                    id: entry

                    required property var modelData
                    required property int index
                    readonly property bool isEnabled: modelData.enabled ?? true
                    readonly property bool isArmed: root.armed === index
                    readonly property color tint: modelData.danger ? Theme.red : Theme.fgSoft

                    width: column.width
                    height: 32
                    radius: 10
                    opacity: isEnabled ? 1 : 0.4
                    color: isArmed ? Qt.alpha(Theme.red, 0.18)
                         : entryMouse.containsMouse && isEnabled ? Theme.surfaceAlt
                         : "transparent"

                    Behavior on color {
                        ColorAnimation { duration: Theme.animFast }
                    }

                    BarText {
                        id: entryGlyph
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        width: 18
                        text: entry.modelData.glyph ?? ""
                        color: entry.tint
                    }

                    BarText {
                        anchors.left: entryGlyph.right
                        anchors.leftMargin: 8
                        anchors.right: check.left
                        anchors.rightMargin: 6
                        text: entry.isArmed ? `Click again to ${entry.modelData.text.toLowerCase()}` : entry.modelData.text
                        elide: Text.ElideRight
                        font.pixelSize: 12
                        color: entry.tint
                    }

                    BarText {
                        id: check
                        anchors.right: parent.right
                        anchors.rightMargin: 10
                        visible: entry.modelData.checked !== undefined
                        width: visible ? implicitWidth : 0
                        text: entry.modelData.checked ? Theme.glyph(0xf14a) : Theme.glyph(0xf0c8)
                        color: entry.modelData.checked ? Theme.accentBright : Theme.gray
                    }

                    MouseArea {
                        id: entryMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: entry.isEnabled
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (entry.modelData.confirm && !entry.isArmed) {
                                root.armed = entry.index;
                                return;
                            }
                            const action = entry.modelData.action;
                            root.close();
                            action?.();
                        }
                    }
                }
            }
        }
    }
}
