import Quickshell
import Quickshell.Services.UPower
import QtQuick
import "../.."

Item {
    id: batWrapper
    width: batIcon.width
    height: 26

    property bool expanded: false
    property var battery: UPower.displayDevice
    property bool charging: battery.state === UPowerDeviceState.Charging
    readonly property int level: Math.round(battery.percentage * 100)

    readonly property string icon: {
        if (charging)        return "\ue919"
        else if (level > 70) return "\ue91a"
        else if (level > 60) return "\ue91b"
        else if (level > 20) return "\ue91c"
        else if (level > 10) return "\ue91d"
        else                 return "\ue91e"
    }

    readonly property color iconColor:
        charging       ? Theme.accent :
        level > 50     ? Theme.accent :
        level > 20     ? Theme.amber  : Theme.red

    property string timeText: {
        let secs = charging ? battery.timeToFull : battery.timeToEmpty
        if (!secs || secs <= 0) return ""
        let h = Math.floor(secs / 3600)
        let m = Math.floor((secs % 3600) / 60)
        return h + "h " + m + "m"
    }

    // Pulso suave cuando batería está crítica (<=10%)
    SequentialAnimation {
        running: !batWrapper.charging && batWrapper.level <= 10
        loops: Animation.Infinite
        NumberAnimation { target: batIconText; property: "opacity"; to: 0.3; duration: 700; easing.type: Easing.InOutSine }
        NumberAnimation { target: batIconText; property: "opacity"; to: 1.0; duration: 700; easing.type: Easing.InOutSine }
    }

    Row {
        id: batIcon
        spacing: 3
        height: 26
        anchors.verticalCenter: parent.verticalCenter

        Text {
            id: batIconText
            text: batWrapper.icon
            font.family: Theme.iconFont
            font.pixelSize: Theme.fontSizeLg
            color: batWrapper.iconColor
            anchors.verticalCenter: parent.verticalCenter
            Behavior on color { ColorAnimation { duration: 300 } }
        }

        Text {
            id: batDetail
            opacity: batWrapper.expanded ? 1.0 : 0.0
            visible: opacity > 0
            text: batWrapper.level + "% · " + batWrapper.timeText
            color: Theme.text
            font.family: Theme.font
            font.pixelSize: Theme.fontSizeLg
            anchors.verticalCenter: parent.verticalCenter
            Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutQuad } }
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: batWrapper.expanded = true
        onExited:  batWrapper.expanded = false
    }
}