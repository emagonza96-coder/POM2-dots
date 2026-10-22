import Quickshell
import Quickshell.Hyprland
import QtQuick
import "../.."

Row {
    anchors.centerIn: parent
    spacing: 6

    Repeater {
        model: {
            let wss = []
            for (let i = 0; i < Hyprland.workspaces.values.length; i++) {
                wss.push(Hyprland.workspaces.values[i])
            }
            return wss.sort((a, b) => a.id - b.id)
        }

        delegate: Item {
            required property var modelData
            width: wsLabel.width + 10
            height: 20

            property bool isFocused: Hyprland.focusedWorkspace?.id === modelData.id
            property bool hovered: false

            // Underline indicator para el workspace activo
            Rectangle {
                id: indicator
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                height: 2
                width: isFocused ? parent.width * 0.7 : 0
                radius: 1
                color: Theme.accent
                Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            }

            Text {
                id: wsLabel
                anchors.centerIn: parent
                text: modelData.id.toString()
                font.family: Theme.font
                font.pixelSize: 13
                font.bold: isFocused
                color: isFocused ? Theme.accent : (hovered ? Theme.text : Theme.muted)
                scale: isFocused ? 1.08 : 1.0
                Behavior on color { ColorAnimation { duration: 180 } }
                Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack } }
            }

            // Animación de click
            SequentialAnimation {
                id: clickAnim
                NumberAnimation { target: wsLabel; property: "scale"; to: 0.80; duration: 80;  easing.type: Easing.InQuad  }
                NumberAnimation { target: wsLabel; property: "scale"; to: isFocused ? 1.08 : 1.0; duration: 200; easing.type: Easing.OutElastic }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onEntered: hovered = true
                onExited:  hovered = false
                onClicked: {
                    clickAnim.start()
                    Hyprland.dispatch("workspace " + modelData.id)
                }
            }
        }
    }
}