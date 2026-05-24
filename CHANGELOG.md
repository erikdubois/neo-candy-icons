# Changelog

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
