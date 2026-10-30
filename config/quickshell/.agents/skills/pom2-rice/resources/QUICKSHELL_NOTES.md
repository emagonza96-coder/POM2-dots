# Notas Quickshell / QML (lecciones ya pagadas)

Leer antes de escribir o modificar QML. Agregar aquí cada trampa nueva.

## Layout
- `Row` NO tiene `verticalItemAlignment` (eso es de `Grid`). Para centrar: wrapper `Item` con el `Row` adentro y `anchors.verticalCenter: parent.verticalCenter` en el `Row`; o usar `RowLayout` (`import QtQuick.Layouts`).
- Dentro de un `Row` los hijos NO pueden usar `anchors.left/right/horizontalCenter/fill/centerIn` (el Row deja de funcionar). Por eso cada módulo es `Item` wrapper > `Row` + `MouseArea` hermano.
- No fijar `height` rígido en el Row interno si el texto es más chico: queda pegado arriba. Preferir `implicitWidth/implicitHeight` del contenido.

## Imports y tipos
- Propiedades booleanas en QML: Evitar nombrar propiedades que comiencen con `is` (como `isWarning`), ya que el generador de señales de Qt genera `isWarningChanged` y los manejadores directos como `onIsWarningChanged` fallan en el parser de QML. Usar nombres sin prefijo como `warning` o `active`, y gestionar reactividad con `Connections`.
- Los handlers de señal `on<Property>Changed` deben colocarse directamente en el elemento que declara la propiedad o mediante `Connections`; asignarlos en un Item hijo sin dicha propiedad rompe la carga con "Cannot assign to non-existent property".
- Propiedades calculadas en elementos anidados (ej. `cornerColor` para esquinas iluminadas): referenciarlas siempre calificadas con el `id` del contenedor padre (`cardId.cornerColor`) o declararlas en el Item raíz; el acceso no calificado puede arrojar `ReferenceError` al instanciarse en cascada.
- Quickshell tiene hot-reload automático al guardar archivos QML: no matar ni reiniciar el proceso (`killall quickshell`) innecesariamente.
- Todo archivo QML necesita `import QtQuick`; si falta sale el error engañoso "Text is not a type".
- `Theme.qml` es `pragma Singleton` y requiere `qmldir` (`singleton Theme 1.0 Theme.qml`). Desde `modules/bar/` se importa con `import "../.."`.
- Subcarpetas se importan por ruta: `import "../popups"`, `import "tabs"`.
- `Process` y `StdioCollector` requieren `import Quickshell.Io`.
- Un `Process` que ejecuta una aplicación GUI que no sale inmediatamente (como `spotify-launcher`) queda con `running = true`, lo que causa que llamadas subsiguientes a `exec()` se descarten o congelen los demás botones. Para lanzar apps de escritorio, usar `hyprctl dispatch exec <app>` o instancias dedicadas de `Process`.
- Control de medios (MPRIS): Usar `import Quickshell.Services.Mpris` (`activePlayer.togglePlaying()`, `activePlayer.previous()`, `activePlayer.next()`) en lugar de invocar `playerctl` en subprocesos para respuesta reactiva instantánea sin bloqueos de proceso.
- `QtQuick.Controls Slider` puede no estilizar bien: se prefiere slider custom (Rectangle + MouseArea).

## PopupWindow
- Usar `implicitWidth`/`implicitHeight` (`width`/`height` está deprecado).
- Anclaje relativo: `property var parentAnchor`, `anchor.item: parentAnchor`, `anchor.edges: Edges.Bottom`.
- Fusión visual y centrado exacto con la barra (`PanelWindow`): para alinear un popup con bordes recortados en la barra al píxel, anclar a la ventana con `anchor.window: root`, `anchor.rect.x: Math.round((root.width / 2) - (implicitWidth / 2))` y `anchor.rect.y: root.height`. Evita depender del ancho dinámico del módulo/icono de la barra y garantiza que los cortes de contorno en la barra y el popup coincidan a nivel de píxel.
- Un archivo pisado por otro (ej. contenido de un Tab dentro de un Popup) rompe con "non-existent property parentAnchor": verificar que cada popup tenga `PopupWindow` + `parentAnchor`.
- Contenedor con esquinas redondeadas: poner `clip: true` en el `Rectangle` contenedor para evitar que los fondos de los delegates desborden el borde redondeado exterior.
- En delegates con texto y botón (ej. `NetworkPopup`): delimitar la `Column` de texto mediante anclas (`anchors.left: icon.right; anchors.right: button.left`) en lugar de meterlos en un `Row` con `width: parent.width - X` (produce bucle de bindings y el texto se sobrepone al botón). Dar margen lateral (6px) y radio (6px) al delegate para no tapar el contorno del popup.

## Quickshell.Networking (v0.3.x)
- Nombre de la red: **`name`** (NO `ssid`; `.ssid` da undefined).
- `Network`: `name`, `connected`, `known`, `connect()`, `disconnect()`; `WifiNetwork` suma `connectWithPsk(psk)` y señal `connectionFailed(reason)` (`ConnectionFailReason.NoSecrets` = falta contraseña).
- `NetworkDevice`: `name` (interfaz), `type`, `networks`, `disconnect()`.
- **`WifiDevice.scannerEnabled` debe ser `true`** para que liste redes disponibles (si no, solo aparece la conectada). `nmcli dev wifi rescan` NO alimenta el modelo de Quickshell. Activarlo al abrir el popup y apagarlo al cerrarlo.
- `Networking.devices` es `ObjectModel`: usar `.values` para listas y `forEach`. Un array JS usado como `model` no es reactivo: refrescarlo con un `Timer` que reasigne la lista mientras el popup esté visible.
- Al desconectar una red conocida, NetworkManager reconecta solo (autoconnect). Plan: `nmcli connection modify "<nombre>" connection.autoconnect no; nmcli device disconnect <iface>`.

## Otros módulos
- Audio: `wpctl get-volume @DEFAULT_AUDIO_SINK@` / `@DEFAULT_AUDIO_SOURCE@`, `wpctl set-volume`, `wpctl set-mute ... toggle`.
- Batería: `Quickshell.Services.UPower` (`UPower.displayDevice`, `percentage` 0-1, `state`, `timeToFull/timeToEmpty`).
- Workspaces: `Quickshell.Hyprland` (`Hyprland.workspaces.values`, `focusedWorkspace`, `Hyprland.dispatch(...)`).
- Quickshell.Wayland (a futuro): `WlSessionLock` (lockscreen nativo), `ScreencopyView` + `Toplevel` (overview de ventanas), `WlrLayershell`.

## Glifos de POM2Icons
Confirmados: `\ue9e7` wifi, `\ue9e8` sin wifi, `\ue9bf` mute, `\ue9c0` volumen, `\ue919`-`\ue91e` batería, `\ue967`/`\ue91f`/`\ue920` notificaciones.
SIN VERIFICAR (adivinados): `\ue97e` refresh, `\ue9c1` micrófono, `\ue9bd` candado, `\ue9d3` engranaje.
