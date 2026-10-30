import Quickshell
import Quickshell.Wayland
import QtQuick
import "modules/bar"
import "modules/popups"
import "."

PanelWindow {
    id: root
    anchors.top: true
    anchors.left: true
    anchors.right: true
    implicitHeight: 26
    color: Theme.surface

    Row {
        id: barLeft
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: 18
        spacing: 12

        Clock {}

        Text {
            text: "//"
            font.family: Theme.font
            font.pixelSize: 10
            font.bold: true
            color: Theme.separator
            anchors.verticalCenter: parent.verticalCenter
        }

        Workspace {}
    }

    Row {
        id: barRight
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.rightMargin: 18
        spacing: 12

        Volume {}
        Battery {}
        Network {}
    }

    // Bahía central táctica POM-2 calibrada al ancho del Dashboard (480px)
    Item {
        id: centralBay
        width: 480
        x: Math.round((root.width - width) / 2)
        anchors.top: parent.top
        anchors.bottom: parent.bottom

        DashboardIsland {
            id: centralIsland
            anchors.centerIn: parent
            dashboardOpen: dashboardPopup.visible
            onClicked: dashboardPopup.visible = !dashboardPopup.visible
        }
    }

    Dashboard {
        id: dashboardPopup
        visible: false
        parentAnchor: centralBay
    }

    // Contorno táctico de la barra fusionado con el Dashboard
    Item {
        id: waybarContour
        anchors.fill: parent
        opacity: dashboardPopup.visible ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutQuad } }

        // Ala izquierda de la barra (unida directamente al notch central)
        Rectangle {
            id: barBorderLeft
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            width: centralBay.x + 1
            height: 1
            color: Theme.border
        }

        // Ala derecha de la barra (unida directamente al notch central)
        Rectangle {
            id: barBorderRight
            anchors.left: parent.left
            anchors.leftMargin: centralBay.x + centralBay.width - 1
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 1
            color: Theme.border
        }
    }
}