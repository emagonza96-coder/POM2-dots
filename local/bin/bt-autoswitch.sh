#!/bin/bash
pactl subscribe 2>/dev/null | grep --line-buffered "new.*sink\|remove.*sink" | while read -r line; do
    sleep 1
    SINK_ID=$(wpctl status | grep -i bluez | grep -oP '^\s*\K\d+' | head -1)
    if [ -n "$SINK_ID" ]; then
        wpctl set-default "$SINK_ID"
    fi
done
