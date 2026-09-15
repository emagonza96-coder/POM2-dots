import Quickshell
import Quickshell.Wayland
import QtQuick
import "modules/bar"
import "."

PanelWindow {
    id: root
    anchors.top: true
    anchors.left: true
    anchors.right: true
    implicitHeight: 26
    color: "#0e180f"

    Row {
        id: barLeft
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: 18
        spacing: 12

        Clock {}
        Weather {}
    }

    Workspace {}

    Row {
        id: barRight
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.rightMargin: 18
        spacing: 12

        
        Volume {}
        Battery {}
        Network {}
        Notifications {}
    }
}