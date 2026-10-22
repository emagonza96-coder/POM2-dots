import Quickshell.Io
import QtQuick
import "../.."
import "../popups"

Item {
    id: volWrapper
    width: volRow.width
    height: 26
    property bool hovered: false

    // Estado del audio
    property string deviceIcon: "󰓃"
    property string volumeIcon: "󰕾"
    property string volumeText: "100%"
    property bool isMuted: false
    property bool isOccupied: false
    property bool isPlaying: false
    property string activeApp: ""

    Row {
        id: volRow
        spacing: 4
        height: 26
        anchors.verticalCenter: parent.verticalCenter

        // Ícono de la salida actual (Bocinas / Audífonos / Bluetooth)
        Text {
            id: devIconText
            font.family: Theme.font
            font.pixelSize: Theme.fontSizeLg
            text: volWrapper.deviceIcon
            color: volWrapper.isMuted ? Theme.muted : (volWrapper.hovered || volWrapper.isPlaying ? Theme.accent : Theme.text)
            anchors.verticalCenter: parent.verticalCenter
            Behavior on color { ColorAnimation { duration: 150 } }
        }

        // Ícono de nivel de volumen según qué tanto volumen tiene
        Text {
            id: volIconText
            font.family: Theme.font
            font.pixelSize: Theme.fontSizeLg
            text: volWrapper.volumeIcon
            color: volWrapper.isMuted ? Theme.muted : (volWrapper.hovered || volWrapper.isPlaying ? Theme.accent : Theme.text)
            anchors.verticalCenter: parent.verticalCenter
            Behavior on color { ColorAnimation { duration: 150 } }
        }

        // Porcentaje de volumen
        Text {
            id: volText
            font.family: Theme.font
            font.pixelSize: Theme.fontSizeLg
            text: volWrapper.isMuted ? "MUTED" : volWrapper.volumeText
            color: volWrapper.isMuted ? Theme.muted : (volWrapper.hovered || volWrapper.isPlaying ? Theme.accent : Theme.text)
            anchors.verticalCenter: parent.verticalCenter
            Behavior on color { ColorAnimation { duration: 150 } }
        }

        // Indicador de app activa ocupando la salida
        Rectangle {
            id: activeDot
            width: 5
            height: 5
            radius: 2.5
            color: Theme.accent
            anchors.verticalCenter: parent.verticalCenter
            visible: volWrapper.isOccupied
            opacity: volWrapper.isPlaying ? 1.0 : 0.4

            // Pulso suave cuando una aplicación está reproduciendo
            SequentialAnimation on opacity {
                running: volWrapper.isPlaying
                loops: Animation.Infinite
                NumberAnimation { to: 0.3; duration: 900; easing.type: Easing.InOutQuad }
                NumberAnimation { to: 1.0; duration: 900; easing.type: Easing.InOutQuad }
            }
        }
    }

    Process {
        id: volProcess
        command: ["/home/emn/.config/quickshell/modules/popups/audio_ctl.py", "status"]
        stdout: StdioCollector { id: volCollector }
        onExited: {
            try {
                let data = JSON.parse(volCollector.text)
                if (data.master) {
                    volWrapper.isMuted = Boolean(data.master.muted)
                    volWrapper.deviceIcon = data.master.deviceIcon || "󰓃"
                    volWrapper.volumeIcon = data.master.volumeIcon || (volWrapper.isMuted ? "󰖁" : "󰕾")
                    volWrapper.volumeText = Math.round(data.master.volume * 100) + "%"
                    volWrapper.isOccupied = Boolean(data.master.isOccupied)
                    volWrapper.isPlaying = Boolean(data.master.isPlaying)
                    volWrapper.activeApp = data.master.activeApp || ""
                }
            } catch (e) {
                // Ignore parse errors on transient chunks
            }
        }
    }

    Timer {
        interval: 2500
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!volProcess.running) volProcess.running = true
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: {
            volWrapper.hovered = true
            volQuickTimer.restart()
        }
        onExited:  volWrapper.hovered = false
        onClicked: volumePopup.visible = !volumePopup.visible
        // Scroll para ajustar volumen rápidamente
        onWheel: (wheel) => {
            let delta = wheel.angleDelta.y > 0 ? "5%+" : "5%-"
            scrollVolProc.exec(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", delta])
            volQuickTimer.restart()
        }
    }

    Timer {
        id: volQuickTimer
        interval: 50
        repeat: false
        onTriggered: {
            if (!volProcess.running) volProcess.running = true
        }
    }

    Process { id: scrollVolProc }

    VolumePopup {
        id: volumePopup
        visible: false
        parentAnchor: volWrapper
    }
}