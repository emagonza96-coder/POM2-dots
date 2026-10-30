---
name: pom2-rice
description: Diseño, meta y plan del rice "POM-2" del usuario emn (EndeavourOS + Hyprland + Quickshell, tema verde oscuro táctico). Usar siempre que se pida crear, arreglar o cambiar algo del escritorio - barra y popups Quickshell (QML), red/volumen/bluetooth, Hyprland, rofi, GTK/Qt/Kvantum, fuente de iconos POM2Icons, dotfiles/repo o el fix del WiFi RTL8822CE. Al terminar cualquier tarea, este skill se actualiza a sí mismo (ver "Protocolo de cierre").
---

# POM-2 Rice

## Meta
Un escritorio Linux oscuro, minimalista y táctico (inspiración militar/Warframe), 100% propio: barra y paneles hechos en Quickshell (QML) con la paleta POM-2, sin depender de dotfiles ajenos. Funcional primero, estético segundo. Todo debe poder reinstalarse rápido en otro usuario desde el repo de dotfiles.

## Usuario y máquina
- Usuario: **emn**. Equipo: **EPC06** (Huawei MateBook BOM-WXX9, Ryzen 7 5700U, 16GB, NVMe 512GB).
- SO: EndeavourOS, Hyprland 0.54.x, shell **fish**, Quickshell 0.3.x (paquete `quickshell`).
- WiFi/BT: Realtek RTL8822CE (driver rtw88, con bugs conocidos).
- Repo: `~/POM2-dots` -> https://github.com/emagonza96-coder/POM2-dots

## Reglas de trabajo (obligatorias)
1. Responder en **español**, directo y corto. Sin preámbulos ni explicar lo que el usuario ya sabe. Solo extenderse si pide "plan detallado" o "damelo completo".
2. Un comando o pocos a la vez; esperar el resultado antes de seguir. Nunca dar algo por funcionando sin confirmación del usuario.
3. **Verificar en la documentación oficial antes de escribir código de una API** (Quickshell, Hyprland, Qt). Varios errores previos vinieron de asumir propiedades inexistentes.
4. Editar siempre sobre el contenido real del archivo actual, no sobre una versión recordada. Si hay duda, leer el archivo primero.
5. Verificar antes de modificar. No borrar, sobrescribir ni usar `sudo` sin avisar qué hará.
6. Fish: NO usar heredoc (`<< EOF`), ni wildcards tipo `/dev/sd*`, ni `${variable}` (usar `$variable`). Editor: `nano`.
7. Probar Quickshell con `qs -p ~/.config/quickshell/Shell.qml` y leer los warnings. Hyprland: `hyprctl reload`.

## Diseño

Paleta (usar siempre estos valores, idealmente vía `Theme.qml`):
```
Fondo principal   #08100a      Superficie/barra/popups  #0e180f
Separador/selec.  #1e2e1f      Borde activo             #4e9e5a
Acento/hover      #6abf74      Texto principal          #b8d4bc
Texto muted       #5a7a5e      Ámbar/alerta             #c8a86a
Rojo crítico      #ff6b6b (solo batería baja/errores graves)
```
- Tipografía: JetBrainsMono Nerd Font (texto) + `POM2Icons` (iconos propios, `~/.local/share/fonts/POM2Icons.ttf`).
- Contornos de popups 100% cuadrados (`radius: 0`) con esquinas tácticas iluminadas en 1px (estilo militar/HUD táctico). Bordes verdes sutiles, nunca neón. Sin sombras ni decoración innecesaria.
- Patrón de interacción: hover expande info breve en la barra; click abre popup con la configuración detallada (wifi, bluetooth, audio). Un "dashboard/control center" con pestañas queda para después.

## Arquitectura actual
```
~/.config/quickshell/
  Shell.qml  Theme.qml  qmldir
  modules/bar/     Clock Weather Workspace Battery Volume Network Notifications
  modules/popups/  NetworkPopup VolumePopup TacticalSlider TacticalVerticalSlider TacticalRing Dashboard (BluetoothPopup pendiente)
```
Fuente de verdad: `~/.config/...` (sistema vivo). El repo `~/POM2-dots` es el espejo versionado.

## Decisiones permanentes (no revertir sin orden explícita del usuario)
- Quickshell es la barra activa (Waybar quedó solo como respaldo en el repo).
- Sin hyprbars, sin nm-applet, sin eww, sin cmatrix, sin ASCII de búnker.
- wlogout reemplazado por rofi (`SUPER+M`, power-menu.sh); sin Hibernate.
- power-profiles-daemon sobre TLP. Papirus-Dark con carpetas verdes.
- `recolor = false` en Zathura.
- Seguridad/Privacidad y Sistema de KDE NO se rehacen en QML: se abren con `systemsettings` y se tematizan con Kvantum.
- Dashboard: NO reintegrar slider de volumen ni toggles rápidos de sistema en pestaña 01 DASH (queda solo Brillo, Clima y botones de Sesión). El control de Spotify debe ser funcional completo con un visualizador táctico retro de audio.

## Fix de hardware vigente
`/etc/modprobe.d/rtw88.conf` debe contener exactamente `options rtw88_core disable_lps_deep=Y` (el parámetro viejo `lps_deep_mode` NO existe y el kernel lo ignoraba). Si reaparece `failed to do dpk calibration` o hay resets abruptos, el siguiente paso es probar `pcie_aspm=off` como parámetro de arranque.

## Más contexto
- Reglas y trampas de Quickshell/QML ya descubiertas: `resources/QUICKSHELL_NOTES.md` (LEER antes de escribir QML).
- Estado, pendientes y changelog: `resources/PLAN.md` (LEER al empezar cada sesión).

## Protocolo de cierre (auto-actualización)
Al terminar cualquier tarea de este proyecto, antes de dar la respuesta final:
1. Actualizar `resources/PLAN.md`: mover lo terminado a "Hecho" con fecha; agregar pendientes nuevos; marcar "sin confirmar" todo lo que el usuario aún no probó (nunca marcar como hecho algo sin su confirmación).
2. Si cambió la paleta, la arquitectura, una decisión permanente o el fix de hardware: editar la sección correspondiente de este `SKILL.md`.
3. Si se descubrió un error de API, una propiedad real o una trampa nueva: agregarla a `resources/QUICKSHELL_NOTES.md`.
4. Añadir una línea al "Changelog" de `PLAN.md` (fecha + qué cambió).
5. Nunca borrar una decisión permanente por iniciativa propia: si una tarea la contradice, preguntar primero.
6. Si hubo cambios en archivos del sistema, avisar que hay que sincronizar con el repo y proponer el commit (no ejecutar `git push` sin que el usuario lo pida).
