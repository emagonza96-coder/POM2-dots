import Quickshell
import Quickshell.Wayland
import QtQuick
import "modules/bar"
import "modules/popups"
import "."

PanelWindow {
    id: root
    anchors.top: true
    anchors.left: true
    anchors.right: true
    implicitHeight: 26
    color: Theme.surface

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

        // TODO: Control Center (pendiente de implementar)
        Item {
            id: ccButton
            width: 20
            height: 20

            property bool hovered: false

            transform: Scale {
                origin.x: ccButton.width / 2
                origin.y: ccButton.height / 2
                xScale: ccButton.hovered ? 1.18 : 1.0
                yScale: ccButton.hovered ? 1.18 : 1.0
                Behavior on xScale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
                Behavior on yScale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
            }

            Text {
                anchors.centerIn: parent
                text: "\ue9d3"
                font.family: Theme.iconFont
                font.pixelSize: 14
                color: ccButton.hovered ? Theme.accent : Theme.text
                Behavior on color { ColorAnimation { duration: 150 } }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onEntered: ccButton.hovered = true
                onExited:  ccButton.hovered = false
                // TODO: onClicked: controlCenter.visible = !controlCenter.visible
            }
        }
    }
}