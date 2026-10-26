#!/bin/bash
# Waybar custom module: print Bluetooth state as JSON (text, tooltip, class).
# Shows the first connected device's name, or "On" / "Off" when nothing is connected.

ICON_ON=$'\U000F00AF'    # 󰂯 bluetooth
ICON_OFF=$'\U000F00B2'   # 󰂲 bluetooth_disabled
ICON_CONN=$'\U000F00B1'  # 󰂱 bluetooth_connected

# Escape a string for use inside a JSON string literal
json_str() {
    local s=${1//\\/\\\\}
    s=${s//\"/\\\"}
    printf '%s' "$s"
}

powered=$(timeout 3 bluetoothctl show 2>/dev/null | awk '/Powered:/ {print $2}')
if [[ $powered != yes ]]; then
    printf '{"text":"%s Off","tooltip":"Bluetooth is off","class":"off"}\n' "$ICON_OFF"
    exit 0
fi

names=()
while read -r _ _ name; do
    [[ -n $name ]] && names+=("$name")
done < <(timeout 3 bluetoothctl devices Connected 2>/dev/null)

if [[ ${#names[@]} -eq 0 ]]; then
    printf '{"text":"%s On","tooltip":"Bluetooth on, no devices connected","class":"on"}\n' "$ICON_ON"
    exit 0
fi

tooltip=""
for n in "${names[@]}"; do
    tooltip+="${tooltip:+\\n}$(json_str "$n")"
done
printf '{"text":"%s %s","tooltip":"Connected:\\n%s","class":"connected"}\n' \
    "$ICON_CONN" "$(json_str "${names[0]}")" "$tooltip"
