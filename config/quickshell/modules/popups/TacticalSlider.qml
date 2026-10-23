import QtQuick
import "../.."

Item {
    id: sliderRoot
    height: 22

    property real value: 1.0
    property real maxVal: 1.0
    property bool muted: false
    property bool allowOverdrive: false
    property int totalBlocks: 16

    signal moved(real val)
    signal committed(real val)

    readonly property bool dragging: mouseArea.pressed
    readonly property bool hovered: mouseArea.containsMouse
    readonly property real normalized: Math.max(0, Math.min(1.0, maxVal > 0 ? value / maxVal : 0))

    // Fila de bloques segmentados (VU-meter horizontal táctico POM-2 con variación por intensidad)
    Row {
        id: blocksRow
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.right: parent.right
        height: 14
        spacing: 2

        readonly property real blockWidth: Math.max(2, (width - ((sliderRoot.totalBlocks - 1) * spacing)) / sliderRoot.totalBlocks)
        readonly property int activeBlocks: Math.round(sliderRoot.normalized * sliderRoot.totalBlocks)

        Repeater {
            model: sliderRoot.totalBlocks
            Rectangle {
                required property int index
                readonly property bool isActive: index < blocksRow.activeBlocks

                // Cálculo del valor de volumen real que representa este bloque
                readonly property real blockVal: ((index + 0.5) / sliderRoot.totalBlocks) * sliderRoot.maxVal
                readonly property bool isCritical: sliderRoot.allowOverdrive && blockVal > 1.25 // > 125% (Rojo / Peligro distorsión)
                readonly property bool isWarn: !isCritical && blockVal > 0.85                  // > 85%  (Ámbar / Alerta alta ganancia)

                width: blocksRow.blockWidth
                height: parent.height
                radius: 0

                color: !isActive ? "#0d180f"
                     : sliderRoot.muted ? Theme.muted
                     : isCritical ? (sliderRoot.hovered ? "#ff8585" : Theme.red)
                     : isWarn     ? (sliderRoot.hovered ? "#ffd280" : Theme.amber)
                     : (sliderRoot.hovered ? "#7cd486" : Theme.accent)

                border.color: !isActive ? "#132416"
                            : sliderRoot.muted ? Theme.muted
                            : isCritical ? Theme.red
                            : isWarn     ? Theme.amber
                            : Theme.border
                border.width: 1

                Behavior on color { ColorAnimation { duration: 50 } }
                Behavior on border.color { ColorAnimation { duration: 50 } }
            }
        }
    }

    // Indicador / Agarre táctico iluminado en el nivel activo (estilo HUD / corchete [ | ])
    Rectangle {
        id: levelGrip
        width: 4
        height: 18
        radius: 0
        anchors.verticalCenter: parent.verticalCenter
        x: Math.max(0, Math.min(sliderRoot.width - width, sliderRoot.normalized * (sliderRoot.width - width)))

        // Variación dinámica de color según el volumen actual
        readonly property real currentVol: sliderRoot.normalized * sliderRoot.maxVal
        readonly property bool isCritical: sliderRoot.allowOverdrive && currentVol > 1.25
        readonly property bool isWarn: !isCritical && currentVol > 0.85

        readonly property color gripColor: sliderRoot.muted ? Theme.muted
                                         : isCritical ? (sliderRoot.dragging ? "#ff9999" : (sliderRoot.hovered ? "#ff8585" : Theme.red))
                                         : isWarn     ? (sliderRoot.dragging ? "#ffe099" : (sliderRoot.hovered ? "#ffd280" : Theme.amber))
                                         : (sliderRoot.dragging ? "#a3e8ab" : (sliderRoot.hovered ? "#7cd486" : Theme.accent))

        color: levelGrip.gripColor

        Behavior on x     { NumberAnimation { duration: sliderRoot.dragging ? 0 : 40 } }
        Behavior on color { ColorAnimation  { duration: 80 } }

        // Muesca superior del corchete táctico
        Rectangle {
            width: 8
            height: 2
            radius: 0
            anchors.centerIn: parent
            anchors.verticalCenterOffset: -parent.height / 2
            color: levelGrip.gripColor
            Behavior on color { ColorAnimation { duration: 80 } }
        }

        // Muesca inferior del corchete táctico
        Rectangle {
            width: 8
            height: 2
            radius: 0
            anchors.centerIn: parent
            anchors.verticalCenterOffset: parent.height / 2
            color: levelGrip.gripColor
            Behavior on color { ColorAnimation { duration: 80 } }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onPositionChanged: (mouse) => {
            if (pressed) {
                let ratio = Math.max(0, Math.min(1.0, mouse.x / width))
                sliderRoot.moved(ratio * sliderRoot.maxVal)
            }
        }
        onClicked: (mouse) => {
            let ratio = Math.max(0, Math.min(1.0, mouse.x / width))
            sliderRoot.committed(ratio * sliderRoot.maxVal)
        }
        onWheel: (wheel) => {
            let step = (wheel.angleDelta.y > 0 ? 0.05 : -0.05) * sliderRoot.maxVal
            let next = Math.max(0.0, Math.min(sliderRoot.maxVal, sliderRoot.value + step))
            sliderRoot.committed(next)
        }
    }
}
