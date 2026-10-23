import Quickshell
import QtQuick
import "../.."

Item {
    id: vSliderRoot
    width: 64
    height: parent.height

    property real value: 0.5 // 0.0 - 1.0
    property string icon: "󰕾"
    property string label: "VOLUMEN"
    property string code: "SYS // VOL"
    property bool muted: false
    property int totalBlocks: 16

    signal moved(real val)
    signal committed(real val)

    readonly property bool dragging: mouseArea.pressed
    readonly property real normalized: Math.max(0, Math.min(1.0, value))
    readonly property int activeBlocks: Math.round(normalized * totalBlocks)
    readonly property bool hovered: mouseArea.containsMouse

    Rectangle {
        id: bgCard
        anchors.fill: parent
        color: "#081109"
        border.color: vSliderRoot.hovered ? Theme.accent : Theme.separator
        border.width: 1
        radius: 0

        // ========================================================
        // ESQUINAS TÁCTICAS ILUMINADAS (1px)
        // ========================================================
        readonly property color cornerColor: vSliderRoot.hovered ? Theme.accent : Theme.border

        // Superior Izquierda
        Rectangle { width: 5; height: 1; color: bgCard.cornerColor; anchors.top: parent.top; anchors.left: parent.left }
        Rectangle { width: 1; height: 5; color: bgCard.cornerColor; anchors.top: parent.top; anchors.left: parent.left }
        // Superior Derecha
        Rectangle { width: 5; height: 1; color: bgCard.cornerColor; anchors.top: parent.top; anchors.right: parent.right }
        Rectangle { width: 1; height: 5; color: bgCard.cornerColor; anchors.top: parent.top; anchors.right: parent.right }
        // Inferior Izquierda
        Rectangle { width: 5; height: 1; color: bgCard.cornerColor; anchors.bottom: parent.bottom; anchors.left: parent.left }
        Rectangle { width: 1; height: 5; color: bgCard.cornerColor; anchors.bottom: parent.bottom; anchors.left: parent.left }
        // Inferior Derecha
        Rectangle { width: 5; height: 1; color: bgCard.cornerColor; anchors.bottom: parent.bottom; anchors.right: parent.right }
        Rectangle { width: 1; height: 5; color: bgCard.cornerColor; anchors.bottom: parent.bottom; anchors.right: parent.right }

        Column {
            anchors.centerIn: parent
            spacing: 6

            // Header con código táctico
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: vSliderRoot.code
                font.family: Theme.font
                font.pixelSize: 7
                font.bold: true
                color: vSliderRoot.hovered ? Theme.accent : Theme.muted
            }

            // Ícono
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: vSliderRoot.icon
                font.family: Theme.font
                font.pixelSize: 14
                color: vSliderRoot.muted ? Theme.muted : (vSliderRoot.hovered ? Theme.accent : Theme.text)
                Behavior on color { ColorAnimation { duration: 120 } }
            }

            // Columna de bloques segmentados (VU-meter vertical táctico)
            Item {
                id: trackArea
                width: 36
                height: 190
                anchors.horizontalCenter: parent.horizontalCenter

                Column {
                    id: blocksCol
                    anchors.centerIn: parent
                    width: parent.width - 8
                    height: parent.height
                    spacing: 2

                    readonly property real blockH: Math.max(2, (height - ((vSliderRoot.totalBlocks - 1) * spacing)) / vSliderRoot.totalBlocks)

                    Repeater {
                        model: vSliderRoot.totalBlocks
                        Rectangle {
                            required property int index
                            // index 0 es el tope (100%), index 15 es la base (0%)
                            readonly property int blockFromBottom: (vSliderRoot.totalBlocks - 1) - index
                            readonly property bool isActive: blockFromBottom < vSliderRoot.activeBlocks
                            readonly property bool isOverdrive: blockFromBottom >= 13 // > 85%

                            width: blocksCol.width
                            height: blocksCol.blockH
                            radius: 0

                            color: !isActive ? "#0d180f"
                                 : vSliderRoot.muted ? Theme.muted
                                 : isOverdrive ? Theme.amber
                                 : (vSliderRoot.hovered ? "#7cd486" : Theme.accent)

                            border.color: !isActive ? "#132416"
                                        : vSliderRoot.muted ? Theme.muted
                                        : isOverdrive ? Theme.amber
                                        : Theme.border
                            border.width: 1

                            Behavior on color { ColorAnimation { duration: 50 } }
                        }
                    }
                }

                // Indicador / Agarre táctico iluminado en el nivel activo
                Rectangle {
                    id: levelGrip
                    width: parent.width
                    height: 4
                    radius: 0
                    color: vSliderRoot.muted ? Theme.muted : Theme.accent
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: Math.max(0, Math.min(trackArea.height - height, (1.0 - vSliderRoot.normalized) * (trackArea.height - height)))

                    Behavior on y { NumberAnimation { duration: 40 } }

                    // Muescas laterales del agarre
                    Rectangle { width: 2; height: 8; anchors.centerIn: parent; anchors.horizontalCenterOffset: -parent.width / 2; color: Theme.accent }
                    Rectangle { width: 2; height: 8; anchors.centerIn: parent; anchors.horizontalCenterOffset: parent.width / 2; color: Theme.accent }
                }

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onPositionChanged: (mouse) => {
                        if (pressed) {
                            let ratio = 1.0 - (mouse.y / height)
                            vSliderRoot.moved(Math.max(0.0, Math.min(1.0, ratio)))
                        }
                    }
                    onClicked: (mouse) => {
                        let ratio = 1.0 - (mouse.y / height)
                        vSliderRoot.committed(Math.max(0.0, Math.min(1.0, ratio)))
                    }
                    onWheel: (wheel) => {
                        let step = wheel.angleDelta.y > 0 ? 0.05 : -0.05
                        let next = Math.max(0.0, Math.min(1.0, vSliderRoot.value + step))
                        vSliderRoot.committed(next)
                    }
                }
            }

            // Porcentaje monospace
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: vSliderRoot.muted ? "MUTED" : Math.round(vSliderRoot.normalized * 100) + "%"
                font.family: Theme.font
                font.pixelSize: 9
                font.bold: true
                color: vSliderRoot.muted ? Theme.muted : Theme.text
            }

            // Etiqueta
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: vSliderRoot.label
                font.family: Theme.font
                font.pixelSize: 8
                font.bold: true
                color: vSliderRoot.hovered ? Theme.accent : Theme.muted
            }
        }
    }
}
