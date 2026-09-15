#!/bin/bash
DOTS=("·····" "·•···" "·•●··" "·•●•·" "··●··" "·•●•·" "·•●●·" "··●●·" "••●··" "·●●•·")
i=0
while true; do
    STATUS=$(playerctl -p spotify status 2>/dev/null)
    TITLE=$(playerctl -p spotify metadata title 2>/dev/null | cut -c1-25)
    if [ -z "$STATUS" ]; then
        echo '{"text": "Spotify", "alt": "", "class": "inactive"}'
        sleep 0.2
        continue
    fi
    if [ "$STATUS" = "Playing" ]; then
        ICON="⏸"
        VIZ="${DOTS[$i]}"
        i=$(( (i+1) % 10 ))
    else
        ICON="▶"
        VIZ="·····"
    fi
    echo "{\"text\": \"$VIZ $TITLE\", \"alt\": \"$ICON\", \"class\": \"$STATUS\"}"
    sleep 0.2
done
