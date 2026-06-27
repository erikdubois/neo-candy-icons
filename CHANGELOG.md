# Changelog

## 2026.06.27 — Surfn house as base home icon

### What Changed

Replaced every non-symbolic **home** alias in the shared base `places` set with
Surfn's solid house glyph (`go-home.svg`). `neo-candy-icons/places` is a symlink
to `al-beautyline/places`, so this single change re-skins the home icon for every
neo-candy variant that inherits the base (papirus-*, etc.). Variants that ship
their own home icon (tela, numix, vertexed, vimix) are unaffected — by design,
since the coherent ones already match their folder colour.

### Technical Details

- Source: `Surfn/actions/16/go-home.svg` for the `16` dir, `Surfn/actions/scalable/go-home.svg` for the `48` dir (both vector).
- Aliases overwritten in `al-beautyline/places/16`: default-user-home, folder-home, folder_home, gnome-fs-home, gnome-home, go-home, go-home-large, gohome, gtg-home, gtk-home, home, kfm_home, redhat-home, stock_home, user-home, user-home-open.
- Aliases overwritten in `al-beautyline/places/48`: folder-home, folder_home, gnome-fs-home, gnome-home, user-home.
- Left untouched: `*-symbolic` variants (monochrome contexts) and `akonadi-phone-home` (not a home-folder icon). `16@2x`/`16@3x` are symlinks to `16`, so covered automatically.

### Files Modified

- `usr/share/icons/al-beautyline/places/16/*home*.svg` (16 aliases)
- `usr/share/icons/al-beautyline/places/48/*home*.svg` (5 aliases)

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
