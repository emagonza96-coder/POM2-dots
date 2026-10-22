import Quickshell
import Quickshell.Networking
import Quickshell.Io
import QtQuick
import "../.."

PopupWindow {
    id: popup
    property var parentAnchor
    anchor.item: parentAnchor
    anchor.edges: Edges.Bottom
    implicitWidth: 320
    implicitHeight: Math.min(list.count * 46 + 68, 370)
    color: "transparent"
    grabFocus: true

    property var pendingNetwork: null
    property bool showPasswordPrompt: false
    property var networkList: []
    property string connectingSsid: ""

    Timer {
        id: connectingSafetyTimer
        interval: 20000
        running: popup.connectingSsid !== ""
        repeat: false
        onTriggered: {
            popup.connectingSsid = ""
        }
    }

    function refreshNetworks() {
        let nets = []
        Networking.devices.values.forEach(d => {
            if (d && d.networks && d.networks.values) {
                d.networks.values.forEach(n => {
                    if (n && n.name && n.name.trim() !== "") {
                        nets.push(n)
                    }
                })
            }
        })
        nets.sort((a, b) => {
            if (a.connected && !b.connected) return -1
            if (!a.connected && b.connected) return 1
            if (a.known && !b.known) return -1
            if (!a.known && b.known) return 1
            return a.name.localeCompare(b.name)
        })
        popup.networkList = nets
        list.model = popup.networkList
    }

    function tryConnect(net) {
        if (net.known) {
            popup.connectingSsid = net.name
            net.connect()
        } else {
            popup.pendingNetwork = net
            popup.showPasswordPrompt = true
        }
    }

    function setScanning(enabled) {
        Networking.devices.values.forEach(d => {
            if (d.scannerEnabled !== undefined) {
                d.scannerEnabled = enabled
            }
        })
    }

    onVisibleChanged: {
        popup.setScanning(visible)
        if (visible) {
            popup.refreshNetworks()
            fadeIn.start()
        }
    }

    Timer {
        interval: 1500
        running: popup.visible
        repeat: true
        triggeredOnStart: true
        onTriggered: popup.refreshNetworks()
    }

    // Contenedor con animación de entrada
    Rectangle {
        id: container
        anchors.fill: parent
        color: Theme.surface
        border.color: Theme.border
        border.width: 1
        radius: 8
        clip: true
        opacity: 0
        transform: Translate { id: slideTranslate; y: -6 }

        NumberAnimation { id: fadeIn;  target: container; property: "opacity"; from: 0; to: 1; duration: 180; easing.type: Easing.OutQuad }
        NumberAnimation { id: slideIn; target: slideTranslate; property: "y";  from: -6; to: 0; duration: 180; easing.type: Easing.OutQuad }

        Component.onCompleted: { if (popup.visible) { fadeIn.start(); slideIn.start() } }

        Column {
            anchors.fill: parent
            spacing: 0

            // -- Header --
            Item {
                width: parent.width
                height: 34

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Redes disponibles"
                    font.family: Theme.font
                    font.pixelSize: 11
                    color: Theme.muted
                }

                Item {
                    anchors.right: parent.right
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    width: 20; height: 20
                    property bool hovered: false

                    Text {
                        anchors.centerIn: parent
                        text: "\ue97e"
                        font.family: Theme.iconFont
                        font.pixelSize: 12
                        color: parent.hovered ? Theme.accent : Theme.text
                        scale: parent.hovered ? 1.15 : 1.0
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
                    }
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: parent.hovered = true
                        onExited:  parent.hovered = false
                        onClicked: {
                            rescanProc.exec(["nmcli", "dev", "wifi", "rescan"])
                            popup.refreshNetworks()
                        }
                    }
                }
            }

            Rectangle { width: parent.width; height: 1; color: Theme.separator }

            // -- Lista de redes --
            ListView {
                id: list
                width: parent.width
                height: Math.min(count * 46, 300)
                clip: true
                spacing: 2
                model: popup.networkList

                delegate: Item {
                    id: delegateItem
                    required property var modelData
                    width: list.width
                    height: 44
                    property bool hovered: mainHover.containsMouse || (btnHover && btnHover.containsMouse)

                    readonly property bool isConnecting: {
                        if (popup.connectingSsid !== "" && popup.connectingSsid === modelData.name) return true
                        if (modelData.state === ConnectionState.Connecting) return true
                        if (modelData.stateChanging && !modelData.connected) return true
                        return false
                    }

                    Rectangle {
                        anchors.fill: parent
                        anchors.leftMargin: 6
                        anchors.rightMargin: 6
                        radius: 6
                        color: modelData.connected ? Theme.separator
                             : delegateItem.isConnecting ? "#241d0c"
                             : delegateItem.hovered ? "#142015"
                             : "transparent"
                        border.color: modelData.connected ? Theme.border
                                    : delegateItem.isConnecting ? Theme.amber
                                    : "transparent"
                        border.width: (modelData.connected || delegateItem.isConnecting) ? 1 : 0
                        Behavior on color { ColorAnimation { duration: 120 } }

                        // Ícono de WiFi o spinner
                        Item {
                            id: netIconItem
                            anchors.left: parent.left
                            anchors.leftMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            width: 16
                            height: 16

                            Text {
                                anchors.centerIn: parent
                                visible: !delegateItem.isConnecting
                                text: "\ue9e7"
                                font.family: Theme.iconFont
                                font.pixelSize: 13
                                color: modelData.connected ? Theme.accent : Theme.text
                            }

                            Text {
                                id: rowSpinIcon
                                anchors.centerIn: parent
                                visible: delegateItem.isConnecting
                                text: "󰑐"
                                font.family: Theme.font
                                font.pixelSize: 12
                                color: Theme.amber
                                transformOrigin: Item.Center

                                NumberAnimation on rotation {
                                    running: delegateItem.isConnecting
                                    from: 0; to: 360; duration: 1000; loops: Animation.Infinite
                                    onRunningChanged: { if (!running) rowSpinIcon.rotation = 0 }
                                }
                            }
                        }

                        // Botón Conectar / Desconectar / Estado Conectando
                        Rectangle {
                            id: actionBtn
                            visible: delegateItem.isConnecting || modelData.connected || (delegateItem.hovered && !modelData.connected)
                            anchors.right: parent.right
                            anchors.rightMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            width: delegateItem.isConnecting ? 98 : 76
                            height: 24
                            radius: 6

                            property bool isConnect: !modelData.connected

                            color: delegateItem.isConnecting ? "#241d0c"
                                 : btnHover.containsMouse ? (isConnect ? Theme.accent : Theme.amber)
                                 : "transparent"
                            border.color: delegateItem.isConnecting ? Theme.amber
                                        : (isConnect ? Theme.accent : Theme.amber)
                            border.width: 1
                            Behavior on color { ColorAnimation { duration: 120 } }
                            Behavior on width { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }

                            SequentialAnimation on opacity {
                                running: delegateItem.isConnecting
                                loops: Animation.Infinite
                                NumberAnimation { to: 0.45; duration: 500; easing.type: Easing.InOutQuad }
                                NumberAnimation { to: 1.0; duration: 500; easing.type: Easing.InOutQuad }
                            }

                            Row {
                                anchors.centerIn: parent
                                spacing: 4

                                Text {
                                    id: btnSpinIcon
                                    text: "󰑐"
                                    font.family: Theme.font
                                    font.pixelSize: 10
                                    color: Theme.amber
                                    visible: delegateItem.isConnecting
                                    anchors.verticalCenter: parent.verticalCenter
                                    transformOrigin: Item.Center

                                    NumberAnimation on rotation {
                                        running: delegateItem.isConnecting
                                        from: 0; to: 360; duration: 1000; loops: Animation.Infinite
                                        onRunningChanged: { if (!running) btnSpinIcon.rotation = 0 }
                                    }
                                }

                                Text {
                                    text: delegateItem.isConnecting ? "Conectando..." : (actionBtn.isConnect ? "Conectar" : "Desconectar")
                                    font.family: Theme.font
                                    font.pixelSize: 9
                                    font.bold: delegateItem.isConnecting
                                    color: delegateItem.isConnecting ? Theme.amber
                                         : (btnHover.containsMouse ? Theme.bg : (actionBtn.isConnect ? Theme.accent : Theme.amber))
                                    anchors.verticalCenter: parent.verticalCenter
                                    Behavior on color { ColorAnimation { duration: 120 } }
                                }
                            }

                            MouseArea {
                                id: btnHover
                                anchors.fill: parent
                                hoverEnabled: !delegateItem.isConnecting
                                cursorShape: delegateItem.isConnecting ? Qt.ArrowCursor : Qt.PointingHandCursor
                                onClicked: {
                                    if (delegateItem.isConnecting) return
                                    if (actionBtn.isConnect) {
                                        popup.tryConnect(modelData)
                                    } else {
                                        let iface = modelData.device.name
                                        disconnectProc.exec(["bash", "-c",
                                            "nmcli connection modify \"" + modelData.name + "\" connection.autoconnect no; nmcli device disconnect " + iface])
                                    }
                                }
                            }
                        }

                        // Columna de textos delimitada entre icono y botón
                        Column {
                            anchors.left: netIconItem.right
                            anchors.leftMargin: 8
                            anchors.right: actionBtn.visible ? actionBtn.left : parent.right
                            anchors.rightMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2

                            Text {
                                text: modelData.name
                                font.family: Theme.font
                                font.pixelSize: 12
                                font.bold: modelData.connected || delegateItem.isConnecting
                                color: delegateItem.isConnecting ? Theme.amber : (modelData.connected ? Theme.accent : Theme.text)
                                elide: Text.ElideRight
                                width: parent.width
                            }
                            Text {
                                visible: modelData.connected || delegateItem.isConnecting
                                text: delegateItem.isConnecting ? "Conectando..." : "Conectado"
                                font.family: Theme.font
                                font.pixelSize: 10
                                color: delegateItem.isConnecting ? Theme.amber : Theme.muted
                            }
                        }

                        // MouseArea sobre la fila (sin colisionar con el botón)
                        MouseArea {
                            id: mainHover
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            anchors.right: actionBtn.visible ? actionBtn.left : parent.right
                            hoverEnabled: !delegateItem.isConnecting
                            cursorShape: delegateItem.isConnecting ? Qt.ArrowCursor : Qt.PointingHandCursor
                            onClicked: {
                                if (!modelData.connected && !delegateItem.isConnecting) {
                                    popup.tryConnect(modelData)
                                }
                            }
                        }

                        Connections {
                            target: modelData
                            function onConnectedChanged() {
                                if (modelData.connected && popup.connectingSsid === modelData.name) {
                                    popup.connectingSsid = ""
                                }
                            }
                            function onStateChanged() {
                                if (modelData.connected && popup.connectingSsid === modelData.name) {
                                    popup.connectingSsid = ""
                                }
                            }
                            function onConnectionFailed(reason) {
                                if (popup.connectingSsid === modelData.name) {
                                    popup.connectingSsid = ""
                                }
                                if (reason === ConnectionFailReason.NoSecrets) {
                                    popup.pendingNetwork = modelData
                                    popup.showPasswordPrompt = true
                                }
                            }
                        }
                    }
                }
            }

            Rectangle { width: parent.width; height: 1; color: Theme.separator }

            // -- Footer --
            Item {
                width: parent.width
                height: 30
                property bool hovered: false

                Rectangle {
                    anchors.fill: parent
                    color: parent.hovered ? "#142015" : "transparent"
                    Behavior on color { ColorAnimation { duration: 120 } }
                }
                Text {
                    anchors.centerIn: parent
                    text: "Configuración de red"
                    font.family: Theme.font
                    font.pixelSize: 11
                    color: parent.hovered ? Theme.accent : Theme.muted
                    Behavior on color { ColorAnimation { duration: 120 } }
                }
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: parent.hovered = true
                    onExited:  parent.hovered = false
                    onClicked: settingsProc.exec(["nm-connection-editor"])
                }
            }
        }

        // -- Prompt de contraseña --
        Rectangle {
            visible: popup.showPasswordPrompt
            anchors.fill: parent
            color: Theme.surface
            border.color: Theme.border
            border.width: 1
            radius: 8
            opacity: popup.showPasswordPrompt ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 180 } }

            Column {
                anchors.centerIn: parent
                spacing: 10
                width: parent.width - 40

                Column {
                    spacing: 4
                    width: parent.width

                    Text {
                        text: "Conectar a red privada"
                        font.family: Theme.font
                        font.pixelSize: 14
                        font.bold: true
                        color: Theme.text
                    }

                    Text {
                        text: popup.pendingNetwork ? "Introduce la contraseña para conectar a la red <b>" + popup.pendingNetwork.name + "</b>" : ""
                        font.family: Theme.font
                        font.pixelSize: 11
                        color: Theme.muted
                        wrapMode: Text.WordWrap
                        width: parent.width
                    }
                }

                Rectangle {
                    width: parent.width; height: 30; radius: 6
                    color: Theme.bg
                    border.color: pskInput.activeFocus ? Theme.accent : Theme.border
                    Behavior on border.color { ColorAnimation { duration: 150 } }

                    TextInput {
                        id: pskInput
                        anchors.fill: parent
                        anchors.margins: 8
                        echoMode: TextInput.Password
                        color: Theme.text
                        font.family: Theme.font
                        font.pixelSize: 12
                        focus: popup.showPasswordPrompt

                        Keys.onReturnPressed: {
                            if (popup.pendingNetwork) {
                                popup.connectingSsid = popup.pendingNetwork.name
                                popup.pendingNetwork.connectWithPsk(pskInput.text)
                                popup.showPasswordPrompt = false
                                pskInput.text = ""
                            }
                        }
                    }
                }

                Row {
                    spacing: 8

                    // Botón Conectar
                    Rectangle {
                        id: connectBtn
                        width: 100; height: 26; radius: 6
                        property bool hovered: false
                        color: hovered ? Theme.accent : Theme.separator
                        border.color: Theme.border
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Text {
                            anchors.centerIn: parent
                            text: "Conectar"
                            font.family: Theme.font; font.pixelSize: 11
                            color: connectBtn.hovered ? Theme.bg : Theme.accent
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered: connectBtn.hovered = true
                            onExited:  connectBtn.hovered = false
                            onClicked: {
                                if (popup.pendingNetwork) {
                                    popup.connectingSsid = popup.pendingNetwork.name
                                    popup.pendingNetwork.connectWithPsk(pskInput.text)
                                    popup.showPasswordPrompt = false
                                    pskInput.text = ""
                                }
                            }
                        }
                    }

                    // Botón Cancelar
                    Rectangle {
                        id: cancelBtn
                        width: 90; height: 26; radius: 6
                        property bool hovered: false
                        color: "transparent"
                        border.color: hovered ? Theme.text : Theme.muted
                        Behavior on border.color { ColorAnimation { duration: 150 } }
                        Text {
                            anchors.centerIn: parent
                            text: "Cancelar"
                            font.family: Theme.font; font.pixelSize: 11
                            color: cancelBtn.hovered ? Theme.text : Theme.muted
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered: cancelBtn.hovered = true
                            onExited:  cancelBtn.hovered = false
                            onClicked: {
                                popup.showPasswordPrompt = false
                                pskInput.text = ""
                            }
                        }
                    }
                }
            }
        }
    }

    Process { id: rescanProc }
    Process { id: settingsProc }
    Process { id: disconnectProc }
}