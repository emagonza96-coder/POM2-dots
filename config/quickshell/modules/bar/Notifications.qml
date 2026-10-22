import Quickshell
import Quickshell.Io
import QtQuick
import "../.."

Item {
    id: notifRoot
    width: row.width
    height: 26

    Row {
        id: row
        spacing: 3
        anchors.verticalCenter: parent.verticalCenter

        Text {
            id: notifIcon
            font.family: Theme.iconFont
            font.pixelSize: Theme.fontSizeLg
            color: Theme.text
            text: "\ue967"
            anchors.verticalCenter: parent.verticalCenter
            Behavior on color { ColorAnimation { duration: 200 } }
        }

        Text {
            id: notifCount
            font.family: Theme.font
            font.pixelSize: Theme.fontSizeLg
            color: Theme.amber
            visible: opacity > 0
            opacity: 0
            anchors.verticalCenter: parent.verticalCenter
            Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutQuad } }
        }
    }

    // Animación de pulso al llegar notificaciones nuevas
    SequentialAnimation {
        id: bounceAnim
        NumberAnimation { target: notifIcon; property: "scale"; to: 1.3; duration: 120; easing.type: Easing.OutBack }
        NumberAnimation { target: notifIcon; property: "scale"; to: 1.0; duration: 180; easing.type: Easing.OutElastic }
    }

    // Click: escala de presión
    SequentialAnimation {
        id: pressAnim
        NumberAnimation { target: notifRoot; property: "scale"; to: 0.88; duration: 80;  easing.type: Easing.InQuad  }
        NumberAnimation { target: notifRoot; property: "scale"; to: 1.0;  duration: 150; easing.type: Easing.OutBack }
    }

    Process {
        id: toggleProc
        command: ["swaync-client", "-t", "-sw"]
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            pressAnim.start()
            toggleProc.running = true
            refreshTimer.restart()
        }
    }

    Timer {
        id: refreshTimer
        interval: 200
        repeat: false
        onTriggered: {
            if (!swayncCount.running) swayncCount.running = true
        }
    }

    property int previousCount: 0

    Process {
        id: swayncCount
        command: ["swaync-client", "-c"]
        stdout: StdioCollector { id: notifCollector }
        onExited: {
            let count = parseInt(notifCollector.text.trim()) || 0
            let hasNew = count > notifRoot.previousCount && notifRoot.previousCount >= 0
            notifRoot.previousCount = count
            if (count > 0) {
                notifIcon.text     = "\ue920"
                notifIcon.color    = Theme.amber
                notifCount.text    = count.toString()
                notifCount.opacity = 1
                if (hasNew) bounceAnim.restart()
            } else {
                notifIcon.text     = "\ue91f"
                notifIcon.color    = Theme.text
                notifCount.opacity = 0
            }
        }
    }

    Timer {
        interval: 2500
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!swayncCount.running) swayncCount.running = true
        }
    }
}