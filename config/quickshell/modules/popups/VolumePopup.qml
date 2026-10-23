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
    implicitHeight: Math.min(mainColumn.implicitHeight + 24, 560)
    color: "transparent"
    grabFocus: true

    // Pestaña activa: "audio" | "bluetooth"
    property string currentTab: "audio"

    // Estado Audio
    property string masterSinkName: ""
    property var sinksList: []
    property var appsList: []
    property int selectedAppForSinkMenu: -1

    // Estado Bluetooth
    property bool btPowered: true
    property bool btDiscovering: false
    property var btPairedDevices: []
    property var btAvailableDevices: []
    property string connectingMac: ""

    function getBatteryGlyph(val) {
        if (val === null || val === undefined) return "󰂎"
        if (val >= 90) return "󰁹"
        if (val >= 75) return "󰂂"
        if (val >= 60) return "󰂀"
        if (val >= 45) return "󰁾"
        if (val >= 30) return "󰁽"
        if (val >= 15) return "󰁼"
        return "󰁺"
    }

    Component.onCompleted: {
        if (visible) {
            container.opacity = 1
            slideTranslate.y = 0
            statusProc.running = true
            btStatusProc.running = true
        }
    }

    onVisibleChanged: {
        if (visible) {
            fadeIn.start()
            slideIn.start()
            statusProc.running = true
            btStatusProc.running = true
        } else {
            selectedAppForSinkMenu = -1
            container.opacity = 0
            slideTranslate.y = -6
        }
    }

    // Contenedor principal con animación de entrada
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

        // Muescas tácticas iluminadas en las 4 esquinas del popup en verde POM-2
        Rectangle { width: 6; height: 1; color: Theme.accent; anchors.top: parent.top; anchors.left: parent.left }
        Rectangle { width: 1; height: 6; color: Theme.accent; anchors.top: parent.top; anchors.left: parent.left }
        Rectangle { width: 6; height: 1; color: Theme.accent; anchors.top: parent.top; anchors.right: parent.right }
        Rectangle { width: 1; height: 6; color: Theme.accent; anchors.top: parent.top; anchors.right: parent.right }
        Rectangle { width: 6; height: 1; color: Theme.accent; anchors.bottom: parent.bottom; anchors.left: parent.left }
        Rectangle { width: 1; height: 6; color: Theme.accent; anchors.bottom: parent.bottom; anchors.left: parent.left }
        Rectangle { width: 6; height: 1; color: Theme.accent; anchors.bottom: parent.bottom; anchors.right: parent.right }
        Rectangle { width: 1; height: 6; color: Theme.accent; anchors.bottom: parent.bottom; anchors.right: parent.right }

        NumberAnimation { id: fadeIn;  target: container;      property: "opacity"; from: 0;  to: 1; duration: 180; easing.type: Easing.OutQuad }
        NumberAnimation { id: slideIn; target: slideTranslate; property: "y";       from: -6; to: 0; duration: 180; easing.type: Easing.OutQuad }

        Flickable {
            id: scrollArea
            anchors.fill: parent
            anchors.margins: 12
            contentWidth: width
            contentHeight: mainColumn.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: mainColumn
                width: parent.width
                spacing: 12

                // ==========================================
                // BARRA DE PESTAÑAS (TABS): AUDIO / BLUETOOTH
                // ==========================================
                Item {
                    width: parent.width
                    height: 32

                    // Línea base sutil
                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width
                        height: 1
                        color: Theme.separator
                    }

                    Row {
                        anchors.fill: parent
                        spacing: 0

                        // Pestaña Audio
                        Item {
                            id: tabAudioBtn
                            width: parent.width / 2
                            height: parent.height
                            property bool isActive: popup.currentTab === "audio"
                            property bool hovered: false

                            // Underline indicator tipo Workspace
                            Rectangle {
                                anchors.bottom: parent.bottom
                                anchors.horizontalCenter: parent.horizontalCenter
                                height: 2
                                width: tabAudioBtn.isActive ? parent.width * 0.65 : 0
                                radius: 0
                                color: Theme.accent
                                Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                            }

                            Row {
                                anchors.centerIn: parent
                                spacing: 6
                                scale: tabAudioBtn.isActive ? 1.05 : 1.0
                                Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack } }

                                Text {
                                    text: "󰕾"
                                    font.family: Theme.font
                                    font.pixelSize: 12
                                    color: tabAudioBtn.isActive ? Theme.accent : (tabAudioBtn.hovered ? Theme.text : Theme.muted)
                                    anchors.verticalCenter: parent.verticalCenter
                                    Behavior on color { ColorAnimation { duration: 180 } }
                                }

                                Text {
                                    text: "Audio"
                                    font.family: Theme.font
                                    font.pixelSize: 11
                                    font.bold: tabAudioBtn.isActive
                                    color: tabAudioBtn.isActive ? Theme.accent : (tabAudioBtn.hovered ? Theme.text : Theme.muted)
                                    anchors.verticalCenter: parent.verticalCenter
                                    Behavior on color { ColorAnimation { duration: 180 } }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onEntered: tabAudioBtn.hovered = true
                                onExited:  tabAudioBtn.hovered = false
                                onClicked: popup.currentTab = "audio"
                            }
                        }

                        // Pestaña Bluetooth
                        Item {
                            id: tabBtBtn
                            width: parent.width / 2
                            height: parent.height
                            property bool isActive: popup.currentTab === "bluetooth"
                            property bool hovered: false

                            // Underline indicator tipo Workspace
                            Rectangle {
                                anchors.bottom: parent.bottom
                                anchors.horizontalCenter: parent.horizontalCenter
                                height: 2
                                width: tabBtBtn.isActive ? parent.width * 0.65 : 0
                                radius: 0
                                color: Theme.accent
                                Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                            }

                            Row {
                                anchors.centerIn: parent
                                spacing: 6
                                scale: tabBtBtn.isActive ? 1.05 : 1.0
                                Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack } }

                                Text {
                                    text: "󰂯"
                                    font.family: Theme.font
                                    font.pixelSize: 12
                                    color: tabBtBtn.isActive ? Theme.accent : (tabBtBtn.hovered ? Theme.text : Theme.muted)
                                    anchors.verticalCenter: parent.verticalCenter
                                    Behavior on color { ColorAnimation { duration: 180 } }
                                }

                                Text {
                                    text: "Bluetooth"
                                    font.family: Theme.font
                                    font.pixelSize: 11
                                    font.bold: tabBtBtn.isActive
                                    color: tabBtBtn.isActive ? Theme.accent : (tabBtBtn.hovered ? Theme.text : Theme.muted)
                                    anchors.verticalCenter: parent.verticalCenter
                                    Behavior on color { ColorAnimation { duration: 180 } }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onEntered: tabBtBtn.hovered = true
                                onExited:  tabBtBtn.hovered = false
                                onClicked: {
                                    popup.currentTab = "bluetooth"
                                    btStatusProc.running = true
                                }
                            }
                        }
                    }
                }

                // ==========================================
                // VISTA 1: AUDIO
                // ==========================================
                Column {
                    width: parent.width
                    spacing: 12
                    visible: popup.currentTab === "audio"

                    // SALIDAS DE AUDIO (DISPOSITIVOS)
                    Column {
                        width: parent.width
                        spacing: 8

                        Text {
                            text: "SALIDAS DE AUDIO"
                            font.family: Theme.font
                            font.pixelSize: 10
                            font.bold: true
                            color: Theme.muted
                        }

                        Repeater {
                            model: popup.sinksList

                            Rectangle {
                                id: sinkCard
                                width: parent.width
                                implicitHeight: sinkCol.implicitHeight + 14
                                radius: 0
                                
                                readonly property string sinkName: modelData.name
                                readonly property int sinkId: modelData.id
                                readonly property string sinkDesc: modelData.description || modelData.name
                                readonly property string sinkIcon: modelData.icon || "󰓃"
                                readonly property bool isDefault: Boolean(modelData.isDefault) || sinkName === popup.masterSinkName
                                property real sinkVol: modelData.volume
                                property bool sinkMuted: Boolean(modelData.muted)

                                color: isDefault ? "#0f1c11" : "#09130b"
                                border.color: isDefault ? Theme.accent : Theme.separator
                                border.width: 1

                                // Esquinas tácticas iluminadas
                                readonly property color cornerColor: isDefault ? Theme.accent : Theme.border
                                Rectangle { width: 5; height: 1; color: sinkCard.cornerColor; anchors.top: parent.top; anchors.left: parent.left }
                                Rectangle { width: 1; height: 5; color: sinkCard.cornerColor; anchors.top: parent.top; anchors.left: parent.left }
                                Rectangle { width: 5; height: 1; color: sinkCard.cornerColor; anchors.top: parent.top; anchors.right: parent.right }
                                Rectangle { width: 1; height: 5; color: sinkCard.cornerColor; anchors.top: parent.top; anchors.right: parent.right }
                                Rectangle { width: 5; height: 1; color: sinkCard.cornerColor; anchors.bottom: parent.bottom; anchors.left: parent.left }
                                Rectangle { width: 1; height: 5; color: sinkCard.cornerColor; anchors.bottom: parent.bottom; anchors.left: parent.left }
                                Rectangle { width: 5; height: 1; color: sinkCard.cornerColor; anchors.bottom: parent.bottom; anchors.right: parent.right }
                                Rectangle { width: 1; height: 5; color: sinkCard.cornerColor; anchors.bottom: parent.bottom; anchors.right: parent.right }

                                Column {
                                    id: sinkCol
                                    width: parent.width - 16
                                    anchors.centerIn: parent
                                    spacing: 8

                                    // Fila superior: Ícono de salida + Nombre + Botón "Usar para todo"
                                    Row {
                                        width: parent.width
                                        spacing: 6

                                        Text {
                                            text: sinkCard.sinkIcon
                                            font.family: Theme.font
                                            font.pixelSize: 13
                                            color: sinkCard.isDefault ? Theme.accent : Theme.text
                                            anchors.verticalCenter: parent.verticalCenter
                                        }

                                        Text {
                                            text: sinkCard.sinkDesc
                                            font.family: Theme.font
                                            font.pixelSize: 11
                                            font.bold: true
                                            color: sinkCard.isDefault ? Theme.accent : Theme.text
                                            elide: Text.ElideRight
                                            maximumLineCount: 1
                                            width: Math.min(implicitWidth, sinkCard.width - (modelData.battery !== null ? 210 : 160))
                                            anchors.verticalCenter: parent.verticalCenter
                                        }

                                        // Badge de batería si la salida es Bluetooth
                                        Rectangle {
                                            visible: modelData.battery !== null && modelData.battery !== undefined
                                            height: 15
                                            width: sinkBatRow.implicitWidth + 8
                                            radius: 0
                                            color: (modelData.battery !== null && modelData.battery < 25) ? "#2b1a10" : "#132515"
                                            border.color: (modelData.battery !== null && modelData.battery < 25) ? Theme.amber : Theme.accent
                                            border.width: 1
                                            anchors.verticalCenter: parent.verticalCenter

                                            Row {
                                                id: sinkBatRow
                                                anchors.centerIn: parent
                                                spacing: 3

                                                Text {
                                                    text: getBatteryGlyph(modelData.battery)
                                                    font.family: Theme.font
                                                    font.pixelSize: 9
                                                    color: (modelData.battery !== null && modelData.battery < 25) ? Theme.amber : Theme.accent
                                                    anchors.verticalCenter: parent.verticalCenter
                                                }

                                                Text {
                                                    text: (modelData.battery !== null ? modelData.battery : 0) + "%"
                                                    font.family: Theme.font
                                                    font.pixelSize: 8
                                                    font.bold: true
                                                    color: (modelData.battery !== null && modelData.battery < 25) ? Theme.amber : Theme.text
                                                    anchors.verticalCenter: parent.verticalCenter
                                                }
                                            }
                                        }

                                        Item { width: 1; height: 1; Layout.fillWidth: true }

                                        // Indicador / Botón de salida general
                                        Rectangle {
                                            id: masterToggleBtn
                                            height: 20
                                            width: masterToggleRow.implicitWidth + 12
                                            radius: 0
                                            anchors.verticalCenter: parent.verticalCenter
                                            
                                            color: sinkCard.isDefault ? "#1a331c" : (masterMouse.containsMouse ? "#142416" : "#0d180f")
                                            border.color: sinkCard.isDefault ? Theme.accent : Theme.separator
                                            border.width: 1

                                            Row {
                                                id: masterToggleRow
                                                anchors.centerIn: parent
                                                spacing: 4

                                                Text {
                                                    text: sinkCard.isDefault ? "✓ Salida general" : "󰁯 Usar para todo"
                                                    font.family: Theme.font
                                                    font.pixelSize: 9
                                                    color: sinkCard.isDefault ? Theme.accent : (masterMouse.containsMouse ? Theme.text : Theme.muted)
                                                    anchors.verticalCenter: parent.verticalCenter
                                                }
                                            }

                                            MouseArea {
                                                id: masterMouse
                                                anchors.fill: parent
                                                hoverEnabled: !sinkCard.isDefault
                                                cursorShape: sinkCard.isDefault ? Qt.ArrowCursor : Qt.PointingHandCursor
                                                onClicked: {
                                                    if (!sinkCard.isDefault) {
                                                        cmdProc.exec(["/home/emn/.config/quickshell/modules/popups/audio_ctl.py", "set-master-sink", sinkCard.sinkName])
                                                        popup.masterSinkName = sinkCard.sinkName
                                                        refreshTimer.restart()
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    // Fila inferior: Mute independiente + Slider de volumen independiente + %
                                    Row {
                                        width: parent.width
                                        spacing: 8

                                        // Botón mute salida individual
                                        Rectangle {
                                            id: sinkMuteBtn
                                            width: 22; height: 22; radius: 0
                                            color: sinkMuteHover.containsMouse ? (sinkCard.sinkMuted ? "#3a2a0a" : "#122212") : "transparent"
                                            border.color: sinkCard.sinkMuted ? Theme.amber : Theme.border
                                            anchors.verticalCenter: parent.verticalCenter
                                            Behavior on color { ColorAnimation { duration: 120 } }
                                            Behavior on border.color { ColorAnimation { duration: 150 } }

                                            Text {
                                                anchors.centerIn: parent
                                                font.family: Theme.iconFont
                                                font.pixelSize: 11
                                                color: sinkCard.sinkMuted ? Theme.amber : Theme.accent
                                                text: sinkCard.sinkMuted ? "\ue9bf" : "\ue9c0"
                                                Behavior on color { ColorAnimation { duration: 150 } }
                                            }
                                            MouseArea {
                                                id: sinkMuteHover
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    sinkCard.sinkMuted = !sinkCard.sinkMuted
                                                    cmdProc.exec(["/home/emn/.config/quickshell/modules/popups/audio_ctl.py", "toggle-sink-mute", sinkCard.sinkName])
                                                    refreshTimer.restart()
                                                }
                                            }
                                        }

                                        // Slider volumen individual retro táctico
                                        TacticalSlider {
                                            width: parent.width - 68
                                            anchors.verticalCenter: parent.verticalCenter
                                            value: sinkCard.sinkVol
                                            maxVal: 1.5
                                            allowOverdrive: true
                                            muted: sinkCard.sinkMuted
                                            onMoved: (val) => {
                                                sinkCard.sinkVol = val
                                                cmdProc.exec(["/home/emn/.config/quickshell/modules/popups/audio_ctl.py", "set-sink-volume", sinkCard.sinkName, val.toFixed(2)])
                                            }
                                            onCommitted: (val) => {
                                                sinkCard.sinkVol = val
                                                cmdProc.exec(["/home/emn/.config/quickshell/modules/popups/audio_ctl.py", "set-sink-volume", sinkCard.sinkName, val.toFixed(2)])
                                                refreshTimer.restart()
                                            }
                                        }

                                        // Porcentaje salida
                                        Text {
                                            text: Math.round(sinkCard.sinkVol * 100) + "%"
                                            font.family: Theme.font
                                            font.pixelSize: 10
                                            color: sinkCard.sinkMuted ? Theme.muted : Theme.text
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Separador
                    Rectangle {
                        width: parent.width
                        height: 1
                        color: Theme.separator
                    }

                    // VOLUMEN POR APLICACIÓN
                    Column {
                        width: parent.width
                        spacing: 8

                        Text {
                            text: "VOLUMEN POR APLICACIÓN"
                            font.family: Theme.font
                            font.pixelSize: 10
                            font.bold: true
                            color: Theme.muted
                        }

                        Rectangle {
                            width: parent.width
                            height: 36
                            radius: 0
                            color: "#09120b"
                            border.color: Theme.separator
                            border.width: 1
                            visible: popup.appsList.length === 0

                            Rectangle { width: 4; height: 1; color: Theme.border; anchors.top: parent.top; anchors.left: parent.left }
                            Rectangle { width: 1; height: 4; color: Theme.border; anchors.top: parent.top; anchors.left: parent.left }
                            Rectangle { width: 4; height: 1; color: Theme.border; anchors.top: parent.top; anchors.right: parent.right }
                            Rectangle { width: 1; height: 4; color: Theme.border; anchors.top: parent.top; anchors.right: parent.right }
                            Rectangle { width: 4; height: 1; color: Theme.border; anchors.bottom: parent.bottom; anchors.left: parent.left }
                            Rectangle { width: 1; height: 4; color: Theme.border; anchors.bottom: parent.bottom; anchors.left: parent.left }
                            Rectangle { width: 4; height: 1; color: Theme.border; anchors.bottom: parent.bottom; anchors.right: parent.right }
                            Rectangle { width: 1; height: 4; color: Theme.border; anchors.bottom: parent.bottom; anchors.right: parent.right }

                            Text {
                                anchors.centerIn: parent
                                text: "No hay aplicaciones reproduciendo audio"
                                font.family: Theme.font
                                font.pixelSize: 10
                                color: Theme.muted
                            }
                        }

                        Repeater {
                            model: popup.appsList

                            Rectangle {
                                id: appCard
                                width: parent.width
                                implicitHeight: appCol.implicitHeight + 14
                                radius: 0
                                color: "#0a140c"
                                border.color: Theme.separator
                                border.width: 1

                                // Esquinas tácticas iluminadas
                                Rectangle { width: 5; height: 1; color: Theme.border; anchors.top: parent.top; anchors.left: parent.left }
                                Rectangle { width: 1; height: 5; color: Theme.border; anchors.top: parent.top; anchors.left: parent.left }
                                Rectangle { width: 5; height: 1; color: Theme.border; anchors.top: parent.top; anchors.right: parent.right }
                                Rectangle { width: 1; height: 5; color: Theme.border; anchors.top: parent.top; anchors.right: parent.right }
                                Rectangle { width: 5; height: 1; color: Theme.border; anchors.bottom: parent.bottom; anchors.left: parent.left }
                                Rectangle { width: 1; height: 5; color: Theme.border; anchors.bottom: parent.bottom; anchors.left: parent.left }
                                Rectangle { width: 5; height: 1; color: Theme.border; anchors.bottom: parent.bottom; anchors.right: parent.right }
                                Rectangle { width: 1; height: 5; color: Theme.border; anchors.bottom: parent.bottom; anchors.right: parent.right }

                                readonly property int appId: modelData.id
                                readonly property string appName: modelData.name
                                readonly property string appIcon: modelData.icon || "󰎆"
                                property real appVol: modelData.volume
                                property bool appMuted: modelData.muted
                                readonly property int appSinkId: modelData.sinkId
                                readonly property string appSinkName: modelData.sinkName
                                readonly property string appSinkDesc: modelData.sinkDesc || "Salida"
                                readonly property string appSinkIcon: modelData.sinkIcon || "󰓃"

                                Column {
                                id: appCol
                                width: parent.width - 16
                                anchors.centerIn: parent
                                spacing: 8

                                // Fila superior: Ícono de app + Nombre + Selector de salida por app
                                Row {
                                    width: parent.width
                                    spacing: 6

                                    Text {
                                        text: appCard.appIcon
                                        font.family: Theme.font
                                        font.pixelSize: 14
                                        color: Theme.accent
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    Text {
                                        text: appCard.appName
                                        font.family: Theme.font
                                        font.pixelSize: 11
                                        font.bold: true
                                        color: Theme.text
                                        elide: Text.ElideRight
                                        maximumLineCount: 1
                                        width: Math.min(implicitWidth, appCard.width - 160)
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    Item { width: 1; height: 1; Layout.fillWidth: true }

                                    // Selector de salida para esta app específica
                                    Rectangle {
                                        id: appSinkChip
                                        height: 20
                                        width: appSinkRow.implicitWidth + 12
                                        radius: 0
                                        anchors.verticalCenter: parent.verticalCenter
                                        property bool isOpen: popup.selectedAppForSinkMenu === appCard.appId
                                        color: isOpen ? "#162818" : (appSinkMouse.containsMouse ? "#112013" : "#0e1a10")
                                        border.color: isOpen ? Theme.accent : Theme.separator
                                        border.width: 1

                                        Row {
                                            id: appSinkRow
                                            anchors.centerIn: parent
                                            spacing: 4

                                            Text {
                                                text: appCard.appSinkIcon
                                                font.family: Theme.font
                                                font.pixelSize: 10
                                                color: Theme.accent
                                                anchors.verticalCenter: parent.verticalCenter
                                            }

                                            Text {
                                                text: appCard.appSinkDesc
                                                font.family: Theme.font
                                                font.pixelSize: 9
                                                color: Theme.text
                                                elide: Text.ElideRight
                                                maximumLineCount: 1
                                                width: Math.min(implicitWidth, 65)
                                                anchors.verticalCenter: parent.verticalCenter
                                            }

                                            Text {
                                                text: appSinkChip.isOpen ? "▴" : "▾"
                                                font.family: Theme.font
                                                font.pixelSize: 8
                                                color: Theme.muted
                                                anchors.verticalCenter: parent.verticalCenter
                                            }
                                        }

                                        MouseArea {
                                            id: appSinkMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                if (popup.selectedAppForSinkMenu === appCard.appId) {
                                                    popup.selectedAppForSinkMenu = -1
                                                } else {
                                                    popup.selectedAppForSinkMenu = appCard.appId
                                                }
                                            }
                                        }
                                    }
                                }

                                // Menú desplegable para cambiar la salida de ESTA aplicación
                                Column {
                                    width: parent.width
                                    visible: popup.selectedAppForSinkMenu === appCard.appId
                                    spacing: 4

                                    Rectangle { width: parent.width; height: 1; color: Theme.separator }

                                    Text {
                                        text: "Seleccionar salida para " + appCard.appName + ":"
                                        font.family: Theme.font
                                        font.pixelSize: 9
                                        color: Theme.muted
                                    }

                                    Repeater {
                                        model: popup.sinksList

                                        Rectangle {
                                            id: appSinkOption
                                            width: parent.width
                                            height: 22
                                            radius: 0
                                            property bool isSelected: modelData.id === appCard.appSinkId || modelData.name === appCard.appSinkName
                                            color: optionMouse.containsMouse ? "#142416" : (isSelected ? "#0f1c11" : "transparent")
                                            border.color: isSelected ? Theme.accent : "transparent"
                                            border.width: 1

                                            Row {
                                                anchors.fill: parent
                                                anchors.leftMargin: 6
                                                anchors.rightMargin: 6
                                                spacing: 6

                                                Text {
                                                    text: modelData.icon || "󰓃"
                                                    font.family: Theme.font
                                                    font.pixelSize: 11
                                                    color: isSelected ? Theme.accent : Theme.muted
                                                    anchors.verticalCenter: parent.verticalCenter
                                                }

                                                Text {
                                                    text: modelData.description || modelData.name
                                                    font.family: Theme.font
                                                    font.pixelSize: 9
                                                    color: isSelected ? Theme.accent : Theme.text
                                                    elide: Text.ElideRight
                                                    maximumLineCount: 1
                                                    width: parent.width - 45
                                                    anchors.verticalCenter: parent.verticalCenter
                                                }

                                                Text {
                                                    text: isSelected ? "✓" : ""
                                                    font.family: Theme.font
                                                    font.pixelSize: 9
                                                    color: Theme.accent
                                                    anchors.verticalCenter: parent.verticalCenter
                                                }
                                            }

                                            MouseArea {
                                                id: optionMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    cmdProc.exec(["/home/emn/.config/quickshell/modules/popups/audio_ctl.py", "move-app-sink", appCard.appId.toString(), modelData.name])
                                                    popup.selectedAppForSinkMenu = -1
                                                    refreshTimer.restart()
                                                }
                                            }
                                        }
                                    }

                                    Rectangle { width: parent.width; height: 1; color: Theme.separator }
                                }

                                // Fila inferior: Mute individual + Slider individual + Porcentaje
                                Row {
                                    width: parent.width
                                    spacing: 8

                                    // Botón mute app
                                    Rectangle {
                                        id: appMuteBtn
                                        width: 20; height: 20; radius: 0
                                        color: appMuteHover.containsMouse ? (appCard.appMuted ? "#3a2a0a" : "#122212") : "transparent"
                                        border.color: appCard.appMuted ? Theme.amber : Theme.border
                                        anchors.verticalCenter: parent.verticalCenter
                                        Behavior on color { ColorAnimation { duration: 120 } }
                                        Behavior on border.color { ColorAnimation { duration: 150 } }

                                        Text {
                                            anchors.centerIn: parent
                                            font.family: Theme.iconFont
                                            font.pixelSize: 10
                                            color: appCard.appMuted ? Theme.amber : Theme.accent
                                            text: appCard.appMuted ? "\ue9bf" : "\ue9c0"
                                            Behavior on color { ColorAnimation { duration: 150 } }
                                        }
                                        MouseArea {
                                            id: appMuteHover
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                appCard.appMuted = !appCard.appMuted
                                                cmdProc.exec(["/home/emn/.config/quickshell/modules/popups/audio_ctl.py", "toggle-app-mute", appCard.appId.toString()])
                                                refreshTimer.restart()
                                            }
                                        }
                                    }

                                    // Slider volumen de la app retro táctico
                                    TacticalSlider {
                                        width: parent.width - 66
                                        anchors.verticalCenter: parent.verticalCenter
                                        value: appCard.appVol
                                        maxVal: 1.0
                                        totalBlocks: 14
                                        allowOverdrive: false
                                        muted: appCard.appMuted
                                        onMoved: (val) => {
                                            appCard.appVol = val
                                            cmdProc.exec(["/home/emn/.config/quickshell/modules/popups/audio_ctl.py", "set-app-volume", appCard.appId.toString(), val.toFixed(2)])
                                        }
                                        onCommitted: (val) => {
                                            appCard.appVol = val
                                            cmdProc.exec(["/home/emn/.config/quickshell/modules/popups/audio_ctl.py", "set-app-volume", appCard.appId.toString(), val.toFixed(2)])
                                            refreshTimer.restart()
                                        }
                                    }

                                    // Porcentaje app
                                    Text {
                                        text: Math.round(appCard.appVol * 100) + "%"
                                        font.family: Theme.font
                                        font.pixelSize: 10
                                        color: appCard.appMuted ? Theme.muted : Theme.text
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }
                            }
                        }
                    }
                }
            }

                // ==========================================
                // VISTA 2: BLUETOOTH
                // Dispositivos en memoria y Búsqueda de nuevos dispositivos
                // ==========================================
                Column {
                    width: parent.width
                    spacing: 12
                    visible: popup.currentTab === "bluetooth"

                    // Cabecera: Adaptador Bluetooth (Power + Scan)
                    Rectangle {
                        id: btAdapterCard
                        width: parent.width
                        height: 42
                        radius: 0
                        color: "#0a140c"
                        border.color: Theme.separator
                        border.width: 1

                        // Esquinas tácticas iluminadas
                        readonly property color cornerColor: popup.btPowered ? Theme.accent : Theme.border
                        Rectangle { width: 5; height: 1; color: btAdapterCard.cornerColor; anchors.top: parent.top; anchors.left: parent.left }
                        Rectangle { width: 1; height: 5; color: btAdapterCard.cornerColor; anchors.top: parent.top; anchors.left: parent.left }
                        Rectangle { width: 5; height: 1; color: btAdapterCard.cornerColor; anchors.top: parent.top; anchors.right: parent.right }
                        Rectangle { width: 1; height: 5; color: btAdapterCard.cornerColor; anchors.top: parent.top; anchors.right: parent.right }
                        Rectangle { width: 5; height: 1; color: btAdapterCard.cornerColor; anchors.bottom: parent.bottom; anchors.left: parent.left }
                        Rectangle { width: 1; height: 5; color: btAdapterCard.cornerColor; anchors.bottom: parent.bottom; anchors.left: parent.left }
                        Rectangle { width: 5; height: 1; color: btAdapterCard.cornerColor; anchors.bottom: parent.bottom; anchors.right: parent.right }
                        Rectangle { width: 1; height: 5; color: btAdapterCard.cornerColor; anchors.bottom: parent.bottom; anchors.right: parent.right }

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 8

                            Text {
                                text: "󰂯"
                                font.family: Theme.font
                                font.pixelSize: 16
                                color: popup.btPowered ? Theme.accent : Theme.muted
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2

                                Text {
                                    text: "Adaptador Bluetooth"
                                    font.family: Theme.font
                                    font.pixelSize: 11
                                    font.bold: true
                                    color: Theme.text
                                }

                                Text {
                                    text: popup.btPowered ? (popup.btDiscovering ? "Escaneando dispositivos..." : "Activado") : "Desactivado"
                                    font.family: Theme.font
                                    font.pixelSize: 9
                                    color: popup.btPowered ? Theme.accent : Theme.muted
                                }
                            }

                            Item { width: 1; height: 1; Layout.fillWidth: true }

                            // Botón Encender / Apagar
                            Rectangle {
                                id: powerBtn
                                width: powerRow.implicitWidth + 14
                                height: 24
                                radius: 0
                                anchors.verticalCenter: parent.verticalCenter
                                color: popup.btPowered ? "#162a18" : "#201212"
                                border.color: popup.btPowered ? Theme.accent : Theme.amber
                                border.width: 1

                                Row {
                                    id: powerRow
                                    anchors.centerIn: parent
                                    spacing: 4

                                    Text {
                                        text: popup.btPowered ? "ON" : "OFF"
                                        font.family: Theme.font
                                        font.pixelSize: 10
                                        font.bold: true
                                        color: popup.btPowered ? Theme.accent : Theme.amber
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        let nextState = popup.btPowered ? "off" : "on"
                                        popup.btPowered = !popup.btPowered
                                        if (!popup.btPowered) {
                                            popup.btDiscovering = false
                                        }
                                        btActionProc.exec(["/home/emn/.config/quickshell/modules/popups/audio_ctl.py", "bt-power", nextState])
                                        btRefreshTimer.restart()
                                    }
                                }
                            }
                        }
                    }

                    // Botón prominente para Buscar Nuevos Dispositivos
                    Rectangle {
                        id: btSearchBtn
                        width: parent.width
                        height: 32
                        radius: 0
                        color: popup.btDiscovering ? (searchMouse.containsMouse ? "#241414" : "#1a0f0f") : (searchMouse.containsMouse ? "#122014" : "#0d180f")
                        border.color: popup.btDiscovering ? Theme.amber : Theme.border
                        border.width: 1

                        // Esquinas tácticas iluminadas
                        readonly property color cornerColor: popup.btDiscovering ? Theme.amber : (searchMouse.containsMouse ? Theme.accent : Theme.border)
                        Rectangle { width: 5; height: 1; color: btSearchBtn.cornerColor; anchors.top: parent.top; anchors.left: parent.left }
                        Rectangle { width: 1; height: 5; color: btSearchBtn.cornerColor; anchors.top: parent.top; anchors.left: parent.left }
                        Rectangle { width: 5; height: 1; color: btSearchBtn.cornerColor; anchors.top: parent.top; anchors.right: parent.right }
                        Rectangle { width: 1; height: 5; color: btSearchBtn.cornerColor; anchors.top: parent.top; anchors.right: parent.right }
                        Rectangle { width: 5; height: 1; color: btSearchBtn.cornerColor; anchors.bottom: parent.bottom; anchors.left: parent.left }
                        Rectangle { width: 1; height: 5; color: btSearchBtn.cornerColor; anchors.bottom: parent.bottom; anchors.left: parent.left }
                        Rectangle { width: 5; height: 1; color: btSearchBtn.cornerColor; anchors.bottom: parent.bottom; anchors.right: parent.right }
                        Rectangle { width: 1; height: 5; color: btSearchBtn.cornerColor; anchors.bottom: parent.bottom; anchors.right: parent.right }

                        Behavior on color { ColorAnimation { duration: 120 } }
                        Behavior on border.color { ColorAnimation { duration: 150 } }

                        Row {
                            anchors.centerIn: parent
                            spacing: 8

                            Text {
                                text: popup.btDiscovering ? "󰅖" : "󰑐"
                                font.family: Theme.font
                                font.pixelSize: 13
                                color: popup.btDiscovering ? Theme.amber : Theme.accent
                                anchors.verticalCenter: parent.verticalCenter
                                rotation: popup.btDiscovering ? 0 : (searchMouse.containsMouse ? 180 : 0)
                                Behavior on rotation { NumberAnimation { duration: 400 } }
                            }

                            Text {
                                text: popup.btDiscovering ? "Cancelar búsqueda de dispositivos" : "Buscar nuevos dispositivos cercanos"
                                font.family: Theme.font
                                font.pixelSize: 10
                                font.bold: true
                                color: popup.btDiscovering ? Theme.amber : Theme.text
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            id: searchMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (popup.btDiscovering) {
                                    popup.btDiscovering = false
                                    btActionProc.exec(["/home/emn/.config/quickshell/modules/popups/audio_ctl.py", "bt-scan", "off"])
                                } else {
                                    if (!popup.btPowered) {
                                        popup.btPowered = true
                                    }
                                    popup.btDiscovering = true
                                    btActionProc.exec(["/home/emn/.config/quickshell/modules/popups/audio_ctl.py", "bt-scan", "on"])
                                }
                                btRefreshTimer.restart()
                            }
                        }
                    }

                    // SECCIÓN 1: DISPOSITIVOS VINCULADOS (EN MEMORIA)
                    Column {
                        width: parent.width
                        spacing: 8

                        Text {
                            text: "DISPOSITIVOS EN MEMORIA"
                            font.family: Theme.font
                            font.pixelSize: 10
                            font.bold: true
                            color: Theme.muted
                        }

                        // Aviso si no hay vinculados
                        Rectangle {
                            width: parent.width
                            height: 32
                            radius: 0
                            color: "#09120b"
                            border.color: Theme.separator
                            border.width: 1
                            visible: popup.btPairedDevices.length === 0

                            Rectangle { width: 4; height: 1; color: Theme.border; anchors.top: parent.top; anchors.left: parent.left }
                            Rectangle { width: 1; height: 4; color: Theme.border; anchors.top: parent.top; anchors.left: parent.left }
                            Rectangle { width: 4; height: 1; color: Theme.border; anchors.top: parent.top; anchors.right: parent.right }
                            Rectangle { width: 1; height: 4; color: Theme.border; anchors.top: parent.top; anchors.right: parent.right }
                            Rectangle { width: 4; height: 1; color: Theme.border; anchors.bottom: parent.bottom; anchors.left: parent.left }
                            Rectangle { width: 1; height: 4; color: Theme.border; anchors.bottom: parent.bottom; anchors.left: parent.left }
                            Rectangle { width: 4; height: 1; color: Theme.border; anchors.bottom: parent.bottom; anchors.right: parent.right }
                            Rectangle { width: 1; height: 4; color: Theme.border; anchors.bottom: parent.bottom; anchors.right: parent.right }

                            Text {
                                anchors.centerIn: parent
                                text: "No hay dispositivos vinculados en memoria"
                                font.family: Theme.font
                                font.pixelSize: 10
                                color: Theme.muted
                            }
                        }

                        // Tarjetas de Dispositivos en Memoria
                        Repeater {
                            model: popup.btPairedDevices

                            Rectangle {
                                id: pairedDevCard
                                width: parent.width
                                height: 44
                                radius: 0
                                
                                readonly property string devMac: modelData.mac
                                readonly property string devName: modelData.name || devMac
                                readonly property bool isConnected: Boolean(modelData.connected)
                                readonly property bool isConnecting: popup.connectingMac === devMac
                                readonly property string devIcon: modelData.icon || "󰂯"

                                color: isConnected ? "#0f1c11" : (isConnecting ? "#19150b" : "#09130b")
                                border.color: isConnected ? Theme.accent : (isConnecting ? Theme.amber : Theme.separator)
                                border.width: 1

                                // Esquinas tácticas iluminadas
                                readonly property color cornerColor: isConnected ? Theme.accent : (isConnecting ? Theme.amber : Theme.border)
                                Rectangle { width: 5; height: 1; color: pairedDevCard.cornerColor; anchors.top: parent.top; anchors.left: parent.left }
                                Rectangle { width: 1; height: 5; color: pairedDevCard.cornerColor; anchors.top: parent.top; anchors.left: parent.left }
                                Rectangle { width: 5; height: 1; color: pairedDevCard.cornerColor; anchors.top: parent.top; anchors.right: parent.right }
                                Rectangle { width: 1; height: 5; color: pairedDevCard.cornerColor; anchors.top: parent.top; anchors.right: parent.right }
                                Rectangle { width: 5; height: 1; color: pairedDevCard.cornerColor; anchors.bottom: parent.bottom; anchors.left: parent.left }
                                Rectangle { width: 1; height: 5; color: pairedDevCard.cornerColor; anchors.bottom: parent.bottom; anchors.left: parent.left }
                                Rectangle { width: 5; height: 1; color: pairedDevCard.cornerColor; anchors.bottom: parent.bottom; anchors.right: parent.right }
                                Rectangle { width: 1; height: 5; color: pairedDevCard.cornerColor; anchors.bottom: parent.bottom; anchors.right: parent.right }

                                Behavior on color { ColorAnimation { duration: 150 } }
                                Behavior on border.color { ColorAnimation { duration: 150 } }

                                Row {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    spacing: 8

                                    Text {
                                        text: pairedDevCard.devIcon
                                        font.family: Theme.font
                                        font.pixelSize: 15
                                        color: pairedDevCard.isConnected ? Theme.accent : (pairedDevCard.isConnecting ? Theme.amber : Theme.text)
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    Column {
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 2
                                        width: pairedDevCard.width - 150

                                        Text {
                                            text: pairedDevCard.devName
                                            font.family: Theme.font
                                            font.pixelSize: 11
                                            font.bold: true
                                            color: pairedDevCard.isConnected ? Theme.accent : Theme.text
                                            elide: Text.ElideRight
                                            maximumLineCount: 1
                                        }

                                        Row {
                                            spacing: 6

                                            Text {
                                                text: pairedDevCard.isConnecting ? "Conectando..." : (pairedDevCard.isConnected ? "Conectado" : "Desconectado")
                                                font.family: Theme.font
                                                font.pixelSize: 9
                                                color: pairedDevCard.isConnecting ? Theme.amber : (pairedDevCard.isConnected ? Theme.accent : Theme.muted)
                                                anchors.verticalCenter: parent.verticalCenter
                                            }

                                            // Badge de batería visual y porcentaje
                                            Rectangle {
                                                visible: pairedDevCard.isConnected && modelData.battery !== null
                                                height: 15
                                                width: pairedBatRow.implicitWidth + 8
                                                radius: 0
                                                color: (modelData.battery !== null && modelData.battery < 25) ? "#2b1a10" : "#132515"
                                                border.color: (modelData.battery !== null && modelData.battery < 25) ? Theme.amber : Theme.accent
                                                border.width: 1
                                                anchors.verticalCenter: parent.verticalCenter

                                                Row {
                                                    id: pairedBatRow
                                                    anchors.centerIn: parent
                                                    spacing: 3

                                                    Text {
                                                        text: getBatteryGlyph(modelData.battery)
                                                        font.family: Theme.font
                                                        font.pixelSize: 9
                                                        color: (modelData.battery !== null && modelData.battery < 25) ? Theme.amber : Theme.accent
                                                        anchors.verticalCenter: parent.verticalCenter
                                                    }

                                                    Text {
                                                        text: (modelData.battery !== null ? modelData.battery : 0) + "%"
                                                        font.family: Theme.font
                                                        font.pixelSize: 8
                                                        font.bold: true
                                                        color: (modelData.battery !== null && modelData.battery < 25) ? Theme.amber : Theme.text
                                                        anchors.verticalCenter: parent.verticalCenter
                                                    }
                                                }
                                            }

                                            Text {
                                                visible: pairedDevCard.isConnected && modelData.battery === null
                                                text: "• Bat. N/D"
                                                font.family: Theme.font
                                                font.pixelSize: 8
                                                color: Theme.muted
                                                anchors.verticalCenter: parent.verticalCenter
                                            }
                                        }
                                    }

                                    Item { width: 1; height: 1; Layout.fillWidth: true }

                                    // Botón Conectar / Desconectar
                                    Rectangle {
                                        id: pairedBtn
                                        height: 24
                                        width: pairedBtnRow.implicitWidth + 14
                                        radius: 0
                                        anchors.verticalCenter: parent.verticalCenter

                                        color: pairedDevCard.isConnecting ? "#2e210a" : (pairedDevCard.isConnected ? (pairedBtnMouse.containsMouse ? "#2d1616" : "#1a1010") : (pairedBtnMouse.containsMouse ? "#18321a" : "#102212"))
                                        border.color: pairedDevCard.isConnecting ? Theme.amber : (pairedDevCard.isConnected ? Theme.amber : Theme.accent)
                                        border.width: 1

                                        Behavior on color { ColorAnimation { duration: 120 } }
                                        Behavior on border.color { ColorAnimation { duration: 120 } }

                                        SequentialAnimation on opacity {
                                            running: pairedDevCard.isConnecting
                                            loops: Animation.Infinite
                                            NumberAnimation { to: 0.4; duration: 500; easing.type: Easing.InOutQuad }
                                            NumberAnimation { to: 1.0; duration: 500; easing.type: Easing.InOutQuad }
                                        }

                                        Row {
                                            id: pairedBtnRow
                                            anchors.centerIn: parent
                                            spacing: 4

                                            Text {
                                                text: "󰑐"
                                                font.family: Theme.font
                                                font.pixelSize: 10
                                                color: Theme.amber
                                                visible: pairedDevCard.isConnecting
                                                anchors.verticalCenter: parent.verticalCenter
                                            }

                                            Text {
                                                text: pairedDevCard.isConnecting ? "Conectando..." : (pairedDevCard.isConnected ? "Desconectar" : "Conectar")
                                                font.family: Theme.font
                                                font.pixelSize: 10
                                                font.bold: true
                                                color: pairedDevCard.isConnecting ? Theme.amber : (pairedDevCard.isConnected ? Theme.amber : Theme.accent)
                                                anchors.verticalCenter: parent.verticalCenter
                                            }
                                        }

                                        MouseArea {
                                            id: pairedBtnMouse
                                            anchors.fill: parent
                                            hoverEnabled: !pairedDevCard.isConnecting
                                            cursorShape: pairedDevCard.isConnecting ? Qt.ArrowCursor : Qt.PointingHandCursor
                                            onClicked: {
                                                if (pairedDevCard.isConnecting) return

                                                if (pairedDevCard.isConnected) {
                                                    btActionProc.exec(["/home/emn/.config/quickshell/modules/popups/audio_ctl.py", "bt-disconnect", pairedDevCard.devMac])
                                                    btRefreshTimer.restart()
                                                } else {
                                                    popup.connectingMac = pairedDevCard.devMac
                                                    btActionProc.exec(["/home/emn/.config/quickshell/modules/popups/audio_ctl.py", "bt-connect", pairedDevCard.devMac])
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Separador
                    Rectangle {
                        width: parent.width
                        height: 1
                        color: Theme.separator
                    }

                    // SECCIÓN 2: NUEVOS DISPOSITIVOS ENCONTRADOS
                    Column {
                        width: parent.width
                        spacing: 8

                        Row {
                            width: parent.width
                            spacing: 6

                            Text {
                                text: "NUEVOS DISPOSITIVOS ENCONTRADOS"
                                font.family: Theme.font
                                font.pixelSize: 10
                                font.bold: true
                                color: Theme.muted
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: popup.btDiscovering ? "• Buscando..." : ""
                                font.family: Theme.font
                                font.pixelSize: 9
                                color: Theme.accent
                                visible: popup.btDiscovering
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        // Aviso si no hay nuevos descubiertos
                        Rectangle {
                            width: parent.width
                            height: 38
                            radius: 0
                            color: "#09120b"
                            border.color: Theme.separator
                            border.width: 1
                            visible: popup.btAvailableDevices.length === 0

                            Rectangle { width: 4; height: 1; color: Theme.border; anchors.top: parent.top; anchors.left: parent.left }
                            Rectangle { width: 1; height: 4; color: Theme.border; anchors.top: parent.top; anchors.left: parent.left }
                            Rectangle { width: 4; height: 1; color: Theme.border; anchors.top: parent.top; anchors.right: parent.right }
                            Rectangle { width: 1; height: 4; color: Theme.border; anchors.top: parent.top; anchors.right: parent.right }
                            Rectangle { width: 4; height: 1; color: Theme.border; anchors.bottom: parent.bottom; anchors.left: parent.left }
                            Rectangle { width: 1; height: 4; color: Theme.border; anchors.bottom: parent.bottom; anchors.left: parent.left }
                            Rectangle { width: 4; height: 1; color: Theme.border; anchors.bottom: parent.bottom; anchors.right: parent.right }
                            Rectangle { width: 1; height: 4; color: Theme.border; anchors.bottom: parent.bottom; anchors.right: parent.right }

                            Row {
                                anchors.centerIn: parent
                                spacing: 6

                                Text {
                                    text: popup.btDiscovering ? "󰑐" : "󰂲"
                                    font.family: Theme.font
                                    font.pixelSize: 11
                                    color: Theme.muted
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Text {
                                    text: popup.btDiscovering ? "Escaneando dispositivos cercanos..." : "Pulsa 'Buscar' para descubrir dispositivos cercanos"
                                    font.family: Theme.font
                                    font.pixelSize: 10
                                    color: Theme.muted
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }
                        }

                        // Tarjetas de Nuevos Dispositivos Disponibles
                        Repeater {
                            model: popup.btAvailableDevices

                            Rectangle {
                                id: availDevCard
                                width: parent.width
                                height: 42
                                radius: 0
                                
                                readonly property string devMac: modelData.mac
                                readonly property string devName: modelData.name || devMac
                                readonly property bool isConnecting: popup.connectingMac === devMac
                                readonly property string devIcon: modelData.icon || "󰂯"

                                color: isConnecting ? "#19150b" : "#09130b"
                                border.color: isConnecting ? Theme.amber : Theme.separator
                                border.width: 1

                                // Esquinas tácticas iluminadas
                                readonly property color cornerColor: isConnecting ? Theme.amber : Theme.border
                                Rectangle { width: 5; height: 1; color: availDevCard.cornerColor; anchors.top: parent.top; anchors.left: parent.left }
                                Rectangle { width: 1; height: 5; color: availDevCard.cornerColor; anchors.top: parent.top; anchors.left: parent.left }
                                Rectangle { width: 5; height: 1; color: availDevCard.cornerColor; anchors.top: parent.top; anchors.right: parent.right }
                                Rectangle { width: 1; height: 5; color: availDevCard.cornerColor; anchors.top: parent.top; anchors.right: parent.right }
                                Rectangle { width: 5; height: 1; color: availDevCard.cornerColor; anchors.bottom: parent.bottom; anchors.left: parent.left }
                                Rectangle { width: 1; height: 5; color: availDevCard.cornerColor; anchors.bottom: parent.bottom; anchors.left: parent.left }
                                Rectangle { width: 5; height: 1; color: availDevCard.cornerColor; anchors.bottom: parent.bottom; anchors.right: parent.right }
                                Rectangle { width: 1; height: 5; color: availDevCard.cornerColor; anchors.bottom: parent.bottom; anchors.right: parent.right }

                                Behavior on color { ColorAnimation { duration: 150 } }
                                Behavior on border.color { ColorAnimation { duration: 150 } }

                                Row {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    spacing: 8

                                    Text {
                                        text: availDevCard.devIcon
                                        font.family: Theme.font
                                        font.pixelSize: 14
                                        color: availDevCard.isConnecting ? Theme.amber : Theme.accent
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    Column {
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 2
                                        width: availDevCard.width - 150

                                        Text {
                                            text: availDevCard.devName
                                            font.family: Theme.font
                                            font.pixelSize: 10
                                            font.bold: true
                                            color: Theme.text
                                            elide: Text.ElideRight
                                            maximumLineCount: 1
                                        }

                                        Text {
                                            text: availDevCard.isConnecting ? "Vinculando y conectando..." : "Nuevo dispositivo disponible"
                                            font.family: Theme.font
                                            font.pixelSize: 8
                                            color: availDevCard.isConnecting ? Theme.amber : Theme.muted
                                        }
                                    }

                                    Item { width: 1; height: 1; Layout.fillWidth: true }

                                    // Botón Vincular / Conectar
                                    Rectangle {
                                        id: availBtn
                                        height: 22
                                        width: availBtnRow.implicitWidth + 12
                                        radius: 0
                                        anchors.verticalCenter: parent.verticalCenter

                                        color: availDevCard.isConnecting ? "#2e210a" : (availBtnMouse.containsMouse ? "#18321a" : "#102212")
                                        border.color: availDevCard.isConnecting ? Theme.amber : Theme.accent
                                        border.width: 1

                                        SequentialAnimation on opacity {
                                            running: availDevCard.isConnecting
                                            loops: Animation.Infinite
                                            NumberAnimation { to: 0.4; duration: 500; easing.type: Easing.InOutQuad }
                                            NumberAnimation { to: 1.0; duration: 500; easing.type: Easing.InOutQuad }
                                        }

                                        Row {
                                            id: availBtnRow
                                            anchors.centerIn: parent
                                            spacing: 4

                                            Text {
                                                text: "󰑐"
                                                font.family: Theme.font
                                                font.pixelSize: 9
                                                color: Theme.amber
                                                visible: availDevCard.isConnecting
                                                anchors.verticalCenter: parent.verticalCenter
                                            }

                                            Text {
                                                text: availDevCard.isConnecting ? "Conectando..." : "Conectar"
                                                font.family: Theme.font
                                                font.pixelSize: 9
                                                font.bold: true
                                                color: availDevCard.isConnecting ? Theme.amber : Theme.accent
                                                anchors.verticalCenter: parent.verticalCenter
                                            }
                                        }

                                        MouseArea {
                                            id: availBtnMouse
                                            anchors.fill: parent
                                            hoverEnabled: !availDevCard.isConnecting
                                            cursorShape: availDevCard.isConnecting ? Qt.ArrowCursor : Qt.PointingHandCursor
                                            onClicked: {
                                                if (availDevCard.isConnecting) return

                                                popup.connectingMac = availDevCard.devMac
                                                btActionProc.exec(["/home/emn/.config/quickshell/modules/popups/audio_ctl.py", "bt-pair-connect", availDevCard.devMac])
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
    }

    // ==========================================
    // PROCESOS Y TIMERS DE AUDIO Y BLUETOOTH
    // ==========================================
    Process { id: cmdProc }

    Process {
        id: btActionProc
        onExited: {
            popup.connectingMac = ""
            btRefreshTimer.restart()
            refreshTimer.restart()
        }
    }

    // Proceso de estado de Audio
    Process {
        id: statusProc
        command: ["/home/emn/.config/quickshell/modules/popups/audio_ctl.py", "status"]
        stdout: StdioCollector { id: statusCollector }
        onExited: {
            try {
                let data = JSON.parse(statusCollector.text)
                if (data.master) {
                    popup.masterSinkName = data.master.sinkName
                }
                if (data.sinks) {
                    popup.sinksList = data.sinks
                }
                if (data.apps) {
                    popup.appsList = data.apps
                }
            } catch (e) {
                // Ignore parse errors on intermediate chunks
            }
        }
    }

    // Proceso de estado de Bluetooth
    Process {
        id: btStatusProc
        command: ["/home/emn/.config/quickshell/modules/popups/audio_ctl.py", "bt-status"]
        stdout: StdioCollector { id: btCollector }
        onExited: {
            try {
                let data = JSON.parse(btCollector.text)
                popup.btPowered = Boolean(data.powered)
                popup.btDiscovering = Boolean(data.discovering)
                if (data.pairedDevices) {
                    popup.btPairedDevices = data.pairedDevices
                }
                if (data.availableDevices) {
                    popup.btAvailableDevices = data.availableDevices
                }
            } catch (e) {
                // Ignore parse errors on intermediate chunks
            }
        }
    }

    Timer {
        id: refreshTimer
        interval: 120
        repeat: false
        onTriggered: statusProc.running = true
    }

    Timer {
        id: btRefreshTimer
        interval: 700
        repeat: false
        onTriggered: btStatusProc.running = true
    }

    Timer {
        interval: 1200
        running: popup.visible
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!statusProc.running) {
                statusProc.running = true
            }
            if (popup.currentTab === "bluetooth" && !btStatusProc.running) {
                btStatusProc.running = true
            }
        }
    }
}