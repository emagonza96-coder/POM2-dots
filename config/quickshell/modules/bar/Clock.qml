import QtQuick
import "../.."

Text {
    id: clockText
    color: hovered ? Theme.text : Theme.accent
    font.family: Theme.font
    font.pixelSize: Theme.fontSizeLg
    anchors.verticalCenter: parent.verticalCenter
    property bool hovered: false

    Behavior on color { ColorAnimation { duration: 180 } }
    Behavior on opacity { NumberAnimation { duration: 120 } }

    function switchText(next) {
        // Fade out → cambiar → fade in
        fadeOut.nextText = next
        fadeOut.start()
    }

    function updateText() {
        let next
        if (hovered) {
            next = new Date().toLocaleDateString([], { day: '2-digit', month: 'short', year: 'numeric' })
        } else {
            next = new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
        }
        // Solo animar si el texto cambió
        if (next !== clockText.text) {
            clockText.switchText(next)
        }
    }

    SequentialAnimation {
        id: fadeOut
        property string nextText: ""
        NumberAnimation { target: clockText; property: "opacity"; to: 0; duration: 80; easing.type: Easing.InQuad }
        ScriptAction { script: { clockText.text = fadeOut.nextText } }
        NumberAnimation { target: clockText; property: "opacity"; to: 1; duration: 120; easing.type: Easing.OutQuad }
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
        onEntered: { clockText.hovered = true;  clockText.updateText() }
        onExited:  { clockText.hovered = false; clockText.updateText() }
    }
}