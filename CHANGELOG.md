# Changelog

## 2026.07.07 — Trash back to colourful candy (green empty / red full)

### What Changed

Reverted the Surfn grey recycle-bin trash (added 2026.06.27) back to the
original colourful candy trash: **green empty** (`user-trash`) and **red/pink
full** (`user-trash-full`). Erik preferred the colourful glyph over the
stand-out grey bin. Only the trash icons were reverted — the deliberate PNG
folder set from that same commit is untouched.

### Technical Details

- Restored the pre-`9fcc3b8` trash `.svg` family (real files + symlink aliases) in `al-beautyline/places/{16,48}` via `git checkout 9fcc3b8^ -- …`, and `git rm`'d the grey `*trash*.png` set that had replaced them so the SVG wins the lookup cleanly (no same-dir PNG/SVG precedence ambiguity).
- Gradients: empty `#00B59C → #9CFFAC` (green), full `#FD3A84 → #FFA68D` (red/pink). `neo-candy-icons/places` is a symlink to `al-beautyline/places`, so every inheriting variant gets the colourful trash again.
- Pre-existing quirk restored faithfully: the red *full* real glyph exists only at 16px; 48px full-state aliases flatten to the green base. The sidebar renders at 16px, so the visible icon is red-full-capable.
- 33 SVGs restored, 47 PNGs removed. `check-icons.sh` passes clean on all five themes.

### Files Modified

- `usr/share/icons/al-beautyline/places/16/*trash*` (png → svg, both states)
- `usr/share/icons/al-beautyline/places/48/*trash*` (png → svg, both states)

## 2026.06.27 — Base home stays colourful (white house moved to papirus)

### What Changed

Briefly experimented with replacing the base `places` home with Surfn's white
house, then **reverted** it: the default `neo-candy-icons` (and the colourful
variants) must keep their colourful home. The white house is wanted only on the
**neo-candy-papirus** variants, where the colourful base home clashed with grey
folders — so it now ships from those variants instead (see `make-papirus-colour`),
not from the base.

### Technical Details

- Reverted all home aliases in `al-beautyline/places/{16,48}` to the colourful original (`git checkout 396a708 -- …`). `neo-candy-icons/places` is a symlink to `al-beautyline/places`, so the default theme is colourful again.
- White home for papirus is injected by `~/.bin/make-papirus-colour` for the `neo-candy` base only (surfn papirus keeps its base home).

### Files Modified

- `usr/share/icons/al-beautyline/places/{16,48}/*home*.svg` (reverted to colourful)

## 2026.06.27 — Surfn recycle bin as base trash icon

### What Changed

Replaced the green line-style trash icons in the shared base `places` set with
Surfn's grey recycle-bin glyph (`user-trash` / `user-trash-full`), so every
neo-candy variant inheriting the base shows it. The trash is deliberately allowed
to stand out from the theme's folder colour — it should be quick to spot.

### Technical Details

- Source: Surfn `places/16/user-trash.png` + `user-trash-full.png` for the `16` dir, `places/48/...` for the `48` dir. PNG (not the Surfn SVG, which was rejected). Both base dirs are `Type=Scalable`, so 16px is pixel-crisp in the sidebar (the only place Trash renders) and 48 covers larger sizes.
- Empty-state aliases ← `user-trash.png`: edittrash, emptytrash, gnome-dev-trash-empty, gnome-fs-trash-empty(-accept), gnome-stock-trash(-empty), stock_trash_empty, trashcan_empty, trash-empty, user-trash, xfce-trash_empty.
- Full-state aliases ← `user-trash-full.png`: gnome-dev-trash-full, gnome-fs-trash-full, gnome-stock-trash-full, stock_trash_full, trashcan_full(-new), trash-full, user-trash-full, xfce-trash_full.
- Old `.svg` raster aliases deleted (PNG wins the lookup). The `*-symbolic` entries were symlinks to those deleted SVGs, so they were repointed to the PNGs as `.png` symlinks (and the 48px full-symbolic, which had pointed at the *empty* icon, was fixed to point at full).
- Removed a stray `places/48/.ruff_cache/` dir that should not ship.

### Files Modified

- `usr/share/icons/al-beautyline/places/16/*trash*` (svg → png, both states)
- `usr/share/icons/al-beautyline/places/48/*trash*` (svg → png, both states)

## 2026.06.26 — Candy-style Shelly icon

### What Changed

Replaced the imported Shelly brand "S" logo (`shelly.svg` and `shelly-tray.svg`)
with a hand-drawn **candy-style venus/scallop shell** that matches the rest of
the theme — rounded outline glyph, candy gradient, 48-unit canvas. The previous
brand logo was an Inkscape 24×24 import that clashed with the line-icon look.

### Technical Details

- Single stroked `<path>` (silhouette + 5 radiating ribs from the hinge),
  `stroke-width="4"`, round caps/joins — matches the dominant outline style.
- 3-stop linear gradient violet `rgb(124,0,255)` → magenta `rgb(245,32,250)`
  → warm orange `rgb(255,150,40)`, run top-to-bottom for clear contrast.
- `viewBox="0 0 48 48"`, output size set to `width="64" height="64"`.

### Files Modified

- usr/share/icons/al-candy-icons/apps/scalable/shelly.svg
- usr/share/icons/al-candy-icons/apps/scalable/shelly-tray.svg

## 2026.06.23 — README install commands

### What Changed

**Install docs:** the README install section now lists the meta packages (top-level `*-icons-meta`, plus the group meta where applicable) alongside the per-variant `*-icons-git` package — replacing the outdated single `pacman -S` line.

### Files Modified

- README.md

## 2026.06.21 — Add check-icons.sh pre-publish validator

### What Changed

Added [check-icons.sh](./check-icons.sh), a pre-publish validator for every
icon theme in a repo, and wired it into [up.sh](./up.sh) so a broken theme can
never be pushed. It consolidates and broadens every risk the older ad-hoc
helpers (`fix-icon-cache.sh`, `icons-checker.sh`, `*cache*.sh`) checked for, so
users never hit an error or a wall of missing icons on install.

Layout-agnostic and reusable across every icon-theme repo (the whole surfn
family): it locates themes by finding `index.theme` anywhere under the repo,
so it works whether themes live in `usr/share/icons/`, `icons/`, `surfn-icons/`
or the repo root. Run it in place, or against any repo: `./check-icons.sh /path`.
Smoke-tested across 30 surfn/neo repos — 23 clean, 7 correctly flagged for
genuine relative broken symlinks and stale committed `icon-theme.cache` files.

Checks performed (ERROR blocks the push, WARN is reported):
- index.theme present, has `[Icon Theme]` + `Name=`, Unix line endings (ERROR)
- every `Directories=`/`ScaledDirectories=` path exists on disk (ERROR); real
  context folders not declared in index.theme (WARN)
- `gtk-update-icon-cache` builds cleanly per theme (ERROR)
- relative broken symlinks (ERROR); unresolved absolute symlinks (WARN)
- file/dir names containing spaces — the `(copy)`/`(1)` bug (ERROR)
- a stale `icon-theme.cache` committed into the tree (ERROR)
- hidden files/dirs and editor/OS junk (WARN); non-world-readable perms (WARN)
- index.theme/disk directory mismatches, both directions (WARN — gtk tolerates
  over-declaration, verified on surfn-plasma-flow, so it must not block)
- Skips themes under git-ignored paths (e.g. a `_src/` build snapshot) so
  scaffolding that never ships is not validated as if it were a theme.

### Technical Details

- `gtk-update-icon-cache` has no dry-run mode and writes `icon-theme.cache`
  next to the theme, so the validator runs it against a throwaway `cp -a` copy
  in `mktemp -d` with `--index-only --force`, reads the exit status, and deletes
  the temp dir — the source tree is never touched.
- Broken-symlink detection only fails (ERROR) when the resolved target stays
  **inside the theme's own directory** and is missing — genuinely broken in the
  package and safe to remove. Symlinks whose target **escapes the theme** (via
  `../` into a sibling theme, or an absolute `/usr/share/icons/...` path) are
  WARN only: icon themes legitimately link across packages (meta-theme pattern,
  e.g. neo-candy into al-beautyline) and those resolve only once everything is
  installed together. This prevents the validator from ever flagging — or
  recommending deletion of — a working cross-theme link.
- Script intentionally uses `set -uo pipefail` (not `-e`): it accumulates all
  findings and returns its own exit code, rather than aborting on the first
  non-matching `find`/`grep`.
- Follows the canonical Kiro script template (header, colors, log_* helpers,
  on_error trap, main).

### Files Modified

- `check-icons.sh` (new)
- `up.sh` — runs `check-icons.sh` before commit/push; aborts on validation error

## 2026.06.20 — README: correct folder count for manual install

### What Changed

The manual-install section told users to "move the 3 folders" of
`/usr/share/icons`, but the repo ships **5** icon-theme folders. Corrected the
count and named them explicitly so a manual install copies everything the
`neo-candy-icons` meta-theme depends on. Also fixed the step numbering in the
same block (it skipped from `2.` to `4.`).

### Technical Details

- `neo-candy-icons` is a meta-theme: its `actions/apps/devices/mimetypes/panel/places/status`
  subdirs are symlinks into `al-beautyline`, and the rest resolves through its
  `Inherits=` chain (al-beautyline, or-beautyline, al-candy-icons, or-candy-icons,
  …). A manual install therefore needs all 5 folders present, not 3.

### Files Modified

- README.md

## 2026.05.24 — fix-icons: self-locating path (drop dead absolute dev path)

### What Changed

The `al-beautyline/fix-icons` maintenance script (run after a copy/paste during
theme work to prune unwanted SVGs) was hardcoded to a long-dead ArcoLinux dev
path (`/home/erik/ARCO/ARCOLINUX/a-candy-beauty-icon-theme-dev/...`). Made it
self-locating so it operates on whatever copy of the theme it lives in. Found
during an ecosystem-wide hardcoded-`/home/erik` sweep across EDU/KIRO.

### Technical Details

- `usr/share/icons/al-beautyline/fix-icons` line 3: absolute path →
  `path="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"`. Downstream
  `rm $path/...` lines unchanged; no `set -e`, so it still skips
  already-removed files as designed.

### Files Modified

- usr/share/icons/al-beautyline/fix-icons

## 2026.05.21

### What Changed
- Initial markdown scaffold added per the ecosystem MD-scaffold rule ([HQ/CLAUDE.md](/home/erik/Insync/Kiro/Kiro-HQ/CLAUDE.md#required-markdown-scaffold-every-repo)).
- Stubs created for `CHANGELOG.md`, `CLAUDE.md`, `IDEAS.md`, `TODO.md` (whichever were missing).
- README rewritten with real install/usage content (replaced earlier one-line stub) where applicable.

### Files Modified
- CHANGELOG.md (created)
- CLAUDE.md (created where missing)
- IDEAS.md (created where missing)
- TODO.md (created where missing)
- README.md (rewritten where it was a stub)
