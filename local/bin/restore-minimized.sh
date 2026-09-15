#!/bin/bash
windows=$(hyprctl clients -j | jq -r '.[] | select(.workspace.name == "special:minimized") | "\(.address) \(.floating) \(.title)"')

if [ -z "$windows" ]; then
    notify-send "Sin ventanas minimizadas"
    exit 0
fi

selected=$(echo "$windows" | awk '{$1=""; $2=""; print substr($0,3)}' | rofi -dmenu -p "Restaurar ventana")

if [ -n "$selected" ]; then
    address=$(echo "$windows" | grep "$selected" | awk '{print $1}')
    was_floating=$(echo "$windows" | grep "$selected" | awk '{print $2}')
    
    hyprctl dispatch movetoworkspace "e+0,address:$address"
    
    if [ "$was_floating" = "true" ]; then
        sleep 0.1
        hyprctl dispatch setfloating "address:$address"
    fi
fi
