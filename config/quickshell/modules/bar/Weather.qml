import Quickshell.Io
import QtQuick
import "../.."

Row {
    spacing: 3
    height: 26
    opacity: weatherTemp.text === "..." ? 0.4 : 1.0
    Behavior on opacity { NumberAnimation { duration: 400 } }

    Text {
        id: weatherTemp
        text: "..."
        color: Theme.text
        font.family: Theme.font
        font.pixelSize: Theme.fontSizeLg
        anchors.verticalCenter: parent.verticalCenter
    }

    Text {
        id: weatherIcon
        text: ""
        color: Theme.text
        font.family: Theme.iconFont
        font.pixelSize: Theme.fontSizeLg
        anchors.verticalCenter: parent.verticalCenter
    }

    Process {
        id: weatherProcess
        command: ["curl", "-s", "https://wttr.in/Puebla?format=%25t+%25C"]
        stdout: StdioCollector { id: weatherCollector }
        onExited: {
            let raw = weatherCollector.text.trim()
            if (!raw) return
            let clean = raw.replace(/\+/g, "")
            let parts = clean.split(" ")
            weatherTemp.text = parts[0]
            let condition = parts.slice(1).join(" ").toLowerCase()
            let icon = "\ue900"
            if (condition.includes("sunny") || condition.includes("clear"))        icon = "\ue9c8"
            else if (condition.includes("cloud") || condition.includes("overcast")) icon = "\ue919"
            else if (condition.includes("rain") || condition.includes("drizzle") ||
                     condition.includes("shower") || condition.includes("snow"))    icon = "\ue91a"
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