#!/usr/bin/env python3
"""Fastfetch with a tumbling 3D Arch logo. Usage: spin.py [seconds]  (0 = forever, Ctrl-C to stop)"""
import math, subprocess, sys, time

DEPTH = 1.5         # half-thickness of the extrusion, in columns
SPEED = 1.0         # tumble speed multiplier
LOGO_NAME = "arch_small"  # "arch" for the full-size logo

LOGO = subprocess.run(["fastfetch", "-c", "none", "-l", LOGO_NAME, "--pipe", "true", "-s", "none"],
                      capture_output=True, text=True).stdout.rstrip("\n").splitlines()
H = len(LOGO)
W = max(len(l) for l in LOGO)
LOGO = [l.ljust(W) for l in LOGO]
CW = int(math.hypot(W, 2 * H)) + 2      # canvas wide enough for any orientation
CH = CW // 2 + 1
# dark crimson -> ember -> dusk gold, matching the wallpaper
RAMP = [(70, 12, 22), (110, 20, 30), (156, 30, 40), (200, 46, 50),
        (226, 70, 56), (240, 112, 60), (244, 158, 72), (232, 200, 108)]

def filled(r, c):
    return 0 <= r < H and 0 <= c < W and LOGO[r][c] != " "

# object-space sample points: (x, y, z, char, kind) with y in column units (cells are 2x taller)
# kind: 1 = front face, -1 = back face, 0 = side wall
PTS = []
for r in range(H):
    for c in range(W):
        if not filled(r, c): continue
        ch = LOGO[r][c]
        edge = not all(filled(r + dr, c + dc) for dr, dc in ((1, 0), (-1, 0), (0, 1), (0, -1)))
        for sx in (0.25, 0.75):
            for sy in (0.125, 0.375, 0.625, 0.875):
                x, y = c + sx - W / 2, (r + sy - H / 2) * 2
                PTS.append((x, y, DEPTH, ch, 1))
                PTS.append((x, y, -DEPTH, ch, -1))
                if edge:
                    for z in (-DEPTH / 2, 0, DEPTH / 2):
                        PTS.append((x, y, z, ch, 0))

def mul(a, b):
    return [[sum(a[i][k] * b[k][j] for k in range(3)) for j in range(3)] for i in range(3)]

def rot(w, dt):
    """Rotation matrix for angular velocity vector w held for dt (Rodrigues)."""
    ang = math.sqrt(sum(v * v for v in w)) * dt
    if ang < 1e-9: return [[1, 0, 0], [0, 1, 0], [0, 0, 1]]
    ux, uy, uz = (v / math.sqrt(sum(q * q for q in w)) for v in w)
    c, s, t = math.cos(ang), math.sin(ang), 1 - math.cos(ang)
    return [[t*ux*ux + c, t*ux*uy - s*uz, t*ux*uz + s*uy],
            [t*ux*uy + s*uz, t*uy*uy + c, t*uy*uz - s*ux],
            [t*ux*uz - s*uy, t*uy*uz + s*ux, t*uz*uz + c]]

def render(R):
    zbuf = {}
    (a, b, c), (d, e, f), (g, h, i) = R
    for x, y, z, ch, kind in PTS:
        sz = g * x + h * y + i * z
        col = int(round(a * x + b * y + c * z + CW / 2))
        row = int(round((d * x + e * y + f * z) / 2 + CH / 2))
        k = (row, col)
        old = zbuf.get(k)
        if old is None or sz > old[0]:
            zbuf[k] = (sz, ch, kind)
    nz = i  # screen-z of the +z face normal
    lines = []
    for row in range(CH):
        out, last = "", None
        for col in range(CW):
            p = zbuf.get((row, col))
            if p is None:
                out += " "; continue
            _, ch, kind = p
            facing = nz * kind
            br = 0.3 if kind == 0 else 0.3 + 0.7 * max(0.0, facing)
            code = RAMP[min(len(RAMP) - 1, int(br * len(RAMP)))]
            if code != last: out += "\x1b[38;2;%d;%d;%dm" % code; last = code
            out += ch
        lines.append(out + "\x1b[0m")
    return lines

def draw(logo, info, n):
    frame = f"\x1b[{n}A"
    for r in range(n):
        l = logo[r] if r < len(logo) else " " * CW
        frame += "\r" + l + " " + (info[r] if r < len(info) else "") + "\x1b[K\n"
    sys.stdout.write(frame); sys.stdout.flush()

info = subprocess.run(["fastfetch", "--logo", "none", "--pipe", "false"], capture_output=True, text=True).stdout.splitlines()
n = max(len(info), CH)
dur = float(sys.argv[1]) if len(sys.argv) > 1 else 0
IDENT = [[1, 0, 0], [0, 1, 0], [0, 0, 1]]
R = IDENT
sys.stdout.write("\n" * n + "\x1b[?25l")
t0 = last = time.time()
try:
    while True:
        now = time.time()
        el, dt = now - t0, now - last
        last = now
        if dur and el > dur: break
        # angular velocity wanders so the axis of rotation keeps changing
        w = (2.2 * math.sin(0.61 * el), 2.2 * math.sin(0.43 * el + 2), 2.2 * math.sin(0.29 * el + 4))
        w = tuple(v * SPEED + 0.6 for v in w)
        R = mul(rot(w, dt), R)
        draw(render(R), info, n)
        time.sleep(0.01)
except KeyboardInterrupt:
    pass
ox, oy = (CW - W) // 2, (CH - H) // 2
rest = [" " * CW] * CH
for r in range(H):
    rest[oy + r] = " " * ox + "\x1b[38;2;226;70;56m" + LOGO[r] + "\x1b[0m"
draw(rest, info, n)
sys.stdout.write("\x1b[?25h")
