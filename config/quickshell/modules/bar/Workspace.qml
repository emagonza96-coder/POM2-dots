import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import "../.."

Row {
    id: wsRoot
    height: 22
    anchors.verticalCenter: parent.verticalCenter
    spacing: 0

    // Diccionario de ventanas por workspace { wsId: [glyph1, glyph2, ...] }
    property var clientsMap: ({})
    property int hoveredWsId: -1
    property bool hoveredHasApps: false

    function getAppGlyph(appClass) {
        let c = (appClass || "").toLowerCase()
        if (c.includes("firefox") || c.includes("zen") || c.includes("librewolf")) return "󰈹"
        if (c.includes("spotify")) return "󰓇"
        if (c.includes("kitty") || c.includes("alacritty") || c.includes("foot") || c.includes("term")) return "󰞷"
        if (c.includes("discord") || c.includes("vesktop") || c.includes("webcord")) return "󰙯"
        if (c.includes("antigravity") || c.includes("code") || c.includes("vscodium") || c.includes("nvim")) return "󰨞"
        if (c.includes("thunar") || c.includes("nemo") || c.includes("nautilus") || c.includes("dolphin")) return "󰉋"
        if (c.includes("chrome") || c.includes("chromium") || c.includes("brave")) return "󰊯"
        if (c.includes("steam")) return "󰊴"
        if (c.includes("telegram")) return "󰒥"
        if (c.includes("mpv") || c.includes("vlc") || c.includes("video")) return "󰕼"
        if (c.includes("obs")) return "󰑋"
        if (c.includes("gimp") || c.includes("inkscape") || c.includes("krita")) return "󰽉"
        return "󰖲"
    }

    Process {
        id: clientsProc
        command: ["hyprctl", "clients", "-j"]
        stdout: StdioCollector { id: clientsCollector }
        onExited: {
            try {
                let data = JSON.parse(clientsCollector.text)
                let map = {}
                if (Array.isArray(data)) {
                    data.forEach(c => {
                        if (c.workspace && c.workspace.id !== undefined) {
                            let id = c.workspace.id
                            if (!map[id]) map[id] = []
                            let cls = c.class || c.initialClass || ""
                            let glyph = wsRoot.getAppGlyph(cls)
                            if (!map[id].includes(glyph)) {
                                map[id].push(glyph)
                            }
                        }
                    })
                }
                wsRoot.clientsMap = map
            } catch (e) {}
        }
    }

    Timer {
        id: refreshTimer
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: clientsProc.running = true
    }

    Connections {
        target: Hyprland
        function onFocusedWorkspaceChanged() {
            clientsProc.running = true
        }
    }

    Repeater {
        model: {
            let wss = []
            for (let i = 0; i < Hyprland.workspaces.values.length; i++) {
                wss.push(Hyprland.workspaces.values[i])
            }
            return wss.sort((a, b) => a.id - b.id)
        }

        delegate: Item {
            id: delegateWs
            required property var modelData
            height: 20
            anchors.verticalCenter: parent.verticalCenter
            clip: true

            readonly property var wsApps: wsRoot.clientsMap[modelData.id] || []
            readonly property bool isFocused: Hyprland.focusedWorkspace?.id === modelData.id
            readonly property bool isHovered: wsMouse.containsMouse
            readonly property bool isExpanded: isHovered && wsApps.length > 0
            readonly property bool shouldCollapse: wsRoot.hoveredHasApps && wsRoot.hoveredWsId !== -1 && wsRoot.hoveredWsId !== modelData.id

            readonly property int normalWidth: wsLabel.implicitWidth + 14
            readonly property int expandedWidth: expandedRow.implicitWidth + 14

            width: shouldCollapse ? 0 : (isExpanded ? expandedWidth : normalWidth)
            opacity: shouldCollapse ? 0 : 1.0

            Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
            Behavior on opacity { NumberAnimation { duration: 150 } }

            // Contenedor con escala de click
            Item {
                id: wsContent
                anchors.fill: parent
                scale: delegateWs.isFocused ? 1.05 : 1.0
                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }

                // Underline indicator para el workspace activo
                Rectangle {
                    id: indicator
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    height: 2
                    width: delegateWs.isFocused && !delegateWs.shouldCollapse ? parent.width * 0.72 : 0
                    radius: 0
                    color: Theme.accent
                    Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                }

                // Modo normal: solo el número
                Text {
                    id: wsLabel
                    anchors.centerIn: parent
                    visible: !delegateWs.isExpanded && !delegateWs.shouldCollapse
                    text: modelData.id.toString()
                    font.family: Theme.font
                    font.pixelSize: 13
                    font.bold: delegateWs.isFocused
                    color: delegateWs.isFocused ? Theme.accent : (delegateWs.isHovered ? Theme.text : Theme.muted)
                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                // Modo expandido (al pasar hover con apps)
                Row {
                    id: expandedRow
                    anchors.centerIn: parent
                    spacing: 4
                    visible: delegateWs.isExpanded

                    Text {
                        text: modelData.id.toString()
                        font.family: Theme.font
                        font.pixelSize: 13
                        font.bold: true
                        color: delegateWs.isFocused ? Theme.accent : Theme.text
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: "//"
                        font.family: Theme.font
                        font.pixelSize: 8
                        font.bold: true
                        color: Theme.muted
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Row {
                        spacing: 4
                        anchors.verticalCenter: parent.verticalCenter

                        Repeater {
                            model: delegateWs.wsApps
                            delegate: Text {
                                text: modelData
                                font.family: Theme.font
                                font.pixelSize: 11
                                color: delegateWs.isFocused ? Theme.accent : Theme.text
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    }
                }
            }

            // Animación de click táctico
            SequentialAnimation {
                id: clickAnim
                NumberAnimation { target: wsContent; property: "scale"; to: 0.82; duration: 70;  easing.type: Easing.InQuad }
                NumberAnimation { target: wsContent; property: "scale"; to: delegateWs.isFocused ? 1.05 : 1.0; duration: 180; easing.type: Easing.OutElastic }
            }

            MouseArea {
                id: wsMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: {
                    wsRoot.hoveredWsId = modelData.id
                    wsRoot.hoveredHasApps = (delegateWs.wsApps.length > 0)
                    if (delegateWs.wsApps.length === 0) {
                        clientsProc.running = true
                    }
                }
                onExited: {
                    if (wsRoot.hoveredWsId === modelData.id) {
                        wsRoot.hoveredWsId = -1
                        wsRoot.hoveredHasApps = false
                    }
                }
                onClicked: {
                    clickAnim.start()
                    Hyprland.dispatch("workspace " + modelData.id)
                }
            }
        }
    }
}