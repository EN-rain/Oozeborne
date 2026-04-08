from __future__ import annotations

import re
from dataclasses import dataclass
from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
SKILL_ROOT = ROOT / "game" / "resources" / "skills"
ICON_ROOT = ROOT / "game" / "assets" / "class_icons"
LOGICAL_SIZE = 64
EXPORT_SIZE = 128

OUTLINE = (27, 22, 32, 255)
PANEL = (20, 22, 30, 235)
WHITE = (245, 247, 250, 255)
GOLD = (247, 214, 114, 255)
SILVER = (196, 208, 224, 255)
GREEN = (115, 222, 129, 255)
PURPLE = (146, 106, 222, 255)
CYAN = (92, 212, 228, 255)
RED = (229, 88, 83, 255)

CLASS_COLORS = {
    "tank": ((84, 142, 214, 255), (143, 198, 255, 255)),
    "guardian": ((75, 128, 209, 255), (166, 209, 255, 255)),
    "berserker": ((194, 58, 67, 255), (242, 133, 98, 255)),
    "paladin": ((212, 176, 78, 255), (255, 235, 171, 255)),
    "dps": ((212, 63, 73, 255), (248, 120, 103, 255)),
    "assassin": ((101, 68, 137, 255), (183, 107, 205, 255)),
    "ranger": ((81, 172, 93, 255), (154, 227, 124, 255)),
    "mage": ((119, 93, 218, 255), (171, 140, 255, 255)),
    "samurai": ((195, 80, 59, 255), (243, 158, 95, 255)),
    "support": ((80, 184, 108, 255), (171, 240, 181, 255)),
    "cleric": ((118, 214, 132, 255), (229, 245, 212, 255)),
    "bard": ((222, 185, 87, 255), (255, 231, 138, 255)),
    "alchemist": ((104, 179, 103, 255), (173, 245, 120, 255)),
    "necromancer": ((103, 82, 132, 255), (183, 147, 216, 255)),
    "hybrid": ((124, 88, 205, 255), (113, 227, 182, 255)),
    "spellblade": ((114, 95, 224, 255), (104, 214, 229, 255)),
    "shadow_knight": ((90, 72, 127, 255), (201, 91, 116, 255)),
    "monk": ((198, 100, 78, 255), (255, 205, 104, 255)),
    "controller": ((73, 193, 212, 255), (165, 242, 250, 255)),
    "chronomancer": ((83, 200, 219, 255), (175, 248, 255, 255)),
    "warden": ((88, 140, 205, 255), (178, 228, 255, 255)),
    "hexbinder": ((127, 85, 177, 255), (230, 108, 147, 255)),
    "stormcaller": ((73, 199, 221, 255), (198, 245, 255, 255)),
}

TYPE_BADGES = {
    "ability": ("A", (96, 182, 255, 255)),
    "passive": ("P", (117, 218, 135, 255)),
    "stat": ("S", (228, 190, 96, 255)),
    "special": ("X", (208, 118, 255, 255)),
}

KEYWORD_MOTIFS = [
    ({"shield", "wall", "bastion", "ward", "guard", "fortify", "aegis", "bulwark"}, "shield"),
    ({"slash", "strike", "blade", "sword", "iaijutsu", "rend", "stab", "smash", "parry", "flurry"}, "blade"),
    ({"heal", "holy", "blessing", "aid", "aura", "revitalize", "resurrection", "sanctify", "light"}, "cross"),
    ({"poison", "plague", "acid", "toxic", "flask", "brew", "transmutation"}, "flask"),
    ({"shadow", "dark", "death", "grave", "soul", "void", "hex", "curse", "shroud"}, "skull"),
    ({"storm", "lightning", "shock", "thunder", "surge", "chain", "static", "tempest"}, "bolt"),
    ({"time", "tempo", "rewind", "borrowed", "freeze", "fracture", "slow"}, "clock"),
    ({"trap", "mark", "hawk", "arrow", "volley", "hunter"}, "arrow"),
    ({"song", "hymn", "rhythm", "symphony", "bardic", "melody"}, "note"),
    ({"chi", "flow", "discipline", "seven", "pressure", "wind", "monk"}, "fist"),
    ({"meteor", "arcane", "mana", "frost", "elemental", "spell"}, "star"),
    ({"blood", "rage", "frenzy", "war", "adrenaline"}, "burst"),
    ({"command", "control", "field", "ring", "entrapment", "line"}, "ring"),
]


@dataclass
class SkillMeta:
    path: Path
    skill_id: str
    display_name: str
    skill_type: str
    class_id: str


@dataclass
class SkillStyle:
    base: tuple[int, int, int, int]
    accent: tuple[int, int, int, int]
    motif: str
    secondary_motif: str
    pattern: str
    variant: int


def parse_skill_meta(path: Path) -> SkillMeta:
    text = path.read_text(encoding="utf-8")
    skill_id = read_prop(text, "skill_id")
    display_name = read_prop(text, "display_name")
    suffix = skill_id.split("_")[-1]
    class_id = path.parent.name
    if class_id == "main":
        class_id = path.parent.parent.name
    return SkillMeta(path=path, skill_id=skill_id, display_name=display_name, skill_type=suffix, class_id=class_id)


def read_prop(text: str, key: str) -> str:
    match = re.search(rf'^{key} = "(.*)"$', text, re.MULTILINE)
    if not match:
        raise ValueError(f"Missing {key}")
    return match.group(1)


def slug_tokens(meta: SkillMeta) -> list[str]:
    return meta.skill_id.split("_")[2:-1]


def pick_motif(meta: SkillMeta) -> str:
    tokens = set(slug_tokens(meta))
    name_tokens = set(re.sub(r"[^a-z0-9]+", " ", meta.display_name.lower()).split())
    full = tokens | name_tokens
    for keys, motif in KEYWORD_MOTIFS:
        if full & keys:
            return motif
    return {
        "ability": "blade",
        "passive": "ring",
        "stat": "gem",
        "special": "star",
    }[meta.skill_type]


def build_style(meta: SkillMeta) -> SkillStyle:
    base, accent = CLASS_COLORS[meta.class_id]
    if meta.skill_type == "passive":
        accent = lighten(accent, 10)
    elif meta.skill_type == "stat":
        accent = GOLD
    elif meta.skill_type == "special":
        accent = PURPLE if meta.class_id not in {"tank", "guardian", "paladin"} else GOLD

    signature = sum((index + 1) * ord(char) for index, char in enumerate(meta.skill_id))
    accent_shift = ((signature % 23) - 11, ((signature // 3) % 19) - 9, ((signature // 5) % 17) - 8)
    accent = shift_color(accent, accent_shift)
    motif = pick_motif(meta)
    secondary_options = ["ring", "star", "burst", "arrow", "gem", "clock"]
    secondary = secondary_options[(signature // 7) % len(secondary_options)]
    if secondary == motif:
        secondary = secondary_options[(signature // 11) % len(secondary_options)]
    pattern = ["rays", "bands", "grid", "corners"][(signature // 13) % 4]
    return SkillStyle(
        base=base,
        accent=accent,
        motif=motif,
        secondary_motif=secondary,
        pattern=pattern,
        variant=signature % 4,
    )


def canvas(style: SkillStyle) -> tuple[Image.Image, ImageDraw.ImageDraw]:
    img = Image.new("RGBA", (LOGICAL_SIZE, LOGICAL_SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw.rounded_rectangle((6, 6, 58, 58), radius=14, fill=PANEL, outline=OUTLINE, width=2)
    draw.rounded_rectangle((10, 10, 54, 54), radius=12, fill=darken(style.base, 80), outline=lighten(style.base, 25), width=2)
    draw.pieslice((4, 4, 60, 60), start=215, end=320, fill=(*style.accent[:3], 40))
    draw.arc((10, 10, 54, 54), start=210, end=320, fill=lighten(style.accent, 20), width=2)
    draw_pattern(draw, style)
    return img, draw


def lighten(color: tuple[int, int, int, int], amount: int) -> tuple[int, int, int, int]:
    return tuple(min(c + amount, 255) for c in color[:3]) + (color[3],)


def darken(color: tuple[int, int, int, int], amount: int) -> tuple[int, int, int, int]:
    return tuple(max(c - amount, 0) for c in color[:3]) + (color[3],)


def shift_color(color: tuple[int, int, int, int], delta: tuple[int, int, int]) -> tuple[int, int, int, int]:
    return (
        max(0, min(255, color[0] + delta[0])),
        max(0, min(255, color[1] + delta[1])),
        max(0, min(255, color[2] + delta[2])),
        color[3],
    )


def draw_pattern(draw: ImageDraw.ImageDraw, style: SkillStyle) -> None:
    tint = (*lighten(style.accent, 35)[:3], 55)
    if style.pattern == "rays":
        for offset in range(0, 24, 6):
            draw.line((14 + offset, 14, 34 + offset // 2, 50), fill=tint, width=1)
    elif style.pattern == "bands":
        for y in (18, 25, 32, 39):
            draw.line((14, y, 50, y), fill=tint, width=1)
    elif style.pattern == "grid":
        for x in (18, 28, 38, 48):
            draw.line((x, 14, x, 50), fill=tint, width=1)
        for y in (18, 28, 38, 48):
            draw.line((14, y, 50, y), fill=tint, width=1)
    else:
        draw.arc((12, 12, 28, 28), start=180, end=300, fill=tint, width=2)
        draw.arc((36, 12, 52, 28), start=240, end=360, fill=tint, width=2)
        draw.arc((12, 36, 28, 52), start=120, end=240, fill=tint, width=2)
        draw.arc((36, 36, 52, 52), start=0, end=120, fill=tint, width=2)


def draw_badge(draw: ImageDraw.ImageDraw, skill_type: str) -> None:
    glyph, color = TYPE_BADGES[skill_type]
    draw.rounded_rectangle((40, 40, 56, 56), radius=6, fill=color, outline=OUTLINE, width=2)
    # simple pixel-ish glyphs instead of font rendering
    if glyph == "A":
        draw.line((45, 51, 48, 45), fill=OUTLINE, width=2)
        draw.line((48, 45, 51, 51), fill=OUTLINE, width=2)
        draw.line((46, 49, 50, 49), fill=OUTLINE, width=2)
    elif glyph == "P":
        draw.line((46, 45, 46, 52), fill=OUTLINE, width=2)
        draw.line((46, 45, 50, 45), fill=OUTLINE, width=2)
        draw.line((50, 45, 50, 48), fill=OUTLINE, width=2)
        draw.line((46, 48, 50, 48), fill=OUTLINE, width=2)
    elif glyph == "S":
        draw.arc((44, 44, 52, 49), start=20, end=200, fill=OUTLINE, width=2)
        draw.arc((44, 48, 52, 53), start=200, end=20, fill=OUTLINE, width=2)
    else:
        draw.line((45, 45, 51, 51), fill=OUTLINE, width=2)
        draw.line((51, 45, 45, 51), fill=OUTLINE, width=2)


def draw_motif(draw: ImageDraw.ImageDraw, motif: str, base: tuple[int, int, int, int], accent: tuple[int, int, int, int]) -> None:
    if motif == "shield":
        draw.polygon([(32, 14), (44, 18), (44, 31), (40, 40), (32, 46), (24, 40), (20, 31), (20, 18)], fill=accent, outline=OUTLINE)
        draw.line((32, 20, 32, 39), fill=WHITE, width=2)
        draw.line((25, 28, 39, 28), fill=WHITE, width=2)
    elif motif == "blade":
        draw.line((22, 42, 40, 20), fill=OUTLINE, width=6)
        draw.line((22, 42, 40, 20), fill=SILVER, width=3)
        draw.polygon([(39, 17), (46, 22), (40, 24)], fill=WHITE, outline=OUTLINE)
        draw.rectangle((18, 39, 25, 44), fill=BROWNISH(base), outline=OUTLINE)
    elif motif == "cross":
        draw.line((32, 18, 32, 42), fill=OUTLINE, width=6)
        draw.line((32, 18, 32, 42), fill=WHITE, width=3)
        draw.line((22, 28, 42, 28), fill=OUTLINE, width=6)
        draw.line((22, 28, 42, 28), fill=WHITE, width=3)
        draw.ellipse((25, 10, 39, 24), fill=accent, outline=OUTLINE)
    elif motif == "flask":
        draw.polygon([(24, 16), (40, 16), (37, 26), (37, 39), (44, 48), (20, 48), (27, 39), (27, 26)], fill=accent, outline=OUTLINE)
        draw.rectangle((27, 20, 37, 25), fill=WHITE)
        draw.ellipse((23, 30, 41, 46), fill=GREEN)
    elif motif == "skull":
        draw.ellipse((21, 15, 43, 34), fill=accent, outline=OUTLINE)
        draw.rectangle((24, 30, 40, 40), fill=accent, outline=OUTLINE)
        draw.rectangle((26, 23, 29, 27), fill=OUTLINE)
        draw.rectangle((35, 23, 38, 27), fill=OUTLINE)
        draw.polygon([(32, 28), (29, 33), (35, 33)], fill=OUTLINE)
    elif motif == "bolt":
        draw.polygon([(34, 14), (24, 31), (31, 31), (26, 46), (42, 27), (34, 27)], fill=accent, outline=OUTLINE)
        draw.arc((14, 19, 30, 43), start=260, end=70, fill=lighten(accent, 50), width=2)
    elif motif == "clock":
        draw.ellipse((18, 18, 46, 46), fill=accent, outline=OUTLINE)
        draw.ellipse((23, 23, 41, 41), fill=darken(base, 40), outline=OUTLINE)
        draw.line((32, 32, 32, 24), fill=GOLD, width=2)
        draw.line((32, 32, 38, 35), fill=GOLD, width=2)
    elif motif == "arrow":
        draw.line((22, 42, 40, 22), fill=OUTLINE, width=4)
        draw.line((22, 42, 40, 22), fill=SILVER, width=2)
        draw.polygon([(38, 18), (46, 24), (39, 27)], fill=accent, outline=OUTLINE)
        draw.line((18, 18, 18, 43), fill=lighten(accent, 60), width=2)
        draw.arc((16, 15, 32, 43), start=280, end=80, fill=accent, width=2)
    elif motif == "note":
        draw.ellipse((20, 32, 31, 43), fill=accent, outline=OUTLINE)
        draw.ellipse((33, 28, 44, 39), fill=accent, outline=OUTLINE)
        draw.line((31, 18, 31, 38), fill=OUTLINE, width=4)
        draw.line((40, 14, 40, 34), fill=OUTLINE, width=4)
        draw.line((31, 18, 40, 14), fill=OUTLINE, width=4)
        draw.line((31, 18, 40, 14), fill=WHITE, width=1)
    elif motif == "fist":
        draw.rounded_rectangle((20, 21, 43, 40), radius=8, fill=accent, outline=OUTLINE, width=2)
        for x in (22, 28, 34, 40):
            draw.line((x, 18, x, 27), fill=accent, width=4)
            draw.line((x, 18, x, 27), fill=OUTLINE, width=1)
    elif motif == "star":
        draw.polygon([(32, 14), (37, 25), (49, 26), (40, 34), (43, 46), (32, 39), (21, 46), (24, 34), (15, 26), (27, 25)], fill=accent, outline=OUTLINE)
        draw.ellipse((27, 24, 37, 34), fill=lighten(accent, 60))
    elif motif == "burst":
        draw.polygon([(32, 14), (37, 22), (47, 20), (43, 29), (51, 36), (41, 37), (40, 48), (32, 42), (24, 48), (23, 37), (13, 36), (21, 29), (17, 20), (27, 22)], fill=accent, outline=OUTLINE)
    elif motif == "ring":
        draw.ellipse((17, 17, 47, 47), fill=accent, outline=OUTLINE)
        draw.ellipse((24, 24, 40, 40), fill=darken(base, 50), outline=OUTLINE)
        draw.arc((13, 13, 51, 51), start=215, end=335, fill=lighten(accent, 55), width=2)
    else:
        draw.rounded_rectangle((21, 21, 43, 43), radius=6, fill=accent, outline=OUTLINE, width=2)
        draw.ellipse((27, 27, 37, 37), fill=lighten(accent, 55))


def draw_secondary_motif(draw: ImageDraw.ImageDraw, motif: str, accent: tuple[int, int, int, int], variant: int) -> None:
    tint = (*lighten(accent, 35)[:3], 180)
    if motif == "ring":
        draw.ellipse((16 + variant, 16, 48 - variant, 48), outline=tint, width=1)
    elif motif == "star":
        draw.polygon([(32, 19), (35, 27), (43, 28), (37, 33), (39, 41), (32, 36), (25, 41), (27, 33), (21, 28), (29, 27)], outline=tint)
    elif motif == "burst":
        draw.line((20, 20, 44, 44), fill=tint, width=1)
        draw.line((44, 20, 20, 44), fill=tint, width=1)
        draw.line((32, 16, 32, 48), fill=tint, width=1)
    elif motif == "arrow":
        draw.line((20, 42, 42, 22), fill=tint, width=1)
        draw.polygon([(40, 20), (46, 24), (40, 27)], fill=tint)
    elif motif == "clock":
        draw.ellipse((20, 20, 44, 44), outline=tint, width=1)
        draw.line((32, 32, 32, 25), fill=tint, width=1)
        draw.line((32, 32, 38, 34), fill=tint, width=1)
    else:
        draw.rounded_rectangle((25, 25, 39, 39), radius=4, outline=tint, width=1)


def BROWNISH(base: tuple[int, int, int, int]) -> tuple[int, int, int, int]:
    if base[0] > base[2]:
        return (139, 81, 52, 255)
    return (120, 86, 57, 255)


def build_icon(meta: SkillMeta) -> Image.Image:
    style = build_style(meta)
    img, draw = canvas(style)
    draw_secondary_motif(draw, style.secondary_motif, style.accent, style.variant)
    draw_motif(draw, style.motif, style.base, style.accent)
    draw_badge(draw, meta.skill_type)
    return img.resize((EXPORT_SIZE, EXPORT_SIZE), Image.Resampling.NEAREST)


def icon_output_path(meta: SkillMeta) -> Path:
    class_dir = ICON_ROOT / meta.class_id
    class_dir.mkdir(parents=True, exist_ok=True)
    return class_dir / f"{meta.skill_id}.png"


def update_tres_icon(meta: SkillMeta, icon_path: Path) -> None:
    rel = icon_path.relative_to(ROOT / "game").as_posix()
    res_path = f"res://{rel}"
    text = meta.path.read_text(encoding="utf-8")

    if 'id="2_skillicon"' not in text:
        text = text.replace(
            '[ext_resource type="Script" path="res://scripts/resources/skill_definition.gd" id="1_skilldef"]',
            '[ext_resource type="Script" path="res://scripts/resources/skill_definition.gd" id="1_skilldef"]\n'
            f'[ext_resource type="Texture2D" path="{res_path}" id="2_skillicon"]',
        )

    text = re.sub(r"load_steps=(\d+)", lambda m: f'load_steps={max(int(m.group(1)), 3)}', text, count=1)

    if re.search(r"^icon = ExtResource\\(\"2_skillicon\"\\)$", text, re.MULTILINE):
        pass
    elif re.search(r"^icon = .*?$", text, re.MULTILINE):
        text = re.sub(r"^icon = .*?$", 'icon = ExtResource("2_skillicon")', text, flags=re.MULTILINE)
    else:
        if not text.endswith("\n"):
            text += "\n"
        text += 'icon = ExtResource("2_skillicon")\n'

    meta.path.write_text(text, encoding="utf-8")


def main() -> None:
    skill_paths = sorted(SKILL_ROOT.rglob("*.tres"))
    for path in skill_paths:
        meta = parse_skill_meta(path)
        icon_path = icon_output_path(meta)
        build_icon(meta).save(icon_path)
        update_tres_icon(meta, icon_path)
        print(f"generated {meta.skill_id}")


if __name__ == "__main__":
    main()
