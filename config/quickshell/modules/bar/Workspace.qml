import Quickshell
import Quickshell.Hyprland
import QtQuick

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

        delegate: Text {
            required property var modelData
            text: modelData.id.toString()
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 13
            font.bold: Hyprland.focusedWorkspace?.id === modelData.id
            color: Hyprland.focusedWorkspace?.id === modelData.id ? "#6abf74" : "#5a7a5e"

            MouseArea {
                anchors.fill: parent
                onClicked: Hyprland.dispatch("workspace " + modelData.id)
            }
        }
    }
}