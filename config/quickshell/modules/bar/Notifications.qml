import Quickshell
import Quickshell.Io
import QtQuick

Item {
    width: row.width
    height: 26

    Row {
        id: row
        spacing: 3
        anchors.verticalCenter: parent.verticalCenter

        Text {
            id: notifIcon
            font.family: "POM2Icons"
            font.pixelSize: 12
            color: "#b8d4bc"
            text: "\ue967"
            anchors.verticalCenter: parent.verticalCenter

        }

        Text {
            id: notifCount
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 12
            color: "#c8a86a"
            visible: false
            anchors.verticalCenter: parent.verticalCenter

        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            var proc = Qt.createQmlObject('import Quickshell; import Quickshell.Io; Process { command: ["swaync-client", "-t", "-sw"] }', parent)
            proc.running = true
        }
    }

    Process {
        id: swayncCount
        command: ["bash", "-c", "swaync-client --count 2>/dev/null || echo 0"]
        stdout: StdioCollector { id: notifCollector }
        onExited: {
            let count = notifCollector.text.trim()
            if (count !== "0" && count !== "") {
                notifIcon.text = "\ue920"
                notifIcon.color = "#c8a86a"
                notifCount.text = count
                notifCount.visible = true
            } else {
                notifIcon.text = "\ue91f"
                notifIcon.color = "#b8d4bc"
                notifCount.visible = false
            }
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: swayncCount.running = true
    }
}