import Quickshell.Io
import QtQuick
import "../popups"

Item {
    id: volWrapper
    width: volRow.width
    height: 26

    Row {
        id: volRow
        spacing: 3
        height: 26
        anchors.verticalCenter: parent.verticalCenter

        Text {
            id: volIcon
            font.family: "POM2Icons"
            font.pixelSize: 12
            color: "#b8d4bc"
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            id: volText
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 12
            color: "#b8d4bc"
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    Process {
        id: volProcess
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        stdout: StdioCollector { id: volCollector }
        onExited: {
            let clean = volCollector.text.replace("Volume:", "").trim()
            if (clean.includes("[MUTED]")) {
                volIcon.text = "\ue9bf"
                volIcon.color = "#5a7a5e"
                volText.color = "#5a7a5e"
            } else {
                let vol = Math.round(parseFloat(clean) * 100)
                volIcon.text = "\ue9c0"
                volText.text = vol + "%"
                volIcon.color = "#b8d4bc"
                volText.color = "#b8d4bc"
            }
        }
    }

    Timer {
        interval: 800
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: volProcess.running = true
    }

    MouseArea {
        anchors.fill: parent
        onClicked: volumePopup.visible = !volumePopup.visible
    }

    VolumePopup {
        id: volumePopup
        visible: false
        parentAnchor: volWrapper
    }
}