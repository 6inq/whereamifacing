"""Draws resources/arrow.png: a white, north-pointing arrow with a dark outline.

White so the plugin can tint it to any colour; the outline stays dark after tinting,
which keeps the arrow readable on any background. Supersampled for smooth edges.
"""
import pathlib

from PIL import Image, ImageDraw

SIZE, SCALE = 64, 8
OUT = pathlib.Path(__file__).resolve().parent.parent / "resources" / "arrow.png"

# Arrow polygon in 64x64 space, tip at the top.
POINTS = [(32, 4), (58, 34), (42, 34), (42, 60), (22, 60), (22, 34), (6, 34)]


def main():
    big = SIZE * SCALE
    image = Image.new("RGBA", (big, big), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    scaled = [(x * SCALE, y * SCALE) for x, y in POINTS]
    draw.polygon(scaled, fill=(255, 255, 255, 255), outline=(20, 20, 20, 255), width=3 * SCALE)
    OUT.parent.mkdir(parents=True, exist_ok=True)
    image.resize((SIZE, SIZE), Image.LANCZOS).save(OUT)
    print(f"wrote {OUT}")


if __name__ == "__main__":
    main()
