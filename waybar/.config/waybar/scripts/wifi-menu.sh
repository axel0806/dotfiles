#!/bin/bash
# Pick a Wi-Fi network with rofi and connect to it through NetworkManager.
# Saved networks are brought up directly; new secured ones ask for a password.

notify() { command -v notify-send >/dev/null && notify-send -a wifi "$1" "${2:-}"; }

declare -A ssid_for=()
entries=()
while IFS= read -r line; do
    # Terse output: IN-USE:SIGNAL:SECURITY:SSID, with ':' inside SSID escaped as '\:'
    IFS=: read -r inuse signal sec ssid <<< "$line"
    ssid=${ssid//\\:/:}
    [[ -z $ssid || -n ${ssid_for[$ssid]:-} ]] && continue

    mark="  "
    [[ $inuse == "*" ]] && mark="* "
    lock=""
    [[ -n $sec && $sec != "--" ]] && lock="  [secured]"

    entry="${mark}${ssid}  (${signal}%)${lock}"
    ssid_for[$entry]=$ssid
    entries+=("$entry")
done < <(nmcli -t -f IN-USE,SIGNAL,SECURITY,SSID dev wifi list --rescan auto 2>/dev/null)

if [[ ${#entries[@]} -eq 0 ]]; then
    notify "Wi-Fi" "No networks found"
    exit 1
fi

choice=$(printf '%s\n' "${entries[@]}" | rofi -dmenu -i -p "Wi-Fi")
[[ -z $choice ]] && exit 0
ssid=${ssid_for[$choice]}

if nmcli -t -f NAME connection show | grep -qxF "$ssid"; then
    out=$(nmcli connection up id "$ssid" 2>&1)
else
    secured=""
    [[ $choice == *"[secured]" ]] && secured=1
    if [[ -n $secured ]]; then
        pw=$(rofi -dmenu -password -p "Password for $ssid" </dev/null)
        [[ -z $pw ]] && exit 0
        out=$(nmcli dev wifi connect "$ssid" password "$pw" 2>&1)
    else
        out=$(nmcli dev wifi connect "$ssid" 2>&1)
    fi
fi

if [[ $? -eq 0 ]]; then
    notify "Connected" "$ssid"
else
    notify "Connection to $ssid failed" "$out"
    exit 1
fi
