#!/bin/bash
CHOICE=$(echo -e "󰐥 Shutdown\n󰑙 Reboot\n󰌾 Lock\n󰍃 Logout\n󰤄 Suspend" | rofi -dmenu -p "" -theme ~/.config/rofi/themes/power-menu.rasi -theme-str 'inputbar { enabled: false; }' -no-custom -hide-scrollbar)
case "$CHOICE" in
    "󰌾 Lock") hyprlock ;;
    "󰍃 Logout") hyprctl dispatch exit ;;
    "󰤄 Suspend") systemctl suspend ;;
    "󰐥 Shutdown") systemctl poweroff ;;
    "󰑙 Reboot") systemctl reboot ;;
esac
