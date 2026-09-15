import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Controls

PopupWindow {
   id: popup
   property var parentAnchor
   anchor.item: parentAnchor
   anchor.edges: Edges.Bottom
   implicitWidth: 180
   implicitHeight: 50
   color: "#0e180f"

   Slider {
       anchors.centerIn: parent
       width: parent.width - 20
       from: 0; to: 1.5
       onValueChanged: setVolProc.exec(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", value.toString()])
   }

   Process { id: setVolProc }
}