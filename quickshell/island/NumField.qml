import QtQuick
import qs.services

// Small number box; empty means "no value". Reports on Enter / focus out.
Rectangle {
    id: root

    property var value: null
    property string placeholder: "–"
    signal committed(string text)

    width: 44
    height: 26
    radius: 8
    color: input.activeFocus ? Theme.selected : Theme.surfaceAlt
    border.width: input.activeFocus ? 1 : 0
    border.color: Theme.accentBright

    TextInput {
        id: input

        anchors.fill: parent
        anchors.leftMargin: 6
        anchors.rightMargin: 6
        horizontalAlignment: TextInput.AlignHCenter
        verticalAlignment: TextInput.AlignVCenter
        text: root.value ?? ""
        validator: IntValidator { bottom: 1; top: 999 }
        color: Theme.fgBright
        selectByMouse: true
        font.family: Theme.font
        font.pixelSize: 12
        font.weight: Font.Bold
        clip: true

        onEditingFinished: {
            if (text !== String(root.value ?? ""))
                root.committed(text);
        }

        Text {
            anchors.centerIn: parent
            visible: input.text === "" && !input.activeFocus
            text: root.placeholder
            color: Theme.gray
            font: input.font
        }
    }
}
