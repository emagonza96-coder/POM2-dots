import Quickshell
import Quickshell.Networking
import QtQuick
import "../popups"

Item {
   id: netRoot
   width: expanded ? expandedRow.width : collapsed.width
   height: 22
   property bool expanded: false

   property var activeDevice: Networking.devices.values.find(d => d.networks.values.some(n => n.connected))
   property var activeNet: activeDevice ? activeDevice.networks.values.find(n => n.connected) : null
   property int strength: activeNet && activeNet.signalStrength ? Math.round(activeNet.signalStrength * 100) : 100

   Behavior on width { NumberAnimation { duration: 120 } }

   Row {
       id: collapsed
       visible: !netRoot.expanded
       spacing: 4
       anchors.verticalCenter: parent.verticalCenter
       Text {
           font.family: "POM2Icons"; font.pixelSize: 14; color: "#6abf74"
           text: netRoot.activeNet ? "\ue9e7" : "\ue9e8"
           anchors.verticalCenter: parent.verticalCenter
       }
   }

   Row {
       id: expandedRow
       visible: netRoot.expanded
       spacing: 6
       anchors.verticalCenter: parent.verticalCenter
       Text {
           font.family: "POM2Icons"; font.pixelSize: 14; color: "#6abf74"
           text: "\ue9e7"
           anchors.verticalCenter: parent.verticalCenter
       }
       Text {
           font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12; color: "#b8d4bc"
           text: (netRoot.activeNet ? netRoot.activeNet.ssid : "Sin red") + " · " + netRoot.strength + "%"
           anchors.verticalCenter: parent.verticalCenter
       }
   }

   MouseArea {
       anchors.fill: parent
       hoverEnabled: true
       onEntered: netRoot.expanded = true
       onExited: netRoot.expanded = false
       onClicked: networkPopup.visible = !networkPopup.visible
   }

   NetworkPopup {
       id: networkPopup
       visible: false
       parentAnchor: netRoot
   }
}