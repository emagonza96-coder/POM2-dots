import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Layouts
import "../.."

PopupWindow {
    id: popup
    property var parentAnchor
    property var rootWindow: null

    anchor.window: rootWindow
    anchor.rect.x: rootWindow ? Math.round((rootWindow.width / 2) - (popup.implicitWidth / 2)) : 0
    anchor.rect.y: rootWindow ? rootWindow.height : 0
    anchor.item: rootWindow ? null : parentAnchor
    anchor.edges: rootWindow ? 0 : Edges.Bottom

    implicitWidth: 480
    implicitHeight: 330
    color: "transparent"
    grabFocus: true

    // Integración reactiva con MPRIS exclusivamente para Spotify
    function isSpotify(p) {
        if (!p) return false
        let id = String(p.identity || "").toLowerCase()
        let de = String(p.desktopEntry || "").toLowerCase()
        return id.includes("spotify") || de.includes("spotify")
    }

    readonly property var activePlayer: {
        if (!Mpris.players || !Mpris.players.values) return null
        return Mpris.players.values.find(p => p && popup.isSpotify(p) && p.playbackState === MprisPlaybackState.Playing)
            || Mpris.players.values.find(p => p && popup.isSpotify(p) && p.trackTitle && p.trackTitle.length > 0)
            || null
    }

    // Pestaña activa: "dash" | "perf" | "media"
    property string currentTab: "dash"

    // Estado real de brillo
    property real currentBright: 0.75

    // Estado del Clima (telemetría ambiental)
    property string weatherTemp: "--°C"
    property string weatherIcon: "󰖐"
    property string weatherCondition: "Consultando..."

    // Estado de telemetría de sistema (PERF)
    property real sysCpuUsage: 0.0
    property string sysCpuDisplay: "0%"
    property bool sysCpuWarn: false
    property real sysRamUsage: 0.0
    property string sysRamDisplay: "0%"
    property real sysCpuTemp: 0.0
    property string sysCpuTempDisplay: "0°C"
    property bool sysCpuTempWarn: false
    property real sysGpuTemp: 0.0
    property string sysGpuTempDisplay: "0°C"

    // Estado de medios (MEDIA - Spotify/MPRIS)
    property bool mediaActive: false
    property string mediaTitle: "SIN REPRODUCCIÓN"
    property string mediaArtist: "MPRIS2 // STANDBY"
    property string mediaAlbum: ""
    property string mediaStatus: "Stopped"
    property real mediaProgress: 0.0
    property string mediaPosStr: "0:00"
    property string mediaLengthStr: "0:00"
    property int mediaLengthSec: 0
    property int mediaPosSec: 0
    property string mediaArtUrl: ""

    // Visualizador de audio táctico (CAVA)
    property var cavaValues: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

    // Estado del agente de IA (Antigravity / Ojo de Entrati)
    property string agentState: "idle"
    property bool agentActive: false
    property string agentTool: ""
    property string agentCategory: "STANDBY"
    property string agentIcon: "󰍛"
    property string agentTarget: ""
    property string agentDetail: ""
    property var agentHistory: []
    property int agentCallCount: 0
    property var agentFilesModified: []

    // Notificaciones generales acumuladas (SwayNC + Logger)
    property int unreadCount: 0
    property var notificationsList: []

    onCurrentTabChanged: {
        if (visible) {
            if (currentTab === "dash") {
                if (!notifCountProc.running) notifCountProc.running = true
                if (!notifListProc.running) notifListProc.running = true
            }
            if (currentTab === "perf" && !sysProc.running) sysProc.running = true
            if (currentTab === "media" && !mediaProc.running) mediaProc.running = true
            if (currentTab === "agent" && !dashAgentProc.running) dashAgentProc.running = true
        }
    }

    Component.onCompleted: {
        if (visible) {
            container.opacity = 1
            if (!notifCountProc.running) notifCountProc.running = true
            if (!notifListProc.running) notifListProc.running = true
            if (!brightStatusProc.running) brightStatusProc.running = true
            if (!weatherProc.running) weatherProc.running = true
            if (currentTab === "perf" && !sysProc.running) sysProc.running = true
            if (currentTab === "media" && !mediaProc.running) mediaProc.running = true
            if (currentTab === "agent" && !dashAgentProc.running) dashAgentProc.running = true
        }
    }

    onVisibleChanged: {
        if (visible) {
            fadeIn.start()
            slideIn.start()
            if (!notifCountProc.running) notifCountProc.running = true
            if (!notifListProc.running) notifListProc.running = true
            if (!brightStatusProc.running) brightStatusProc.running = true
            if (!weatherProc.running) weatherProc.running = true
            if (currentTab === "perf" && !sysProc.running) sysProc.running = true
            if (currentTab === "media" && !mediaProc.running) mediaProc.running = true
            if (currentTab === "agent" && !dashAgentProc.running) dashAgentProc.running = true
        } else {
            container.opacity = 0
            slideTranslate.y = -6
        }
    }

    Rectangle {
        id: container
        anchors.fill: parent
        color: Theme.surface
        border.width: 0
        radius: 0
        clip: true
        opacity: 0
        transform: Translate { id: slideTranslate; y: -6 }

        NumberAnimation { id: fadeIn;  target: container;      property: "opacity"; from: 0;  to: 1; duration: 180; easing.type: Easing.OutQuad }
        NumberAnimation { id: slideIn; target: slideTranslate; property: "y";       from: -6; to: 0; duration: 180; easing.type: Easing.OutQuad }

        // Contorno táctico abierto arriba (fusionado con la barra como una sola pieza)
        // Borde lateral izquierdo continuo que sube hasta la barra y empalma con barBorderLeft
        Rectangle { width: 1; color: Theme.border; anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom }
        // Borde lateral derecho continuo que sube hasta la barra y empalma con barBorderRight
        Rectangle { width: 1; color: Theme.border; anchors.right: parent.right; anchors.top: parent.top; anchors.bottom: parent.bottom }
        // Borde inferior que cierra la bahía inferior del Dashboard
        Rectangle { height: 1; color: Theme.border; anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right }

        // Muescas tácticas iluminadas en verde POM-2 en las 2 esquinas inferiores (las superiores conectan con la barra)
        Rectangle { width: 6; height: 1; color: Theme.accent; anchors.bottom: parent.bottom; anchors.left: parent.left }
        Rectangle { width: 1; height: 6; color: Theme.accent; anchors.bottom: parent.bottom; anchors.left: parent.left }
        Rectangle { width: 6; height: 1; color: Theme.accent; anchors.bottom: parent.bottom; anchors.right: parent.right }
        Rectangle { width: 1; height: 6; color: Theme.accent; anchors.bottom: parent.bottom; anchors.right: parent.right }



        Column {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 12

            // ========================================================
            // BARRA DE PESTAÑAS TÁCTICAS: [ 01 // DASH ] | [ 02 // PERF ] | [ 03 // MEDIA ]
            // ========================================================
            Item {
                width: parent.width
                height: 28

                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: 1
                    color: Theme.separator
                }

                Row {
                    anchors.fill: parent
                    spacing: 0

                    // TAB 1: DASH
                    Item {
                        id: tabDashBtn
                        width: parent.width / 4
                        height: parent.height
                        property bool isActive: popup.currentTab === "dash"
                        property bool hovered: false

                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.horizontalCenter: parent.horizontalCenter
                            height: 2
                            width: tabDashBtn.isActive ? parent.width * 0.75 : 0
                            radius: 0
                            color: Theme.accent
                            Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "01 // DASH"
                            font.family: Theme.font
                            font.pixelSize: 10
                            font.bold: tabDashBtn.isActive
                            color: tabDashBtn.isActive ? Theme.accent : (tabDashBtn.hovered ? Theme.text : Theme.muted)
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: tabDashBtn.hovered = true
                            onExited:  tabDashBtn.hovered = false
                            onClicked: popup.currentTab = "dash"
                        }
                    }

                    // TAB 2: PERF
                    Item {
                        id: tabPerfBtn
                        width: parent.width / 4
                        height: parent.height
                        property bool isActive: popup.currentTab === "perf"
                        property bool hovered: false

                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.horizontalCenter: parent.horizontalCenter
                            height: 2
                            width: tabPerfBtn.isActive ? parent.width * 0.75 : 0
                            radius: 0
                            color: Theme.accent
                            Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "02 // PERF"
                            font.family: Theme.font
                            font.pixelSize: 10
                            font.bold: tabPerfBtn.isActive
                            color: tabPerfBtn.isActive ? Theme.accent : (tabPerfBtn.hovered ? Theme.text : Theme.muted)
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: tabPerfBtn.hovered = true
                            onExited:  tabPerfBtn.hovered = false
                            onClicked: popup.currentTab = "perf"
                        }
                    }

                    // TAB 3: MEDIA
                    Item {
                        id: tabMediaBtn
                        width: parent.width / 4
                        height: parent.height
                        property bool isActive: popup.currentTab === "media"
                        property bool hovered: false

                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.horizontalCenter: parent.horizontalCenter
                            height: 2
                            width: tabMediaBtn.isActive ? parent.width * 0.75 : 0
                            radius: 0
                            color: Theme.accent
                            Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "03 // MEDIA"
                            font.family: Theme.font
                            font.pixelSize: 10
                            font.bold: tabMediaBtn.isActive
                            color: tabMediaBtn.isActive ? Theme.accent : (tabMediaBtn.hovered ? Theme.text : Theme.muted)
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: tabMediaBtn.hovered = true
                            onExited:  tabMediaBtn.hovered = false
                            onClicked: popup.currentTab = "media"
                        }
                    }

                    // TAB 4: AGENT
                    Item {
                        id: tabAgentBtn
                        width: parent.width / 4
                        height: parent.height
                        property bool isActive: popup.currentTab === "agent"
                        property bool hovered: false

                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.horizontalCenter: parent.horizontalCenter
                            height: 2
                            width: tabAgentBtn.isActive ? parent.width * 0.75 : 0
                            radius: 0
                            color: Theme.accent
                            Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "04 // AGENT"
                            font.family: Theme.font
                            font.pixelSize: 10
                            font.bold: tabAgentBtn.isActive
                            color: tabAgentBtn.isActive ? Theme.accent : (tabAgentBtn.hovered ? Theme.text : Theme.muted)
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: tabAgentBtn.hovered = true
                            onExited:  tabAgentBtn.hovered = false
                            onClicked: popup.currentTab = "agent"
                        }
                    }
                }
            }

            // =====================================================            // =====================================================            // ========================================================
            // VISTA 1: TAB DASH (BRILLO + CONTROL DE SESIÓN + BANDEJA NOTIFICACIONES)
            // ========================================================
            Item {
                width: parent.width
                height: parent.height - 42
                visible: popup.currentTab === "dash"

                Row {
                    anchors.fill: parent
                    spacing: 8

                    // COLUMNA 1 (IZQUIERDA): SLIDER VERTICAL DE BRILLO
                    TacticalVerticalSlider {
                        id: brightSlider
                        width: 68
                        height: parent.height
                        icon: "󰃠"
                        label: "BRILLO"
                        code: "DISP // BRI"
                        value: popup.currentBright
                        onMoved: (val) => {
                            popup.currentBright = val
                            actionProc.exec(["brightnessctl", "set", Math.round(val * 100) + "%"])
                        }
                        onCommitted: (val) => {
                            popup.currentBright = val
                            actionProc.exec(["brightnessctl", "set", Math.round(val * 100) + "%"])
                        }
                    }

                    // COLUMNA 2 (CENTRO): METEO Y CONTROL DE SESIÓN (POSICIONES ORIGINALES)
                    Column {
                        width: 196
                        height: parent.height
                        spacing: 6

                        // TARJETA DE CLIMA (METEO)
                        Rectangle {
                            id: weatherCard
                            width: parent.width
                            height: 44
                            radius: 0
                            color: "#081109"
                            border.color: Theme.separator
                            border.width: 1

                            // Esquinas iluminadas POM-2
                            Rectangle { width: 5; height: 1; color: Theme.accent; anchors.top: parent.top; anchors.left: parent.left }
                            Rectangle { width: 1; height: 5; color: Theme.accent; anchors.top: parent.top; anchors.left: parent.left }
                            Rectangle { width: 5; height: 1; color: Theme.accent; anchors.top: parent.top; anchors.right: parent.right }
                            Rectangle { width: 1; height: 5; color: Theme.accent; anchors.top: parent.top; anchors.right: parent.right }
                            Rectangle { width: 5; height: 1; color: Theme.accent; anchors.bottom: parent.bottom; anchors.left: parent.left }
                            Rectangle { width: 1; height: 5; color: Theme.accent; anchors.bottom: parent.bottom; anchors.left: parent.left }
                            Rectangle { width: 5; height: 1; color: Theme.accent; anchors.bottom: parent.bottom; anchors.right: parent.right }
                            Rectangle { width: 1; height: 5; color: Theme.accent; anchors.bottom: parent.bottom; anchors.right: parent.right }

                            Row {
                                anchors.fill: parent
                                anchors.margins: 6
                                spacing: 8

                                Text {
                                    id: weatherIconText
                                    text: popup.weatherIcon
                                    font.family: Theme.font
                                    font.pixelSize: 18
                                    color: Theme.accent
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Column {
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 2
                                    width: parent.width - 28

                                    Text {
                                        text: "[ENV // METEO]"
                                        font.family: Theme.font
                                        font.pixelSize: 7
                                        font.bold: true
                                        color: Theme.muted
                                    }

                                    Text {
                                        text: popup.weatherTemp + " · " + popup.weatherCondition
                                        font.family: Theme.font
                                        font.pixelSize: 8
                                        font.bold: true
                                        color: Theme.text
                                        elide: Text.ElideRight
                                        width: parent.width
                                    }
                                }
                            }
                        }

                        Row {
                            spacing: 6
                            Text {
                                text: "[PWR // CONTROL]"
                                font.family: Theme.font
                                font.pixelSize: 8
                                font.bold: true
                                color: Theme.muted
                            }
                        }

                        // GRID 2x2 ORIGINAL DE BOTONES DE ENERGÍA
                        Grid {
                            width: parent.width
                            columns: 2
                            spacing: 6

                            // BOTÓN 1: SUSPEND
                            Rectangle {
                                id: suspBtn
                                width: (parent.width - 6) / 2
                                height: 98
                                radius: 0
                                color: suspMouse.containsMouse ? "#112213" : "#081109"
                                border.color: suspMouse.containsMouse ? Theme.accent : Theme.separator
                                border.width: 1

                                readonly property color cornerColor: suspMouse.containsMouse ? Theme.accent : Theme.border
                                Rectangle { width: 5; height: 1; color: suspBtn.cornerColor; anchors.top: parent.top; anchors.left: parent.left }
                                Rectangle { width: 1; height: 5; color: suspBtn.cornerColor; anchors.top: parent.top; anchors.left: parent.left }
                                Rectangle { width: 5; height: 1; color: suspBtn.cornerColor; anchors.top: parent.top; anchors.right: parent.right }
                                Rectangle { width: 1; height: 5; color: suspBtn.cornerColor; anchors.top: parent.top; anchors.right: parent.right }
                                Rectangle { width: 5; height: 1; color: suspBtn.cornerColor; anchors.bottom: parent.bottom; anchors.left: parent.left }
                                Rectangle { width: 1; height: 5; color: suspBtn.cornerColor; anchors.bottom: parent.bottom; anchors.left: parent.left }
                                Rectangle { width: 5; height: 1; color: suspBtn.cornerColor; anchors.bottom: parent.bottom; anchors.right: parent.right }
                                Rectangle { width: 1; height: 5; color: suspBtn.cornerColor; anchors.bottom: parent.bottom; anchors.right: parent.right }

                                Column {
                                    anchors.centerIn: parent
                                    spacing: 4

                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: "󰒲"
                                        font.family: Theme.font
                                        font.pixelSize: 18
                                        color: suspMouse.containsMouse ? Theme.accent : Theme.text
                                    }
                                    Column {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        spacing: 2
                                        Text {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            text: "SUSPEND"
                                            font.family: Theme.font
                                            font.pixelSize: 8
                                            font.bold: true
                                            color: suspMouse.containsMouse ? Theme.accent : Theme.text
                                        }
                                        Text {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            text: "SLEEP // RAM"
                                            font.family: Theme.font
                                            font.pixelSize: 7
                                            color: Theme.muted
                                        }
                                    }
                                }

                                MouseArea {
                                    id: suspMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: actionProc.exec(["systemctl", "suspend"])
                                }
                            }

                            // BOTÓN 2: LOCK
                            Rectangle {
                                id: lockBtn
                                width: (parent.width - 6) / 2
                                height: 98
                                radius: 0
                                color: lockMouse.containsMouse ? "#112213" : "#081109"
                                border.color: lockMouse.containsMouse ? Theme.accent : Theme.separator
                                border.width: 1

                                readonly property color cornerColor: lockMouse.containsMouse ? Theme.accent : Theme.border
                                Rectangle { width: 5; height: 1; color: lockBtn.cornerColor; anchors.top: parent.top; anchors.left: parent.left }
                                Rectangle { width: 1; height: 5; color: lockBtn.cornerColor; anchors.top: parent.top; anchors.left: parent.left }
                                Rectangle { width: 5; height: 1; color: lockBtn.cornerColor; anchors.top: parent.top; anchors.right: parent.right }
                                Rectangle { width: 1; height: 5; color: lockBtn.cornerColor; anchors.top: parent.top; anchors.right: parent.right }
                                Rectangle { width: 5; height: 1; color: lockBtn.cornerColor; anchors.bottom: parent.bottom; anchors.left: parent.left }
                                Rectangle { width: 1; height: 5; color: lockBtn.cornerColor; anchors.bottom: parent.bottom; anchors.left: parent.left }
                                Rectangle { width: 5; height: 1; color: lockBtn.cornerColor; anchors.bottom: parent.bottom; anchors.right: parent.right }
                                Rectangle { width: 1; height: 5; color: lockBtn.cornerColor; anchors.bottom: parent.bottom; anchors.right: parent.right }

                                Column {
                                    anchors.centerIn: parent
                                    spacing: 4

                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: "󰌾"
                                        font.family: Theme.font
                                        font.pixelSize: 18
                                        color: lockMouse.containsMouse ? Theme.accent : Theme.text
                                    }
                                    Column {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        spacing: 2
                                        Text {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            text: "LOCK"
                                            font.family: Theme.font
                                            font.pixelSize: 8
                                            font.bold: true
                                            color: lockMouse.containsMouse ? Theme.accent : Theme.text
                                        }
                                        Text {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            text: "SESSION // SEC"
                                            font.family: Theme.font
                                            font.pixelSize: 7
                                            color: Theme.muted
                                        }
                                    }
                                }

                                MouseArea {
                                    id: lockMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: actionProc.exec(["bash", "-c", "hyprlock || swaylock"])
                                }
                            }

                            // BOTÓN 3: REBOOT
                            Rectangle {
                                id: rebtBtn
                                width: (parent.width - 6) / 2
                                height: 98
                                radius: 0
                                color: rebtMouse.containsMouse ? "#24180c" : "#081109"
                                border.color: rebtMouse.containsMouse ? Theme.amber : Theme.separator
                                border.width: 1

                                readonly property color cornerColor: rebtMouse.containsMouse ? Theme.amber : Theme.border
                                Rectangle { width: 5; height: 1; color: rebtBtn.cornerColor; anchors.top: parent.top; anchors.left: parent.left }
                                Rectangle { width: 1; height: 5; color: rebtBtn.cornerColor; anchors.top: parent.top; anchors.left: parent.left }
                                Rectangle { width: 5; height: 1; color: rebtBtn.cornerColor; anchors.top: parent.top; anchors.right: parent.right }
                                Rectangle { width: 1; height: 5; color: rebtBtn.cornerColor; anchors.top: parent.top; anchors.right: parent.right }
                                Rectangle { width: 5; height: 1; color: rebtBtn.cornerColor; anchors.bottom: parent.bottom; anchors.left: parent.left }
                                Rectangle { width: 1; height: 5; color: rebtBtn.cornerColor; anchors.bottom: parent.bottom; anchors.left: parent.left }
                                Rectangle { width: 5; height: 1; color: rebtBtn.cornerColor; anchors.bottom: parent.bottom; anchors.right: parent.right }
                                Rectangle { width: 1; height: 5; color: rebtBtn.cornerColor; anchors.bottom: parent.bottom; anchors.right: parent.right }

                                Column {
                                    anchors.centerIn: parent
                                    spacing: 4

                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: "󰑙"
                                        font.family: Theme.font
                                        font.pixelSize: 18
                                        color: rebtMouse.containsMouse ? Theme.amber : Theme.text
                                    }
                                    Column {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        spacing: 2
                                        Text {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            text: "REBOOT"
                                            font.family: Theme.font
                                            font.pixelSize: 8
                                            font.bold: true
                                            color: rebtMouse.containsMouse ? Theme.amber : Theme.text
                                        }
                                        Text {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            text: "WARM // RESTART"
                                            font.family: Theme.font
                                            font.pixelSize: 7
                                            color: Theme.muted
                                        }
                                    }
                                }

                                MouseArea {
                                    id: rebtMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: actionProc.exec(["systemctl", "reboot"])
                                }
                            }

                            // BOTÓN 4: POWER OFF
                            Rectangle {
                                id: shutBtn
                                width: (parent.width - 6) / 2
                                height: 98
                                radius: 0
                                color: shutMouse.containsMouse ? "#2a1012" : "#081109"
                                border.color: shutMouse.containsMouse ? Theme.red : Theme.separator
                                border.width: 1

                                readonly property color cornerColor: shutMouse.containsMouse ? Theme.red : Theme.border
                                Rectangle { width: 5; height: 1; color: shutBtn.cornerColor; anchors.top: parent.top; anchors.left: parent.left }
                                Rectangle { width: 1; height: 5; color: shutBtn.cornerColor; anchors.top: parent.top; anchors.left: parent.left }
                                Rectangle { width: 5; height: 1; color: shutBtn.cornerColor; anchors.top: parent.top; anchors.right: parent.right }
                                Rectangle { width: 1; height: 5; color: shutBtn.cornerColor; anchors.top: parent.top; anchors.right: parent.right }
                                Rectangle { width: 5; height: 1; color: shutBtn.cornerColor; anchors.bottom: parent.bottom; anchors.left: parent.left }
                                Rectangle { width: 1; height: 5; color: shutBtn.cornerColor; anchors.bottom: parent.bottom; anchors.left: parent.left }
                                Rectangle { width: 5; height: 1; color: shutBtn.cornerColor; anchors.bottom: parent.bottom; anchors.right: parent.right }
                                Rectangle { width: 1; height: 5; color: shutBtn.cornerColor; anchors.bottom: parent.bottom; anchors.right: parent.right }

                                Column {
                                    anchors.centerIn: parent
                                    spacing: 4

                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: "󰐥"
                                        font.family: Theme.font
                                        font.pixelSize: 18
                                        color: shutMouse.containsMouse ? Theme.red : Theme.text
                                    }
                                    Column {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        spacing: 2
                                        Text {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            text: "POWER OFF"
                                            font.family: Theme.font
                                            font.pixelSize: 8
                                            font.bold: true
                                            color: shutMouse.containsMouse ? Theme.red : Theme.text
                                        }
                                        Text {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            text: "SYS // SHUTDOWN"
                                            font.family: Theme.font
                                            font.pixelSize: 7
                                            color: Theme.muted
                                        }
                                    }
                                }

                                MouseArea {
                                    id: shutMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: actionProc.exec(["systemctl", "poweroff"])
                                }
                            }
                        }
                    }

                    // COLUMNA 3 (DERECHA): BANDEJA DE NOTIFICACIONES ACUMULADAS
                    Rectangle {
                        width: parent.width - brightSlider.width - 196 - 16
                        height: parent.height
                        radius: 0
                        color: "#081109"
                        border.color: popup.notificationsList.length > 0 ? Theme.amber : Theme.separator
                        border.width: 1

                        // Esquinas iluminadas
                        Rectangle { width: 5; height: 1; color: popup.notificationsList.length > 0 ? Theme.amber : Theme.accent; anchors.top: parent.top; anchors.left: parent.left }
                        Rectangle { width: 1; height: 5; color: popup.notificationsList.length > 0 ? Theme.amber : Theme.accent; anchors.top: parent.top; anchors.left: parent.left }
                        Rectangle { width: 5; height: 1; color: popup.notificationsList.length > 0 ? Theme.amber : Theme.accent; anchors.top: parent.top; anchors.right: parent.right }
                        Rectangle { width: 1; height: 5; color: popup.notificationsList.length > 0 ? Theme.amber : Theme.accent; anchors.top: parent.top; anchors.right: parent.right }
                        Rectangle { width: 5; height: 1; color: popup.notificationsList.length > 0 ? Theme.amber : Theme.accent; anchors.bottom: parent.bottom; anchors.left: parent.left }
                        Rectangle { width: 1; height: 5; color: popup.notificationsList.length > 0 ? Theme.amber : Theme.accent; anchors.bottom: parent.bottom; anchors.left: parent.left }
                        Rectangle { width: 5; height: 1; color: popup.notificationsList.length > 0 ? Theme.amber : Theme.accent; anchors.bottom: parent.bottom; anchors.right: parent.right }
                        Rectangle { width: 1; height: 5; color: popup.notificationsList.length > 0 ? Theme.amber : Theme.accent; anchors.bottom: parent.bottom; anchors.right: parent.right }

                        Column {
                            anchors.fill: parent
                            anchors.margins: 6
                            spacing: 4

                            // CABECERA DE LA BANDEJA CON BOTÓN LIMPIAR
                            Item {
                                width: parent.width
                                height: 20

                                Row {
                                    anchors.left: parent.left
                                    spacing: 4
                                    anchors.verticalCenter: parent.verticalCenter

                                    Text {
                                        text: "󰂚"
                                        font.family: Theme.font
                                        font.pixelSize: 11
                                        color: popup.notificationsList.length > 0 ? Theme.amber : Theme.muted
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    Text {
                                        text: "[NOTIF]"
                                        font.family: Theme.font
                                        font.pixelSize: 8
                                        font.bold: true
                                        color: Theme.muted
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    Text {
                                        text: "(" + popup.notificationsList.length + ")"
                                        font.family: Theme.font
                                        font.pixelSize: 8
                                        font.bold: true
                                        color: popup.notificationsList.length > 0 ? Theme.amber : Theme.muted
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }

                                // Botón Limpiar Todo
                                Rectangle {
                                    visible: popup.notificationsList.length > 0 || popup.unreadCount > 0
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 50
                                    height: 18
                                    radius: 0
                                    color: clearMouse.containsMouse ? "#24180c" : "#112213"
                                    border.color: clearMouse.containsMouse ? Theme.amber : Theme.separator
                                    border.width: 1

                                    Text {
                                        anchors.centerIn: parent
                                        text: "LIMPIAR"
                                        font.family: Theme.font
                                        font.pixelSize: 7
                                        font.bold: true
                                        color: clearMouse.containsMouse ? Theme.amber : Theme.text
                                    }

                                    MouseArea {
                                        id: clearMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            popup.unreadCount = 0
                                            popup.notificationsList = []
                                            actionProc.exec(["bash", "-c", "pom2-notif-logger --clear && swaync-client -C"])
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                width: parent.width
                                height: 1
                                color: Theme.separator
                            }

                            // LISTA SCROLLEABLE DE NOTIFICACIONES
                            Item {
                                width: parent.width
                                height: parent.height - 26
                                clip: true

                                Flickable {
                                    id: notifFlick
                                    anchors.fill: parent
                                    contentWidth: width
                                    contentHeight: notifItemsCol.implicitHeight
                                    boundsBehavior: Flickable.StopAtBounds

                                    Column {
                                        id: notifItemsCol
                                        width: parent.width
                                        spacing: 5

                                        Repeater {
                                            model: popup.notificationsList

                                            Rectangle {
                                                width: notifItemsCol.width
                                                height: itemCol.implicitHeight + 8
                                                radius: 0
                                                color: "#050d06"
                                                border.color: modelData.urgency === "critical" ? Theme.red : Theme.separator
                                                border.width: 1

                                                Column {
                                                    id: itemCol
                                                    anchors.fill: parent
                                                    anchors.margins: 4
                                                    spacing: 2

                                                    Row {
                                                        width: parent.width
                                                        spacing: 4

                                                        Text {
                                                            text: "[" + (modelData.app || "SYS").toUpperCase() + "]"
                                                            font.family: Theme.font
                                                            font.pixelSize: 8
                                                            font.bold: true
                                                            color: modelData.urgency === "critical" ? Theme.red : Theme.accent
                                                        }

                                                        Text {
                                                            text: modelData.time || ""
                                                            font.family: Theme.font
                                                            font.pixelSize: 7
                                                            color: Theme.muted
                                                            anchors.verticalCenter: parent.verticalCenter
                                                        }
                                                    }

                                                    Text {
                                                        text: modelData.summary || ""
                                                        font.family: Theme.font
                                                        font.pixelSize: 8
                                                        font.bold: true
                                                        color: Theme.text
                                                        elide: Text.ElideRight
                                                        width: parent.width
                                                        visible: modelData.summary && modelData.summary.length > 0
                                                    }

                                                    Text {
                                                        text: modelData.body || ""
                                                        font.family: Theme.font
                                                        font.pixelSize: 8
                                                        color: Theme.muted
                                                        wrapMode: Text.Wrap
                                                        maximumLineCount: 2
                                                        elide: Text.ElideRight
                                                        width: parent.width
                                                        visible: modelData.body && modelData.body.length > 0
                                                    }
                                                }
                                            }
                                        }

                                        // Estado vacío
                                        Item {
                                            width: parent.width
                                            height: 100
                                            visible: !popup.notificationsList || popup.notificationsList.length === 0

                                            Column {
                                                anchors.centerIn: parent
                                                spacing: 4

                                                Text {
                                                    anchors.horizontalCenter: parent.horizontalCenter
                                                    text: "󰄬"
                                                    font.family: Theme.font
                                                    font.pixelSize: 18
                                                    color: Theme.separator
                                                }

                                                Text {
                                                    anchors.horizontalCenter: parent.horizontalCenter
                                                    text: "SIN PENDIENTES"
                                                    font.family: Theme.font
                                                    font.pixelSize: 8
                                                    font.bold: true
                                                    color: Theme.muted
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // VISTA 2: TAB PERF (MÉTRICAS TÁCTICAS)
            // ========================================================
            Item {
                width: parent.width
                height: parent.height - 42
                visible: popup.currentTab === "perf"

                Grid {
                    width: parent.width
                    anchors.centerIn: parent
                    columns: 2
                    spacing: 8

                    TacticalRing {
                        width: (parent.width - 8) / 2
                        height: 124
                        code: "SYS // CPU_LOAD"
                        label: "CPU USO"
                        value: popup.sysCpuUsage
                        displayValue: popup.sysCpuDisplay
                        activeColor: popup.sysCpuWarn ? Theme.amber : Theme.accent
                        warnColor: Theme.amber
                        warning: popup.sysCpuWarn
                    }

                    TacticalRing {
                        width: (parent.width - 8) / 2
                        height: 124
                        code: "MEM // RAM_ALLOC"
                        label: "RAM USO"
                        value: popup.sysRamUsage
                        displayValue: popup.sysRamDisplay
                        activeColor: popup.sysRamUsage >= 0.85 ? Theme.amber : Theme.accent
                        warnColor: Theme.amber
                        warning: popup.sysRamUsage >= 0.85
                    }

                    TacticalRing {
                        width: (parent.width - 8) / 2
                        height: 124
                        code: "THM // CPU_THERM"
                        label: "CPU TEMP"
                        value: popup.sysCpuTemp
                        displayValue: popup.sysCpuTempDisplay
                        activeColor: popup.sysCpuTempWarn ? Theme.amber : Theme.accent
                        warnColor: Theme.amber
                        warning: popup.sysCpuTempWarn
                    }

                    TacticalRing {
                        width: (parent.width - 8) / 2
                        height: 124
                        code: "THM // GPU_THERM"
                        label: "GPU TEMP"
                        value: popup.sysGpuTemp
                        displayValue: popup.sysGpuTempDisplay
                        activeColor: popup.sysGpuTemp >= 0.80 ? Theme.amber : Theme.accent
                        warnColor: Theme.amber
                        warning: popup.sysGpuTemp >= 0.80
                    }
                }
            }

            // ========================================================
            // VISTA 3: TAB MEDIA (CONSOLA SPOTIFY TÁCTICA + ESPECTRO)
            // ========================================================
            Item {
                width: parent.width
                height: parent.height - 42
                visible: popup.currentTab === "media"

                Column {
                    anchors.centerIn: parent
                    spacing: 8
                    width: parent.width - 24

                    Row {
                        spacing: 6
                        Text {
                            text: popup.mediaActive ? ((popup.mediaStatus === "Playing" || (popup.activePlayer && popup.activePlayer.playbackState === MprisPlaybackState.Playing)) ? "[MEDIA // SPOTIFY_LIVE]" : "[MEDIA // PAUSED]") : "[MEDIA // STANDBY]"
                            font.family: Theme.font
                            font.pixelSize: 8
                            font.bold: true
                            color: popup.mediaActive ? Theme.accent : Theme.muted
                        }
                    }

                    // Fila superior: Carátula + Datos de la pista
                    Row {
                        width: parent.width
                        spacing: 12

                        // Carátula táctica cuadrada (56x56)
                        Rectangle {
                            width: 56
                            height: 56
                            radius: 0
                            color: "#081109"
                            border.color: popup.mediaActive ? Theme.border : Theme.separator
                            border.width: 1
                            clip: true

                            Rectangle { width: 4; height: 1; color: Theme.accent; anchors.top: parent.top; anchors.left: parent.left }
                            Rectangle { width: 1; height: 4; color: Theme.accent; anchors.top: parent.top; anchors.left: parent.left }
                            Rectangle { width: 4; height: 1; color: Theme.accent; anchors.top: parent.top; anchors.right: parent.right }
                            Rectangle { width: 1; height: 4; color: Theme.accent; anchors.top: parent.top; anchors.right: parent.right }
                            Rectangle { width: 4; height: 1; color: Theme.accent; anchors.bottom: parent.bottom; anchors.left: parent.left }
                            Rectangle { width: 1; height: 4; color: Theme.accent; anchors.bottom: parent.bottom; anchors.left: parent.left }
                            Rectangle { width: 4; height: 1; color: Theme.accent; anchors.bottom: parent.bottom; anchors.right: parent.right }
                            Rectangle { width: 1; height: 4; color: Theme.accent; anchors.bottom: parent.bottom; anchors.right: parent.right }

                            Image {
                                id: albumArtImg
                                anchors.fill: parent
                                anchors.margins: 1
                                source: popup.mediaArtUrl
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                cache: true
                                visible: popup.mediaActive && popup.mediaArtUrl !== "" && status === Image.Ready
                            }

                            Text {
                                anchors.centerIn: parent
                                text: "󰓇"
                                font.family: Theme.font
                                font.pixelSize: 24
                                color: popup.mediaActive ? Theme.accent : Theme.muted
                                visible: !albumArtImg.visible
                            }
                        }

                        // Columna derecha: Título, Artista y Botón de Inicio si está apagado
                        Column {
                            width: parent.width - 68
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 4

                            Text {
                                text: popup.mediaTitle
                                font.family: Theme.font
                                font.pixelSize: 11
                                font.bold: true
                                color: Theme.text
                                elide: Text.ElideRight
                                width: parent.width
                            }

                            Text {
                                text: popup.mediaArtist + (popup.mediaAlbum ? " · " + popup.mediaAlbum : "")
                                font.family: Theme.font
                                font.pixelSize: 8
                                color: Theme.muted
                                elide: Text.ElideRight
                                width: parent.width
                            }

                            // Botón para iniciar Spotify si no está activo
                            Rectangle {
                                visible: !popup.mediaActive
                                width: 130
                                height: 22
                                radius: 0
                                color: launchMouse.containsMouse ? "#112213" : "#081109"
                                border.color: launchMouse.containsMouse ? Theme.accent : Theme.border
                                border.width: 1

                                Row {
                                    anchors.centerIn: parent
                                    spacing: 4
                                    Text {
                                        text: "󰓇"
                                        font.family: Theme.font
                                        font.pixelSize: 11
                                        color: Theme.accent
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                    Text {
                                        text: "ABRIR SPOTIFY"
                                        font.family: Theme.font
                                        font.pixelSize: 8
                                        font.bold: true
                                        color: launchMouse.containsMouse ? Theme.accent : Theme.text
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }

                                MouseArea {
                                    id: launchMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        launchProc.exec(["hyprctl", "dispatch", "exec", "spotify-launcher"])
                                        mediaFastRefreshTimer.restart()
                                    }
                                }
                            }
                        }
                    }

                    // Visualizador táctico retro de audio ARRIBA de la barra de progreso
                    TacticalSpectrum {
                        id: spectrumView
                        width: parent.width
                        height: 62
                        active: popup.mediaActive && ((popup.mediaStatus === "Playing") || (popup.activePlayer && popup.activePlayer.playbackState === MprisPlaybackState.Playing))
                        values: popup.cavaValues
                    }

                    // Barra progresiva con Seek interactivo
                    Column {
                        width: parent.width
                        spacing: 3

                        Item {
                            width: parent.width
                            height: 12

                            Row {
                                id: progRow
                                anchors.centerIn: parent
                                spacing: 2
                                Repeater {
                                    model: 24
                                    Rectangle {
                                        width: Math.floor((progRow.parent.width - 23 * 2) / 24)
                                        height: 4
                                        radius: 0
                                        readonly property bool filled: popup.mediaActive && (index / 24.0 <= popup.mediaProgress)
                                        color: filled ? Theme.accent : "#0e1a10"
                                        border.color: filled ? Theme.border : "#132416"
                                        border.width: 1
                                    }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: popup.mediaActive ? Qt.PointingHandCursor : Qt.ArrowCursor
                                onClicked: (mouse) => {
                                    if (popup.mediaActive && popup.mediaLengthSec > 0) {
                                        let frac = Math.max(0.0, Math.min(1.0, mouse.x / width))
                                        let targetSec = (frac * popup.mediaLengthSec).toFixed(1)
                                        seekProc.exec(["playerctl", "--player=spotify", "position", targetSec])
                                        popup.mediaProgress = frac
                                        mediaFastRefreshTimer.restart()
                                    }
                                }
                            }
                        }

                        Item {
                            width: parent.width
                            height: 10
                            visible: popup.mediaActive

                            Text {
                                anchors.left: parent.left
                                text: popup.mediaPosStr
                                font.family: Theme.font
                                font.pixelSize: 8
                                color: Theme.muted
                            }
                            Text {
                                anchors.right: parent.right
                                text: popup.mediaLengthStr
                                font.family: Theme.font
                                font.pixelSize: 8
                                color: Theme.muted
                            }
                        }
                    }

                    // Controles de reproducción Prev / Play-Pause / Next
                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 12

                        // PREV BTN
                        Rectangle {
                            id: mediaPrevBtn
                            width: 36; height: 24; radius: 0
                            color: prevMouse.containsMouse ? "#112213" : "#081109"
                            border.color: prevMouse.containsMouse ? Theme.accent : Theme.separator
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: "󰒮"
                                font.family: Theme.font
                                font.pixelSize: 12
                                color: prevMouse.containsMouse ? Theme.accent : Theme.text
                            }

                            MouseArea {
                                id: prevMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (popup.activePlayer && popup.activePlayer.canGoPrevious) {
                                        popup.activePlayer.previous()
                                    } else {
                                        mediaCmdProc.exec(["playerctl", "--player=spotify", "previous"])
                                    }
                                    mediaFastRefreshTimer.restart()
                                }
                            }
                        }

                        // PLAY / PAUSE BTN
                        Rectangle {
                            id: mediaPlayBtn
                            width: 52; height: 24; radius: 0
                            color: playMouse.containsMouse ? "#18301b" : "#112213"
                            border.color: playMouse.containsMouse ? Theme.accent : Theme.border
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: ((popup.mediaStatus === "Playing") || (popup.activePlayer && popup.activePlayer.playbackState === MprisPlaybackState.Playing)) ? "󰏤" : "󰐊"
                                font.family: Theme.font
                                font.pixelSize: 13
                                color: Theme.accent
                            }

                            MouseArea {
                                id: playMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (popup.activePlayer && popup.activePlayer.canTogglePlaying) {
                                        popup.activePlayer.togglePlaying()
                                    } else {
                                        mediaCmdProc.exec(["playerctl", "--player=spotify", "play-pause"])
                                    }
                                    popup.mediaStatus = (popup.mediaStatus === "Playing") ? "Paused" : "Playing"
                                    mediaFastRefreshTimer.restart()
                                }
                            }
                        }

                        // NEXT BTN
                        Rectangle {
                            id: mediaNextBtn
                            width: 36; height: 24; radius: 0
                            color: nextMouse.containsMouse ? "#112213" : "#081109"
                            border.color: nextMouse.containsMouse ? Theme.accent : Theme.separator
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: "󰒭"
                                font.family: Theme.font
                                font.pixelSize: 12
                                color: nextMouse.containsMouse ? Theme.accent : Theme.text
                            }

                            MouseArea {
                                id: nextMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (popup.activePlayer && popup.activePlayer.canGoNext) {
                                        popup.activePlayer.next()
                                    } else {
                                        mediaCmdProc.exec(["playerctl", "--player=spotify", "next"])
                                    }
                                    mediaFastRefreshTimer.restart()
                                }
                            }
                        }
                    }
                }
            }

            // ========================================================
            // VISTA 4: TAB AGENT (TELEMETRÍA ENTRATI // ANTIGRAVITY)
            // ========================================================
            Item {
                width: parent.width
                height: parent.height - 42
                visible: popup.currentTab === "agent"

                Column {
                    anchors.fill: parent
                    spacing: 8

                    // 1. HEADER CARD: EL OJO DE ENTRATI (AVATAR TÁCTICO + PACING STATS)
                    Rectangle {
                        width: parent.width
                        height: 48
                        radius: 0
                        color: "#081109"
                        border.color: Theme.separator
                        border.width: 1

                        // Esquinas tácticas iluminadas POM-2
                        Rectangle { width: 5; height: 1; color: Theme.accent; anchors.top: parent.top; anchors.left: parent.left }
                        Rectangle { width: 1; height: 5; color: Theme.accent; anchors.top: parent.top; anchors.left: parent.left }
                        Rectangle { width: 5; height: 1; color: Theme.accent; anchors.top: parent.top; anchors.right: parent.right }
                        Rectangle { width: 1; height: 5; color: Theme.accent; anchors.top: parent.top; anchors.right: parent.right }
                        Rectangle { width: 5; height: 1; color: Theme.accent; anchors.bottom: parent.bottom; anchors.left: parent.left }
                        Rectangle { width: 1; height: 5; color: Theme.accent; anchors.bottom: parent.bottom; anchors.left: parent.left }
                        Rectangle { width: 5; height: 1; color: Theme.accent; anchors.bottom: parent.bottom; anchors.right: parent.right }
                        Rectangle { width: 1; height: 5; color: Theme.accent; anchors.bottom: parent.bottom; anchors.right: parent.right }

                        Row {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 10

                            // Iris del Ojo de Entrati (Avatar con anillo pulsante)
                            Rectangle {
                                width: 32
                                height: 32
                                radius: 0
                                color: "#0d1a0f"
                                border.color: popup.agentActive ? ((popup.agentState === "thinking") ? Theme.amber : Theme.accent) : Theme.separator
                                border.width: 1
                                anchors.verticalCenter: parent.verticalCenter

                                Text {
                                    anchors.centerIn: parent
                                    text: "󰈈"
                                    font.family: Theme.font
                                    font.pixelSize: 18
                                    color: popup.agentActive ? ((popup.agentState === "thinking") ? Theme.amber : Theme.accent) : Theme.muted
                                }
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2
                                width: parent.width - 44

                                Item {
                                    width: parent.width
                                    height: 16

                                    Text {
                                        anchors.left: parent.left
                                        text: "ENTRATI // AI TELEMETRY"
                                        font.family: Theme.font
                                        font.pixelSize: 10
                                        font.bold: true
                                        color: Theme.accent
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    // Badge de métricas de sesión estilo Coucou (Calls | Files)
                                    Row {
                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 6

                                        Rectangle {
                                            width: statsText.implicitWidth + 10
                                            height: 16
                                            radius: 0
                                            color: "#050d06"
                                            border.color: Theme.separator
                                            border.width: 1

                                            Text {
                                                id: statsText
                                                anchors.centerIn: parent
                                                text: "CALLS: " + popup.agentCallCount + " | MOD: " + popup.agentFilesModified.length
                                                font.family: Theme.font
                                                font.pixelSize: 7
                                                font.bold: true
                                                color: Theme.muted
                                            }
                                        }
                                    }
                                }

                                Row {
                                    spacing: 6
                                    Text {
                                        text: {
                                            if (popup.agentState === "working") return "● ACTIVE // EXECUTING"
                                            if (popup.agentState === "thinking") return "◌ THINKING // INFERENCE"
                                            if (popup.agentState === "finished") return "󰄬 TASK // COMPLETED"
                                            return "○ STANDBY // READY"
                                        }
                                        font.family: Theme.font
                                        font.pixelSize: 9
                                        font.bold: true
                                        color: {
                                            if (popup.agentState === "working") return Theme.accent
                                            if (popup.agentState === "thinking") return Theme.amber
                                            if (popup.agentState === "finished") return Theme.accent
                                            return Theme.muted
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // 2. FILA DE DOS COLUMNAS TÁCTICAS (HORIZONTAL WIDESCREEN)
                    Row {
                        width: parent.width
                        height: parent.height - 56
                        spacing: 8

                        // COLUMNA IZQUIERDA: OPERACIÓN ACTUAL + TERMINAL & RESET ACTIONS
                        Column {
                            width: (parent.width - 8) / 2
                            height: parent.height
                            spacing: 8

                            // TARJETA DE OPERACIÓN ACTUAL
                            Rectangle {
                                width: parent.width
                                height: parent.height - 38
                                radius: 0
                                color: "#081109"
                                border.color: Theme.separator
                                border.width: 1

                                Rectangle { width: 5; height: 1; color: Theme.accent; anchors.top: parent.top; anchors.left: parent.left }
                                Rectangle { width: 1; height: 5; color: Theme.accent; anchors.top: parent.top; anchors.left: parent.left }
                                Rectangle { width: 5; height: 1; color: Theme.accent; anchors.top: parent.top; anchors.right: parent.right }
                                Rectangle { width: 1; height: 5; color: Theme.accent; anchors.top: parent.top; anchors.right: parent.right }
                                Rectangle { width: 5; height: 1; color: Theme.accent; anchors.bottom: parent.bottom; anchors.left: parent.left }
                                Rectangle { width: 1; height: 5; color: Theme.accent; anchors.bottom: parent.bottom; anchors.left: parent.left }
                                Rectangle { width: 5; height: 1; color: Theme.accent; anchors.bottom: parent.bottom; anchors.right: parent.right }
                                Rectangle { width: 1; height: 5; color: Theme.accent; anchors.bottom: parent.bottom; anchors.right: parent.right }

                                Column {
                                    anchors.fill: parent
                                    anchors.margins: 8
                                    spacing: 4

                                    Item {
                                        width: parent.width
                                        height: 16

                                        Text {
                                            anchors.left: parent.left
                                            text: "[ OPERACIÓN // ACTUAL ]"
                                            font.family: Theme.font
                                            font.pixelSize: 8
                                            font.bold: true
                                            color: Theme.muted
                                            anchors.verticalCenter: parent.verticalCenter
                                        }

                                        // Badge de categoría táctica Coucou (EXEC, CODE, FS, etc.)
                                        Rectangle {
                                            anchors.right: parent.right
                                            anchors.verticalCenter: parent.verticalCenter
                                            width: catText.implicitWidth + 8
                                            height: 14
                                            radius: 0
                                            color: popup.agentActive ? "#112213" : "#0c150e"
                                            border.color: popup.agentActive ? Theme.accent : Theme.separator
                                            border.width: 1

                                            Text {
                                                id: catText
                                                anchors.centerIn: parent
                                                text: popup.agentCategory
                                                font.family: Theme.font
                                                font.pixelSize: 7
                                                font.bold: true
                                                color: popup.agentActive ? Theme.accent : Theme.muted
                                            }
                                        }
                                    }

                                    // Objetivo / Destino de la herramienta
                                    Row {
                                        spacing: 6
                                        width: parent.width

                                        Text {
                                            text: popup.agentIcon
                                            font.family: Theme.font
                                            font.pixelSize: 10
                                            color: popup.agentActive ? Theme.accent : Theme.muted
                                            anchors.verticalCenter: parent.verticalCenter
                                        }

                                        Text {
                                            text: popup.agentTarget !== "" ? popup.agentTarget : "En espera"
                                            font.family: Theme.font
                                            font.pixelSize: 8
                                            font.bold: true
                                            color: Theme.text
                                            elide: Text.ElideRight
                                            width: parent.width - 24
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                    }

                                    // Caja de código / inspección de comando (Code Box de Coucou)
                                    Rectangle {
                                        width: parent.width
                                        height: parent.height - 52
                                        radius: 0
                                        color: "#030704"
                                        border.color: "#122415"
                                        border.width: 1
                                        clip: true

                                        Flickable {
                                            anchors.fill: parent
                                            anchors.margins: 4
                                            contentWidth: width
                                            contentHeight: codeText.implicitHeight
                                            boundsBehavior: Flickable.StopAtBounds

                                            Text {
                                                id: codeText
                                                width: parent.width
                                                text: popup.agentDetail !== "" ? popup.agentDetail : "Esperando instrucciones o ejecución de tareas..."
                                                font.family: Theme.font
                                                font.pixelSize: 8
                                                color: popup.agentActive ? Theme.text : Theme.muted
                                                wrapMode: Text.Wrap
                                            }
                                        }
                                    }
                                }
                            }

                            // FILA DE ACCIONES RÁPIDAS: FOCUS KITTY + RESET SESSION
                            Row {
                                width: parent.width
                                height: 30
                                spacing: 6

                                // BOTÓN FOCUS TERMINAL KITTY
                                Rectangle {
                                    id: focusTermBtn
                                    width: parent.width - 46
                                    height: parent.height
                                    radius: 0
                                    color: termMouse.containsMouse ? "#112213" : "#081109"
                                    border.color: termMouse.containsMouse ? Theme.accent : Theme.separator
                                    border.width: 1

                                    Rectangle { width: 3; height: 1; color: termMouse.containsMouse ? Theme.accent : Theme.border; anchors.top: parent.top; anchors.left: parent.left }
                                    Rectangle { width: 1; height: 3; color: termMouse.containsMouse ? Theme.accent : Theme.border; anchors.top: parent.top; anchors.left: parent.left }

                                    Row {
                                        anchors.centerIn: parent
                                        spacing: 6

                                        Text {
                                            text: "󰞷"
                                            font.family: Theme.font
                                            font.pixelSize: 12
                                            color: termMouse.containsMouse ? Theme.accent : Theme.text
                                            anchors.verticalCenter: parent.verticalCenter
                                        }

                                        Text {
                                            text: "FOCUS KITTY TERMINAL"
                                            font.family: Theme.font
                                            font.pixelSize: 8
                                            font.bold: true
                                            color: termMouse.containsMouse ? Theme.accent : Theme.text
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                    }

                                    MouseArea {
                                        id: termMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: actionProc.exec(["hyprctl", "dispatch", "focuswindow", "class:^(kitty)$"])
                                    }
                                }

                                // BOTÓN RESET STATUS TELEMETRY
                                Rectangle {
                                    id: rstBtn
                                    width: 40
                                    height: parent.height
                                    radius: 0
                                    color: rstMouse.containsMouse ? "#241d0c" : "#081109"
                                    border.color: rstMouse.containsMouse ? Theme.amber : Theme.separator
                                    border.width: 1

                                    Text {
                                        anchors.centerIn: parent
                                        text: "RST"
                                        font.family: Theme.font
                                        font.pixelSize: 8
                                        font.bold: true
                                        color: rstMouse.containsMouse ? Theme.amber : Theme.muted
                                    }

                                    MouseArea {
                                        id: rstMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            actionProc.exec(["/home/emn/.local/bin/pom2-agy-hook", "--reset"])
                                            popup.agentState = "idle"
                                            popup.agentTarget = "Sin operación activa"
                                            popup.agentDetail = "Telemetría reiniciada"
                                            popup.agentCallCount = 0
                                            popup.agentFilesModified = []
                                        }
                                    }
                                }
                            }
                        }

                        // COLUMNA DERECHA: REGISTRO DE ACTIVIDAD / TELEMETRY STREAM
                        Rectangle {
                            width: (parent.width - 8) / 2
                            height: parent.height
                            radius: 0
                            color: "#081109"
                            border.color: Theme.separator
                            border.width: 1

                            Rectangle { width: 5; height: 1; color: Theme.accent; anchors.top: parent.top; anchors.left: parent.left }
                            Rectangle { width: 1; height: 5; color: Theme.accent; anchors.top: parent.top; anchors.left: parent.left }
                            Rectangle { width: 5; height: 1; color: Theme.accent; anchors.top: parent.top; anchors.right: parent.right }
                            Rectangle { width: 1; height: 5; color: Theme.accent; anchors.top: parent.top; anchors.right: parent.right }
                            Rectangle { width: 5; height: 1; color: Theme.accent; anchors.bottom: parent.bottom; anchors.left: parent.left }
                            Rectangle { width: 1; height: 5; color: Theme.accent; anchors.bottom: parent.bottom; anchors.left: parent.left }
                            Rectangle { width: 5; height: 1; color: Theme.accent; anchors.bottom: parent.bottom; anchors.right: parent.right }
                            Rectangle { width: 1; height: 5; color: Theme.accent; anchors.bottom: parent.bottom; anchors.right: parent.right }

                            Column {
                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: 5

                                Text {
                                    text: "[ REGISTRO // ACTIVIDAD ]"
                                    font.family: Theme.font
                                    font.pixelSize: 8
                                    font.bold: true
                                    color: Theme.muted
                                }

                                Column {
                                    width: parent.width
                                    spacing: 4

                                    Repeater {
                                        model: popup.agentHistory.length > 0 ? popup.agentHistory.slice(0, 6) : 0

                                        Row {
                                            spacing: 5
                                            width: parent.width

                                            Text {
                                                text: modelData.time || "--:--:--"
                                                font.family: Theme.font
                                                font.pixelSize: 7
                                                color: Theme.muted
                                                anchors.verticalCenter: parent.verticalCenter
                                            }

                                            Text {
                                                text: modelData.status === "ok" ? "󰄬" : (modelData.status === "error" ? "󰅖" : "󰑮")
                                                font.family: Theme.font
                                                font.pixelSize: 8
                                                color: modelData.status === "ok" ? Theme.accent : (modelData.status === "error" ? Theme.red : Theme.amber)
                                                anchors.verticalCenter: parent.verticalCenter
                                            }

                                            // Tag de categoría
                                            Text {
                                                text: "[" + (modelData.category || "TOOL") + "]"
                                                font.family: Theme.font
                                                font.pixelSize: 7
                                                font.bold: true
                                                color: Theme.accent
                                                anchors.verticalCenter: parent.verticalCenter
                                            }

                                            Text {
                                                text: modelData.target || modelData.tool || ""
                                                font.family: Theme.font
                                                font.pixelSize: 8
                                                color: Theme.text
                                                elide: Text.ElideRight
                                                width: parent.width - 110
                                                anchors.verticalCenter: parent.verticalCenter
                                            }
                                        }
                                    }

                                    Text {
                                        visible: !popup.agentHistory || popup.agentHistory.length === 0
                                        text: "Sin eventos registrados en la sesión actual."
                                        font.family: Theme.font
                                        font.pixelSize: 8
                                        color: Theme.muted
                                    }
                                }

                                // Ticker de archivos modificados al fondo si existen
                                Item {
                                    width: parent.width
                                    height: 18
                                    visible: popup.agentFilesModified && popup.agentFilesModified.length > 0

                                    Rectangle {
                                        width: parent.width
                                        height: 1
                                        color: Theme.separator
                                        anchors.top: parent.top
                                    }

                                    Row {
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 4
                                        width: parent.width

                                        Text {
                                            text: "MODS:"
                                            font.family: Theme.font
                                            font.pixelSize: 7
                                            font.bold: true
                                            color: Theme.amber
                                        }

                                        Text {
                                            text: popup.agentFilesModified.slice(-3).join(", ")
                                            font.family: Theme.font
                                            font.pixelSize: 7
                                            color: Theme.text
                                            elide: Text.ElideRight
                                            width: parent.width - 35
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Process { id: actionProc }
    Process { id: mediaCmdProc }
    Process { id: launchProc }
    Process { id: seekProc }

    Process {
        id: brightStatusProc
        command: ["brightnessctl", "-m"]
        stdout: StdioCollector { id: brightCollector }
        onExited: {
            let parts = brightCollector.text.trim().split(",")
            if (parts.length >= 4) {
                let pct = parseInt(parts[3]) || 0
                popup.currentBright = pct / 100.0
            }
        }
    }

    Process {
        id: weatherProc
        command: ["curl", "-s", "https://wttr.in/Puebla?format=%25t+%25C"]
        stdout: StdioCollector { id: weatherCollector }
        onExited: {
            let raw = weatherCollector.text.trim()
            if (!raw) return
            let clean = raw.replace(/\+/g, "")
            let parts = clean.split(" ")
            popup.weatherTemp = parts[0]
            let cond = parts.slice(1).join(" ")
            popup.weatherCondition = cond ? (cond.charAt(0).toUpperCase() + cond.slice(1)) : "Despejado"
            let lower = cond.toLowerCase()
            let icon = "󰖐"
            if (lower.includes("sunny") || lower.includes("clear"))        icon = "󰖙"
            else if (lower.includes("cloud") || lower.includes("overcast")) icon = "󰖐"
            else if (lower.includes("rain") || lower.includes("drizzle") ||
                     lower.includes("shower"))                              icon = "󰖖"
            else if (lower.includes("snow"))                               icon = "󰼶"
            else if (lower.includes("thunder") || lower.includes("storm")) icon = "󰖓"
            popup.weatherIcon = icon
        }
    }

    Timer {
        id: weatherTimer
        interval: 300000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: weatherProc.running = true
    }

    // Telemetría de sistema (PERF)
    Process {
        id: sysProc
        command: ["/home/emn/.config/quickshell/modules/popups/system_telemetry.py"]
        stdout: StdioCollector { id: sysCollector }
        onExited: {
            try {
                let data = JSON.parse(sysCollector.text.trim())
                popup.sysCpuUsage = data.cpu_usage || 0.0
                popup.sysCpuDisplay = data.cpu_display || "0%"
                popup.sysCpuWarn = !!data.cpu_warn

                popup.sysRamUsage = data.ram_usage || 0.0
                popup.sysRamDisplay = data.ram_display || "0%"

                popup.sysCpuTemp = data.cpu_temp || 0.0
                popup.sysCpuTempDisplay = data.cpu_temp_display || "0°C"
                popup.sysCpuTempWarn = !!data.cpu_temp_warn

                popup.sysGpuTemp = data.gpu_temp || 0.0
                popup.sysGpuTempDisplay = data.gpu_temp_display || "0°C"
            } catch (e) {}
        }
    }

    Timer {
        id: sysTimer
        interval: 2000
        running: popup.visible && popup.currentTab === "perf"
        repeat: true
        onTriggered: {
            if (!sysProc.running) sysProc.running = true
        }
    }

    // Telemetría de medios (MEDIA)
    Process {
        id: mediaProc
        command: ["/home/emn/.config/quickshell/modules/popups/media_telemetry.py"]
        stdout: StdioCollector { id: mediaCollector }
        onExited: {
            try {
                let data = JSON.parse(mediaCollector.text.trim())
                popup.mediaActive = !!data.active
                popup.mediaTitle = data.title || "SIN REPRODUCCIÓN"
                popup.mediaArtist = data.artist || "MPRIS2 // STANDBY"
                popup.mediaAlbum = data.album || ""
                popup.mediaStatus = data.status || "Stopped"
                popup.mediaProgress = data.progress || 0.0
                popup.mediaPosStr = data.pos_str || "0:00"
                popup.mediaLengthStr = data.length_str || "0:00"
                popup.mediaLengthSec = data.length_sec || 0
                popup.mediaPosSec = data.pos_sec || 0
                popup.mediaArtUrl = data.art_url || ""
            } catch (e) {}
        }
    }

    // Visualizador de audio táctico en tiempo real (CAVA)
    Process {
        id: cavaProc
        command: ["/home/emn/.local/bin/cava", "-p", "/home/emn/.config/quickshell/modules/popups/cava.conf"]
        running: popup.visible && popup.currentTab === "media"
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: (data) => {
                let parts = data.trim().split(";").filter(s => s !== "").map(Number)
                if (parts.length > 0) {
                    popup.cavaValues = parts
                }
            }
        }
    }

    Timer {
        id: mediaTimer
        interval: 1000
        running: popup.visible && popup.currentTab === "media"
        repeat: true
        onTriggered: {
            if (!mediaProc.running) mediaProc.running = true
        }
    }

    Timer {
        id: mediaFastRefreshTimer
        interval: 250
        running: false
        repeat: false
        onTriggered: {
            if (!mediaProc.running) mediaProc.running = true
        }
    }

    // Telemetría de Agente (Antigravity // Entrati)
    Process {
        id: dashAgentProc
        command: ["cat", "/run/user/1000/pom2-agent.json"]
        stdout: StdioCollector { id: dashAgentCollector }
        onExited: {
            try {
                let d = JSON.parse(dashAgentCollector.text.trim())
                popup.agentState = d.state || "idle"
                popup.agentActive = !!d.active
                popup.agentTool = d.tool || ""
                popup.agentCategory = d.category || "STANDBY"
                popup.agentIcon = d.icon || "󰍛"
                popup.agentTarget = d.target || ""
                popup.agentDetail = d.detail || ""
                popup.agentHistory = d.history || []
                popup.agentCallCount = d.call_count || 0
                popup.agentFilesModified = d.files_modified || []
            } catch (e) {}
        }
    }

    Timer {
        id: dashAgentTimer
        interval: popup.agentActive ? 600 : 1500
        running: popup.visible && popup.currentTab === "agent"
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!dashAgentProc.running) dashAgentProc.running = true
        }
    }

    // Subprocesos de Notificaciones Generales (SwayNC CLI + Logger en RAM)
    Process {
        id: notifCountProc
        command: ["swaync-client", "-c"]
        stdout: StdioCollector { id: notifCollector }
        onExited: {
            let count = parseInt(notifCollector.text.trim())
            popup.unreadCount = isNaN(count) ? 0 : count
        }
    }

    Process {
        id: notifListProc
        command: ["/home/emn/.local/bin/pom2-notif-logger", "--get"]
        stdout: StdioCollector { id: notifListCollector }
        onExited: {
            try {
                let list = JSON.parse(notifListCollector.text.trim())
                popup.notificationsList = Array.isArray(list) ? list : []
            } catch (e) {
                popup.notificationsList = []
            }
        }
    }

    Process {
        id: notifClearProc
        command: ["bash", "-c", "pom2-notif-logger --clear && swaync-client -C"]
        onExited: {
            popup.unreadCount = 0
            popup.notificationsList = []
            if (!notifCountProc.running) notifCountProc.running = true
            if (!notifListProc.running) notifListProc.running = true
        }
    }

    Timer {
        id: notifTimer
        interval: 2500
        running: popup.visible && popup.currentTab === "dash"
        repeat: true
        onTriggered: {
            if (!notifCountProc.running) notifCountProc.running = true
            if (!notifListProc.running) notifListProc.running = true
        }
    }
}
