from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
OUTPUT_DIR = ROOT / "game" / "assets" / "class_icons"
LOGICAL_SIZE = 32
EXPORT_SIZE = 128

OUTLINE = (31, 24, 36, 255)
SHADOW = (0, 0, 0, 70)
HILITE = (255, 255, 255, 70)
STEEL = (192, 206, 219, 255)
GOLD = (246, 232, 162, 255)
BROWN = (166, 88, 44, 255)


def new_canvas() -> tuple[Image.Image, ImageDraw.ImageDraw]:
    image = Image.new("RGBA", (LOGICAL_SIZE, LOGICAL_SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    return image, draw


def add_shadow(draw: ImageDraw.ImageDraw) -> None:
    draw.ellipse((5, 24, 27, 29), fill=SHADOW)


def save_icon(image: Image.Image, class_id: str) -> Path:
    class_dir = OUTPUT_DIR / class_id
    class_dir.mkdir(parents=True, exist_ok=True)
    scaled = image.resize((EXPORT_SIZE, EXPORT_SIZE), Image.Resampling.NEAREST)
    out_path = class_dir / "icon.png"
    scaled.save(out_path)
    return out_path


def draw_shield(base: tuple[int, int, int, int], core: tuple[int, int, int, int], crest: tuple[int, int, int, int] = GOLD) -> Image.Image:
    image, draw = new_canvas()
    add_shadow(draw)
    draw.polygon(
        [(16, 3), (24, 6), (24, 15), (22, 22), (16, 27), (10, 22), (8, 15), (8, 6)],
        fill=base,
        outline=OUTLINE,
    )
    draw.polygon(
        [(16, 6), (21, 8), (21, 14), (20, 19), (16, 23), (12, 19), (11, 14), (11, 8)],
        fill=core,
    )
    draw.rectangle((15, 7, 17, 21), fill=crest)
    draw.rectangle((12, 12, 20, 14), fill=crest)
    draw.line((10, 8, 14, 6), fill=HILITE, width=1)
    return image


def draw_crossed_blades(accent: tuple[int, int, int, int], blade: tuple[int, int, int, int] = STEEL) -> Image.Image:
    image, draw = new_canvas()
    add_shadow(draw)
    draw.line((9, 8, 22, 21), fill=OUTLINE, width=5)
    draw.line((22, 8, 9, 21), fill=OUTLINE, width=5)
    draw.line((10, 8, 21, 19), fill=blade, width=3)
    draw.line((21, 8, 10, 19), fill=blade, width=3)
    draw.polygon([(7, 6), (11, 5), (13, 7), (9, 10)], fill=accent, outline=OUTLINE)
    draw.polygon([(25, 6), (21, 5), (19, 7), (23, 10)], fill=accent, outline=OUTLINE)
    draw.polygon([(8, 24), (11, 20), (14, 23), (11, 27)], fill=BROWN, outline=OUTLINE)
    draw.polygon([(24, 24), (21, 20), (18, 23), (21, 27)], fill=BROWN, outline=OUTLINE)
    draw.line((11, 8, 14, 11), fill=HILITE, width=1)
    draw.line((21, 8, 18, 11), fill=HILITE, width=1)
    return image


def draw_staff(orb: tuple[int, int, int, int], shaft: tuple[int, int, int, int], cross: tuple[int, int, int, int] | None = None) -> Image.Image:
    image, draw = new_canvas()
    add_shadow(draw)
    draw.line((16, 6, 16, 24), fill=OUTLINE, width=5)
    draw.line((16, 6, 16, 24), fill=shaft, width=3)
    if cross is not None:
        draw.line((11, 12, 21, 12), fill=OUTLINE, width=5)
        draw.line((11, 12, 21, 12), fill=cross, width=3)
    draw.ellipse((11, 2, 21, 12), fill=orb, outline=OUTLINE)
    draw.ellipse((13, 4, 19, 10), fill=lighten(orb, 70))
    draw.rectangle((13, 19, 19, 24), fill=shaft, outline=OUTLINE)
    draw.line((12, 5, 15, 4), fill=HILITE, width=1)
    return image


def draw_arcane_blades(gem: tuple[int, int, int, int], left: tuple[int, int, int, int], right: tuple[int, int, int, int]) -> Image.Image:
    image, draw = new_canvas()
    add_shadow(draw)
    draw.polygon([(10, 7), (15, 4), (20, 7), (23, 12), (20, 17), (15, 20), (10, 17), (7, 12)],
                 fill=gem, outline=OUTLINE)
    draw.polygon([(15, 7), (19, 10), (15, 13), (11, 10)], fill=GOLD)
    draw.line((8, 21, 14, 15), fill=OUTLINE, width=5)
    draw.line((8, 21, 14, 15), fill=left, width=3)
    draw.line((22, 21, 16, 15), fill=OUTLINE, width=5)
    draw.line((22, 21, 16, 15), fill=right, width=3)
    draw.polygon([(6, 23), (8, 18), (11, 21), (9, 26)], fill=BROWN, outline=OUTLINE)
    draw.polygon([(24, 23), (22, 18), (19, 21), (21, 26)], fill=darken(right, 70), outline=OUTLINE)
    draw.line((9, 8, 13, 6), fill=HILITE, width=1)
    return image


def draw_orb_ring(outer: tuple[int, int, int, int], inner: tuple[int, int, int, int], core: tuple[int, int, int, int], arrows: bool = True) -> Image.Image:
    image, draw = new_canvas()
    add_shadow(draw)
    draw.ellipse((8, 8, 24, 24), fill=outer, outline=OUTLINE)
    draw.ellipse((11, 11, 21, 21), fill=inner, outline=OUTLINE)
    draw.ellipse((13, 13, 19, 19), fill=core)
    draw.line((16, 4, 16, 9), fill=OUTLINE, width=3)
    draw.line((16, 23, 16, 28), fill=OUTLINE, width=3)
    draw.line((4, 16, 9, 16), fill=OUTLINE, width=3)
    draw.line((23, 16, 28, 16), fill=OUTLINE, width=3)
    if arrows:
        for points in (
            [(16, 2), (18, 6), (14, 6)],
            [(30, 16), (26, 18), (26, 14)],
            [(16, 30), (18, 26), (14, 26)],
            [(2, 16), (6, 18), (6, 14)],
        ):
            draw.polygon(points, fill=lighten(outer, 80), outline=OUTLINE)
    draw.arc((5, 5, 27, 27), start=220, end=320, fill=lighten(core, 50), width=1)
    return image


def lighten(color: tuple[int, int, int, int], amount: int) -> tuple[int, int, int, int]:
    return tuple(min(channel + amount, 255) for channel in color[:3]) + (color[3],)


def darken(color: tuple[int, int, int, int], amount: int) -> tuple[int, int, int, int]:
    return tuple(max(channel - amount, 0) for channel in color[:3]) + (color[3],)


def draw_guardian() -> Image.Image:
    image = draw_shield((65, 116, 194, 255), (126, 184, 255, 255))
    draw = ImageDraw.Draw(image)
    draw.rectangle((10, 10, 22, 19), outline=(224, 239, 255, 255))
    return image


def draw_berserker() -> Image.Image:
    image = draw_crossed_blades((214, 56, 60, 255))
    draw = ImageDraw.Draw(image)
    draw.polygon([(16, 4), (18, 9), (16, 8), (14, 13), (13, 10), (15, 7), (13, 4)], fill=GOLD, outline=OUTLINE)
    return image


def draw_paladin() -> Image.Image:
    image = draw_shield((214, 175, 72, 255), (255, 237, 163, 255), crest=(244, 251, 221, 255))
    draw = ImageDraw.Draw(image)
    draw.ellipse((12, 5, 20, 13), outline=(255, 255, 215, 255))
    return image


def draw_assassin() -> Image.Image:
    image, draw = new_canvas()
    add_shadow(draw)
    draw.polygon([(16, 4), (24, 12), (16, 28), (8, 12)], fill=(72, 48, 93, 255), outline=OUTLINE)
    draw.polygon([(16, 7), (21, 12), (16, 23), (11, 12)], fill=(128, 83, 160, 255))
    draw.line((16, 7, 16, 25), fill=(220, 226, 235, 255), width=3)
    draw.polygon([(13, 6), (19, 6), (16, 2)], fill=(218, 56, 76, 255), outline=OUTLINE)
    draw.line((11, 11, 14, 8), fill=HILITE, width=1)
    return image


def draw_ranger() -> Image.Image:
    image, draw = new_canvas()
    add_shadow(draw)
    draw.arc((6, 5, 24, 25), start=285, end=75, fill=OUTLINE, width=5)
    draw.arc((7, 6, 23, 24), start=285, end=75, fill=(114, 202, 114, 255), width=3)
    draw.line((22, 7, 12, 23), fill=OUTLINE, width=3)
    draw.line((21, 8, 13, 22), fill=STEEL, width=1)
    draw.polygon([(11, 24), (13, 19), (16, 23)], fill=(112, 197, 97, 255), outline=OUTLINE)
    draw.line((10, 8, 10, 24), fill=(204, 224, 181, 255), width=1)
    return image


def draw_mage() -> Image.Image:
    image, draw = new_canvas()
    add_shadow(draw)
    draw.polygon([(16, 3), (24, 10), (21, 21), (16, 28), (11, 21), (8, 10)], fill=(118, 88, 216, 255), outline=OUTLINE)
    draw.polygon([(16, 7), (19, 11), (16, 15), (13, 11)], fill=(176, 152, 255, 255))
    draw.line((16, 4, 16, 26), fill=(255, 233, 160, 255), width=2)
    draw.line((8, 16, 24, 16), fill=(255, 233, 160, 255), width=2)
    return image


def draw_samurai() -> Image.Image:
    image, draw = new_canvas()
    add_shadow(draw)
    draw.line((10, 22, 22, 8), fill=OUTLINE, width=5)
    draw.line((10, 22, 22, 8), fill=STEEL, width=3)
    draw.polygon([(19, 5), (25, 9), (21, 11)], fill=(220, 222, 228, 255), outline=OUTLINE)
    draw.rectangle((8, 20, 13, 24), fill=BROWN, outline=OUTLINE)
    draw.arc((6, 9, 18, 21), start=210, end=340, fill=(216, 52, 56, 255), width=2)
    draw.line((14, 14, 18, 10), fill=HILITE, width=1)
    return image


def draw_cleric() -> Image.Image:
    return draw_staff((114, 220, 135, 255), (234, 240, 215, 255), cross=(234, 240, 215, 255))


def draw_bard() -> Image.Image:
    image, draw = new_canvas()
    add_shadow(draw)
    draw.ellipse((8, 8, 18, 18), fill=(239, 206, 96, 255), outline=OUTLINE)
    draw.rectangle((17, 12, 21, 14), fill=(239, 206, 96, 255), outline=OUTLINE)
    draw.line((21, 13, 24, 7), fill=OUTLINE, width=3)
    draw.line((21, 13, 24, 7), fill=(211, 175, 81, 255), width=1)
    draw.line((14, 6, 14, 24), fill=OUTLINE, width=3)
    draw.line((14, 6, 14, 24), fill=(244, 242, 225, 255), width=1)
    draw.arc((10, 4, 18, 12), start=0, end=180, fill=(129, 200, 255, 255), width=1)
    draw.arc((10, 10, 18, 18), start=0, end=180, fill=(150, 227, 154, 255), width=1)
    return image


def draw_alchemist() -> Image.Image:
    image, draw = new_canvas()
    add_shadow(draw)
    draw.polygon([(12, 5), (20, 5), (18, 11), (18, 20), (22, 25), (10, 25), (14, 20), (14, 11)], fill=(112, 204, 120, 255), outline=OUTLINE)
    draw.rectangle((13, 9, 19, 12), fill=(229, 240, 245, 255))
    draw.ellipse((11, 14, 21, 24), fill=(149, 242, 93, 255))
    draw.arc((9, 13, 23, 27), start=200, end=340, fill=(255, 247, 181, 255), width=1)
    return image


def draw_necromancer() -> Image.Image:
    image, draw = new_canvas()
    add_shadow(draw)
    draw.staff = None
    draw.line((11, 24, 18, 6), fill=OUTLINE, width=5)
    draw.line((11, 24, 18, 6), fill=(107, 85, 132, 255), width=3)
    draw.ellipse((12, 2, 22, 12), fill=(104, 72, 126, 255), outline=OUTLINE)
    draw.ellipse((14, 4, 20, 10), fill=(188, 246, 194, 255))
    draw.arc((8, 7, 20, 19), start=210, end=350, fill=(214, 235, 220, 255), width=2)
    draw.arc((15, 7, 27, 19), start=190, end=330, fill=(214, 235, 220, 255), width=2)
    return image


def draw_spellblade() -> Image.Image:
    image, draw = new_canvas()
    add_shadow(draw)
    draw.line((11, 23, 21, 8), fill=OUTLINE, width=5)
    draw.line((11, 23, 21, 8), fill=STEEL, width=3)
    draw.arc((9, 8, 24, 23), start=220, end=40, fill=(108, 217, 238, 255), width=2)
    draw.polygon([(20, 6), (25, 9), (21, 11)], fill=(255, 183, 95, 255), outline=OUTLINE)
    draw.rectangle((10, 21, 14, 25), fill=(125, 82, 212, 255), outline=OUTLINE)
    return image


def draw_shadow_knight() -> Image.Image:
    image, draw = new_canvas()
    add_shadow(draw)
    draw.polygon([(16, 3), (24, 6), (24, 15), (22, 22), (16, 27), (10, 22), (8, 15), (8, 6)],
                 fill=(92, 74, 125, 255), outline=OUTLINE)
    draw.line((11, 23, 21, 8), fill=OUTLINE, width=5)
    draw.line((11, 23, 21, 8), fill=(205, 85, 110, 255), width=3)
    draw.polygon([(12, 11), (20, 11), (16, 17)], fill=(196, 92, 117, 255), outline=OUTLINE)
    return image


def draw_monk() -> Image.Image:
    image, draw = new_canvas()
    add_shadow(draw)
    draw.ellipse((7, 10, 16, 19), fill=(230, 186, 121, 255), outline=OUTLINE)
    draw.ellipse((16, 10, 25, 19), fill=(230, 186, 121, 255), outline=OUTLINE)
    draw.arc((4, 6, 18, 24), start=300, end=70, fill=(216, 90, 64, 255), width=2)
    draw.arc((14, 6, 28, 24), start=110, end=240, fill=(255, 212, 109, 255), width=2)
    draw.rectangle((13, 15, 19, 18), fill=(167, 74, 58, 255), outline=OUTLINE)
    return image


def draw_chronomancer() -> Image.Image:
    image = draw_orb_ring((73, 204, 220, 255), (24, 87, 118, 255), (177, 249, 255, 255), arrows=False)
    draw = ImageDraw.Draw(image)
    draw.line((16, 16, 16, 10), fill=GOLD, width=1)
    draw.line((16, 16, 20, 18), fill=GOLD, width=1)
    for points in (
        [(16, 2), (18, 6), (14, 6)],
        [(30, 16), (26, 18), (26, 14)],
        [(16, 30), (18, 26), (14, 26)],
        [(2, 16), (6, 18), (6, 14)],
    ):
        draw.polygon(points, fill=(180, 246, 255, 255), outline=OUTLINE)
    return image


def draw_warden() -> Image.Image:
    image, draw = new_canvas()
    add_shadow(draw)
    for x in (8, 13, 18, 23):
        draw.rectangle((x, 8, x + 2, 23), fill=(97, 144, 205, 255), outline=OUTLINE)
    draw.arc((7, 5, 25, 25), start=200, end=340, fill=(174, 227, 255, 255), width=2)
    draw.arc((7, 9, 25, 29), start=20, end=160, fill=(174, 227, 255, 255), width=2)
    return image


def draw_hexbinder() -> Image.Image:
    image, draw = new_canvas()
    add_shadow(draw)
    draw.polygon([(16, 4), (25, 10), (21, 23), (11, 23), (7, 10)], fill=(118, 82, 164, 255), outline=OUTLINE)
    draw.line((10, 10, 22, 20), fill=(219, 92, 144, 255), width=2)
    draw.line((22, 10, 10, 20), fill=(219, 92, 144, 255), width=2)
    draw.ellipse((13, 11, 19, 17), fill=(248, 222, 176, 255), outline=OUTLINE)
    return image


def draw_stormcaller() -> Image.Image:
    image, draw = new_canvas()
    add_shadow(draw)
    draw.polygon([(17, 4), (12, 14), (18, 14), (13, 27), (24, 15), (18, 15), (23, 4)],
                 fill=(103, 214, 228, 255), outline=OUTLINE)
    draw.arc((6, 9, 17, 24), start=260, end=70, fill=(189, 244, 255, 255), width=2)
    draw.arc((15, 9, 26, 24), start=110, end=280, fill=(189, 244, 255, 255), width=2)
    return image


def build_icons() -> dict[str, Image.Image]:
    return {
        "tank": draw_shield((72, 137, 209, 255), (128, 196, 255, 255)),
        "guardian": draw_guardian(),
        "berserker": draw_berserker(),
        "paladin": draw_paladin(),
        "dps": draw_crossed_blades((227, 72, 72, 255)),
        "assassin": draw_assassin(),
        "ranger": draw_ranger(),
        "mage": draw_mage(),
        "samurai": draw_samurai(),
        "support": draw_staff((112, 220, 135, 255), (238, 242, 214, 255), cross=(238, 242, 214, 255)),
        "cleric": draw_cleric(),
        "bard": draw_bard(),
        "alchemist": draw_alchemist(),
        "necromancer": draw_necromancer(),
        "hybrid": draw_arcane_blades((133, 85, 211, 255), (195, 206, 226, 255), (109, 232, 170, 255)),
        "spellblade": draw_spellblade(),
        "shadow_knight": draw_shadow_knight(),
        "monk": draw_monk(),
        "controller": draw_orb_ring((72, 202, 220, 255), (23, 78, 111, 255), (171, 249, 255, 255)),
        "chronomancer": draw_chronomancer(),
        "warden": draw_warden(),
        "hexbinder": draw_hexbinder(),
        "stormcaller": draw_stormcaller(),
    }


def main() -> None:
    for class_id, image in build_icons().items():
        out_path = save_icon(image, class_id)
        print(f"generated {out_path}")


if __name__ == "__main__":
    main()
