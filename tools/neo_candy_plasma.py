#!/usr/bin/env python3
"""Make al-beautyline's panel and tray icons follow the Plasma colour scheme and fix icons QtSvg draws wrong."""
# Idempotent: update-upstream.sh runs it after every upstream sync. Fixes live in al-* only, because or-* is
# overwritten by the sync. Recolour logic ported from ~/EDU/surpa/build_surpa.py.
import argparse
import base64
import re
import subprocess
import sys
import tempfile
from pathlib import Path

# The greys and whites neo-candy's tray glyphs are drawn in; accents (red mute marks, orange warnings) stay
NEUTRAL = {"#ececec", "#fefefe", "#fdfdfd", "#fff", "#ffffff", "#e4e4e4", "#dedede", "#dfdfdf", "#eeeeee",
           "#aaa", "#aaaaaa", "#888", "#888888", "#808080", "#464646", "#353535", "#000", "#000000"}
HEX = r"#[0-9a-fA-F]{3,6}"
SCHEME_STYLE = '<style type="text/css" id="current-color-scheme">.ColorScheme-Text { color:{c}; }</style>'
HOOK_DIRS = ["al-beautyline/status/16", "al-beautyline/status/22", "al-beautyline/panel/16", "al-beautyline/panel/22"]
# Erik (2026-11-07): quit / lock / hibernate / logout and the rest of the session and power family stay exactly as
# drawn. A match on any name, symlink or real file, protects the real file behind it.
PROTECT = re.compile(r"shutdown|power-?off|reboot|restart|suspend|hibernat|sleep|log-?out|logoff|(^|-)exit($|-)"
                     r"|(^|-)quit($|-)|switch-?user|user-switch|session|xfsm|lock-?screen|screen-?lock"
                     r"|^(un)?lock$|^object-(un)?locked$|^changes-(prevent|allow)$")


# Tray glyphs Erik wants candy-coloured like their tray neighbours instead of following the colour scheme
# (2026-11-07, ramp B "Cochiti Lake"): sound and Variety
CANDY_NAMES = re.compile(r"^(audio-volume-|variety-indicator)")
CANDY_RAMP = ["#0072FF", "#00C6FF"]
CANDY_EXTRA = ["al-beautyline/apps/scalable"]


def protected_files(root):
    """Return the real files that a session/power icon name resolves to inside the hook dirs."""
    out = set()
    for d in HOOK_DIRS:
        for p in (root / d).glob("*.svg"):
            if PROTECT.search(p.stem):
                out.add(p.resolve())
    return out

# QtSvg ignores <clipPath> and drops filtered groups (see kde-gtk-icon-recolour-rules)
FLATTEN = ["al-beautyline/mimetypes/scalable/application-executable.svg"]
STRIP_WRAPPERS = ["al-beautyline/apps/scalable/purism-chatty.svg"]
FLAT_MARK = "<!-- neo-candy: flattened for QtSvg -->"


def _lightness(c):
    c = c.lstrip("#")
    if len(c) == 3:
        c = "".join(ch * 2 for ch in c)
    r, g, b = (int(c[i:i + 2], 16) for i in (0, 2, 4))
    return (max(r, g, b) + min(r, g, b)) / 2


def _paint_colours(svg):
    # Inkscape leaves a color: attribute on paths that is not paint; judge only fill/stroke/stop-color
    cols = set()
    for c in re.findall(r"(?:fill|stroke|stop-color)\s*[=:]\s*[\"']?(" + HEX + ")", svg):
        c = c.lower()
        cols.add("#" + "".join(ch * 2 for ch in c[1:]) if len(c) == 4 else c)
    return cols


def _neutral_swatches(svg):
    grads = {}
    for m in re.finditer(r"<(linearGradient|radialGradient)\b([^>]*?)(?:/>|>(.*?)</\1>)", svg, re.DOTALL):
        gid = re.search(r"\bid=[\"']([^\"']+)", m.group(2))
        if gid:
            href = re.search(r"href=[\"']#([^\"']+)", m.group(2))
            cols = {c.lower() for c in re.findall(r"stop-color[:=][\"']?\s*(" + HEX + ")", m.group(3) or "")}
            grads[gid.group(1)] = (href.group(1) if href else None, cols)
    result = {}
    for gid in grads:
        seen, cur = set(), gid
        while cur in grads and not grads[cur][1] and grads[cur][0] and cur not in seen:
            seen.add(cur)
            cur = grads[cur][0]
        cols = grads.get(cur, (None, set()))[1]
        if len(cols) == 1 and next(iter(cols)) in NEUTRAL:
            result[gid] = next(iter(cols))
    return result


def skip_reason(svg):
    """Return why an icon must keep its drawn colours, or None when it can follow the theme."""
    if re.search(r"ColorScheme-Text|currentColor", svg):
        return "hooked"
    cols = _paint_colours(svg)
    neutral = cols & NEUTRAL
    if not neutral:
        return "colour"
    if len(neutral) > 1:
        # white on light grey (package-available-locked): one theme colour would erase the detail
        return "two-tone"
    light = [_lightness(c) for c in neutral]
    if cols - NEUTRAL and min(light) >= 0xF8:
        # pure white beside an accent is lettering on a coloured badge: theme text colour would erase it on dark
        return "badge"
    return None


def recolour(svg):
    """Return the SVG with its neutral paint following ColorScheme-Text, original colour kept as GTK fallback."""
    swatches = _neutral_swatches(svg)
    replaced = []

    def paint(colour):
        c = colour.strip()
        orig = swatches.get(c[5:-1]) if c.startswith("url(#") else (c.lower() if c.lower() in NEUTRAL else None)
        if orig:
            replaced.append(orig)
        return orig is not None

    def element(m):
        el = m.group(0)
        if el.startswith(("<stop", "<linearGradient", "<radialGradient")):
            return el
        val = HEX + r"|url\(#[^)]+\)"
        new = re.sub(r"\s(fill|stroke)=([\"'])(" + val + r")\2",
                     lambda a: f" {a.group(1)}={a.group(2)}currentColor{a.group(2)}" if paint(a.group(3)) else a.group(0),
                     el)
        new = re.sub(r"(?<![-\w])(fill|stroke):\s*(" + val + ")",
                     lambda a: f"{a.group(1)}:currentColor" if paint(a.group(2)) else a.group(0), new)
        if new == el:
            return el
        # a leftover color on the element would pin currentColor to that fixed grey
        new = re.sub(r"\scolor=([\"'])" + HEX + r"\1", "", new)
        new = re.sub(r"(?<![-\w])color:\s*" + HEX + ";?", "", new)
        if re.search(r"\sclass=[\"']", new):
            return re.sub(r"class=([\"'])(.*?)\1", r"class=\1\2 ColorScheme-Text\1", new, count=1)
        return re.sub(r"^<([\w:]+)", r'<\1 class="ColorScheme-Text"', new)

    out = re.sub(r"<(?!svg\b|/|\?|!|style\b)[a-zA-Z][^>]*>", element, svg)
    if not replaced:
        return svg, False
    # children inherit currentColor but resolve it against their own leftover color (renamed-vlc): strip them all;
    # before the hook nothing used currentColor, so color never painted anything
    out = re.sub(r"\scolor=([\"'])" + HEX + r"\1", "", out)
    out = re.sub(r"(?<![-\w])color:\s*" + HEX + ";?", "", out)
    fallback = max(set(replaced), key=replaced.count)
    out = re.sub(r"(<svg\b[^>]*>)", lambda m: m.group(1) + "\n" + SCHEME_STYLE.replace("{c}", fallback), out, count=1)
    return out, True


def flatten(path):
    """Replace an SVG with one embedded 256 px rsvg render (the original is raster art behind a clipPath)."""
    with tempfile.NamedTemporaryFile(suffix=".png") as tmp:
        subprocess.run(["rsvg-convert", "-w", "256", "-h", "256", str(path), "-o", tmp.name], check=True)
        data = base64.b64encode(Path(tmp.name).read_bytes()).decode()
    return ('<?xml version="1.0" encoding="UTF-8"?>\n' + FLAT_MARK + "\n"
            '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" '
            'width="64" height="64" viewBox="0 0 64 64">\n'
            f'<image width="64" height="64" xlink:href="data:image/png;base64,{data}"/>\n</svg>\n')


def strip_wrappers(svg):
    """Drop filter and clip-path attributes (drop shadows and full-canvas clips QtSvg mis-draws)."""
    return re.sub(r'\s(?:filter|clip-path)="url\(#[^)]+\)"', "", svg)


def candy(svg, stops):
    """Return the SVG with its neutral (or theme-hooked) paint replaced by a diagonal candy gradient."""
    grad = ('<linearGradient id="nc-candy" x1="0" y1="0" x2="1" y2="1">'
            + "".join(f'<stop offset="{i / (len(stops) - 1):g}" stop-color="{c}"/>' for i, c in enumerate(stops))
            + "</linearGradient>")
    swatches = _neutral_swatches(svg)

    def paint(c):
        c = c.strip()
        if c == "currentColor" or c.lower() in NEUTRAL or (c.startswith("url(#") and c[5:-1] in swatches):
            return "url(#nc-candy)"
        return c

    out = re.sub(r'<style[^>]*id="current-color-scheme".*?</style>\s*', "", svg, flags=re.DOTALL)
    out = re.sub(r"\s(fill|stroke)=([\"'])(" + HEX + r"|currentColor|url\(#[^)]+\))\2",
                 lambda a: f" {a.group(1)}={a.group(2)}{paint(a.group(3))}{a.group(2)}", out)
    out = re.sub(r"(?<![-\w])(fill|stroke):\s*(" + HEX + r"|currentColor|url\(#[^)]+\))",
                 lambda a: f"{a.group(1)}:{paint(a.group(2))}", out)
    out = re.sub(r"\s?ColorScheme-Text", "", out)
    out = re.sub(r'\sclass=""', "", out)
    return re.sub(r"(<svg\b[^>]*>)", lambda m: m.group(1) + "\n<defs>" + grad + "</defs>", out, count=1)


def fix_fake_links(root, dry_run):
    """Turn .svg files that only hold a link target (a symlink copied as text) back into real relative symlinks."""
    fixed = 0
    for theme in ("al-beautyline", "al-candy-icons"):
        for p in (root / theme).rglob("*.svg"):
            if p.is_symlink() or p.stat().st_size > 200:
                continue
            text = p.read_text(errors="ignore").strip()
            # Plasma loads these as empty SVGs: KDE Connect's tray icon showed blank (2026-11-07)
            if "<" in text or not text.endswith(".svg") or not (p.parent / text).exists():
                continue
            fixed += 1
            if not dry_run:
                p.unlink()
                p.symlink_to(text)
    return fixed


def main():
    """Apply the Plasma hook and the QtSvg fixes under an icons root."""
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("root", type=Path, help="usr/share/icons of the repo")
    ap.add_argument("--dry-run", action="store_true", help="report only, write nothing")
    ap.add_argument("--list", action="store_true", help="print each file with its decision")
    args = ap.parse_args()

    counts = {"fake-link": fix_fake_links(args.root, args.dry_run)}
    keep = protected_files(args.root)
    for d in HOOK_DIRS + CANDY_EXTRA:
        for p in sorted((args.root / d).glob("*.svg")):
            if p.is_symlink() or not CANDY_NAMES.search(p.stem) or p.resolve() in keep:
                continue
            svg = p.read_text(errors="ignore")
            if 'id="nc-candy"' in svg:
                continue
            counts["candy"] = counts.get("candy", 0) + 1
            if not args.dry_run:
                p.write_text(candy(svg, CANDY_RAMP))
    targets = [p for d in HOOK_DIRS for p in sorted((args.root / d).glob("*.svg"))]
    for p in targets:
        if p.is_symlink():
            continue
        svg = p.read_text(errors="ignore")
        reason = "protected" if p.resolve() in keep else skip_reason(svg)
        if reason is None:
            new, changed = recolour(svg)
            reason = "hook" if changed else "no-paint"
            if changed and not args.dry_run:
                p.write_text(new)
        counts[reason] = counts.get(reason, 0) + 1
        if args.list:
            print(f"{reason}\t{p.relative_to(args.root)}")

    for rel in FLATTEN:
        p = args.root / rel
        if p.exists() and FLAT_MARK not in p.read_text(errors="ignore"):
            counts["flatten"] = counts.get("flatten", 0) + 1
            if not args.dry_run:
                p.write_text(flatten(p))
    for rel in STRIP_WRAPPERS:
        p = args.root / rel
        if p.exists():
            svg = p.read_text(errors="ignore")
            new = strip_wrappers(svg)
            if new != svg:
                counts["strip"] = counts.get("strip", 0) + 1
                if not args.dry_run:
                    p.write_text(new)

    print(" ".join(f"{k}={v}" for k, v in sorted(counts.items())))
    return 0


if __name__ == "__main__":
    sys.exit(main())
