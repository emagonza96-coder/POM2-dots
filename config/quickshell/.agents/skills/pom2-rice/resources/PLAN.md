# PLAN y estado — POM-2

> El agente actualiza este archivo al cerrar cada tarea (ver "Protocolo de cierre" en SKILL.md).
> Regla: solo se marca "Hecho" lo que el usuario confirmó que funciona.

Última actualización: 2026-10-29

## Hecho
- Barra Quickshell base: Clock, Weather, Workspace, Battery, Volume, Network, Notifications.
- Hover expandible en Battery (% + tiempo), Network (nombre + señal), Clock (fecha).
- Fuente POM2Icons actualizada (ruta válida `~/.local/share/fonts/` + `fc-cache -f`).
- Fix WiFi corregido: `options rtw88_core disable_lps_deep=Y` aplicado y verificado (ya no sale "unknown parameter").
- Repo `~/POM2-dots` creado y subido a GitHub con `install.sh` (stow).
- 2026-10-22: Ajuste fino de la barra (altura 26px en Network, Clock con 12px, glifos limpios en Battery). Confirmado por el usuario.
- 2026-10-22: Optimización de subprocesos y batería (polling a 2.5s reactivo, swaync-client sin bash). Confirmado por el usuario.
- 2026-10-22: Modularización de TacticalSlider.qml y unificación en VolumePopup.qml (salidas y apps). Confirmado por el usuario.

## En curso / sin confirmar
- POM-2 Unified Island & Agent Telemetry: Backend de hooks de Antigravity en `~/.local/bin/pom2-agy-hook` y `hooks.json`, Isla central unificada (`DashboardIsland.qml`) con ranura modular de avatar del Ojo de Entrati (Warframe), rotación a 4s entre Spotify y el ticker de herramientas del agente, badge/toast de notificaciones SwayNC integradas, retiro de `Notifications` de `barRight` en `Shell.qml`, y pestaña `04 // AGENT` en `Dashboard.qml` con telemetría de sesión en vivo, registro de pasos recientes y botones tácticos para enfocar Kitty (`hyprctl dispatch focuswindow`) y abrir SwayNC. SIN CONFIRMAR visualmente por el usuario.
- Dashboard Notch: contorno exterior unificado como una sola línea pura continua en Theme.border (sin ninguna esquina iluminada/accent en el perímetro exterior de la barra ni del notch). Los módulos y tarjetas internos conservan sus esquinas tácticas. SIN CONFIRMAR por el usuario.
- Dashboard central: Pestaña 03 MEDIA con Spotify interactivo (carátula, artista/pista, barra de progreso con *seek* interactivo al clic y botón para lanzar Spotify si está cerrado). Controles vinculados reactivamente a `Quickshell.Services.Mpris` con procesos desacoplados para evitar bloqueos. SIN CONFIRMAR por el usuario.
- TacticalSpectrum.qml: Visualizador táctico retro de audio de 16 bandas conectado a `cava` (PipeWire) con símbolos nativos de teclado (`#`, `%`, `*`, `+`, `=`, `-`, `:`, `.`) en lugar de barras, variación cromática militar (verde base, ámbar medio, rojo pico) y reubicado arriba de la barra de progreso. SIN CONFIRMAR visualmente por el usuario.
- Barra superior: Entrada central al Dashboard renderizada exclusivamente como texto táctico interactivo (`󰍛 POM-2 // HUD` / `󰓇 Artista - Pista`), sin cajas ni contornos, y despliegue del popup centrado en pantalla. SIN CONFIRMAR visualmente por el usuario.
- Dashboard táctico POM-2: Pestañas 02 // PERF (telemetría real de CPU, RAM, CPU Temp y GPU Temp vía `system_telemetry.py`) y 03 // MEDIA (control interactivo de Spotify/MPRIS2 vía `media_telemetry.py` con carátula, track/artista, barra progresiva y botones Prev/Play-Pause/Next funcionales). SIN CONFIRMAR visualmente por el usuario.
- Dashboard táctico POM-2: Pestaña DASH refinada sin slider de volumen (solo brillo vertical sincronizado y 4 botones tácticos de sesión), contornos 100% cuadrados (`radius: 0`) con esquinas iluminadas (1px). SIN CONFIRMAR visualmente por el usuario.
- TacticalRing.qml: diseño 100% cuadrado (`radius: 0`), 4 esquinas tácticas iluminadas, corrección de alcance de variables y repintado reactivo a `activeColor`/`warnColor`. SIN CONFIRMAR visualmente por el usuario.
- VolumePopup.qml y NetworkPopup.qml: notch táctico continuo aplicado (perímetro exterior continuo en Theme.border sin esquinas iluminadas, techo abierto fusionado con la barra en Theme.surface, eliminación de slideTranslate y retención de esquinas tácticas en tarjetas internas). SIN CONFIRMAR visualmente por el usuario.
- VolumePopup: speakers + micrófono con slider custom y mute. SIN CONFIRMAR.
- Glifos de iconos adivinados (ver QUICKSHELL_NOTES.md).
- Observación de crashes: pendiente ~1 semana de uso normal tras el fix del WiFi.

## Pendientes (por prioridad)
1. Fusión de la barra (Waybar/Quickshell) con los demás popups ([VolumePopup.qml](file:///home/emn/.config/quickshell/modules/popups/VolumePopup.qml) y [NetworkPopup.qml](file:///home/emn/.config/quickshell/modules/popups/NetworkPopup.qml)).
2. Confirmar/ajustar NetworkPopup y VolumePopup.
3. Bluetooth: separar en BluetoothPopup dedicado y/o módulo en la barra.
4. Simplificar Notifications.qml (hoy usa swaync-client).
6. Kvantum + esquema de color de Plasma para que System Settings combine con POM-2 (tema base plano, radio 8px, sin sombras, `[Palette]` POM-2).
7. Repo dotfiles: carpeta quickshell sincronizada y commiteada (push pendiente cuando el usuario lo solicite).
8. Autostart de `qs` en hyprland.conf (verificar cómo se lanza).
9. Discord permanente vía `.desktop` (`--disable-gpu --disable-gpu-sandbox --no-sandbox`).
10. Bajo prioridad: blur/opacidad kitty, cava, hyprlock (o `WlSessionLock`), yazi, swayosd, volumen BT que se resetea a 76%, gesto 3 dedos abajo.

## Si persisten los resets
- Revisar `journalctl -b -1 -p err` (buscar `dpk calibration`).
- Probar `pcie_aspm=off` en los parámetros de arranque.
- Cambiar de distro NO se espera que lo resuelva (es driver/kernel).

## Changelog
- 2026-10-15: skill creado a partir del contexto v3 del proyecto.
- 2026-10-15: Auditoría y corrección de diseño POM-2: Theme.red agregado, bordes verdes unificados en NetworkPopup y Battery.qml usando Theme.red.
- 2026-10-15: Fix en NetworkPopup.qml: delimitación de textos para evitar sobreposición con el botón Desconectar y márgenes/recorte para no tapar el contorno del popup.
- 2026-10-15: Prototipo de slider retro táctico por segmentos VU-meter en salidas de audio (VolumePopup.qml).
- 2026-10-15: Botón de agarre táctico con indicador `>` añadido sobre la barra segmentada en VolumePopup.qml.
- 2026-10-15: Sliders retro tácticos (segmentos + agarre '>') unificados en todas las salidas y aplicaciones de VolumePopup.qml.
- 2026-10-15: Rediseño de pestañas en VolumePopup.qml con indicador inferior animado (underline tipo Workspace).
- 2026-10-22: Unificación de alturas a 26px (Network), fuente base 12px (Clock) y retiro de espacios en Battery.
- 2026-10-22: Optimización de subprocesos: llamadas directas a swaync-client sin bash y polling espaciado a 2.5s con refresco reactivo.
- 2026-10-22: Creación de TacticalSlider.qml y modularización en VolumePopup.qml (reducción de duplicidad y mantenimiento limpio).
- 2026-10-22: NetworkPopup con deduplicación de SSIDs (mejor señal por nombre) y blindaje al desconectar.
- 2026-10-22: Esqueleto de Dashboard.qml creado (DASH con brillo vertical y sesión, PERF con 4 anillos, MEDIA para Spotify) y enlazado a Shell.qml.
- 2026-10-23: Unificación completa del diseño táctico HUD militar POM-2 (100% contornos cuadrados `radius: 0` y esquinas iluminadas en 1px) en `VolumePopup.qml` y `TacticalRing.qml`. Retiro definitivo del slider de volumen en `Dashboard.qml` DASH (mantenido solo brillo y sesión táctica).
- 2026-10-23: Rediseño táctico militar completo de `NetworkPopup.qml`: separación y tarjeta destacada de red conectada (sin colisiones en esquinas), pestañas con underline animado tipo Workspace (`01 // REDES`, `02 // ESTADO`), header militar `[NET // WLAN0]` con estado de escaneo activo, y telemetría de red en tiempo real vía `network_telemetry.py`.
- 2026-10-23: Corrección del posicionamiento y desbordes de botones en `NetworkPopup.qml`: eliminación de `Row` con `Layout.fillWidth` erróneo y cambio a anclajes directos (`anchors.right: parent.right`, margen 8px) en `refreshBtn`, `disconnectBtn` y `actionBtn` / `rightSlot`.
- 2026-10-23: Integración de telemetría de Clima (`weatherCard`) en Dashboard 01 y reubicación de `Workspace.qml` en la barra superior junto al reloj.
- 2026-10-23: Workspace.qml dinámico con expansión en hover mostrando glifos de apps activas (`hyprctl clients -j`) y colapso animado de los workspaces inactivos.
- 2026-10-23: Fix crítico en Dashboard pestaña 01: corrección estructural del cierre de `TacticalVerticalSlider`, aislamiento del panel derecho y reajuste del grid 2x2 de energía y tarjeta de clima, eliminando toda sobreposición y amontonamiento en esquinas.
- 2026-10-23: Rediseño táctico de `TacticalSlider.qml` horizontal para unificarlo con `TacticalVerticalSlider.qml`: retiro del botón con texto `>`, implementación de retícula HUD con corchetes iluminados `[ | ]`, bloques segmentados consistentes (`#0d180f`, bordes `#132416`), y soporte de rueda de ratón (onWheel).
- 2026-10-23: Variación cromática de 3 niveles por intensidad en sliders de volumen y popup: Verde (`Theme.accent`) para niveles seguros (<= 85%), Ámbar (`Theme.amber`) para alta ganancia (85% a 125%), y Rojo (`Theme.red`) para overdrive extremo (> 125% hasta 150%). Retícula `[ | ]`, bloques segmentados activos y porcentaje numérico adaptados dinámicamente.
- 2026-10-23: Implementación funcional completa del Dashboard: backend ligero `system_telemetry.py` para CPU, RAM y temperaturas (Ryzen 5700U), backend `media_telemetry.py` para Spotify/MPRIS2, integración interactiva en `Dashboard.qml` con timers condicionales y refresco rápido en controles de reproducción.
- 2026-10-29: Dashboard integrado en el centro de la barra superior como texto táctico limpio sin contornos ni corchetes (`󰍛 POM-2 // HUD` o `󰓇 Artista - Pista`). Despliegue del Dashboard centrado en pantalla.
- 2026-10-29: Eliminación definitiva de volumen y toggles de pestaña 01 DASH. Instalación de `cava` y creación de `TacticalSpectrum.qml` (visualizador táctico retro de 16 bandas, bloques cuadrados y variación cromática verde/ámbar/rojo).
- 2026-10-29: Integración completa de Spotify en pestaña 03: carátula, botón `[ ABRIR SPOTIFY ]` cuando está offline, barra de progreso con *seek* interactivo al clic y visualizador de espectro en tiempo real vía CAVA.
- 2026-10-29: Reubicación de TacticalSpectrum arriba de la barra de progreso en pestaña 03 MEDIA. Conversión del visualizador a símbolos nativos de teclado (`#`, `%`, `*`, `+`, `=`, `-`, `:`, `.`) sobre matriz retro militar POM-2.
- 2026-10-29: Corrección de fallos en botones de medios: integración reactiva con `Quickshell.Services.Mpris` (togglePlaying, previous, next) y desacoplamiento de subprocesos (`hyprctl dispatch exec` para Spotify, `seekProc` y `mediaCmdProc`) eliminando bloqueos de interfaz.
- 2026-10-29: Retiro del contorno exterior y esquinas en TacticalSpectrum.qml. Motor de balística dinámica ASCII añadido: espacio superior libre de cuadrícula plana, crestas activas `^`, cuerpo denso y picos flotantes `^` con caída suave por gravedad.
- 2026-10-29: Retiro del texto de cabecera de audio espectro. Calibración de tamaño vertical (74px, fuente 10px en JetBrainsMono) y juego de caracteres variado y vistoso (`!`, `@`, `#`, `$`, `%`, `*`, `(`, `)`, `_`, `+`, `~`, `^`) alternado por columnas.
- 2026-10-29: Corrección de sobreposición en pestaña 03: celdas verticales de TacticalSpectrum encapsuladas a 7px exactos con clip estricto (56px matriz / 62px total), carátula calibrada a 56x56 y márgenes de 10px eliminando cualquier invasión sobre el título o la barra de progreso.
- 2026-10-29: Mutación rítmica continua en TacticalSpectrum.qml: desfase individual por columna (`colShift`), rotación al golpe del ritmo y timer orgánico (120ms) a través del banco `!@#$%*()_+~^`. La línea base inferior ahora varía activamente entre `_`, `=`, `~` y `-` en lugar de ser estática.
- 2026-10-29: Filtrado exclusivo para Spotify en el dashboard de medios (Dashboard.qml), backend (media_telemetry.py) y texto central de la barra (DashboardIsland.qml). Se ignoran navegadores (Firefox/Chrome) y reproductores de video genéricos.
- 2026-10-29: Fusión completa de contorno Waybar-Dashboard: Shell.qml proyecta dinámicamente el contorno táctico inferior (Theme.border) que se abre en la bahía central de 350px, conectando sus esquinas de 90° con los bordes laterales del Dashboard (anclado a ras de root.height). SIN CONFIRMAR visualmente por el usuario.
- 2026-10-30: Refinamiento del Dashboard como notch táctico: retiradas todas las esquinas iluminadas (Theme.accent) del perímetro exterior tanto en la barra como en el Dashboard, logrando una sola línea pura y continua en Theme.border que recorre toda la pantalla y el notch sin interrupciones. Los módulos y tarjetas interiores conservan sus esquinas tácticas POM-2.
- 2026-10-30: Unificación de notch táctico en todos los popups (VolumePopup.qml y NetworkPopup.qml): contorno exterior cerrado en Theme.border continuo sin esquinas accent en el perímetro, techo abierto que se fusiona con la barra en Theme.surface, eliminación de saltos verticales (slideTranslate) y conservación de esquinas tácticas en tarjetas, módulos y botones internos.
- 2026-10-30: Implementación completa de POM-2 Unified Island y telemetría de agentes de IA (Antigravity): backend de hooks en `~/.local/bin/pom2-agy-hook` (<7ms de latencia, RAM `/run/user/1000/pom2-agent.json`), registro en `hooks.json`, Isla central (`DashboardIsland.qml`) con ranura de avatar del Ojo de Entrati (Warframe), rotación cíclica de 4s con Spotify, badge y toast de notificaciones integradas (SwayNC), y retiro del widget Notifications del ala derecha en `Shell.qml`.
- 2026-10-30: Reestructuración widescreen del Dashboard táctico (480px ancho × 330px alto) y bahía central en `Shell.qml` (480px):
  - Retiro total del botón de apertura del daemon/panel flotante de SwayNC (`swaync-client -t -sw`).
  - Integración nativa de notificaciones acumuladas generales en `01 // DASH` (`[NOTIF // BANDEJA]` junto a la tarjeta de clima con contador real vía `swaync-client -c` y botón táctico `[ LIMPIAR ]` con `swaync-client -C`).
  - Aislamiento de eventos de agentes en `04 // AGENT` con distribución horizontal widescreen a dos columnas (columna izquierda: Operación actual, target, detalle y botón directo `[ FOCUS KITTY TERMINAL ]`; columna derecha: Registro de eventos de telemetría).
  - Calibración de `TacticalRing.qml` en `02 // PERF` (tarjetas de 224px × 124px) eliminando cualquier desborde vertical.

