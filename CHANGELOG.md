# Changelog

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
