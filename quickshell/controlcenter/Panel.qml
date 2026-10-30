import QtQuick
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Services.SystemTray
import Quickshell.Services.UPower
import Quickshell.Widgets
import qs.services
import qs.modules

// Expanded control center: tray icons down the left, then volume/brightness
// sliders, battery + power profiles, and Wi-Fi/Bluetooth tiles with lists
CCView {
    id: root

    property var window
    signal closeRequested

    // "", "wifi" or "bt": which list is open under the tiles
    property string section: ""
    // Wi-Fi network waiting for a password
    property var pskNetwork: null
    // audio device lists expanded under the sliders
    property bool audioDevicesOpen: false
    property bool mixerOpen: false

    implicitWidth: 460
    implicitHeight: body.implicitHeight + 32

    onActiveChanged: {
        if (active) {
            forceActiveFocus();
        } else {
            section = "";
            audioDevicesOpen = false;
            mixerOpen = false;
        }
    }
    onSectionChanged: {
        pskNetwork = null;
        Net.setScanning(section === "wifi");
        Net.setDiscovering(section === "bt");
    }
    onPskNetworkChanged: if (pskNetwork) pskInput.forceActiveFocus()

    Keys.onEscapePressed: root.closeRequested()

    Row {
        id: body

        x: 16
        y: 16
        spacing: 14

        // System tray, stacked vertically
        Rectangle {
            id: trayColumn

            visible: SystemTray.items.values.length > 0
            width: 40
            height: main.height
            radius: 20
            color: Theme.surface

            Column {
                anchors.horizontalCenter: parent.horizontalCenter
                y: 12
                spacing: 12

                Repeater {
                    model: SystemTray.items

                    MouseArea {
                        id: trayItem

                        required property SystemTrayItem modelData

                        width: 24
                        height: 24
                        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        onClicked: mouse => {
                            if (mouse.button === Qt.LeftButton && !modelData.onlyMenu) {
                                modelData.activate();
                            } else if (mouse.button === Qt.MiddleButton) {
                                modelData.secondaryActivate();
                            } else if (modelData.hasMenu) {
                                const p = mapToItem(null, width + 6, 0);
                                modelData.display(root.window, p.x, p.y);
                            }
                        }
                        onWheel: wheel => modelData.scroll(wheel.angleDelta.y / 120, false)

                        IconImage {
                            anchors.centerIn: parent
                            implicitSize: 18
                            source: trayItem.modelData.icon
                            scale: trayItem.containsMouse ? 1.15 : 1

                            Behavior on scale {
                                NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutCubic }
                            }
                        }
                    }
                }
            }
        }

        Column {
            id: main

            width: root.implicitWidth - 32 - (trayColumn.visible ? trayColumn.width + body.spacing : 0)
            spacing: 14

            SliderRow {
                glyph: Audio.icon
                value: Audio.volume
                label: Audio.muted ? "muted" : `${Audio.percent}%`
                dimmed: Audio.muted
                onIconClicked: Audio.toggleMute()
                onMoved: v => Audio.setVolume(v)
            }

            SliderRow {
                visible: Brightness.available
                glyph: Brightness.icon
                value: Brightness.percent / 100
                label: `${Brightness.percent}%`
                onMoved: v => Brightness.set(v * 100)
            }

            // Output / input device picker
            Rectangle {
                width: main.width
                height: 36
                radius: 12
                color: root.audioDevicesOpen ? Theme.selected : devicesMouse.containsMouse ? Theme.surfaceAlt : Theme.surface

                Behavior on color {
                    ColorAnimation { duration: Theme.animFast }
                }

                BarText {
                    id: devicesIcon
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    text: Audio.icon
                    color: Theme.accentBright
                }

                BarText {
                    anchors.left: devicesIcon.right
                    anchors.leftMargin: 10
                    anchors.right: devicesChevron.left
                    anchors.rightMargin: 8
                    text: Audio.nodeName(Audio.sink) || "No output"
                    elide: Text.ElideRight
                    font.pixelSize: 12
                    color: Theme.fgSoft
                }

                BarText {
                    id: devicesChevron
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    text: Theme.glyph(0xf078)
                    font.pixelSize: 10
                    color: Theme.gray
                    rotation: root.audioDevicesOpen ? 180 : 0

                    Behavior on rotation {
                        NumberAnimation { duration: Theme.anim; easing.type: Easing.OutCubic }
                    }
                }

                MouseArea {
                    id: devicesMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.audioDevicesOpen = !root.audioDevicesOpen
                }
            }

            Item {
                width: main.width
                height: root.audioDevicesOpen ? devicesPane.implicitHeight : 0
                visible: height > 0
                clip: true

                Behavior on height {
                    NumberAnimation { duration: Theme.anim; easing.type: Easing.OutCubic }
                }

                Column {
                    id: devicesPane

                    width: parent.width
                    spacing: 2

                    BarText {
                        anchors.verticalCenter: undefined
                        leftPadding: 10
                        topPadding: 6
                        bottomPadding: 2
                        text: "Output"
                        font.pixelSize: 11
                        color: Theme.gray
                    }

                    Repeater {
                        model: Audio.sinks

                        ListRow {
                            required property var modelData
                            width: devicesPane.width
                            glyph: Theme.glyph(0xf028)
                            text: Audio.nodeName(modelData)
                            current: modelData === Audio.sink
                            detail: current ? Theme.glyph(0xf00c) : ""
                            onClicked: Audio.setSink(modelData)
                        }
                    }

                    BarText {
                        anchors.verticalCenter: undefined
                        leftPadding: 10
                        topPadding: 6
                        bottomPadding: 2
                        text: "Input"
                        font.pixelSize: 11
                        color: Theme.gray
                    }

                    Repeater {
                        model: Audio.sources

                        ListRow {
                            required property var modelData
                            width: devicesPane.width
                            glyph: Theme.glyph(0xf130)
                            text: Audio.nodeName(modelData)
                            current: modelData === Audio.source
                            detail: current ? Theme.glyph(0xf00c) : ""
                            onClicked: Audio.setSource(modelData)
                        }
                    }
                }
            }

            // Per-app volume mixer
            Rectangle {
                width: main.width
                height: 36
                radius: 12
                color: root.mixerOpen ? Theme.selected : mixerMouse.containsMouse ? Theme.surfaceAlt : Theme.surface

                Behavior on color {
                    ColorAnimation { duration: Theme.animFast }
                }

                BarText {
                    id: mixerIcon
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    text: Theme.glyph(0xf1de)
                    color: Theme.accentBright
                }

                BarText {
                    anchors.left: mixerIcon.right
                    anchors.leftMargin: 10
                    text: Audio.streams.length > 0 ? `App volume · ${Audio.streams.length}` : "App volume"
                    font.pixelSize: 12
                    color: Theme.fgSoft
                }

                BarText {
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    text: Theme.glyph(0xf078)
                    font.pixelSize: 10
                    color: Theme.gray
                    rotation: root.mixerOpen ? 180 : 0

                    Behavior on rotation {
                        NumberAnimation { duration: Theme.anim; easing.type: Easing.OutCubic }
                    }
                }

                MouseArea {
                    id: mixerMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.mixerOpen = !root.mixerOpen
                }
            }

            Item {
                width: main.width
                height: root.mixerOpen ? mixerPane.implicitHeight : 0
                visible: height > 0
                clip: true

                Behavior on height {
                    NumberAnimation { duration: Theme.anim; easing.type: Easing.OutCubic }
                }

                Column {
                    id: mixerPane

                    width: parent.width
                    topPadding: 4
                    spacing: 10

                    BarText {
                        anchors.verticalCenter: undefined
                        width: parent.width
                        height: 32
                        visible: Audio.streams.length === 0
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        text: "Nothing is playing"
                        font.pixelSize: 12
                        font.weight: Font.Bold
                        color: Theme.gray
                    }

                    Repeater {
                        model: Audio.streams

                        Row {
                            id: app

                            required property var modelData
                            readonly property real volume: modelData.audio?.volume ?? 0
                            readonly property bool muted: modelData.audio?.muted ?? false

                            width: mixerPane.width
                            spacing: 10
                            opacity: muted ? 0.55 : 1

                            Behavior on opacity {
                                NumberAnimation { duration: Theme.anim }
                            }

                            // click the icon to mute the app
                            Item {
                                width: 32
                                height: 32

                                IconImage {
                                    anchors.centerIn: parent
                                    implicitSize: 22
                                    source: Audio.streamIcon(app.modelData)
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (app.modelData.audio)
                                            app.modelData.audio.muted = !app.muted;
                                    }
                                }
                            }

                            Column {
                                width: parent.width - 32 - 46 - parent.spacing * 2
                                anchors.verticalCenter: parent.verticalCenter

                                BarText {
                                    anchors.verticalCenter: undefined
                                    width: parent.width
                                    text: Audio.streamName(app.modelData)
                                    elide: Text.ElideRight
                                    font.pixelSize: 11
                                    color: Theme.fgSoft
                                }

                                Slider {
                                    width: parent.width
                                    value: app.volume
                                    onMoved: v => {
                                        if (app.modelData.audio) {
                                            app.modelData.audio.muted = false;
                                            app.modelData.audio.volume = v;
                                        }
                                    }
                                }
                            }

                            BarText {
                                width: 46
                                horizontalAlignment: Text.AlignRight
                                text: app.muted ? "muted" : `${Math.round(app.volume * 100)}%`
                                font.pixelSize: 12
                            }
                        }
                    }
                }
            }

            Separator {}

            Row {
                visible: Power.hasBattery
                spacing: 12

                BarText {
                    text: Power.icon
                    font.pixelSize: 28
                    color: Power.color
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter

                    BarText {
                        anchors.verticalCenter: undefined
                        text: `${Power.capacity}%`
                        font.pixelSize: 18
                        color: Theme.fgBright
                    }
                    BarText {
                        anchors.verticalCenter: undefined
                        text: Power.status
                        font.pixelSize: 11
                        font.weight: Font.Bold
                        color: Theme.gray
                    }
                }
            }

            Row {
                spacing: 8

                ProfileButton {
                    profile: PowerProfile.Performance
                    glyph: Theme.glyph(0xf135)
                    label: "Performance"
                    enabled: Power.hasPerformance
                }
                ProfileButton {
                    profile: PowerProfile.Balanced
                    glyph: Theme.glyph(0xf24e)
                    label: "Balanced"
                }
                ProfileButton {
                    profile: PowerProfile.PowerSaver
                    glyph: Theme.glyph(0xf06c)
                    label: "Saver"
                }
            }

            Separator {}

            Row {
                spacing: 10

                ToggleTile {
                    width: (main.width - 10) / 2
                    glyph: Net.wifiEnabled ? Theme.glyph(0xf05a9) : Theme.glyph(0xf05aa)
                    title: "Wi-Fi"
                    subtitle: Net.wifiStatus
                    on: Net.wifiEnabled
                    expanded: root.section === "wifi"
                    onToggled: Net.toggleWifi()
                    onExpandToggled: root.section = root.section === "wifi" ? "" : "wifi"
                }

                ToggleTile {
                    width: (main.width - 10) / 2
                    glyph: Net.btEnabled ? Theme.glyph(0xf00af) : Theme.glyph(0xf00b2)
                    title: "Bluetooth"
                    subtitle: Net.btStatus
                    on: Net.btEnabled
                    expanded: root.section === "bt"
                    onToggled: Net.toggleBluetooth()
                    onExpandToggled: root.section = root.section === "bt" ? "" : "bt"
                }
            }

            // Device lists slide open under the tiles
            Item {
                width: main.width
                height: root.section === "wifi" ? wifiPane.implicitHeight
                      : root.section === "bt" ? btPane.implicitHeight
                      : 0
                visible: height > 0
                clip: true

                Behavior on height {
                    NumberAnimation { duration: Theme.anim; easing.type: Easing.OutCubic }
                }

                Column {
                    id: wifiPane

                    width: parent.width
                    spacing: 6
                    opacity: root.section === "wifi" ? 1 : 0
                    visible: opacity > 0

                    Behavior on opacity {
                        NumberAnimation { duration: Theme.animFast }
                    }

                    Placeholder {
                        visible: !Net.wifiEnabled || wifiList.count === 0
                        text: !Net.wifiEnabled ? "Wi-Fi is off" : "Searching…"
                    }

                    ListView {
                        id: wifiList

                        width: parent.width
                        height: Math.min(count, 5) * 38
                        visible: Net.wifiEnabled && count > 0
                        spacing: 2
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        model: Net.wifiEnabled ? Net.networks : []

                        delegate: ListRow {
                            required property var modelData

                            glyph: Theme.glyph(0xf05a9)
                            text: modelData.name
                            strength: modelData.signalStrength
                            current: modelData.connected
                            busy: modelData.stateChanging
                            detail: modelData.connected ? "Connected"
                                  : modelData.known ? "Saved"
                                  : Net.isSecured(modelData) ? Theme.glyph(0xf023)
                                  : ""
                            onClicked: {
                                if (modelData.connected)
                                    modelData.disconnect();
                                else if (!modelData.known && Net.isSecured(modelData))
                                    root.pskNetwork = root.pskNetwork === modelData ? null : modelData;
                                else
                                    modelData.connect();
                            }
                        }
                    }

                    // Password prompt for a new secured network
                    Rectangle {
                        width: parent.width
                        height: root.pskNetwork ? 38 : 0
                        visible: height > 0
                        radius: 19
                        color: Theme.surfaceAlt
                        clip: true

                        Behavior on height {
                            NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutCubic }
                        }

                        BarText {
                            id: lock
                            anchors.left: parent.left
                            anchors.leftMargin: 14
                            text: Theme.glyph(0xf023)
                            color: Theme.accentBright
                        }

                        TextInput {
                            id: pskInput

                            anchors.left: lock.right
                            anchors.leftMargin: 10
                            anchors.right: parent.right
                            anchors.rightMargin: 14
                            anchors.verticalCenter: parent.verticalCenter
                            echoMode: TextInput.Password
                            color: Theme.fgBright
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize
                            font.weight: Font.Bold
                            clip: true

                            onAccepted: {
                                root.pskNetwork?.connectWithPsk(text);
                                text = "";
                                root.pskNetwork = null;
                            }
                            Keys.onEscapePressed: {
                                text = "";
                                root.pskNetwork = null;
                            }

                            BarText {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: pskInput.text === ""
                                text: `Password for ${root.pskNetwork?.name ?? ""}`
                                color: Theme.gray
                                font.weight: Font.Bold
                            }
                        }
                    }

                    SettingsButton {
                        text: "Network settings"
                        command: ["nm-connection-editor"]
                    }
                }

                Column {
                    id: btPane

                    width: parent.width
                    spacing: 6
                    opacity: root.section === "bt" ? 1 : 0
                    visible: opacity > 0

                    Behavior on opacity {
                        NumberAnimation { duration: Theme.animFast }
                    }

                    Placeholder {
                        visible: !Net.btEnabled || btList.count === 0
                        text: !Net.adapter ? "No Bluetooth adapter" : !Net.btEnabled ? "Bluetooth is off" : "Searching…"
                    }

                    ListView {
                        id: btList

                        width: parent.width
                        height: Math.min(count, 5) * 38
                        visible: Net.btEnabled && count > 0
                        spacing: 2
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        model: Net.btEnabled ? Net.btDevices : []

                        delegate: ListRow {
                            required property var modelData

                            glyph: Theme.glyph(0xf00af)
                            text: modelData.name
                            current: modelData.connected
                            busy: modelData.pairing
                                || modelData.state === BluetoothDeviceState.Connecting
                                || modelData.state === BluetoothDeviceState.Disconnecting
                            detail: modelData.connected
                                ? (modelData.batteryAvailable ? `${Math.round(modelData.battery * 100)}%` : "Connected")
                                : modelData.paired ? "Paired" : ""
                            onClicked: {
                                if (modelData.connected)
                                    modelData.disconnect();
                                else if (modelData.paired)
                                    modelData.connect();
                                else
                                    modelData.pair();
                            }
                        }
                    }

                    SettingsButton {
                        text: "Bluetooth settings"
                        command: ["blueman-manager"]
                    }
                }
            }
        }
    }

    component Separator: Rectangle {
        width: parent.width
        height: 1
        color: Theme.dim
    }

    component Placeholder: BarText {
        anchors.verticalCenter: undefined
        width: parent.width
        height: 36
        horizontalAlignment: Text.AlignHCenter
        color: Theme.gray
        font.weight: Font.Bold
    }

    component SliderRow: Row {
        id: sliderRow

        property string glyph
        property real value
        property string label
        property bool dimmed: false
        signal iconClicked
        signal moved(real value)

        spacing: 10
        opacity: dimmed ? 0.6 : 1

        Behavior on opacity {
            NumberAnimation { duration: Theme.anim }
        }

        IconButton {
            glyph: sliderRow.glyph
            onClicked: sliderRow.iconClicked()
        }

        Slider {
            anchors.verticalCenter: parent.verticalCenter
            width: main.width - 32 - 46 - sliderRow.spacing * 2
            value: sliderRow.value
            onMoved: v => sliderRow.moved(v)
        }

        BarText {
            width: 46
            horizontalAlignment: Text.AlignRight
            text: sliderRow.label
            font.pixelSize: 12
        }
    }

    component ProfileButton: Rectangle {
        id: profileButton

        property int profile
        property string glyph
        property string label
        readonly property bool selected: Power.profile === profile

        width: (main.width - 16) / 3
        height: 34
        radius: 17
        opacity: enabled ? 1 : 0.4
        color: selected ? Theme.accent : mouse.containsMouse ? Theme.selected : Theme.surfaceAlt

        Behavior on color {
            ColorAnimation { duration: Theme.anim }
        }

        Row {
            anchors.centerIn: parent
            height: parent.height
            spacing: 6

            BarText {
                text: profileButton.glyph
                font.pixelSize: 12
                color: profileButton.selected ? Theme.surface : Theme.fgSoft
            }
            BarText {
                text: profileButton.label
                font.pixelSize: 12
                color: profileButton.selected ? Theme.surface : Theme.fgSoft
            }
        }

        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: Power.setProfile(profileButton.profile)
        }
    }

    component SettingsButton: Rectangle {
        id: settingsButton

        property alias text: label.text
        property list<string> command

        anchors.right: parent.right
        width: label.implicitWidth + 28
        height: 28
        radius: 14
        color: mouse.containsMouse ? Theme.selected : Theme.surfaceAlt

        Behavior on color {
            ColorAnimation { duration: Theme.animFast }
        }

        BarText {
            id: label
            anchors.centerIn: parent
            anchors.verticalCenter: undefined
            font.pixelSize: 11
            color: Theme.fgSoft
        }

        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                Quickshell.execDetached(settingsButton.command);
                root.closeRequested();
            }
        }
    }
}
