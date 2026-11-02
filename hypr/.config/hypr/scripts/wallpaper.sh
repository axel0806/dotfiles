#!/usr/bin/env bash
# Wallpaper switcher: awww for the image, matugen for kitty colors
# (~/.config/matugen/config.toml), border-colors.py for Hyprland borders
# in a hue that contrasts with the wallpaper.
#
#   wallpaper.sh pick        rofi grid with thumbnails
#   wallpaper.sh random      random wallpaper (not the current one)
#   wallpaper.sh next|prev   cycle through the folder
#   wallpaper.sh restore     re-apply the last wallpaper (used at login)
#   wallpaper.sh <file>      apply a specific image

set -euo pipefail

# realpath: ~/Pictures/wallpapers is a stow symlink into ~/dotfiles/wallpapers
WALL_DIR=$(realpath "${WALLPAPER_DIR:-$HOME/Pictures/wallpapers}")
CACHE="$HOME/.cache/wallpaper"
STATE="$CACHE/current"
THUMBS="$CACHE/thumbs"
DEFAULT="$WALL_DIR/twilight-in-the-wilderness/twilight-cropped.jpg"

mkdir -p "$THUMBS"

list_walls() {
    find -L "$WALL_DIR" -type f \
        \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) \
        | sort
}

current() {
    local c=""
    [[ -f $STATE ]] && c=$(<"$STATE")
    [[ -f $c ]] && echo "$c" || echo "$DEFAULT"
}

wait_for_daemon() {
    for _ in $(seq 50); do
        awww query >/dev/null 2>&1 && return 0
        sleep 0.1
    done
    echo "awww-daemon is not running" >&2
    return 1
}

# transition grows out from the mouse cursor (awww measures y from the bottom)
cursor_pos() {
    local pos h
    pos=$(hyprctl cursorpos 2>/dev/null | tr -d ' ') || { echo center; return; }
    h=$(hyprctl monitors -j 2>/dev/null \
        | python3 -I -c 'import json,sys; m=[m for m in json.load(sys.stdin) if m["focused"]][0]; print(int(m["height"]/m["scale"]))' \
        2>/dev/null) || { echo center; return; }
    echo "${pos%,*},$(( h - ${pos#*,} ))"
}

apply() {
    local img
    img=$(realpath "$1")
    [[ -f $img ]] || { echo "no such file: $1" >&2; exit 1; }

    wait_for_daemon
    awww img "$img" \
        --resize crop \
        --transition-type grow \
        --transition-pos "$(cursor_pos)" \
        --transition-duration 1.2 \
        --transition-fps 60

    echo "$img" > "$STATE"

    # kitty palette (matugen's post_hook sends kitty SIGUSR1 to reload)
    matugen image "$img" -m dark --source-color-index 0 >/dev/null

    # window borders in the wallpaper's complementary hue
    python3 -I "$(dirname "$(realpath "$0")")/border-colors.py" "$img" >/dev/null
    hyprctl reload >/dev/null
}

make_thumb() {
    local img=$1 thumb
    thumb="$THUMBS/$(printf '%s' "$img" | md5sum | cut -c1-16).jpg"
    if [[ ! -f $thumb || $img -nt $thumb ]]; then
        python3 -I - "$img" "$thumb" <<'PY'
import sys
from PIL import Image, ImageOps
src, dst = sys.argv[1], sys.argv[2]
with Image.open(src) as im:
    ImageOps.fit(im.convert("RGB"), (400, 225), Image.LANCZOS).save(dst, quality=85)
PY
    fi
    printf '%s' "$thumb"
}

pick() {
    local -a walls
    mapfile -t walls < <(list_walls)
    (( ${#walls[@]} )) || { notify-send "Wallpaper" "No images in $WALL_DIR"; exit 1; }

    local idx
    idx=$(
        for w in "${walls[@]}"; do
            printf '%s\0icon\x1f%s\n' "$(basename "${w%.*}")" "$(make_thumb "$w")"
        done | rofi -dmenu -i -format i -p "Wallpaper" -show-icons \
            -theme-str '
                window   { width: 1040px; }
                listview { columns: 4; lines: 3; fixed-columns: true; spacing: 12px; flow: horizontal; }
                element  { orientation: vertical; padding: 8px; border-radius: 10px; }
                element-icon { size: 180px; horizontal-align: 0.5; }
                element-text { horizontal-align: 0.5; }
            '
    ) || exit 0
    apply "${walls[$idx]}"
}

step() {
    local dir=$1 cur i n
    local -a walls
    mapfile -t walls < <(list_walls)
    n=${#walls[@]}
    (( n )) || exit 1
    cur=$(current)
    for i in "${!walls[@]}"; do
        [[ ${walls[$i]} == "$cur" ]] && break
    done
    apply "${walls[$(( (i + dir + n) % n ))]}"
}

random_wall() {
    local cur
    cur=$(current)
    local next
    next=$(list_walls | grep -vxF "$cur" | shuf -n1 || true)
    apply "${next:-$cur}"
}

case "${1:-pick}" in
    pick)    pick ;;
    random)  random_wall ;;
    next)    step 1 ;;
    prev)    step -1 ;;
    restore) apply "$(current)" ;;
    -h|--help) sed -n '2,10p' "$0" ;;
    *)       apply "$1" ;;
esac
