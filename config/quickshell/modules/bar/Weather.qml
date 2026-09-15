import Quickshell.Io
import QtQuick

Row {
    spacing: 3
    height: 26

    Text {
        id: weatherTemp
        text: "..."
        color: "#b8d4bc"
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 12
        anchors.verticalCenter: parent.verticalCenter
    }

    Text {
        id: weatherIcon
        text: ""
        color: "#b8d4bc"
        font.family: "POM2Icons"
        font.pixelSize: 12
        anchors.verticalCenter: parent.verticalCenter
    }

    Process {
        id: weatherProcess
        command: ["curl", "-s", "https://wttr.in/Puebla?format=%25t+%25C"]
        stdout: StdioCollector { id: weatherCollector }
        onExited: {
            let raw = weatherCollector.text.trim()
            if (!raw) return
            let clean = raw.replace("+", "")
            let parts = clean.split(" ")
            weatherTemp.text = parts[0]
            let condition = parts.slice(1).join(" ").toLowerCase()
            let icon = "\ue900"
            if (condition.includes("sunny") || condition.includes("clear")) icon = "\ue9c8"
            else if (condition.includes("cloud") || condition.includes("overcast")) icon = "\ue919"
            else if (condition.includes("rain") || condition.includes("drizzle") || condition.includes("shower") || condition.includes("snow")) icon = "\ue91a"
            else if (condition.includes("thunder") || condition.includes("storm")) icon = "\ue97e"
            weatherIcon.text = icon
        }
    }

    Timer {
        interval: 300000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: weatherProcess.running = true
    }
}