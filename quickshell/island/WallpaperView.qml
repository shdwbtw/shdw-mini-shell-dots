import QtQuick
import Quickshell.Widgets
import qs.services
import qs.modules

// Wallpaper picker: a strip of thumbnails from Wallpaper.dir. Arrow keys or
// the mouse to browse, Enter/click to apply (awww + matugen), Esc to close.
IslandView {
    id: root

    readonly property int thumbW: 208
    readonly property int thumbH: 117
    readonly property int visibleCount: 3

    implicitWidth: list.width + 36
    implicitHeight: 18 + header.height + 12 + list.height + 12 + nameLabel.height + 16

    onActiveChanged: {
        if (active) {
            list.currentIndex = Math.max(0, Wallpaper.wallpapers.indexOf(Wallpaper.current));
            list.positionViewAtIndex(list.currentIndex, ListView.Center);
            list.forceActiveFocus();
        }
    }

    function apply(index) {
        list.currentIndex = index;
        Wallpaper.set(Wallpaper.wallpapers[index]);
    }

    Item {
        id: header

        x: 18
        y: 18
        width: list.width
        height: 20

        BarText {
            text: `${Theme.glyph(0xf03e)}  Wallpapers`
            color: Theme.fgSoft
        }

        BarText {
            anchors.right: parent.right
            text: Wallpaper.generating ? "Generating colors…" : `${list.currentIndex + 1} / ${list.count}`
            font.pixelSize: 11
            font.weight: Font.Bold
            color: Theme.gray
        }
    }

    ListView {
        id: list

        x: 18
        y: header.y + header.height + 12
        width: root.thumbW * root.visibleCount + spacing * (root.visibleCount - 1)
        height: root.thumbH + 16
        orientation: ListView.Horizontal
        spacing: 12
        clip: true
        model: Wallpaper.wallpapers
        highlightRangeMode: ListView.ApplyRange
        preferredHighlightBegin: (width - root.thumbW) / 2
        preferredHighlightEnd: (width + root.thumbW) / 2
        highlightMoveDuration: Theme.anim
        boundsBehavior: Flickable.StopAtBounds

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape)
                Wallpaper.pickerOpen = false;
            else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
                root.apply(currentIndex);
            else if (event.key === Qt.Key_Left || event.key === Qt.Key_H)
                decrementCurrentIndex();
            else if (event.key === Qt.Key_Right || event.key === Qt.Key_L)
                incrementCurrentIndex();
            else
                return;
            event.accepted = true;
        }

        delegate: Item {
            id: thumb

            required property string modelData
            required property int index
            readonly property bool selected: ListView.isCurrentItem
            readonly property bool applied: modelData === Wallpaper.current

            width: root.thumbW
            height: ListView.view.height

            ClippingRectangle {
                anchors.centerIn: parent
                width: root.thumbW
                height: root.thumbH
                radius: 14
                color: Theme.surfaceAlt
                scale: thumb.selected ? 1 : mouse.containsMouse ? 0.96 : 0.92
                opacity: thumb.selected || mouse.containsMouse ? 1 : 0.6

                Behavior on scale {
                    NumberAnimation { duration: Theme.anim; easing.type: Easing.OutCubic }
                }
                Behavior on opacity {
                    NumberAnimation { duration: Theme.anim; easing.type: Easing.OutCubic }
                }

                Image {
                    anchors.fill: parent
                    source: "file://" + thumb.modelData
                    sourceSize.width: root.thumbW * 2
                    sourceSize.height: root.thumbH * 2
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: true
                }

                // selection ring
                Rectangle {
                    anchors.fill: parent
                    radius: 14
                    color: "transparent"
                    border.width: thumb.selected ? 2 : 0
                    border.color: Theme.accentBright
                }

                // marks the wallpaper in use
                Rectangle {
                    visible: thumb.applied
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 8
                    width: 22
                    height: 22
                    radius: 11
                    color: Theme.accent

                    BarText {
                        anchors.centerIn: parent
                        anchors.verticalCenter: undefined
                        text: Theme.glyph(0xf00c)
                        font.pixelSize: 11
                        color: Theme.surface
                    }
                }
            }

            MouseArea {
                id: mouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.apply(thumb.index)
            }
        }
    }

    BarText {
        id: nameLabel

        anchors.verticalCenter: undefined
        anchors.horizontalCenter: parent.horizontalCenter
        y: list.y + list.height + 12
        width: list.width
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideMiddle
        text: list.count > 0 ? (Wallpaper.wallpapers[list.currentIndex] ?? "").split("/").pop() : `No images in ${Wallpaper.dir}`
        font.pixelSize: 12
        font.weight: Font.Bold
        color: Theme.gray
    }
}
