import Quickshell
import Quickshell.Networking
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import "../.."

PopupWindow {
    id: popup
    property var parentAnchor
    anchor.item: parentAnchor
    anchor.edges: Edges.Bottom
    implicitWidth: 350
    implicitHeight: Math.min(mainCol.implicitHeight + 24, 490)
    color: "transparent"
    grabFocus: true

    // Pestaña activa: "networks" | "status"
    property string currentTab: "networks"

    property var pendingNetwork: null
    property bool showPasswordPrompt: false
    property var networkList: []
    property var availableList: []
    property var connectedNet: null
    property string connectingSsid: ""
    property bool isScanning: false
    property string primaryDeviceName: "wlan0"

    // Datos de telemetría de red
    property var telemetry: ({
        "iface": "wlan0",
        "ip": "N/D",
        "gateway": "N/D",
        "mac": "N/D",
        "freq": "N/D",
        "bitrate": "N/D",
        "signal_dbm": "N/D",
        "ssid": "Sin red",
        "connected": false,
        "driver": "rtw88_8822ce"
    })

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
        let netMap = {}
        let conn = null
        let devName = "wlan0"

        Networking.devices.values.forEach(d => {
            if (d && d.name) {
                devName = d.name
            }
            if (d && d.networks && d.networks.values) {
                d.networks.values.forEach(n => {
                    if (!n || !n.name || n.name.trim() === "") return
                    let ssid = n.name.trim()
                    if (n.connected) {
                        conn = n
                    }
                    if (!netMap[ssid]) {
                        netMap[ssid] = n
                    } else {
                        let existing = netMap[ssid]
                        if (n.connected && !existing.connected) {
                            netMap[ssid] = n
                        } else if (!existing.connected) {
                            let nStrength = n.signalStrength || 0
                            let exStrength = existing.signalStrength || 0
                            if ((n.known && !existing.known) || (n.known === existing.known && nStrength > exStrength)) {
                                netMap[ssid] = n
                            }
                        }
                    }
                })
            }
        })

        popup.primaryDeviceName = devName
        popup.connectedNet = conn

        let allNets = Object.values(netMap)
        allNets.sort((a, b) => {
            if (a.connected && !b.connected) return -1
            if (!a.connected && b.connected) return 1
            if (a.known && !b.known) return -1
            if (!a.known && b.known) return 1
            let aSig = a.signalStrength || 0
            let bSig = b.signalStrength || 0
            if (bSig !== aSig) return bSig - aSig
            return a.name.localeCompare(b.name)
        })
        popup.networkList = allNets

        // Lista de disponibles (excluyendo la conectada para la tarjeta destacada)
        let avail = []
        allNets.forEach(n => {
            if (!conn || n.name !== conn.name) {
                avail.push(n)
            }
        })
        popup.availableList = avail
    }

    function tryConnect(net) {
        if (!net) return
        if (net.known) {
            popup.connectingSsid = net.name
            net.connect()
        } else {
            popup.pendingNetwork = net
            popup.showPasswordPrompt = true
        }
    }

    function disconnectNet(net) {
        if (!net) return
        let iface = (net.device && net.device.name) ? net.device.name : popup.primaryDeviceName
        disconnectProc.exec(["bash", "-c",
            "nmcli connection modify \"" + net.name + "\" connection.autoconnect no; nmcli device disconnect " + iface])
        popup.connectingSsid = ""
        refreshTimer.restart()
    }

    function setScanning(enabled) {
        popup.isScanning = enabled
        Networking.devices.values.forEach(d => {
            if (d && d.scannerEnabled !== undefined) {
                d.scannerEnabled = enabled
            }
        })
    }

    function refreshTelemetry() {
        telemetryProc.running = true
    }

    onVisibleChanged: {
        popup.setScanning(visible)
        if (visible) {
            popup.refreshNetworks()
            popup.refreshTelemetry()
            fadeIn.start()
            slideIn.start()
        } else {
            popup.showPasswordPrompt = false
            popup.pendingNetwork = null
        }
    }

    Timer {
        id: refreshTimer
        interval: 2000
        running: popup.visible
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            popup.refreshNetworks()
            if (popup.currentTab === "status") {
                popup.refreshTelemetry()
            }
        }
    }

    // Contenedor principal con animación de entrada
    Rectangle {
        id: container
        anchors.fill: parent
        color: Theme.surface
        border.color: Theme.border
        border.width: 1
        radius: 0
        clip: true
        opacity: 0
        transform: Translate { id: slideTranslate; y: -6 }

        // Muescas tácticas iluminadas en las 4 esquinas del popup en verde POM-2
        Rectangle { width: 6; height: 1; color: Theme.accent; anchors.top: parent.top; anchors.left: parent.left }
        Rectangle { width: 1; height: 6; color: Theme.accent; anchors.top: parent.top; anchors.left: parent.left }
        Rectangle { width: 6; height: 1; color: Theme.accent; anchors.top: parent.top; anchors.right: parent.right }
        Rectangle { width: 1; height: 6; color: Theme.accent; anchors.top: parent.top; anchors.right: parent.right }
        Rectangle { width: 6; height: 1; color: Theme.accent; anchors.bottom: parent.bottom; anchors.left: parent.left }
        Rectangle { width: 1; height: 6; color: Theme.accent; anchors.bottom: parent.bottom; anchors.left: parent.left }
        Rectangle { width: 6; height: 1; color: Theme.accent; anchors.bottom: parent.bottom; anchors.right: parent.right }
        Rectangle { width: 1; height: 6; color: Theme.accent; anchors.bottom: parent.bottom; anchors.right: parent.right }

        NumberAnimation { id: fadeIn;  target: container;      property: "opacity"; from: 0;  to: 1; duration: 180; easing.type: Easing.OutQuad }
        NumberAnimation { id: slideIn; target: slideTranslate; property: "y";       from: -6; to: 0; duration: 180; easing.type: Easing.OutQuad }

        // Contenido interior con margen de 12px para evitar sobreposición con las esquinas exteriores
        Column {
            id: mainCol
            anchors.fill: parent
            anchors.margins: 12
            spacing: 10

            // ==========================================
            // HEADER TÁCTICO MILITAR CON TELEMETRÍA
            // ==========================================
            Item {
                width: parent.width
                height: 22

                Row {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                    Text {
                        text: "[NET // " + popup.primaryDeviceName.toUpperCase() + "]"
                        font.family: Theme.font
                        font.pixelSize: 9
                        font.bold: true
                        color: Theme.accent
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    // Indicador de escaneo activo
                    Row {
                        spacing: 4
                        anchors.verticalCenter: parent.verticalCenter

                        Text {
                            text: "●"
                            font.family: Theme.font
                            font.pixelSize: 8
                            color: popup.isScanning ? Theme.accent : Theme.muted
                            anchors.verticalCenter: parent.verticalCenter

                            SequentialAnimation on opacity {
                                running: popup.isScanning
                                loops: Animation.Infinite
                                NumberAnimation { to: 0.2; duration: 450 }
                                NumberAnimation { to: 1.0; duration: 450 }
                            }
                        }

                        Text {
                            text: popup.isScanning ? "SCAN // ACTIVO" : "SCAN // STANDBY"
                            font.family: Theme.font
                            font.pixelSize: 8
                            font.bold: true
                            color: popup.isScanning ? Theme.accent : Theme.muted
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }

                // Botón táctico de escaneo/refresco anclado a la derecha
                Rectangle {
                    id: refreshBtn
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: 22
                    height: 20
                    radius: 0
                    color: refreshMouse.containsMouse ? "#142416" : "#0a130b"
                    border.color: refreshMouse.containsMouse ? Theme.accent : Theme.separator
                    border.width: 1

                    Text {
                        id: refreshIcon
                        anchors.centerIn: parent
                        text: "󰑐"
                        font.family: Theme.font
                        font.pixelSize: 11
                        color: refreshMouse.containsMouse ? Theme.accent : Theme.text
                        transformOrigin: Item.Center

                        NumberAnimation on rotation {
                            id: spinAnim
                            from: 0; to: 360; duration: 600
                            running: false
                        }
                    }

                    MouseArea {
                        id: refreshMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            spinAnim.restart()
                            rescanProc.exec(["nmcli", "dev", "wifi", "rescan"])
                            popup.refreshNetworks()
                            popup.refreshTelemetry()
                        }
                    }
                }
            }

            // ==========================================
            // BARRA DE PESTAÑAS (TABS) TIPO WORKSPACE
            // ==========================================
            Item {
                width: parent.width
                height: 28

                // Línea base sutil
                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: 1
                    color: Theme.separator
                }

                Row {
                    anchors.fill: parent
                    spacing: 0

                    // Tab 1: 01 // REDES
                    Item {
                        id: tabNetsBtn
                        width: parent.width / 2
                        height: parent.height
                        property bool isActive: popup.currentTab === "networks"
                        property bool hovered: false

                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.horizontalCenter: parent.horizontalCenter
                            height: 2
                            width: tabNetsBtn.isActive ? parent.width * 0.75 : 0
                            radius: 0
                            color: Theme.accent
                            Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                        }

                        Row {
                            anchors.centerIn: parent
                            spacing: 5
                            scale: tabNetsBtn.isActive ? 1.05 : 1.0
                            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }

                            Text {
                                text: "󰤨"
                                font.family: Theme.font
                                font.pixelSize: 11
                                color: tabNetsBtn.isActive ? Theme.accent : (tabNetsBtn.hovered ? Theme.text : Theme.muted)
                                anchors.verticalCenter: parent.verticalCenter
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }

                            Text {
                                text: "01 // REDES"
                                font.family: Theme.font
                                font.pixelSize: 10
                                font.bold: tabNetsBtn.isActive
                                color: tabNetsBtn.isActive ? Theme.accent : (tabNetsBtn.hovered ? Theme.text : Theme.muted)
                                anchors.verticalCenter: parent.verticalCenter
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: tabNetsBtn.hovered = true
                            onExited:  tabNetsBtn.hovered = false
                            onClicked: popup.currentTab = "networks"
                        }
                    }

                    // Tab 2: 02 // ESTADO
                    Item {
                        id: tabStateBtn
                        width: parent.width / 2
                        height: parent.height
                        property bool isActive: popup.currentTab === "status"
                        property bool hovered: false

                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.horizontalCenter: parent.horizontalCenter
                            height: 2
                            width: tabStateBtn.isActive ? parent.width * 0.75 : 0
                            radius: 0
                            color: Theme.accent
                            Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                        }

                        Row {
                            anchors.centerIn: parent
                            spacing: 5
                            scale: tabStateBtn.isActive ? 1.05 : 1.0
                            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }

                            Text {
                                text: "󰌘"
                                font.family: Theme.font
                                font.pixelSize: 11
                                color: tabStateBtn.isActive ? Theme.accent : (tabStateBtn.hovered ? Theme.text : Theme.muted)
                                anchors.verticalCenter: parent.verticalCenter
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }

                            Text {
                                text: "02 // ESTADO"
                                font.family: Theme.font
                                font.pixelSize: 10
                                font.bold: tabStateBtn.isActive
                                color: tabStateBtn.isActive ? Theme.accent : (tabStateBtn.hovered ? Theme.text : Theme.muted)
                                anchors.verticalCenter: parent.verticalCenter
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: tabStateBtn.hovered = true
                            onExited:  tabStateBtn.hovered = false
                            onClicked: {
                                popup.currentTab = "status"
                                popup.refreshTelemetry()
                            }
                        }
                    }
                }
            }

            // ==========================================
            // VISTA 1: 01 // REDES
            // ==========================================
            Column {
                width: parent.width
                spacing: 8
                visible: popup.currentTab === "networks"

                // TARJETA DESTACADA: RED CONECTADA ACTUAL
                Rectangle {
                    id: connectedCard
                    visible: popup.connectedNet !== null
                    width: parent.width
                    height: 52
                    radius: 0
                    color: "#0f1c11"
                    border.color: Theme.accent
                    border.width: 1

                    // Esquinas tácticas iluminadas en verde acento (Theme.accent)
                    Rectangle { width: 5; height: 1; color: Theme.accent; anchors.top: parent.top; anchors.left: parent.left }
                    Rectangle { width: 1; height: 5; color: Theme.accent; anchors.top: parent.top; anchors.left: parent.left }
                    Rectangle { width: 5; height: 1; color: Theme.accent; anchors.top: parent.top; anchors.right: parent.right }
                    Rectangle { width: 1; height: 5; color: Theme.accent; anchors.top: parent.top; anchors.right: parent.right }
                    Rectangle { width: 5; height: 1; color: Theme.accent; anchors.bottom: parent.bottom; anchors.left: parent.left }
                    Rectangle { width: 1; height: 5; color: Theme.accent; anchors.bottom: parent.bottom; anchors.left: parent.left }
                    Rectangle { width: 5; height: 1; color: Theme.accent; anchors.bottom: parent.bottom; anchors.right: parent.right }
                    Rectangle { width: 1; height: 5; color: Theme.accent; anchors.bottom: parent.bottom; anchors.right: parent.right }

                    // Ícono de WiFi conectado a la izquierda
                    Text {
                        id: connIcon
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        text: "\ue9e7"
                        font.family: Theme.iconFont
                        font.pixelSize: 16
                        color: Theme.accent
                    }

                    // Botón Desconectar fijo y visible a la derecha
                    Rectangle {
                        id: disconnectBtn
                        anchors.right: parent.right
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        width: 78
                        height: 24
                        radius: 0
                        color: disMouse.containsMouse ? "#2b1414" : "#170e0e"
                        border.color: Theme.amber
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: "Desconectar"
                            font.family: Theme.font
                            font.pixelSize: 9
                            font.bold: true
                            color: Theme.amber
                        }

                        MouseArea {
                            id: disMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: popup.disconnectNet(popup.connectedNet)
                        }
                    }

                    // Datos de la red conectada delimitados entre el ícono y el botón
                    Column {
                        anchors.left: connIcon.right
                        anchors.leftMargin: 10
                        anchors.right: disconnectBtn.left
                        anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2
                        clip: true

                        Row {
                            spacing: 6
                            width: parent.width

                            Text {
                                text: popup.connectedNet ? popup.connectedNet.name : ""
                                font.family: Theme.font
                                font.pixelSize: 11
                                font.bold: true
                                color: Theme.accent
                                elide: Text.ElideRight
                                maximumLineCount: 1
                                width: Math.min(implicitWidth, parent.width - 45)
                            }
                            Text {
                                text: popup.connectedNet && popup.connectedNet.signalStrength
                                      ? Math.round(popup.connectedNet.signalStrength * 100) + "%"
                                      : ""
                                font.family: Theme.font
                                font.pixelSize: 9
                                font.bold: true
                                color: Theme.accent
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        Row {
                            spacing: 4
                            Text {
                                text: "[ACTIVO // EN LÍNEA]"
                                font.family: Theme.font
                                font.pixelSize: 8
                                font.bold: true
                                color: Theme.text
                            }
                            Text {
                                text: "· " + popup.telemetry.freq
                                font.family: Theme.font
                                font.pixelSize: 8
                                color: Theme.muted
                                visible: popup.telemetry.freq !== "N/D"
                            }
                        }
                    }
                }

                // SUBHEADER: DISPONIBLES // DETECTADAS
                Row {
                    width: parent.width
                    spacing: 6

                    Text {
                        text: "DISPONIBLES // DETECTADAS [" + popup.availableList.length + "]"
                        font.family: Theme.font
                        font.pixelSize: 9
                        font.bold: true
                        color: Theme.muted
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                // ESTADO VACÍO SI NO HAY REDES DETECTADAS
                Rectangle {
                    visible: popup.availableList.length === 0 && popup.connectedNet === null
                    width: parent.width
                    height: 40
                    radius: 0
                    color: "#09120b"
                    border.color: Theme.separator
                    border.width: 1

                    Rectangle { width: 4; height: 1; color: Theme.border; anchors.top: parent.top; anchors.left: parent.left }
                    Rectangle { width: 1; height: 4; color: Theme.border; anchors.top: parent.top; anchors.left: parent.left }
                    Rectangle { width: 4; height: 1; color: Theme.border; anchors.top: parent.top; anchors.right: parent.right }
                    Rectangle { width: 1; height: 4; color: Theme.border; anchors.top: parent.top; anchors.right: parent.right }
                    Rectangle { width: 4; height: 1; color: Theme.border; anchors.bottom: parent.bottom; anchors.left: parent.left }
                    Rectangle { width: 1; height: 4; color: Theme.border; anchors.bottom: parent.bottom; anchors.left: parent.left }
                    Rectangle { width: 4; height: 1; color: Theme.border; anchors.bottom: parent.bottom; anchors.right: parent.right }
                    Rectangle { width: 1; height: 4; color: Theme.border; anchors.bottom: parent.bottom; anchors.right: parent.right }

                    Row {
                        anchors.centerIn: parent
                        spacing: 6
                        Text { text: "󰑐"; font.family: Theme.font; font.pixelSize: 11; color: Theme.muted; anchors.verticalCenter: parent.verticalCenter }
                        Text { text: "Escaneando entorno... // Buscando señal"; font.family: Theme.font; font.pixelSize: 10; color: Theme.muted; anchors.verticalCenter: parent.verticalCenter }
                    }
                }

                // LISTA DESPLAZABLE DE REDES DISPONIBLES
                ListView {
                    id: list
                    width: parent.width
                    height: Math.min(count * 42, popup.connectedNet ? 240 : 300)
                    clip: true
                    spacing: 4
                    model: popup.availableList

                    delegate: Item {
                        id: delegateItem
                        required property var modelData
                        width: list.width
                        height: 38
                        property bool hovered: mainHover.containsMouse || (btnHover && btnHover.containsMouse)

                        readonly property bool isConnecting: {
                            if (popup.connectingSsid !== "" && popup.connectingSsid === modelData.name) return true
                            if (modelData.state === ConnectionState.Connecting) return true
                            if (modelData.stateChanging && !modelData.connected) return true
                            return false
                        }

                        Rectangle {
                            id: delegateBg
                            anchors.fill: parent
                            radius: 0
                            color: delegateItem.isConnecting ? "#241d0c"
                                 : delegateItem.hovered ? "#122013"
                                 : "#09130a"
                            border.color: delegateItem.isConnecting ? Theme.amber
                                        : delegateItem.hovered ? Theme.accent
                                        : Theme.separator
                            border.width: 1
                            Behavior on color { ColorAnimation { duration: 120 } }
                            Behavior on border.color { ColorAnimation { duration: 120 } }

                            // Esquinas iluminadas al conectar o hover (definidas con id para evitar ReferenceError)
                            readonly property color itemCorner: delegateItem.isConnecting ? Theme.amber
                                                              : (delegateItem.hovered ? Theme.accent : "transparent")
                            Rectangle { width: 4; height: 1; color: delegateBg.itemCorner; anchors.top: parent.top; anchors.left: parent.left }
                            Rectangle { width: 1; height: 4; color: delegateBg.itemCorner; anchors.top: parent.top; anchors.left: parent.left }
                            Rectangle { width: 4; height: 1; color: delegateBg.itemCorner; anchors.top: parent.top; anchors.right: parent.right }
                            Rectangle { width: 1; height: 4; color: delegateBg.itemCorner; anchors.top: parent.top; anchors.right: parent.right }
                            Rectangle { width: 4; height: 1; color: delegateBg.itemCorner; anchors.bottom: parent.bottom; anchors.left: parent.left }
                            Rectangle { width: 1; height: 4; color: delegateBg.itemCorner; anchors.bottom: parent.bottom; anchors.left: parent.left }
                            Rectangle { width: 4; height: 1; color: delegateBg.itemCorner; anchors.bottom: parent.bottom; anchors.right: parent.right }
                            Rectangle { width: 1; height: 4; color: delegateBg.itemCorner; anchors.bottom: parent.bottom; anchors.right: parent.right }

                            // MouseArea base sobre toda la fila para conectar
                            MouseArea {
                                id: mainHover
                                anchors.fill: parent
                                hoverEnabled: !delegateItem.isConnecting
                                cursorShape: delegateItem.isConnecting ? Qt.ArrowCursor : Qt.PointingHandCursor
                                onClicked: {
                                    if (!delegateItem.isConnecting) {
                                        popup.tryConnect(modelData)
                                    }
                                }
                            }

                            // Ícono WiFi o spinner si conecta (anclado a la izquierda)
                            Item {
                                id: netIconItem
                                width: 14
                                height: 14
                                anchors.left: parent.left
                                anchors.leftMargin: 8
                                anchors.verticalCenter: parent.verticalCenter

                                Text {
                                    anchors.centerIn: parent
                                    visible: !delegateItem.isConnecting
                                    text: "\ue9e7"
                                    font.family: Theme.iconFont
                                    font.pixelSize: 13
                                    color: delegateItem.hovered ? Theme.accent : Theme.text
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

                            // Slot derecho: botón Conectar (hover/conectando) o porcentaje de señal
                            Item {
                                id: rightSlot
                                anchors.right: parent.right
                                anchors.rightMargin: 8
                                anchors.verticalCenter: parent.verticalCenter
                                width: actionBtn.visible ? actionBtn.width : signalLabel.implicitWidth
                                height: 24
                                z: 2

                                // Indicador de señal cuando NO está en hover
                                Text {
                                    id: signalLabel
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    visible: !actionBtn.visible
                                    text: Math.round((modelData.signalStrength || 0) * 100) + "%"
                                    font.family: Theme.font
                                    font.pixelSize: 9
                                    font.bold: true
                                    color: Theme.muted
                                }

                                // Botón Conectar (visible al hover o al conectar)
                                Rectangle {
                                    id: actionBtn
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    visible: delegateItem.isConnecting || delegateItem.hovered
                                    width: delegateItem.isConnecting ? 86 : 70
                                    height: 24
                                    radius: 0
                                    color: delegateItem.isConnecting ? "#241d0c"
                                         : btnHover.containsMouse ? Theme.accent
                                         : "#102012"
                                    border.color: delegateItem.isConnecting ? Theme.amber : Theme.accent
                                    border.width: 1
                                    Behavior on color { ColorAnimation { duration: 120 } }

                                    Text {
                                        anchors.centerIn: parent
                                        text: delegateItem.isConnecting ? "Conectando..." : "Conectar"
                                        font.family: Theme.font
                                        font.pixelSize: 9
                                        font.bold: true
                                        color: delegateItem.isConnecting ? Theme.amber
                                             : (btnHover.containsMouse ? Theme.bg : Theme.accent)
                                    }

                                    MouseArea {
                                        id: btnHover
                                        anchors.fill: parent
                                        hoverEnabled: !delegateItem.isConnecting
                                        cursorShape: delegateItem.isConnecting ? Qt.ArrowCursor : Qt.PointingHandCursor
                                        onClicked: {
                                            if (!delegateItem.isConnecting) {
                                                popup.tryConnect(modelData)
                                            }
                                        }
                                    }
                                }
                            }

                            // Columna de datos de la red (delimitada entre el ícono y el slot derecho)
                            Column {
                                anchors.left: netIconItem.right
                                anchors.leftMargin: 8
                                anchors.right: rightSlot.left
                                anchors.rightMargin: 8
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2
                                clip: true

                                Row {
                                    spacing: 4
                                    width: parent.width

                                    Text {
                                        text: modelData.name
                                        font.family: Theme.font
                                        font.pixelSize: 11
                                        font.bold: modelData.known || delegateItem.isConnecting
                                        color: delegateItem.isConnecting ? Theme.amber : (delegateItem.hovered ? Theme.accent : Theme.text)
                                        elide: Text.ElideRight
                                        maximumLineCount: 1
                                        width: Math.min(implicitWidth, parent.width - (modelData.known ? 45 : 0))
                                    }

                                    Text {
                                        visible: modelData.known
                                        text: "[SAVED]"
                                        font.family: Theme.font
                                        font.pixelSize: 7
                                        font.bold: true
                                        color: Theme.muted
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }

                                Row {
                                    spacing: 4
                                    Text {
                                        text: Math.round((modelData.signalStrength || 0) * 100) + "%"
                                        font.family: Theme.font
                                        font.pixelSize: 8
                                        color: delegateItem.isConnecting ? Theme.amber : Theme.muted
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                    Text {
                                        text: "·"
                                        font.family: Theme.font
                                        font.pixelSize: 8
                                        color: Theme.muted
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                    Text {
                                        text: delegateItem.isConnecting ? "Conectando..." : (modelData.known ? "Red guardada" : "Disponible")
                                        font.family: Theme.font
                                        font.pixelSize: 8
                                        color: delegateItem.isConnecting ? Theme.amber : Theme.muted
                                        anchors.verticalCenter: parent.verticalCenter
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
            }

            // ==========================================
            // VISTA 2: 02 // ESTADO (TELEMETRÍA MILITAR)
            // ==========================================
            Column {
                width: parent.width
                spacing: 8
                visible: popup.currentTab === "status"

                // TARJETA 1: ENLACE Y CONEXIÓN
                Rectangle {
                    id: linkCard
                    width: parent.width
                    implicitHeight: linkCol.implicitHeight + 16
                    radius: 0
                    color: "#0a140c"
                    border.color: Theme.separator
                    border.width: 1

                    // Esquinas tácticas iluminadas
                    Rectangle { width: 5; height: 1; color: Theme.border; anchors.top: parent.top; anchors.left: parent.left }
                    Rectangle { width: 1; height: 5; color: Theme.border; anchors.top: parent.top; anchors.left: parent.left }
                    Rectangle { width: 5; height: 1; color: Theme.border; anchors.top: parent.top; anchors.right: parent.right }
                    Rectangle { width: 1; height: 5; color: Theme.border; anchors.top: parent.top; anchors.right: parent.right }
                    Rectangle { width: 5; height: 1; color: Theme.border; anchors.bottom: parent.bottom; anchors.left: parent.left }
                    Rectangle { width: 1; height: 5; color: Theme.border; anchors.bottom: parent.bottom; anchors.left: parent.left }
                    Rectangle { width: 5; height: 1; color: Theme.border; anchors.bottom: parent.bottom; anchors.right: parent.right }
                    Rectangle { width: 1; height: 5; color: Theme.border; anchors.bottom: parent.bottom; anchors.right: parent.right }

                    Column {
                        id: linkCol
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 6

                        Row {
                            spacing: 6
                            Text { text: "󰌘"; font.family: Theme.font; font.pixelSize: 11; color: Theme.accent; anchors.verticalCenter: parent.verticalCenter }
                            Text { text: "ENLACE // CONEXIÓN INALÁMBRICA"; font.family: Theme.font; font.pixelSize: 8; font.bold: true; color: Theme.muted; anchors.verticalCenter: parent.verticalCenter }
                        }

                        Grid {
                            width: parent.width
                            columns: 2
                            spacing: 4

                            Text { text: "SSID actual:"; font.family: Theme.font; font.pixelSize: 9; color: Theme.muted }
                            Text { text: popup.telemetry.ssid; font.family: Theme.font; font.pixelSize: 9; font.bold: true; color: popup.telemetry.connected ? Theme.accent : Theme.text }

                            Text { text: "Banda / Frecuencia:"; font.family: Theme.font; font.pixelSize: 9; color: Theme.muted }
                            Text { text: popup.telemetry.freq; font.family: Theme.font; font.pixelSize: 9; color: Theme.text }

                            Text { text: "Nivel de Señal:"; font.family: Theme.font; font.pixelSize: 9; color: Theme.muted }
                            Text { text: popup.telemetry.signal_dbm; font.family: Theme.font; font.pixelSize: 9; color: Theme.accent }

                            Text { text: "Tasa de Transmisión:"; font.family: Theme.font; font.pixelSize: 9; color: Theme.muted }
                            Text { text: popup.telemetry.bitrate; font.family: Theme.font; font.pixelSize: 9; color: Theme.text }
                        }
                    }
                }

                // TARJETA 2: RED LOCAL IPV4
                Rectangle {
                    id: ipCard
                    width: parent.width
                    implicitHeight: ipCol.implicitHeight + 16
                    radius: 0
                    color: "#0a140c"
                    border.color: Theme.separator
                    border.width: 1

                    Rectangle { width: 5; height: 1; color: Theme.border; anchors.top: parent.top; anchors.left: parent.left }
                    Rectangle { width: 1; height: 5; color: Theme.border; anchors.top: parent.top; anchors.left: parent.left }
                    Rectangle { width: 5; height: 1; color: Theme.border; anchors.top: parent.top; anchors.right: parent.right }
                    Rectangle { width: 1; height: 5; color: Theme.border; anchors.top: parent.top; anchors.right: parent.right }
                    Rectangle { width: 5; height: 1; color: Theme.border; anchors.bottom: parent.bottom; anchors.left: parent.left }
                    Rectangle { width: 1; height: 5; color: Theme.border; anchors.bottom: parent.bottom; anchors.left: parent.left }
                    Rectangle { width: 5; height: 1; color: Theme.border; anchors.bottom: parent.bottom; anchors.right: parent.right }
                    Rectangle { width: 1; height: 5; color: Theme.border; anchors.bottom: parent.bottom; anchors.right: parent.right }

                    Column {
                        id: ipCol
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 6

                        Row {
                            spacing: 6
                            Text { text: "󰩠"; font.family: Theme.font; font.pixelSize: 11; color: Theme.accent; anchors.verticalCenter: parent.verticalCenter }
                            Text { text: "RED // ASIGNACIÓN LOCAL"; font.family: Theme.font; font.pixelSize: 8; font.bold: true; color: Theme.muted; anchors.verticalCenter: parent.verticalCenter }
                        }

                        Grid {
                            width: parent.width
                            columns: 2
                            spacing: 4

                            Text { text: "Dirección IPv4:"; font.family: Theme.font; font.pixelSize: 9; color: Theme.muted }
                            Text { text: popup.telemetry.ip; font.family: Theme.font; font.pixelSize: 9; font.bold: true; color: Theme.text }

                            Text { text: "Puerta de Enlace:"; font.family: Theme.font; font.pixelSize: 9; color: Theme.muted }
                            Text { text: popup.telemetry.gateway; font.family: Theme.font; font.pixelSize: 9; color: Theme.text }

                            Text { text: "Dirección MAC:"; font.family: Theme.font; font.pixelSize: 9; color: Theme.muted }
                            Text { text: popup.telemetry.mac; font.family: Theme.font; font.pixelSize: 9; color: Theme.text }
                        }
                    }
                }

                // TARJETA 3: HARDWARE Y CONTROLADOR
                Rectangle {
                    id: hwCard
                    width: parent.width
                    implicitHeight: hwCol.implicitHeight + 16
                    radius: 0
                    color: "#0a140c"
                    border.color: Theme.separator
                    border.width: 1

                    Rectangle { width: 5; height: 1; color: Theme.border; anchors.top: parent.top; anchors.left: parent.left }
                    Rectangle { width: 1; height: 5; color: Theme.border; anchors.top: parent.top; anchors.left: parent.left }
                    Rectangle { width: 5; height: 1; color: Theme.border; anchors.top: parent.top; anchors.right: parent.right }
                    Rectangle { width: 1; height: 5; color: Theme.border; anchors.top: parent.top; anchors.right: parent.right }
                    Rectangle { width: 5; height: 1; color: Theme.border; anchors.bottom: parent.bottom; anchors.left: parent.left }
                    Rectangle { width: 1; height: 5; color: Theme.border; anchors.bottom: parent.bottom; anchors.left: parent.left }
                    Rectangle { width: 5; height: 1; color: Theme.border; anchors.bottom: parent.bottom; anchors.right: parent.right }
                    Rectangle { width: 1; height: 5; color: Theme.border; anchors.bottom: parent.bottom; anchors.right: parent.right }

                    Column {
                        id: hwCol
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 6

                        Row {
                            spacing: 6
                            Text { text: "󰌢"; font.family: Theme.font; font.pixelSize: 11; color: Theme.accent; anchors.verticalCenter: parent.verticalCenter }
                            Text { text: "HARDWARE // DISPOSITIVO"; font.family: Theme.font; font.pixelSize: 8; font.bold: true; color: Theme.muted; anchors.verticalCenter: parent.verticalCenter }
                        }

                        Grid {
                            width: parent.width
                            columns: 2
                            spacing: 4

                            Text { text: "Interfaz:"; font.family: Theme.font; font.pixelSize: 9; color: Theme.muted }
                            Text { text: popup.telemetry.iface; font.family: Theme.font; font.pixelSize: 9; color: Theme.text }

                            Text { text: "Módulo Kernel:"; font.family: Theme.font; font.pixelSize: 9; color: Theme.muted }
                            Text { text: popup.telemetry.driver; font.family: Theme.font; font.pixelSize: 9; color: Theme.text }

                            Text { text: "Fix POM-2:"; font.family: Theme.font; font.pixelSize: 9; color: Theme.muted }
                            Text { text: "disable_lps_deep=Y"; font.family: Theme.font; font.pixelSize: 9; font.bold: true; color: Theme.accent }
                        }
                    }
                }

                // Botón Configuración Avanzada
                Rectangle {
                    width: parent.width
                    height: 28
                    radius: 0
                    color: setMouse.containsMouse ? "#142416" : "#0a130b"
                    border.color: setMouse.containsMouse ? Theme.accent : Theme.separator
                    border.width: 1

                    Row {
                        anchors.centerIn: parent
                        spacing: 6
                        Text { text: "󰒓"; font.family: Theme.font; font.pixelSize: 10; color: setMouse.containsMouse ? Theme.accent : Theme.muted }
                        Text { text: "CONFIGURACIÓN AVANZADA // NM-CONNECTION-EDITOR"; font.family: Theme.font; font.pixelSize: 9; font.bold: true; color: setMouse.containsMouse ? Theme.accent : Theme.text }
                    }

                    MouseArea {
                        id: setMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: settingsProc.exec(["nm-connection-editor"])
                    }
                }
            }
        }

        // ==========================================
        // PROMPT DE CONTRASEÑA FLOTANTE TÁCTICO
        // ==========================================
        Rectangle {
            id: pskPromptBox
            visible: popup.showPasswordPrompt
            anchors.fill: parent
            anchors.margins: 10
            color: "#0a140c"
            border.color: Theme.accent
            border.width: 1
            radius: 0
            opacity: popup.showPasswordPrompt ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 180 } }

            // Esquinas iluminadas
            Rectangle { width: 5; height: 1; color: Theme.accent; anchors.top: parent.top; anchors.left: parent.left }
            Rectangle { width: 1; height: 5; color: Theme.accent; anchors.top: parent.top; anchors.left: parent.left }
            Rectangle { width: 5; height: 1; color: Theme.accent; anchors.top: parent.top; anchors.right: parent.right }
            Rectangle { width: 1; height: 5; color: Theme.accent; anchors.top: parent.top; anchors.right: parent.right }
            Rectangle { width: 5; height: 1; color: Theme.accent; anchors.bottom: parent.bottom; anchors.left: parent.left }
            Rectangle { width: 1; height: 5; color: Theme.accent; anchors.bottom: parent.bottom; anchors.left: parent.left }
            Rectangle { width: 5; height: 1; color: Theme.accent; anchors.bottom: parent.bottom; anchors.right: parent.right }
            Rectangle { width: 1; height: 5; color: Theme.accent; anchors.bottom: parent.bottom; anchors.right: parent.right }

            Column {
                anchors.centerIn: parent
                spacing: 12
                width: parent.width - 28

                Row {
                    spacing: 6
                    Text { text: "󰌾"; font.family: Theme.font; font.pixelSize: 12; color: Theme.accent; anchors.verticalCenter: parent.verticalCenter }
                    Text { text: "AUTENTICACIÓN // RED SEGURA"; font.family: Theme.font; font.pixelSize: 9; font.bold: true; color: Theme.accent; anchors.verticalCenter: parent.verticalCenter }
                }

                Text {
                    text: popup.pendingNetwork ? "Introduce la clave de seguridad para conectar a <b>" + popup.pendingNetwork.name + "</b>:" : ""
                    font.family: Theme.font
                    font.pixelSize: 10
                    color: Theme.muted
                    wrapMode: Text.WordWrap
                    width: parent.width
                }

                Rectangle {
                    width: parent.width
                    height: 28
                    radius: 0
                    color: "#08100a"
                    border.color: pskInput.activeFocus ? Theme.accent : Theme.separator
                    border.width: 1

                    TextInput {
                        id: pskInput
                        anchors.fill: parent
                        anchors.margins: 6
                        echoMode: TextInput.Password
                        color: Theme.text
                        font.family: Theme.font
                        font.pixelSize: 11
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
                    anchors.horizontalCenter: parent.horizontalCenter

                    // Botón Conectar
                    Rectangle {
                        id: connectBtn
                        width: 90
                        height: 24
                        radius: 0
                        property bool hovered: false
                        color: hovered ? Theme.accent : "#102012"
                        border.color: Theme.accent
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: "Conectar"
                            font.family: Theme.font
                            font.pixelSize: 10
                            font.bold: true
                            color: connectBtn.hovered ? Theme.bg : Theme.accent
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
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
                        width: 90
                        height: 24
                        radius: 0
                        property bool hovered: false
                        color: "transparent"
                        border.color: hovered ? Theme.text : Theme.separator
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: "Cancelar"
                            font.family: Theme.font
                            font.pixelSize: 10
                            color: cancelBtn.hovered ? Theme.text : Theme.muted
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: cancelBtn.hovered = true
                            onExited:  cancelBtn.hovered = false
                            onClicked: {
                                popup.showPasswordPrompt = false
                                popup.pendingNetwork = null
                                pskInput.text = ""
                            }
                        }
                    }
                }
            }
        }
    }

    // Procesos de comandos
    Process { id: rescanProc }
    Process { id: disconnectProc }
    Process { id: settingsProc }

    Process {
        id: telemetryProc
        command: ["/home/emn/.config/quickshell/modules/popups/network_telemetry.py"]
        stdout: StdioCollector { id: telemCollector }
        onExited: {
            try {
                let data = JSON.parse(telemCollector.value)
                if (data) {
                    popup.telemetry = data
                }
            } catch (e) {}
        }
    }
}