import Quickshell
import Quickshell.Networking
import QtQuick

PopupWindow {
   id: popup
   property var parentAnchor
   anchor.item: parentAnchor
   anchor.edges: Edges.Bottom
   implicitWidth: 260
   implicitHeight: Math.min(list.count * 30 + 16, 300)
   color: "#0e180f"

   ListView {
       id: list
       anchors.fill: parent
       anchors.margins: 8
       spacing: 2
       model: {
           let nets = []
           Networking.devices.values.forEach(d => d.networks.values.forEach(n => nets.push(n)))
           return nets
       }
       delegate: Rectangle {
           required property var modelData
           width: list.width; height: 28
           radius: 6
           color: modelData.connected ? "#1e2e1f" : "transparent"
           border.color: modelData.connected ? "#4e9e5a" : "transparent"
           Text {
               anchors.verticalCenter: parent.verticalCenter
               anchors.left: parent.left; anchors.leftMargin: 8
               text: modelData.ssid + (modelData.connected ? "  ✓" : "")
               color: "#b8d4bc"
               font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12
           }
           MouseArea {
               anchors.fill: parent
               onClicked: modelData.connect()
           }
       }
   }
}