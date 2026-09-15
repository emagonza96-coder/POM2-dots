#!/usr/bin/env bash

CONF="$HOME/.config/fastfetch/config.jsonc"
RUN="$HOME/.config/fastfetch/config_run.jsonc"
PALETTE="$HOME/.config/fastfetch/pom2.conf"

read -r _ C1 < <(grep "^C1" "$PALETTE")
read -r _ C2 < <(grep "^C2" "$PALETTE")
read -r _ C3 < <(grep "^C3" "$PALETTE")
read -r _ C4 < <(grep "^C4" "$PALETTE")

sed -e "s/%%C1%%/${C1}/g" \
    -e "s/%%C2%%/${C2}/g" \
    -e "s/%%C3%%/${C3}/g" \
    -e "s/%%C4%%/${C4}/g" \
    "$CONF" > "$RUN"

fastfetch --config "$RUN"
