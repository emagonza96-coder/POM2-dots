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
    readonly property real normalized: Math.max(0, Math.min(1.0, maxVal > 0 ? value / maxVal : 0))

    Row {
        id: blocksRow
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 2

        readonly property real blockWidth: Math.max(2, (width - ((sliderRoot.totalBlocks - 1) * spacing)) / sliderRoot.totalBlocks)
        readonly property int activeBlocks: Math.round(sliderRoot.normalized * sliderRoot.totalBlocks)

        Repeater {
            model: sliderRoot.totalBlocks
            Rectangle {
                required property int index
                width: blocksRow.blockWidth
                height: sliderRoot.dragging ? 12 : 8
                radius: 0

                readonly property bool isActive: index < blocksRow.activeBlocks
                readonly property bool isOverdrive: sliderRoot.allowOverdrive && index >= 11 // > 100% de volumen

                color: !isActive ? "#121f14"
                     : sliderRoot.muted ? Theme.muted
                     : isOverdrive ? Theme.amber
                     : Theme.accent

                border.color: !isActive ? "#1a2c1d"
                            : sliderRoot.muted ? Theme.muted
                            : isOverdrive ? Theme.amber
                            : Theme.border
                border.width: 1

                Behavior on height { NumberAnimation { duration: 90; easing.type: Easing.OutQuad } }
                Behavior on color  { ColorAnimation  { duration: 50 } }
            }
        }
    }

    // Agarre táctico con indicador ">"
    Rectangle {
        id: grip
        width: 14
        height: sliderRoot.dragging ? 18 : 15
        radius: 0
        color: sliderRoot.dragging ? "#142616" : "#0a130b"
        border.color: sliderRoot.dragging ? Theme.accent : Theme.border
        border.width: 1
        anchors.verticalCenter: parent.verticalCenter
        x: Math.max(0, Math.min(parent.width - width, sliderRoot.normalized * (parent.width - width)))

        Behavior on height       { NumberAnimation { duration: 90; easing.type: Easing.OutQuad } }
        Behavior on color        { ColorAnimation  { duration: 90 } }
        Behavior on border.color { ColorAnimation  { duration: 90 } }
        Behavior on x            { NumberAnimation { duration: 40 } }

        Text {
            anchors.centerIn: parent
            anchors.horizontalCenterOffset: 0.5
            text: ">"
            font.family: Theme.font
            font.pixelSize: 10
            font.bold: true
            color: sliderRoot.dragging ? Theme.accent : (sliderRoot.muted ? Theme.muted : Theme.text)
            Behavior on color { ColorAnimation { duration: 90 } }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
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
    }
}
