import Quickshell
import Quickshell.Networking
import QtQuick
import "../.."
import "../popups"

Item {
    id: netRoot
    width: expanded ? expandedRow.implicitWidth : collapsed.implicitWidth
    height: 26
    property bool expanded: false
    property bool hovered: false

    property var activeDevice: Networking.devices.values.find(d => d && d.networks && d.networks.values && d.networks.values.some(n => n && n.connected))
    property var activeNet: (activeDevice && activeDevice.networks && activeDevice.networks.values) ? activeDevice.networks.values.find(n => n && n.connected) : null
    property int strength: activeNet && activeNet.signalStrength ? Math.round(activeNet.signalStrength * 100) : 100

    readonly property bool isConnecting: {
        if (networkPopup && networkPopup.connectingSsid !== "") return true
        for (let i = 0; i < Networking.devices.values.length; i++) {
            let d = Networking.devices.values[i]
            if (d && d.state === ConnectionState.Connecting) return true
            if (d && d.networks && d.networks.values) {
                for (let j = 0; j < d.networks.values.length; j++) {
                    let n = d.networks.values[j]
                    if (n && (n.state === ConnectionState.Connecting || (n.stateChanging && !n.connected))) return true
                }
            }
        }
        return false
    }

    readonly property string connectingName: {
        if (networkPopup && networkPopup.connectingSsid !== "") return networkPopup.connectingSsid
        for (let i = 0; i < Networking.devices.values.length; i++) {
            let d = Networking.devices.values[i]
            if (d && d.networks && d.networks.values) {
                for (let j = 0; j < d.networks.values.length; j++) {
                    let n = d.networks.values[j]
                    if (n && (n.state === ConnectionState.Connecting || (n.stateChanging && !n.connected))) return n.name
                }
            }
        }
        return ""
    }

    Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

    // Ícono colapsado
    Row {
        id: collapsed
        visible: !netRoot.expanded
        opacity: netRoot.expanded ? 0 : 1
        spacing: 4
        anchors.verticalCenter: parent.verticalCenter
        Behavior on opacity { NumberAnimation { duration: 120 } }

        SequentialAnimation on opacity {
            running: netRoot.isConnecting && !netRoot.expanded
            loops: Animation.Infinite
            NumberAnimation { to: 0.35; duration: 500; easing.type: Easing.InOutQuad }
            NumberAnimation { to: 1.0; duration: 500; easing.type: Easing.InOutQuad }
        }

        Item {
            width: 14; height: 14
            anchors.verticalCenter: parent.verticalCenter

            Text {
                anchors.centerIn: parent
                visible: !netRoot.isConnecting
                font.family: Theme.iconFont; font.pixelSize: 14
                color: netRoot.hovered ? Theme.accent : (netRoot.activeNet ? Theme.accent : Theme.muted)
                text: netRoot.activeNet ? "\ue9e7" : "\ue9e8"
                Behavior on color { ColorAnimation { duration: 150 } }
            }

            Text {
                id: colIconSpin
                anchors.centerIn: parent
                visible: netRoot.isConnecting
                font.family: Theme.font; font.pixelSize: 12
                color: Theme.amber
                text: "󰑐"
                transformOrigin: Item.Center

                NumberAnimation on rotation {
                    running: netRoot.isConnecting && !netRoot.expanded
                    from: 0; to: 360; duration: 1000; loops: Animation.Infinite
                    onRunningChanged: { if (!running) colIconSpin.rotation = 0 }
                }
            }
        }
    }

    // Vista expandida
    Row {
        id: expandedRow
        visible: netRoot.expanded
        opacity: netRoot.expanded ? 1 : 0
        spacing: 6
        anchors.verticalCenter: parent.verticalCenter
        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutQuad } }

        Item {
            width: 14; height: 14
            anchors.verticalCenter: parent.verticalCenter

            Text {
                anchors.centerIn: parent
                visible: !netRoot.isConnecting
                font.family: Theme.iconFont; font.pixelSize: 14
                color: netRoot.activeNet ? Theme.accent : Theme.muted
                text: netRoot.activeNet ? "\ue9e7" : "\ue9e8"
            }

            Text {
                id: expIconSpin
                anchors.centerIn: parent
                visible: netRoot.isConnecting
                font.family: Theme.font; font.pixelSize: 12
                color: Theme.amber
                text: "󰑐"
                transformOrigin: Item.Center

                NumberAnimation on rotation {
                    running: netRoot.isConnecting && netRoot.expanded
                    from: 0; to: 360; duration: 1000; loops: Animation.Infinite
                    onRunningChanged: { if (!running) expIconSpin.rotation = 0 }
                }
            }
        }

        Text {
            font.family: Theme.font; font.pixelSize: Theme.fontSizeLg
            color: netRoot.isConnecting ? Theme.amber : Theme.text
            text: netRoot.isConnecting
                  ? (netRoot.connectingName !== "" ? "Conectando a " + netRoot.connectingName + "..." : "Conectando...")
                  : ((netRoot.activeNet ? netRoot.activeNet.name : "Sin red") + (netRoot.activeNet ? " · " + netRoot.strength + "%" : ""))
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: { netRoot.hovered = true;  netRoot.expanded = true  }
        onExited:  { netRoot.hovered = false; netRoot.expanded = false }
        onClicked: networkPopup.visible = !networkPopup.visible
    }

    NetworkPopup {
        id: networkPopup
        visible: false
        parentAnchor: netRoot
    }
}