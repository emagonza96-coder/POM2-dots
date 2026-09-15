import Quickshell
import Quickshell.Services.UPower
import QtQuick

Item {
    id: batWrapper
    width: batIcon.width
    height: 26

    property bool expanded: false
    property var battery: UPower.displayDevice
    property bool charging: battery.state === UPowerDeviceState.Charging
    readonly property int level: Math.round(battery.percentage * 100)

    readonly property string icon: {
        if (charging) return "\ue919 "
        else if (level <= 100 && level > 70) return "\ue91a "
        else if (level <= 70 && level > 60) return "\ue91b "
        else if (level <= 60 && level > 20) return "\ue91c "
        else if (level <= 20 && level > 10) return "\ue91d "
        else if (level <= 10) return "\ue91e "
        else return "\ue91a "
    }

    property string timeText: {
        let secs = charging ? battery.timeToFull : battery.timeToEmpty
        if (!secs || secs <= 0) return ""
        let h = Math.floor(secs / 3600)
        let m = Math.floor((secs % 3600) / 60)
        return h + "h " + m + "m"
    }

    Row {
        id: batIcon
        spacing: 3
        height: 26
        anchors.verticalCenter: parent.verticalCenter

        Text {
            text: batWrapper.icon
            font.family: "POM2Icons"
            font.pixelSize: 12
            color: batWrapper.charging ? "#6abf74"
                                : batWrapper.level > 50 ? "#6abf74"
                                : batWrapper.level > 20 ? "#c8a86a"
                                : "#ff6b6b"
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            visible: batWrapper.expanded
            text: batWrapper.level + "% · " + batWrapper.timeText
            color: "#b8d4bc"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 12
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: batWrapper.expanded = true
        onExited: batWrapper.expanded = false
    }
}