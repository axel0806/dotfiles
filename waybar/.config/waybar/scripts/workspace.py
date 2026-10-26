#!/usr/bin/env python3
# Waybar custom module for one Hyprland workspace (continuous exec, JSON lines).
# Waybar's built-in hyprland/workspaces click sends the legacy "workspace N" dispatch,
# which Hyprland 0.56's Lua config rejects, so each workspace gets its own module and
# the on-click uses a Lua dispatch instead.
#
# Usage: workspace.py <id>
# Classes: focused = active workspace on the focused monitor, occupied = has windows,
# empty = no windows.

import json
import os
import socket
import subprocess
import sys

ws = int(sys.argv[1])
runtime = os.environ["XDG_RUNTIME_DIR"]
sig = os.environ["HYPRLAND_INSTANCE_SIGNATURE"]
events_sock = os.path.join(runtime, "hypr", sig, ".socket2.sock")


def hyprctl(*args):
    return json.loads(subprocess.check_output(["hyprctl", "-j", *args]))


def emit():
    active = hyprctl("activeworkspace")["id"]
    occupied = {w["id"] for w in hyprctl("workspaces") if w["windows"] > 0}
    if ws == active:
        cls = "focused"
    elif ws in occupied:
        cls = "occupied"
    else:
        cls = "empty"
    print(json.dumps({"text": str(ws), "class": cls, "tooltip": f"Workspace {ws}"}), flush=True)


emit()

# Hyprland pushes one line per event on socket2; any event may change this workspace's state
with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
    s.connect(events_sock)
    buf = b""
    while True:
        chunk = s.recv(4096)
        if not chunk:
            sys.exit(0)
        buf += chunk
        while b"\n" in buf:
            _, buf = buf.split(b"\n", 1)
            emit()
