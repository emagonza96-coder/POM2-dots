import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import "../.."

PopupWindow {
    id: popup
    property var parentAnchor
    anchor.item: parentAnchor
    anchor.edges: Edges.Bottom
    implicitWidth: 350
    implicitHeight: 390
    color: "transparent"
    grabFocus: true

    // Pestaña activa: "dash" | "perf" | "media"
    property string currentTab: "dash"

    // Estado real de brillo
    property real currentBright: 0.75

    // Estado del Clima (telemetría ambiental)
    property string weatherTemp: "--°C"
    property string weatherIcon: "󰖐"
    property string weatherCondition: "Consultando..."

    Component.onCompleted: {
        if (visible) {
            container.opacity = 1
            slideTranslate.y = 0
            if (!brightStatusProc.running) brightStatusProc.running = true
            if (!weatherProc.running) weatherProc.running = true
        }
    }

    onVisibleChanged: {
        if (visible) {
            fadeIn.start()
            slideIn.start()
            if (!brightStatusProc.running) brightStatusProc.running = true
            if (!weatherProc.running) weatherProc.running = true
        } else {
            container.opacity = 0
            slideTranslate.y = -6
        }
    }

    Rectangle {
        id: container
        anchors.fill: parent
        color: Theme.surface
        border.color: Theme.border
        border.width: 1
        radius: 0
        clip: true
        opacity: 0
        transform: Translate { id: slideTranslate; y: -6 }

        NumberAnimation { id: fadeIn;  target: container;      property: "opacity"; from: 0;  to: 1; duration: 180; easing.type: Easing.OutQuad }
        NumberAnimation { id: slideIn; target: slideTranslate; property: "y";       from: -6; to: 0; duration: 180; easing.type: Easing.OutQuad }

        // Muescas tácticas iluminadas en las 4 esquinas del popup en verde POM-2
        Rectangle { width: 6; height: 1; color: Theme.accent; anchors.top: parent.top; anchors.left: parent.left }
        Rectangle { width: 1; height: 6; color: Theme.accent; anchors.top: parent.top; anchors.left: parent.left }
        Rectangle { width: 6; height: 1; color: Theme.accent; anchors.top: parent.top; anchors.right: parent.right }
        Rectangle { width: 1; height: 6; color: Theme.accent; anchors.top: parent.top; anchors.right: parent.right }
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
                        width: parent.width / 3
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
                        width: parent.width / 3
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
                        width: parent.width / 3
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
                }
            }

            // ========================================================
            // VISTA 1: TAB DASH (BRILLO VERTICAL + SESIÓN TÁCTICA)
            // ========================================================
            Item {
                width: parent.width
                height: parent.height - 42
                visible: popup.currentTab === "dash"

                Row {
                    anchors.fill: parent
                    spacing: 12

                    // SLIDER VERTICAL: BRILLO
                    TacticalVerticalSlider {
                        id: brightSlider
                        width: 72
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

                    // PANEL DERECHO: METEO Y CONTROL DE SESIÓN
                    Column {
                        width: parent.width - brightSlider.width - 12
                        height: parent.height
                        spacing: 8

                        // TARJETA DE TELEMETRÍA AMBIENTAL: CLIMA
                        Rectangle {
                            id: weatherCard
                            width: parent.width
                            height: 50
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

                            Text {
                                id: weatherIconText
                                text: popup.weatherIcon
                                font.family: Theme.font
                                font.pixelSize: 22
                                color: Theme.accent
                                anchors.left: parent.left
                                anchors.leftMargin: 12
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Column {
                                anchors.left: weatherIconText.right
                                anchors.leftMargin: 10
                                anchors.right: parent.right
                                anchors.rightMargin: 10
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2

                                Text {
                                    text: "[ENV // PUEBLA - METEO]"
                                    font.family: Theme.font
                                    font.pixelSize: 8
                                    font.bold: true
                                    color: Theme.muted
                                }

                                Row {
                                    spacing: 6
                                    Text {
                                        text: popup.weatherTemp
                                        font.family: Theme.font
                                        font.pixelSize: 13
                                        font.bold: true
                                        color: Theme.text
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                    Text {
                                        text: "· " + popup.weatherCondition
                                        font.family: Theme.font
                                        font.pixelSize: 9
                                        color: Theme.accent
                                        elide: Text.ElideRight
                                        maximumLineCount: 1
                                        anchors.verticalCenter: parent.verticalCenter
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

                        // Grid 2x2 de botones tácticos con esquinas iluminadas
                        Grid {
                            width: parent.width
                            columns: 2
                            spacing: 8

                            // BOTÓN 1: SUSPEND
                            Rectangle {
                                id: suspBtn
                                width: (parent.width - 8) / 2
                                height: 104
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
                                    spacing: 6

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
                                            font.pixelSize: 9
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
                                width: (parent.width - 8) / 2
                                height: 104
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
                                    spacing: 6

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
                                            font.pixelSize: 9
                                            font.bold: true
                                            color: lockMouse.containsMouse ? Theme.accent : Theme.text
                                        }
                                        Text {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            text: "AUTH // SEC"
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
                                id: rebootBtn
                                width: (parent.width - 8) / 2
                                height: 104
                                radius: 0
                                color: rebootMouse.containsMouse ? "#241d0c" : "#081109"
                                border.color: rebootMouse.containsMouse ? Theme.amber : Theme.separator
                                border.width: 1

                                readonly property color cornerColor: rebootMouse.containsMouse ? Theme.amber : Theme.border
                                Rectangle { width: 5; height: 1; color: rebootBtn.cornerColor; anchors.top: parent.top; anchors.left: parent.left }
                                Rectangle { width: 1; height: 5; color: rebootBtn.cornerColor; anchors.top: parent.top; anchors.left: parent.left }
                                Rectangle { width: 5; height: 1; color: rebootBtn.cornerColor; anchors.top: parent.top; anchors.right: parent.right }
                                Rectangle { width: 1; height: 5; color: rebootBtn.cornerColor; anchors.top: parent.top; anchors.right: parent.right }
                                Rectangle { width: 5; height: 1; color: rebootBtn.cornerColor; anchors.bottom: parent.bottom; anchors.left: parent.left }
                                Rectangle { width: 1; height: 5; color: rebootBtn.cornerColor; anchors.bottom: parent.bottom; anchors.left: parent.left }
                                Rectangle { width: 5; height: 1; color: rebootBtn.cornerColor; anchors.bottom: parent.bottom; anchors.right: parent.right }
                                Rectangle { width: 1; height: 5; color: rebootBtn.cornerColor; anchors.bottom: parent.bottom; anchors.right: parent.right }

                                Column {
                                    anchors.centerIn: parent
                                    spacing: 6

                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: "󰑐"
                                        font.family: Theme.font
                                        font.pixelSize: 18
                                        color: rebootMouse.containsMouse ? Theme.amber : Theme.text
                                    }
                                    Column {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        spacing: 2
                                        Text {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            text: "REBOOT"
                                            font.family: Theme.font
                                            font.pixelSize: 9
                                            font.bold: true
                                            color: rebootMouse.containsMouse ? Theme.amber : Theme.text
                                        }
                                        Text {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            text: "WARM // RST"
                                            font.family: Theme.font
                                            font.pixelSize: 7
                                            color: Theme.muted
                                        }
                                    }
                                }

                                MouseArea {
                                    id: rebootMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: actionProc.exec(["systemctl", "reboot"])
                                }
                            }

                            // BOTÓN 4: SHUTDOWN
                            Rectangle {
                                id: shutBtn
                                width: (parent.width - 8) / 2
                                height: 104
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
                                    spacing: 6

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
                                            text: "SHUTDOWN"
                                            font.family: Theme.font
                                            font.pixelSize: 9
                                            font.bold: true
                                            color: shutMouse.containsMouse ? Theme.red : Theme.text
                                        }
                                        Text {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            text: "POWER // OFF"
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
                }
            }

            // ========================================================
            // VISTA 2: TAB PERF (MÉTRICAS TÁCTICAS)
            // ========================================================
            Item {
                width: parent.width
                height: parent.height - 42
                visible: popup.currentTab === "perf"

                Grid {
                    anchors.centerIn: parent
                    columns: 2
                    spacing: 12

                    TacticalRing {
                        code: "SYS // CPU_LOAD"
                        label: "CPU USO"
                        value: 0.18
                        displayValue: "18%"
                        activeColor: Theme.accent
                    }

                    TacticalRing {
                        code: "MEM // RAM_ALLOC"
                        label: "RAM USO"
                        value: 0.42
                        displayValue: "42%"
                        activeColor: Theme.accent
                    }

                    TacticalRing {
                        code: "THM // CPU_THERM"
                        label: "CPU TEMP"
                        value: 0.48
                        displayValue: "48°C"
                        activeColor: Theme.accent
                        warnColor: Theme.amber
                        warning: false
                    }

                    TacticalRing {
                        code: "THM // GPU_THERM"
                        label: "GPU TEMP"
                        value: 0.41
                        displayValue: "41°C"
                        activeColor: Theme.accent
                    }
                }
            }

            // ========================================================
            // VISTA 3: TAB MEDIA (CONSOLA SPOTIFY TÁCTICA)
            // ========================================================
            Item {
                width: parent.width
                height: parent.height - 42
                visible: popup.currentTab === "media"

                Column {
                    anchors.centerIn: parent
                    spacing: 14
                    width: parent.width - 24

                    Row {
                        spacing: 6
                        Text {
                            text: "[MEDIA // SPOTIFY_RECEIVER]"
                            font.family: Theme.font
                            font.pixelSize: 8
                            font.bold: true
                            color: Theme.muted
                        }
                    }

                    Rectangle {
                        width: 108; height: 108; radius: 0
                        color: "#081109"
                        border.color: Theme.border; border.width: 1
                        anchors.horizontalCenter: parent.horizontalCenter

                        Rectangle { width: 5; height: 1; color: Theme.accent; anchors.top: parent.top; anchors.left: parent.left }
                        Rectangle { width: 1; height: 5; color: Theme.accent; anchors.top: parent.top; anchors.left: parent.left }
                        Rectangle { width: 5; height: 1; color: Theme.accent; anchors.top: parent.top; anchors.right: parent.right }
                        Rectangle { width: 1; height: 5; color: Theme.accent; anchors.top: parent.top; anchors.right: parent.right }
                        Rectangle { width: 5; height: 1; color: Theme.accent; anchors.bottom: parent.bottom; anchors.left: parent.left }
                        Rectangle { width: 1; height: 5; color: Theme.accent; anchors.bottom: parent.bottom; anchors.left: parent.left }
                        Rectangle { width: 5; height: 1; color: Theme.accent; anchors.bottom: parent.bottom; anchors.right: parent.right }
                        Rectangle { width: 1; height: 5; color: Theme.accent; anchors.bottom: parent.bottom; anchors.right: parent.right }

                        Text {
                            anchors.centerIn: parent
                            text: "󰓇"
                            font.family: Theme.font
                            font.pixelSize: 34
                            color: Theme.accent
                        }
                    }

                    Column {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 3
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "TRACK // SIN REPRODUCCIÓN"
                            font.family: Theme.font
                            font.pixelSize: 10
                            font.bold: true
                            color: Theme.text
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "MPRIS2 // STANDBY"
                            font.family: Theme.font
                            font.pixelSize: 8
                            color: Theme.muted
                        }
                    }

                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 2
                        Repeater {
                            model: 24
                            Rectangle {
                                width: 9; height: 3; radius: 0
                                color: index < 8 ? Theme.accent : "#0e1a10"
                                border.color: index < 8 ? Theme.border : "#132416"
                                border.width: 1
                            }
                        }
                    }

                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 12

                        Rectangle {
                            width: 36; height: 26; radius: 0
                            color: "#081109"; border.color: Theme.separator; border.width: 1
                            Text { anchors.centerIn: parent; text: "󰒮"; font.family: Theme.font; font.pixelSize: 12; color: Theme.text }
                        }
                        Rectangle {
                            width: 52; height: 26; radius: 0
                            color: "#112213"; border.color: Theme.accent; border.width: 1
                            Text { anchors.centerIn: parent; text: "󰐊"; font.family: Theme.font; font.pixelSize: 14; color: Theme.accent }
                        }
                        Rectangle {
                            width: 36; height: 26; radius: 0
                            color: "#081109"; border.color: Theme.separator; border.width: 1
                            Text { anchors.centerIn: parent; text: "󰒭"; font.family: Theme.font; font.pixelSize: 12; color: Theme.text }
                        }
                    }
                }
            }
        }
    }

    Process { id: actionProc }

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
}
