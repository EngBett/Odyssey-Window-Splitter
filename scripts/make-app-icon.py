#!/usr/bin/env python3
"""Generate the AppIcon PNG set for OdysseyWindowSplitter.

The icon is a rounded slate panel carrying the app's signature 25/50/25 split.
Rendered analytically from signed distance fields so it stays crisp at 16 pt,
and written with nothing but the standard library — no Pillow, no toolchain.

Usage: scripts/make-app-icon.py [output-appiconset-directory]
"""

from __future__ import annotations

import os
import struct
import sys
import zlib

MASTER = 1024

# Background gradient, top to bottom.
TOP = (0x4A, 0x6F, 0xA5)
BOTTOM = (0x1E, 0x2A, 0x40)
BAR = (0xF5, 0xF8, 0xFC)

# macOS draws app icons inside a rounded square whose radius is ~22.37% of the
# canvas; matching it keeps the icon from looking wrong next to system icons.
CORNER = 0.2237 * MASTER

# The 25/50/25 panel.
PANEL = (148.0, 288.0, 876.0, 736.0)  # left, top, right, bottom
PANEL_GAP = 28.0
PANEL_RADIUS = 26.0

# (filename, pixel size) for every slot in the Contents.json below.
SIZES = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024),
]

CONTENTS_JSON = """{
  "images" : [
    {
      "filename" : "icon_16x16.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "16x16"
    },
    {
      "filename" : "icon_16x16@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "16x16"
    },
    {
      "filename" : "icon_32x32.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "32x32"
    },
    {
      "filename" : "icon_32x32@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "32x32"
    },
    {
      "filename" : "icon_128x128.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "128x128"
    },
    {
      "filename" : "icon_128x128@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "128x128"
    },
    {
      "filename" : "icon_256x256.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "256x256"
    },
    {
      "filename" : "icon_256x256@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "256x256"
    },
    {
      "filename" : "icon_512x512.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "512x512"
    },
    {
      "filename" : "icon_512x512@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "512x512"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
"""


def rounded_rect_sdf(px: float, py: float, rect, radius: float) -> float:
    """Signed distance from (px, py) to a rounded rectangle. Negative = inside."""
    left, top, right, bottom = rect
    cx, cy = (left + right) / 2.0, (top + bottom) / 2.0
    hx, hy = (right - left) / 2.0 - radius, (bottom - top) / 2.0 - radius
    qx, qy = abs(px - cx) - hx, abs(py - cy) - hy
    outside = ((max(qx, 0.0) ** 2 + max(qy, 0.0) ** 2) ** 0.5)
    return outside + min(max(qx, qy), 0.0) - radius


def coverage(distance: float) -> float:
    """One-pixel-wide analytic antialiasing band around the shape's edge."""
    return min(max(0.5 - distance, 0.0), 1.0)


def bar_rects():
    """The three columns of a 25/50/25 split across the panel."""
    left, top, right, bottom = PANEL
    inner = (right - left) - 2 * PANEL_GAP
    quarter, half = inner * 0.25, inner * 0.5
    x = left
    out = []
    for width in (quarter, half, quarter):
        out.append((x, top, x + width, bottom))
        x += width + PANEL_GAP
    return out


def render(size: int) -> bytes:
    """Render the icon at `size` px square as raw RGBA rows."""
    scale = size / MASTER
    bars = [tuple(v * scale for v in r) for r in bar_rects()]
    bar_radius = PANEL_RADIUS * scale
    corner = CORNER * scale
    canvas = (0.0, 0.0, float(size), float(size))

    rows = bytearray()
    for y in range(size):
        py = y + 0.5
        # Vertical gradient, evaluated once per row.
        t = py / size
        bg = tuple(round(TOP[i] + (BOTTOM[i] - TOP[i]) * t) for i in range(3))
        rows.append(0)  # PNG filter type: none
        for x in range(size):
            px = x + 0.5
            alpha = coverage(rounded_rect_sdf(px, py, canvas, corner))
            if alpha <= 0.0:
                rows.extend((0, 0, 0, 0))
                continue
            r, g, b = bg
            for rect in bars:
                ink = coverage(rounded_rect_sdf(px, py, rect, bar_radius))
                if ink > 0.0:
                    r = round(r + (BAR[0] - r) * ink)
                    g = round(g + (BAR[1] - g) * ink)
                    b = round(b + (BAR[2] - b) * ink)
                    break
            rows.extend((r, g, b, round(alpha * 255)))
    return bytes(rows)


def write_png(path: str, size: int, raw: bytes) -> None:
    def chunk(tag: bytes, payload: bytes) -> bytes:
        return (
            struct.pack(">I", len(payload))
            + tag
            + payload
            + struct.pack(">I", zlib.crc32(tag + payload) & 0xFFFFFFFF)
        )

    header = struct.pack(">IIBBBBB", size, size, 8, 6, 0, 0, 0)
    png = (
        b"\x89PNG\r\n\x1a\n"
        + chunk(b"IHDR", header)
        + chunk(b"IDAT", zlib.compress(raw, 9))
        + chunk(b"IEND", b"")
    )
    with open(path, "wb") as handle:
        handle.write(png)


def main() -> int:
    default = os.path.join(
        os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
        "OdysseyWindowSplitter/Resources/Assets.xcassets/AppIcon.appiconset",
    )
    out_dir = sys.argv[1] if len(sys.argv) > 1 else default
    os.makedirs(out_dir, exist_ok=True)

    # Render each distinct pixel size once; @1x and @2x slots that share a size
    # share the render.
    cache: dict[int, bytes] = {}
    for filename, size in SIZES:
        if size not in cache:
            cache[size] = render(size)
        write_png(os.path.join(out_dir, filename), size, cache[size])
        print(f"  {filename} ({size}x{size})")

    with open(os.path.join(out_dir, "Contents.json"), "w") as handle:
        handle.write(CONTENTS_JSON)
    print(f"Wrote {len(SIZES)} icons to {out_dir}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
