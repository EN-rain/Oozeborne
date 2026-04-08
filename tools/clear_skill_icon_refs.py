from __future__ import annotations

import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SKILL_ROOT = ROOT / "game" / "resources" / "skills"


def clear_icon_refs(path: Path) -> None:
    text = path.read_text(encoding="utf-8")
    lines = text.splitlines()
    filtered_lines: list[str] = []

    for line in lines:
        if 'type="Texture2D"' in line and 'id="2_skillicon"' in line:
            continue
        if line.startswith("icon = "):
            continue
        filtered_lines.append(line)

    updated = "\n".join(filtered_lines)
    if text.endswith("\n"):
        updated += "\n"

    updated = re.sub(r"load_steps=(\d+)", "load_steps=2", updated, count=1)
    path.write_text(updated, encoding="utf-8")


def main() -> None:
    for path in sorted(SKILL_ROOT.rglob("*.tres")):
        clear_icon_refs(path)
        print(f"cleared {path.name}")


if __name__ == "__main__":
    main()
