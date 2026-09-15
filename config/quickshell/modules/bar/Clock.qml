import QtQuick
import "../.."

Text {
    id: clockText
    color: Theme.accent
    font.family: Theme.font
    font.pixelSize: Theme.fontSize
    anchors.verticalCenter: parent.verticalCenter
    property bool hover: false

    function updateText() {
        if (hover) {
            clockText.text = new Date().toLocaleDateString([], { day: '2-digit', month: 'short', year: 'numeric' })
        } else {
            clockText.text = new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: clockText.updateText()
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: { clockText.hover = true; clockText.updateText() }
        onExited: { clockText.hover = false; clockText.updateText() }
    }
}