pragma Singleton
import QtQuick
import Quickshell

// Volume / brightness popup shown in the island for a moment after either
// changes (keys, scroll, sliders...)
Singleton {
    id: root

    property int duration: 1500

    property bool visible: false
    // "volume" or "brightness"
    property string kind: "volume"

    readonly property real value: kind === "volume" ? Audio.volume : Brightness.percent / 100
    readonly property bool muted: kind === "volume" && Audio.muted
    readonly property string icon: kind === "volume" ? Audio.icon : Brightness.icon

    // Values settling at startup or when the output device changes aren't
    // user changes
    property bool armed: false

    function show(k) {
        if (!armed)
            return;
        kind = k;
        visible = true;
        hideTimer.restart();
    }

    function settle() {
        armed = false;
        armTimer.restart();
    }

    Component.onCompleted: settle()

    Timer {
        id: armTimer
        interval: 1500
        onTriggered: root.armed = true
    }

    Timer {
        id: hideTimer
        interval: root.duration
        onTriggered: root.visible = false
    }

    Connections {
        target: Audio
        function onVolumeChanged() {
            root.show("volume");
        }
        function onMutedChanged() {
            root.show("volume");
        }
        function onSinkChanged() {
            root.settle();
        }
    }

    Connections {
        target: Brightness
        function onPercentChanged() {
            if (!Brightness.quiet)
                root.show("brightness");
        }
    }
}
