#!/usr/bin/env python3
"""Larp mode: jump to an empty mango tag and open floating terminals at
random spots, picking the random layout with the least overlap.

The programs and their window sizes come from ../larp.json (edited from the
island's larp settings). In a command, `{track}` becomes a random file from
~/Music/larp (the program is skipped if there is none) and `~` is expanded."""

import json
import os
import random
import shlex
import subprocess
import sys
import time

CONFIG = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "larp.json")
MUSIC_DIR = os.path.expanduser("~/Music/larp")
AUDIO = (".mp3", ".flac", ".ogg", ".opus", ".wav", ".m4a", ".aac")


def random_track():
    try:
        tracks = [f for f in os.listdir(MUSIC_DIR) if f.lower().endswith(AUDIO)]
    except FileNotFoundError:
        return None
    return os.path.join(MUSIC_DIR, random.choice(tracks)) if tracks else None


def load_programs():
    """[(kitty class, argv, min (cols, rows), max (cols, rows))]; a size
    dimension of None means unconstrained."""
    try:
        with open(CONFIG) as f:
            entries = json.load(f).get("programs", [])
    except (OSError, ValueError) as e:
        sys.exit(f"larp: can't read {CONFIG}: {e}")
    track = random_track()
    programs = []
    for i, entry in enumerate(entries):
        argv = [os.path.expanduser(a) for a in shlex.split(entry.get("command", ""))]
        if not argv:
            continue
        if "{track}" in argv:
            if not track:
                continue
            argv = [track if a == "{track}" else a for a in argv]
        size = lambda key: tuple(entry.get(key) or (None, None))
        programs.append((f"larp-{i}", argv, size("min"), size("max")))
    return programs


TOP = 60  # bar height + margins, matches where mango tiles windows
GAP = 10
TRIES = 4000
# kitty cell size in px (JetBrainsMono at the current font size) and the
# extra px a window adds around the text area; measured, update if the font changes
CELL = (9, 20)
CHROME = (12, 8)


def cells_to_px(cells):
    return tuple(None if c is None else c * size + extra for c, size, extra in zip(cells, CELL, CHROME))


def size_range(lo, hi, min_px, max_px):
    """Clamp the random [lo, hi] size range to a window's min/max."""
    if min_px is not None:
        lo, hi = max(lo, min_px), max(hi, min_px)
    if max_px is not None:
        lo, hi = min(lo, max_px), min(hi, max_px)
    return lo, hi


def mmsg(*args):
    out = subprocess.run(["mmsg", *args], capture_output=True, text=True).stdout
    return json.loads(out) if out.strip() else {}


def dispatch(cmd, client=None):
    args = ["mmsg", "dispatch", cmd]
    if client is not None:
        args.append(f"client,{client}")
    subprocess.run(args, capture_output=True)


def overlap(a, b):
    w = min(a[0] + a[2], b[0] + b[2]) - max(a[0], b[0])
    h = min(a[1] + a[3], b[1] + b[3]) - max(a[1], b[1])
    return max(0, w) * max(0, h)


def layout(area, programs):
    """Random window rects; keep the set with the least total overlap."""
    ax, ay, aw, ah = area
    ranges = []
    for _, _, min_cells, max_cells in programs:
        min_px = cells_to_px(min_cells)
        max_px = cells_to_px(max_cells)
        ranges.append((
            size_range(int(aw * 0.36), int(aw * 0.46), min_px[0], max_px[0]),
            size_range(int(ah * 0.38), int(ah * 0.46), min_px[1], max_px[1]),
        ))
    best, best_cost = None, None
    for _ in range(TRIES):
        rects = []
        for (wlo, whi), (hlo, hhi) in ranges:
            w = min(aw, random.randint(wlo, whi))
            h = min(ah, random.randint(hlo, hhi))
            rects.append((ax + random.randint(0, aw - w), ay + random.randint(0, ah - h), w, h))
        cost = sum(overlap(a, b) for i, a in enumerate(rects) for b in rects[i + 1:])
        if best_cost is None or cost < best_cost:
            best, best_cost = rects, cost
            if cost == 0:
                break
    return best


def main():
    programs = load_programs()
    if not programs:
        subprocess.run(["notify-send", "Larp", "No programs configured"])
        return

    monitor = next((m for m in mmsg("get", "all-monitors").get("monitors", []) if m["active"]), None)
    if monitor is None:
        sys.exit("larp: no focused monitor")

    tags = monitor["tags"]
    empty = [t for t in tags if t["client_count"] == 0]
    if not empty:
        subprocess.run(["notify-send", "Larp", "No empty workspace left"])
        return
    # stay put if the current tag is already empty
    tag = next((t for t in empty if t["is_active"]), empty[0])["index"]
    dispatch(f"view,{tag},0")

    area = (monitor["x"] + GAP, monitor["y"] + TOP, monitor["width"] - 2 * GAP, monitor["height"] - TOP - GAP)
    rects = dict(zip((p[0] for p in programs), layout(area, programs)))

    for cls, argv, _, _ in programs:
        subprocess.Popen(
            ["kitty", "--class", cls, "-o", "confirm_os_window_close=0", *argv],
            stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
            start_new_session=True,
        )

    # Wait for the windows to map, then float and place each one
    placed = set()
    deadline = time.time() + 10
    while len(placed) < len(programs) and time.time() < deadline:
        for c in mmsg("get", "all-clients").get("clients", []):
            cls = c["appid"]
            if cls not in rects or c["id"] in placed:
                continue
            place(c["id"], c["is_floating"], rects[cls])
            placed.add(c["id"])
        time.sleep(0.1)


def place(client, floating, rect):
    tx, ty, tw, th = rect
    if not floating:
        dispatch("togglefloating", client)
        time.sleep(0.1)
    # mango: signed values (+10,-5) are relative, unsigned ones absolute
    for _ in range(2):
        c = mmsg("get", "client", str(client))
        if not c:
            return
        if (c["width"], c["height"]) != (tw, th):
            dispatch(f"resizewin,{tw - c['width']:+d},{th - c['height']:+d}", client)
        dispatch(f"movewin,{tx},{ty}", client)
        time.sleep(0.05)


if __name__ == "__main__":
    main()
