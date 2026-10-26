#!/bin/sh
# Usage: screenshot.sh region|full
# Saves a PNG to ~/Pictures/Screenshots and copies it to the clipboard.

dir="$HOME/Pictures/Screenshots"
mkdir -p "$dir"
file="$dir/$(date +%Y-%m-%d_%H-%M-%S).png"

case "$1" in
    region)
        geometry=$(slurp) || exit 0   # cancelled with Escape
        grim -g "$geometry" "$file" || exit 1
        ;;
    full)
        grim "$file" || exit 1
        ;;
    *)
        echo "usage: $0 region|full" >&2
        exit 2
        ;;
esac

wl-copy < "$file"
command -v notify-send >/dev/null 2>&1 && notify-send "Screenshot saved" "$file"
