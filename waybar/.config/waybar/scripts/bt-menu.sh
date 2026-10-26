#!/bin/bash
# Pick a Bluetooth action with rofi: toggle power, pair a new device,
# or connect/disconnect a paired device.

notify() { command -v notify-send >/dev/null && notify-send -a bluetooth "$1" "${2:-}"; }

# Scan for nearby devices for a while, then list the ones not yet paired
scan_new() {
    local found mac name
    found=$({
        echo "scan on"; sleep 10
        echo "devices"; sleep 1
        echo "scan off"; echo "quit"
    } | timeout 20 bluetoothctl 2>/dev/null | sed 's/\x1b\[[0-9;]*[a-zA-Z]//g' | grep -E '^Device ')
    local paired
    paired=$(timeout 3 bluetoothctl devices Paired 2>/dev/null | awk '{print $2}')
    while read -r _ mac name; do
        [[ -z $mac ]] && continue
        grep -qxF "$mac" <<< "$paired" && continue
        printf '%s\t%s\n' "$mac" "$name"
    done <<< "$found"
}

# Pair, trust and connect a device without a PIN prompt (NoInputNoOutput agent)
pair_device() {
    local mac=$1 log
    log=$(mktemp)
    {
        echo "agent NoInputNoOutput"; sleep 1
        echo "default-agent"; sleep 1
        echo "pair $mac"; sleep 15
        echo "trust $mac"; sleep 1
        echo "connect $mac"; sleep 5
        echo "quit"
    } | timeout 40 bluetoothctl > "$log" 2>&1
    local ok=1
    grep -q 'Pairing successful' "$log" && ok=0
    rm -f "$log"
    return $ok
}

powered=$(timeout 3 bluetoothctl show 2>/dev/null | awk '/Powered:/ {print $2}')
if [[ $powered == yes ]]; then
    power_entry="󰂲  Turn Bluetooth off"
else
    power_entry="󰂯  Turn Bluetooth on"
fi
pair_entry="+  Pair new device"

declare -A mac_for=()
entries=("$power_entry")

if [[ $powered == yes ]]; then
    entries+=("$pair_entry")
    while read -r _ mac name; do
        [[ -z $mac ]] && continue
        state=""
        timeout 3 bluetoothctl info "$mac" 2>/dev/null | grep -q 'Connected: yes' && state="  [connected]"
        entry="${name}  (${mac})${state}"
        mac_for[$entry]=$mac
        entries+=("$entry")
    done < <(timeout 3 bluetoothctl devices Paired 2>/dev/null)
fi

choice=$(printf '%s\n' "${entries[@]}" | rofi -dmenu -i -p "Bluetooth")
[[ -z $choice ]] && exit 0

if [[ $choice == "$power_entry" ]]; then
    if [[ $powered == yes ]]; then
        out=$(timeout 5 bluetoothctl power off 2>&1)
        notify "Bluetooth" "Turned off"
    else
        out=$(timeout 5 bluetoothctl power on 2>&1)
        notify "Bluetooth" "Turned on"
    fi
    exit 0
fi

if [[ $choice == "$pair_entry" ]]; then
    notify "Bluetooth" "Scanning for 10 seconds. Put your device in pairing mode."
    declare -A new_for=()
    new_entries=()
    while IFS=$'\t' read -r mac name; do
        [[ -z $mac ]] && continue
        entry="${name}  (${mac})"
        new_for[$entry]=$mac
        new_entries+=("$entry")
    done < <(scan_new)
    if [[ ${#new_entries[@]} -eq 0 ]]; then
        notify "Bluetooth" "No new devices found"
        exit 1
    fi
    picked=$(printf '%s\n' "${new_entries[@]}" | rofi -dmenu -i -p "Pair with")
    [[ -z $picked ]] && exit 0
    mac=${new_for[$picked]}
    name=${picked%%  (*}
    notify "Pairing" "Pairing with $name..."
    if pair_device "$mac"; then
        notify "Paired" "$name is paired and connected"
    else
        notify "Pairing with $name failed" "Check that the device is in pairing mode"
        exit 1
    fi
    exit 0
fi

mac=${mac_for[$choice]}
name=${choice%%  (*}
if [[ $choice == *"[connected]" ]]; then
    out=$(timeout 10 bluetoothctl disconnect "$mac" 2>&1)
    if [[ $out == *"Successful"* ]]; then
        notify "Disconnected" "$name"
    else
        notify "Disconnect from $name failed" "$out"
        exit 1
    fi
else
    out=$(timeout 15 bluetoothctl connect "$mac" 2>&1)
    if [[ $out == *"Connection successful"* ]]; then
        notify "Connected" "$name"
    else
        notify "Connection to $name failed" "$out"
        exit 1
    fi
fi
