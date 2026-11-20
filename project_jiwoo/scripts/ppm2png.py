#!/usr/bin/env python3
"""Convert the pictures written by sim/tb_screen.v into PNG and build one HTML report.

Usage:  python scripts/ppm2png.py [folder] [prefix]
          folder : default "result"
          prefix : "shot" (default, tb_screen) or "demo" (tb_demo)

Input : <folder>/<prefix>_NN.ppm   (text PPM, P3, 4-bit colours 0..15)
        <folder>/screen_log.txt  (prefix shot)  or  <folder>/demo_log.txt  (prefix demo)
Output: <folder>/<prefix>_NN.png
        <folder>/report.html  or  demo_report.html   (every picture with its log block)
Only the Python standard library is used.
"""
import glob
import html
import os
import re
import struct
import sys
import zlib


def read_ppm(path):
    with open(path, "r") as f:
        tok = f.read().split()
    assert tok[0] == "P3", "not a P3 file"
    w, h, mx = int(tok[1]), int(tok[2]), int(tok[3])
    vals = tok[4:4 + w * h * 3]
    scale = 255 // mx
    raw = bytearray()
    i = 0
    for _y in range(h):
        raw.append(0)                       # PNG filter type 0 for each row
        for _x in range(w * 3):
            raw.append(int(vals[i]) * scale)
            i += 1
    return w, h, bytes(raw)


def write_png(path, w, h, raw):
    def chunk(tag, data):
        c = struct.pack(">I", len(data)) + tag + data
        return c + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)

    png = b"\x89PNG\r\n\x1a\n"
    png += chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 2, 0, 0, 0))
    png += chunk(b"IDAT", zlib.compress(raw, 9))
    png += chunk(b"IEND", b"")
    with open(path, "wb") as f:
        f.write(png)


def read_log_blocks(path):
    blocks = {}
    if not os.path.exists(path):
        return blocks, ""
    text = open(path, "r", errors="replace").read().replace("\x00", "")
    summary = ""
    parts = re.split(r"(?m)^=== ", text)
    for p in parts[1:]:
        if p.startswith("SHOT"):
            m = re.match(r"SHOT (\d+)", p)
            blocks[int(m.group(1))] = "=== " + p.rstrip()
        elif p.startswith("SUMMARY"):
            summary = "=== " + p.rstrip()
    return blocks, summary


def main():
    folder = sys.argv[1] if len(sys.argv) > 1 else "result"
    prefix = sys.argv[2] if len(sys.argv) > 2 else "shot"      # "shot" = tb_screen, "demo" = tb_demo
    log_name = "screen_log.txt" if prefix == "shot" else prefix + "_log.txt"
    report_name = "report.html" if prefix == "shot" else prefix + "_report.html"
    files = sorted(glob.glob(os.path.join(folder, prefix + "_*.ppm")))
    blocks, summary = read_log_blocks(os.path.join(folder, log_name))
    if not files and not blocks:
        print("nothing found in", folder)
        return 1

    out = ["<!DOCTYPE html><html><head><meta charset='utf-8'>",
           "<title>Black-box Circuit Detective - simulation report</title>",
           "<style>body{font-family:sans-serif;background:#222;color:#ddd;margin:20px}"
           "h2{margin-top:36px}pre{background:#111;padding:10px;overflow:auto;font-size:13px}"
           "img{border:1px solid #666;image-rendering:pixelated;max-width:100%}</style>",
           "</head><body><h1>Black-box Circuit Detective - simulation report</h1>"]

    done = set()
    for f in files:
        n = int(re.search(prefix + r"_(\d+)", os.path.basename(f)).group(1))
        w, h, raw = read_ppm(f)
        png = f[:-4] + ".png"
        write_png(png, w, h, raw)
        print("wrote", png)
        done.add(n)
        out.append("<h2>Shot %d</h2><img src='%s' width='%d' height='%d'>" %
                   (n, html.escape(os.path.basename(png)), w, h))
        out.append("<pre>%s</pre>" % html.escape(blocks.get(n, "(no log block)")))
    for n in sorted(set(blocks) - done):         # log-only shots (SAVE_FRAMES=0)
        out.append("<h2>Shot %d (no picture)</h2><pre>%s</pre>" % (n, html.escape(blocks[n])))
    if summary:
        out.append("<h2>Summary</h2><pre>%s</pre>" % html.escape(summary))
    out.append("</body></html>")

    rep = os.path.join(folder, report_name)
    with open(rep, "w", encoding="utf-8") as f:
        f.write("\n".join(out))
    print("wrote", rep)
    return 0


if __name__ == "__main__":
    sys.exit(main())
