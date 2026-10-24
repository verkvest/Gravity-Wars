#!/usr/bin/env python3
"""Draw the Cindarc app icon and write the iOS and Android sizes."""

from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
IOS = ROOT / "mobile" / "icons" / "ios"
ANDROID = ROOT / "mobile" / "icons" / "android"

BG = (14, 18, 32)
PLANET = (18, 92, 102)
PLANET_DARK = (10, 46, 54)
RIM = (242, 193, 78)
ARC = (232, 106, 58)
SHIP = (244, 241, 232)
MOON = (214, 223, 232)


def draw_icon(size: int) -> Image.Image:
    image = Image.new("RGB", (size, size), BG)
    draw = ImageDraw.Draw(image)
    s = size / 1024.0

    def xy(x, y):
        return x * s, y * s

    # Soft vignette.
    draw.ellipse([*xy(80, 40), *xy(980, 980)], fill=(18, 28, 48))

    # Moon.
    draw.ellipse([*xy(640, 150), *xy(860, 370)], fill=MOON)
    draw.ellipse([*xy(700, 130), *xy(930, 360)], fill=BG)
    draw.ellipse([*xy(690, 210), *xy(760, 280)], outline=PLANET_DARK, width=max(2, int(8 * s)))

    # Planet.
    draw.ellipse([*xy(210, 390), *xy(690, 870)], fill=PLANET_DARK)
    draw.ellipse([*xy(240, 420), *xy(660, 840)], fill=PLANET)
    draw.ellipse([*xy(240, 420), *xy(660, 840)], outline=RIM, width=max(3, int(22 * s)))
    draw.ellipse([*xy(330, 500), *xy(430, 600)], outline=RIM, width=max(2, int(8 * s)))

    # Shot arc.
    draw.arc([*xy(120, 180), *xy(900, 960)], start=286, end=348, fill=ARC, width=max(4, int(30 * s)))
    draw.ellipse([*xy(742, 214), *xy(812, 284)], fill=SHIP)

    # Ship triangle near the start of the arc.
    nose = xy(250, 250)
    left = xy(168, 318)
    right = xy(292, 348)
    draw.polygon([nose, left, right], fill=SHIP)
    return image


def save_ios(master: Image.Image) -> None:
    IOS.mkdir(parents=True, exist_ok=True)
    sizes = {
        "icon-1024pt@1x.png": 1024,
        "icon-83.5pt@2x.png": 167,
        "icon-76pt@2x.png": 152,
        "icon-76pt@1x.png": 76,
        "icon-60pt@3x.png": 180,
        "icon-60pt@2x.png": 120,
        "icon-40pt@3x.png": 120,
        "icon-40pt@2x.png": 80,
        "icon-40pt@1x.png": 40,
        "icon-29pt@3x.png": 87,
        "icon-29pt@2x.png": 58,
        "icon-29pt@1x.png": 29,
    }
    for name, size in sizes.items():
        image = master if size == 1024 else master.resize((size, size), Image.Resampling.LANCZOS)
        image.save(IOS / name, "PNG")


def save_android(master: Image.Image) -> None:
    densities = {
        "drawable-ldpi": 36,
        "drawable-mdpi": 48,
        "drawable-hdpi": 72,
        "drawable-xhdpi": 96,
        "drawable-xxhdpi": 144,
        "drawable-xxxhdpi": 192,
    }
    for folder, size in densities.items():
        path = ANDROID / folder
        path.mkdir(parents=True, exist_ok=True)
        master.resize((size, size), Image.Resampling.LANCZOS).save(path / "love.png", "PNG")
    play = ROOT / "mobile" / "icons" / "play-store-512.png"
    master.resize((512, 512), Image.Resampling.LANCZOS).save(play, "PNG")


def main() -> None:
    master = draw_icon(1024)
    assert master.mode == "RGB"
    save_ios(master)
    save_android(master)
    print(f"wrote icons under {ROOT / 'mobile' / 'icons'}")


if __name__ == "__main__":
    main()
