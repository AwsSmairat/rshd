#!/usr/bin/env python3
"""Prepare RSHD launcher icon assets from the approved logo source."""

from __future__ import annotations

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SOURCE = Path(
    "/Users/dollar/.cursor/projects/Users-dollar-Dev-rshd/assets/"
    "Generated_image_1__8_-0da480e8-ac7b-447c-93f2-0430499d273b.png"
)
OUT_DIR = ROOT / "assets" / "icons"
CANVAS = 1024
BG = (255, 255, 255, 255)
# Adaptive icon safe zone ≈ 66% diameter; keep logo inside for circle/squircle masks.
ADAPTIVE_SCALE = 0.66
# Legacy / iOS icon: slightly larger for small-size legibility.
LAUNCHER_SCALE = 0.78


def trim_white(image: Image.Image, tolerance: int = 12) -> Image.Image:
    rgba = image.convert("RGBA")
    pixels = rgba.load()
    width, height = rgba.size

    def is_background(r: int, g: int, b: int, a: int) -> bool:
        if a < 16:
            return True
        return r >= 255 - tolerance and g >= 255 - tolerance and b >= 255 - tolerance

    top = height
    left = width
    bottom = 0
    right = 0

    for y in range(height):
        for x in range(width):
            if not is_background(*pixels[x, y]):
                top = min(top, y)
                left = min(left, x)
                bottom = max(bottom, y)
                right = max(right, x)

    if bottom <= top or right <= left:
        return rgba

    return rgba.crop((left, top, right + 1, bottom + 1))


def fit_on_canvas(
    logo: Image.Image,
    canvas_size: int,
    scale: float,
    background: tuple[int, int, int, int] | None,
) -> Image.Image:
    max_side = int(canvas_size * scale)
    fitted = logo.copy()
    fitted.thumbnail((max_side, max_side), Image.Resampling.LANCZOS)

    if background is None:
        canvas = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
    else:
        canvas = Image.new("RGBA", (canvas_size, canvas_size), background)

    x = (canvas_size - fitted.width) // 2
    y = (canvas_size - fitted.height) // 2
    canvas.paste(fitted, (x, y), fitted if fitted.mode == "RGBA" else None)
    return canvas


def main() -> None:
    if not SOURCE.exists():
        raise SystemExit(f"Missing source logo: {SOURCE}")

    OUT_DIR.mkdir(parents=True, exist_ok=True)

    source = Image.open(SOURCE)
    trimmed = trim_white(source)

    master = fit_on_canvas(trimmed, CANVAS, LAUNCHER_SCALE, BG).convert("RGB")
    foreground = fit_on_canvas(trimmed, CANVAS, ADAPTIVE_SCALE, None)

    master_path = OUT_DIR / "app_icon.png"
    foreground_path = OUT_DIR / "app_icon_foreground.png"
    source_copy_path = OUT_DIR / "app_icon_source.png"

    master.save(master_path, format="PNG", optimize=True)
    foreground.save(foreground_path, format="PNG", optimize=True)
    master.save(source_copy_path, format="PNG", optimize=True)

    print(f"Wrote {master_path} ({master.size[0]}x{master.size[1]})")
    print(f"Wrote {foreground_path} ({foreground.size[0]}x{foreground.size[1]})")
    print(f"Trimmed logo bounds: {trimmed.size[0]}x{trimmed.size[1]}")


if __name__ == "__main__":
    main()
