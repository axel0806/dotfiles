#!/bin/bash
# Waybar custom module (continuous exec): prints the clock as JSON lines and animates it
# on click. One process owns the animation and prints every step itself. The module
# width is the width of its text, so each step moves the box and the text together.
# Clicks arrive as "toggle" lines on a FIFO.
#
# hidden = leading characters of "Mon, 26. Oct  17:13" that are hidden (0 = date, 14 = time).
# Each step hides or reveals one character, about 7.8px of width in the monospace font.
# STEP is two frames at 60Hz, so the steps land on frame boundaries evenly.

FIFO=${XDG_RUNTIME_DIR:-/tmp}/waybar-clock.fifo
STEP=0.0333

[[ -p $FIFO ]] || mkfifo "$FIFO"
# Open read-write so neither the reader nor writers block when the other side is absent
exec 3<>"$FIFO"

hidden=14
target=14

emit() {
    local full tooltip
    printf -v full '%(%a, %d. %b  %H:%M)T' -1
    printf -v tooltip '%(%A, %d %B %Y)T' -1
    printf '{"text":"%s","tooltip":"%s"}\n' "${full:hidden}" "$tooltip"
}

emit
while true; do
    timeout=1
    (( hidden != target )) && timeout=$STEP

    if read -r -t "$timeout" -u 3 cmd; then
        # Ignore clicks while an animation is running
        if [[ $cmd == toggle ]] && (( hidden == target )); then
            if (( hidden == 0 )); then
                target=14
            else
                target=0
            fi
        fi
    elif (( hidden < target )); then
        (( hidden++ ))
    elif (( hidden > target )); then
        (( hidden-- ))
    fi

    emit
done
