#!/usr/bin/env python3
"""Build or-beautyline-garuda: the icons Garuda's BeautyLine fork has that no neo-candy layer has."""
# Erik, 2026-11-07: neo-candy carries these itself, so the ISO no longer needs the beautyline / candy-icons-git
# packages (their own index.theme files showed up as extra themes in XFCE Appearance). Only missing names come in;
# our icons are never replaced. Rebuilt from scratch on every update-upstream.sh run.
import os
import re
import shutil
import sys
from pathlib import Path

LAYERS = ["al-beautyline", "or-beautyline", "al-candy-icons", "or-candy-icons"]
THEME = "or-beautyline-garuda"


def _names(root):
    names = set()
    for layer in LAYERS:
        for _d, _dirs, files in os.walk(root / layer, followlinks=True):
            names.update(f.rsplit(".", 1)[0] for f in files if f.endswith((".svg", ".png")))
    return names


def _sections(index_text):
    """Return {dir: section text} for every [dir] block of a Garuda index.theme."""
    out = {}
    for m in re.finditer(r"^\[([^\]]+)\]\n(.*?)(?=^\[|\Z)", index_text, re.MULTILINE | re.DOTALL):
        # Garuda's index declares [actions/scalable] twice (Actions, then Status): the first one is right
        if m.group(1) != "Icon Theme" and m.group(1) not in out:
            out[m.group(1)] = m.group(2).strip()
    return out


def main():
    """garuda_extras.py <garuda-clone> <usr/share/icons>: write the theme, print what it holds."""
    garuda, root = Path(sys.argv[1]), Path(sys.argv[2])
    index = (garuda / "index.theme").read_text()
    declared = re.search(r"^Directories=(.*)$", index, re.MULTILINE).group(1).split(",")
    ours = _names(root)
    picked = {}
    for d in declared:
        for p in sorted((garuda / d).glob("*")):
            if p.suffix in (".svg", ".png") and " " not in p.name and p.stem not in ours:
                picked[f"{d}/{p.name}"] = p
    out = root / THEME
    shutil.rmtree(out, ignore_errors=True)
    links = files = 0
    for rel, src in picked.items():
        dest = out / rel
        dest.parent.mkdir(parents=True, exist_ok=True)
        if src.is_symlink():
            target = os.path.normpath(os.path.join(os.path.dirname(rel), os.readlink(src)))
            if target in picked:
                dest.symlink_to(os.readlink(src))
                links += 1
                continue
            if not src.exists():
                continue
        shutil.copyfile(src.resolve(), dest)
        files += 1
    used = [d for d in declared if (out / d).is_dir()]
    sections = _sections(index)
    text = (f"[Icon Theme]\nName=or-beautyLine-garuda\nComment=Garuda BeautyLine icons neo-candy has no own copy of\n"
            f"Hidden=true\n\nDirectories={','.join(used)}\n")
    text += "".join(f"\n[{d}]\n{sections[d]}\n" for d in used)
    (out / "index.theme").write_text(text)
    print(f"  {THEME}: {len({Path(r).stem for r in picked})} names, {files} files, {links} links")
    return 0


if __name__ == "__main__":
    sys.exit(main())
