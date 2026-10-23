import QtQuick
import "../.."

Item {
    id: ringRoot
    width: 142
    height: 142

    property string code: "SYS // METRIC"
    property string label: "METRIC"
    property real value: 0.5 // 0.0 - 1.0
    property string displayValue: "50%"
    property color activeColor: Theme.accent
    property color warnColor: Theme.amber
    property bool warning: false

    Connections {
        target: ringRoot
        function onValueChanged() { canvas.requestPaint() }
        function onWarningChanged() { canvas.requestPaint() }
    }

    Rectangle {
        id: ringCard
        anchors.fill: parent
        radius: 0
        color: "#09130a"
        border.color: Theme.separator
        border.width: 1

        // Esquinas tácticas decorativas en 1px
        readonly property color cornerColor: ringRoot.warning ? ringRoot.warnColor : Theme.border
        Rectangle { width: 4; height: 1; color: ringCard.cornerColor; anchors.top: parent.top; anchors.left: parent.left }
        Rectangle { width: 1; height: 4; color: ringCard.cornerColor; anchors.top: parent.top; anchors.left: parent.left }
        Rectangle { width: 4; height: 1; color: ringCard.cornerColor; anchors.top: parent.top; anchors.right: parent.right }
        Rectangle { width: 1; height: 4; color: ringCard.cornerColor; anchors.top: parent.top; anchors.right: parent.right }
        Rectangle { width: 4; height: 1; color: ringCard.cornerColor; anchors.bottom: parent.bottom; anchors.left: parent.left }
        Rectangle { width: 1; height: 4; color: ringCard.cornerColor; anchors.bottom: parent.bottom; anchors.left: parent.left }
        Rectangle { width: 4; height: 1; color: ringCard.cornerColor; anchors.bottom: parent.bottom; anchors.right: parent.right }
        Rectangle { width: 1; height: 4; color: ringCard.cornerColor; anchors.bottom: parent.bottom; anchors.right: parent.right }

        Column {
            anchors.centerIn: parent
            spacing: 6

            // Código de telemetría táctica
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: ringRoot.code
                font.family: Theme.font
                font.pixelSize: 7
                font.bold: true
                color: Theme.muted
            }

            // Anillo segmentado estilo radar militar
            Item {
                width: 72
                height: 72
                anchors.horizontalCenter: parent.horizontalCenter

                Canvas {
                    id: canvas
                    anchors.fill: parent
                    antialiasing: true

                    onPaint: {
                        let ctx = getContext("2d")
                        ctx.reset()
                        let cx = width / 2
                        let cy = height / 2
                        let r = width / 2 - 6
                        let totalTicks = 16
                        let startAngle = -Math.PI * 0.75
                        let endAngle = Math.PI * 0.75
                        let sweep = endAngle - startAngle
                        let step = sweep / (totalTicks - 1)
                        let activeTicks = Math.round(Math.max(0, Math.min(1.0, ringRoot.value)) * (totalTicks - 1))

                        for (let i = 0; i < totalTicks; i++) {
                            let angle = startAngle + i * step
                            let isActive = i <= activeTicks
                            let isWarn = ringRoot.warning && isActive

                            let tickLength = (i % 4 === 0) ? 6 : 4
                            let x1 = cx + (r - tickLength) * Math.cos(angle)
                            let y1 = cy + (r - tickLength) * Math.sin(angle)
                            let x2 = cx + r * Math.cos(angle)
                            let y2 = cy + r * Math.sin(angle)

                            ctx.beginPath()
                            ctx.moveTo(x1, y1)
                            ctx.lineTo(x2, y2)
                            ctx.lineWidth = 2.5
                            ctx.strokeStyle = !isActive ? "#142416"
                                            : (isWarn ? ringRoot.warnColor : ringRoot.activeColor)
                            ctx.stroke()
                        }
                    }
                    Component.onCompleted: requestPaint()
                }

                // Valor central con corchetes tácticos
                Column {
                    anchors.centerIn: parent
                    spacing: 0

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: ringRoot.displayValue
                        font.family: Theme.font
                        font.pixelSize: 11
                        font.bold: true
                        color: ringRoot.warning ? ringRoot.warnColor : ringRoot.activeColor
                    }
                }
            }

            // Etiqueta inferior
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: ringRoot.label
                font.family: Theme.font
                font.pixelSize: 8
                font.bold: true
                color: Theme.text
            }
        }
    }
}
