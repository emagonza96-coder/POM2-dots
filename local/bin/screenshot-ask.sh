#!/usr/bin/env bash

TMP="/tmp/screenshot-$(date +%Y%m%d-%H%M%S).png"
DEST="$HOME/Imágenes/Capturas/screenshot-$(date +%Y%m%d-%H%M%S).png"

grim -g "$(slurp)" "$TMP" || exit 1

satty --filename "$TMP" --output-filename "$DEST" --early-exit

# Si no guardó archivo, copiar la captura original al portapapeles
if [ ! -f "$DEST" ]; then
    wl-copy < "$TMP"
    notify-send "captura copiada al portapapeles"
fi

rm -f "$TMP"
