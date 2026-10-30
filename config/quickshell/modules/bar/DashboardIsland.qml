import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import "../.."

Item {
    id: islandRoot
    height: 26
    implicitHeight: 26
    width: Math.min(contentRow.implicitWidth, 460)
    implicitWidth: Math.min(contentRow.implicitWidth, 460)

    signal clicked()
    property bool dashboardOpen: false
    readonly property bool hovered: mouseArea.containsMouse

    // ==========================================
    // 1. ESTADO DEL AGENTE DE IA (ANTIGRAVITY / ENTRATI)
    // ==========================================
    property string agentState: "idle"
    property bool agentActive: false
    property string agentTool: ""
    property string agentTarget: ""
    property string agentDetail: ""
    property var agentHistory: []
    readonly property bool isAgentWorking: agentActive || agentState === "thinking" || agentState === "working"

    // Toast temporal al finalizar tarea
    property bool taskFinishedToast: false
    property int finishToastCounter: 0

    function triggerFinishedToast() {
        taskFinishedToast = true
        finishToastCounter = 5
        finishCountdownTimer.restart()
    }

    Timer {
        id: finishCountdownTimer
        interval: 1000
        repeat: true
        onTriggered: {
            islandRoot.finishToastCounter--
            if (islandRoot.finishToastCounter <= 0) {
                islandRoot.taskFinishedToast = false
                finishCountdownTimer.stop()
            }
        }
    }

    Process {
        id: agentProc
        command: ["cat", "/run/user/1000/pom2-agent.json"]
        stdout: StdioCollector { id: agentCollector }
        onExited: {
            try {
                let d = JSON.parse(agentCollector.text.trim())
                let prevState = islandRoot.agentState
                islandRoot.agentState = d.state || "idle"
                islandRoot.agentActive = !!d.active
                islandRoot.agentTool = d.tool || ""
                islandRoot.agentTarget = d.target || ""
                islandRoot.agentDetail = d.detail || ""
                islandRoot.agentHistory = d.history || []

                // Si transitó a finished, encender el toast de éxito
                if (d.state === "finished" && prevState !== "finished" && !islandRoot.taskFinishedToast) {
                    islandRoot.triggerFinishedToast()
                }
            } catch(e) {}
        }
    }

    Timer {
        id: agentPollTimer
        interval: islandRoot.isAgentWorking ? 600 : 1500
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!agentProc.running) agentProc.running = true
        }
    }

    // ==========================================
    // 2. MONITOR DE NOTIFICACIONES (SWAYNC)
    // ==========================================
    property int unreadCount: 0
    property bool notifBounce: false

    function triggerNotifBounce() {
        bounceAnim.restart()
    }

    SequentialAnimation {
        id: bounceAnim
        NumberAnimation { target: avatarIcon; property: "scale"; to: 1.35; duration: 120; easing.type: Easing.OutBack }
        NumberAnimation { target: avatarIcon; property: "scale"; to: 1.0; duration: 180; easing.type: Easing.OutElastic }
    }

    Process {
        id: swayncCountProc
        command: ["swaync-client", "-c"]
        stdout: StdioCollector { id: swayncCollector }
        onExited: {
            let count = parseInt(swayncCollector.text.trim()) || 0
            if (count > islandRoot.unreadCount && islandRoot.unreadCount >= 0) {
                islandRoot.triggerNotifBounce()
            }
            islandRoot.unreadCount = count
        }
    }

    Timer {
        id: swayncPollTimer
        interval: 2500
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!swayncCountProc.running) swayncCountProc.running = true
        }
    }

    // ==========================================
    // 3. MEDIOS (SPOTIFY REACTIVO VÍA MPRIS)
    // ==========================================
    function isSpotify(p) {
        if (!p) return false
        let id = String(p.identity || "").toLowerCase()
        let de = String(p.desktopEntry || "").toLowerCase()
        return id.includes("spotify") || de.includes("spotify")
    }

    readonly property var activePlayer: {
        if (!Mpris.players || !Mpris.players.values) return null
        return Mpris.players.values.find(p => p && islandRoot.isSpotify(p) && p.playbackState === MprisPlaybackState.Playing)
            || Mpris.players.values.find(p => p && islandRoot.isSpotify(p) && p.trackTitle && p.trackTitle.length > 0)
            || null
    }

    readonly property bool hasMedia: activePlayer ? (activePlayer.playbackState === MprisPlaybackState.Playing || (activePlayer.trackTitle && activePlayer.trackTitle.length > 0)) : false
    readonly property bool isPlaying: activePlayer ? (activePlayer.playbackState === MprisPlaybackState.Playing) : false
    readonly property string mediaTitle: activePlayer ? (activePlayer.trackTitle || "") : ""
    readonly property string mediaArtist: activePlayer ? (activePlayer.trackArtist || (activePlayer.trackArtists && activePlayer.trackArtists.length > 0 ? activePlayer.trackArtists[0] : "")) : ""
    readonly property string mediaDisplay: {
        if (!hasMedia) return ""
        if (mediaArtist !== "" && mediaTitle !== "") return mediaArtist + " - " + mediaTitle
        return mediaTitle !== "" ? mediaTitle : mediaArtist
    }

    // ==========================================
    // 4. ALTERNANCIA CÍCLICA (4 SEGUNDOS)
    // ==========================================
    property bool cycleShowMedia: false

    Timer {
        id: cycleTimer
        interval: 4000
        running: islandRoot.hasMedia && islandRoot.isAgentWorking && !islandRoot.taskFinishedToast
        repeat: true
        onTriggered: {
            islandRoot.cycleShowMedia = !islandRoot.cycleShowMedia
        }
    }

    Behavior on width {
        NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
    }

    // ==========================================
    // 5. RENDERIZADO VISUAL HUD
    // ==========================================
    Row {
        id: contentRow
        anchors.centerIn: parent
        spacing: 6

        // SLOT DEL AVATAR TÁCTICO (EL OJO DE ENTRATI / MASCOTA RETRO)
        Text {
            id: avatarIcon
            font.family: Theme.font
            font.pixelSize: Theme.fontSizeLg
            anchors.verticalCenter: parent.verticalCenter

            text: {
                if (islandRoot.taskFinishedToast) return "󰄬"
                if (islandRoot.isAgentWorking) {
                    if (islandRoot.cycleShowMedia && islandRoot.hasMedia) {
                        return islandRoot.isPlaying ? "󰓇" : "󰏤"
                    }
                    // El Ojo de Entrati (Void Reticle de Warframe)
                    return "󰈈"
                }
                if (islandRoot.hasMedia) {
                    return islandRoot.isPlaying ? "󰓇" : "󰏤"
                }
                return "󰍛"
            }

            color: {
                if (islandRoot.taskFinishedToast) return Theme.accent
                if (islandRoot.isAgentWorking) {
                    if (islandRoot.cycleShowMedia && islandRoot.hasMedia) return Theme.accent
                    return (islandRoot.agentState === "thinking") ? Theme.amber : Theme.accent
                }
                if (islandRoot.hovered || islandRoot.dashboardOpen) return Theme.accent
                if (islandRoot.hasMedia) return Theme.accent
                return Theme.text
            }

            Behavior on color { ColorAnimation { duration: 150 } }
        }

        // TEXTO PRINCIPAL DE TELEMETRÍA
        Text {
            id: mainLabel
            font.family: Theme.font
            font.pixelSize: Theme.fontSizeLg
            anchors.verticalCenter: parent.verticalCenter
            elide: Text.ElideRight
            maximumLineCount: 1
            width: Math.min(implicitWidth, 380)

            text: {
                if (islandRoot.taskFinishedToast) {
                    return "AGY // TAREA COMPLETADA"
                }
                if (islandRoot.isAgentWorking) {
                    if (islandRoot.cycleShowMedia && islandRoot.hasMedia) {
                        return islandRoot.mediaDisplay
                    }
                    let toolName = islandRoot.agentTool !== "" ? islandRoot.agentTool.toUpperCase() : "WORKING"
                    if (islandRoot.agentTarget !== "") {
                        return "AGY // " + toolName + ": " + islandRoot.agentTarget
                    }
                    return "AGY // " + toolName
                }
                if (islandRoot.hasMedia) {
                    return islandRoot.mediaDisplay
                }
                return islandRoot.hovered ? "POM-2 // DASHBOARD" : "POM-2 // HUD"
            }

            color: {
                if (islandRoot.taskFinishedToast) return Theme.accent
                if (islandRoot.isAgentWorking) {
                    return (islandRoot.agentState === "thinking") ? Theme.amber : Theme.text
                }
                if (islandRoot.hovered || islandRoot.dashboardOpen) return Theme.accent
                return Theme.text
            }

            Behavior on color { ColorAnimation { duration: 150 } }
        }

        // BADGE DE NOTIFICACIONES PENDIENTES (SWAYNC)
        Row {
            visible: islandRoot.unreadCount > 0 && !islandRoot.taskFinishedToast
            spacing: 4
            anchors.verticalCenter: parent.verticalCenter

            Text {
                font.family: Theme.font
                font.pixelSize: 10
                font.bold: true
                color: Theme.separator
                text: "|"
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                font.family: Theme.font
                font.pixelSize: 10
                font.bold: true
                color: Theme.amber
                text: "󰂚 " + islandRoot.unreadCount
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    // ==========================================
    // 6. INTERACCIÓN DE ENTRADA (CLIC CENTRAL HUD)
    // ==========================================
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: islandRoot.clicked()
    }
}
