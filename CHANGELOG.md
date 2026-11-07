# Changelog

## 2026.11.07 — Upstream check script, Candy fallback fixed

### What Changed

- New `update-upstream.sh` does the 6-monthly upstream check in one run. It fetches Candy icons (GitHub master) and BeautyLine (Pling, the original by sajjad606), compares them with `or-candy-icons` / `or-beautyline`, syncs those copies, re-applies our fixes, validates, records the versions, and pushes to GitHub after a y/N prompt. `--check` only reports.
- Garuda's BeautyLine fork is fetched for a report only and is never merged. It has diverged from the original and drops 430 icons we use. Users with the `beautyline` package still get its icons through `Inherits=BeautyLine`.
- Check result today: BeautyLine unchanged (Pling V2.4, last changed 2024-08-09); Candy has 25 new app/preferences icons.
- `neo-candy-icons` inherited `candyicons`, a theme that does not exist, so the installed Candy theme was never used as a fallback. It now inherits `candy-icons`.
- Plasma: the white and grey status icons in the tray (network, Bluetooth and the like) now follow the colour scheme. Before, they vanished on a light Plasma panel. XFCE and other GTK desktops show them exactly as before (checked pixel by pixel).
- Sound tray icons are now candy-coloured (blue to cyan) in Plasma, like their colourful tray neighbours. In XFCE the sound icon is now neo-candy's own white speaker; before, it was upstream Candy's thin outline speaker.
- Variety's tray icon follows the colour scheme in Plasma (black on a light panel, white on a dark one) and stays white in XFCE.
- The Bluetooth tile in XFCE Settings (Blueberry) shows the blue candy Bluetooth icon instead of the flat tray glyph.
- New candy `insert-link` icon (chain + plus) for Thunar's "Create symlink" action. The old one was a plain white glyph.
- KDE Connect's tray icon was blank. It and 99 other icons were symlinks saved as text files, which show as empty icons. They are real symlinks again.
- Plasma: two icons drawn wrong by Qt are fixed: the executable-file icon (stray blue frame in Dolphin) and the Chatty icon (grey box).
- Synced the 25 new Candy icons.
- Quit, lock, hibernate, log out and the rest of the session/power icons are kept exactly as drawn.
- Four apps that showed a Breeze or hicolor icon in the Plasma menu and System Settings now use a neo-candy icon:
  - Backups (Kup) → the circular-arrow backup icon
  - Journald Browser → the log-viewer icon
  - Resources → the system-monitor icon
  - tuned-gui → the CPU-chip icon

### Technical Details

- Helpers in `tools/`:
  - `compare_trees.py` gives a per-context diff of new / changed / only-ours.
  - `pling_latest.py` asks the Pling OCS API for the newest file and a fresh download link (the token is IP-bound and short-lived).
  - `qt_check.py` flags SVGs that QtSvg (Plasma) draws differently from rsvg (GTK).
  - `neo_candy_plasma.py` holds the Plasma fixes for `al-*`.
- The sync uses `rsync --delete`. It keeps our `index.theme` files and `or-candy-icons/places/16/folder-library.svg`, skips `.github`, `.directory`, names with spaces and `(copy N)` duplicates, and only syncs the BeautyLine contexts we vendor.
- `upstream.lock` records the synced commit/version; `sources.md` is regenerated from it. Each run leaves its report in `versions/<date>_<HHMM>-upstream/` (git-ignored).
- Fixes only ever go into `al-*`, because `or-*` is overwritten by every sync.
- Plasma hook (ported from Surpa's recolour step): 1,641 mono SVGs in `al-beautyline/status/{16,22}` and `panel/{16,22}` get `fill="currentColor"` + `class="ColorScheme-Text"` and a `current-color-scheme` style.
  - The style's colour is the icon's own original colour, so GTK, which ignores the hook, draws them unchanged.
  - Accent colours stay as drawn (red mute marks, orange battery levels).
  - Skipped: gradients, icons with more than one neutral colour (white on a light-grey box would lose its detail), and white lettering on a coloured badge (152 colourful, 14 two-tone, 22 badges left as drawn).
  - Leftover Inkscape `color` values are stripped from hooked icons. Children inherit `currentColor` but resolve it against their own `color`, which broke `renamed-vlc`.
  - Verified: rsvg renders of all hooked icons are pixel-identical before and after at 16, 24 and 48 px.
- Candy step (runs before the hook, `CANDY_RULES`) applies a diagonal `nc-candy` gradient `#0072FF → #00C6FF` (Cochiti Lake) in place of neutral or theme-hooked paint. Accents stay, and files that already carry `nc-candy` are skipped.
  - `audio-volume-*` in `al-beautyline/status` and `panel`.
  - Variety is split by name, not by size. On a 30 px XFCE panel both desktops draw the tray at about 22 px and land on `apps/scalable`. Plasma's tray asks for `<name>-symbolic` first; XFCE's systray asks only for the plain name. So `apps/scalable/variety-indicator-symbolic.svg` is a link to the hooked `panel/22` glyph, which follows Plasma's colour scheme, while `variety-indicator.svg` stays the original white glyph for XFCE. Variety is not in the candy step.
- New aliases `audio-volume-{high,medium,low,muted,high-warning,high-danger}-symbolic` in `al-beautyline/status/{16,22}` point to neo-candy's own speaker files. XFCE's sound plugin asks for these names, which before only existed in `or-candy-icons`. GTK flattens `-symbolic` icons to the panel's text colour, so XFCE draws them white; Plasma keeps the candy.
- `status/22/bluetooth.svg` is now a symlink to `../../apps/scalable/bluetooth.svg`. GTK preferred the mono `status/22` copy at 48 px (closest size), which is why the Settings tile was flat.
- `actions/scalable/insert-link.svg` is drawn new: one stroked path, viewBox 48, width 4, round caps, gradient `#5570FF → #4DD3FF` like `link` / `edit-copy`. The old white glyph is kept as the real `insert-link-symbolic.svg`, which used to be a link to it. Aliases that point to `insert-link` (`gnumeric-link-add`, `itmages-copy-link`, `document-open-remote`, `rabbitvcs-checkmods`) get the candy one too.
- Fake-link repair: an `.svg` of at most 200 bytes whose whole content is an existing sibling's file name is replaced by a relative symlink to it (100 in `al-*`, including `kdeconnect-tray-symbolic`).
- A `PROTECT` name pattern skips every session and power icon (shutdown, reboot, suspend, hibernate, sleep, log out, exit, quit, switch user, session, xfsm, lock screen, padlock lock/unlock), symlink or real file. The session icons themselves live in `apps/` and `actions/`, which the tool never touches.
- QtSvg fixes:
  - `application-executable` was raster art behind a `<clipPath>`, which Qt ignores. It is flattened into one embedded 256 px rsvg render.
  - `purism-chatty` lost its Figma drop-shadow `filter` and full-canvas `clip-path`.
  - The other 491 clipPath/filter SVGs render the same in Qt and rsvg.

### Files Modified

- update-upstream.sh (new)
- upstream.lock (new), sources.md (regenerated)
- README.md (Maintenance section), CLAUDE.md (or-* rule, protected session icons, no cd into the tree)
- .gitignore (versions/, .ruff_cache/)
- usr/share/icons/al-beautyline/status/{16,22}/*, panel/{16,22}/* (Plasma hook)
- usr/share/icons/al-beautyline/mimetypes/scalable/application-executable.svg, apps/scalable/purism-chatty.svg
- usr/share/icons/or-candy-icons/apps/scalable/* (23 new), preferences/scalable/* (2 new)
- usr/share/icons/al-beautyline/apps/scalable/ new relative symlinks:
  - `kup.svg`, `kup-symbolic.svg`, `org.kde.kup.svg` → `preferences-system-backup.svg`
  - `org.kde.kjournaldbrowser.svg` → `utilities-log-viewer.svg`
  - `org.gnome.Resources.svg` → `utilities-system-monitor.svg`
  - `tuned.svg` → `indicator-cpufreq.svg`
- tools/compare_trees.py, tools/pling_latest.py, tools/qt_check.py, tools/neo_candy_plasma.py (new)
- usr/share/icons/neo-candy-icons/index.theme

## 2026.10.01 — Shell-script and empty-file icons match the theme

### What Changed

Two neo-candy file-manager icons looked out of place. Shell scripts such as `~/.fehbg` showed Breeze's grey `>_` page, and empty files such as `~/.ICEauthority` showed a flat grey outline. Both now use the neo-candy gradient style. Also removed a stray mis-named symlink.

### Technical Details

- Qt file managers look up the exact icon name (`text-x-shellscript`) across the whole inherit chain before trying the generic `text-x-script`. al-beautyline had no `text-x-shellscript`, so breeze-dark won. Added `text-x-shellscript.svg` and `text-x-sh.svg` as symlinks to `text-x-script.svg`, the pink `>_` page.
- `application-x-zerosize.svg` was the only flat-grey page. It is now the blue gradient page outline (`#5570FF → #4DD3FF`) taken from `text-x-generic.svg`, without the text lines. `unknown.svg` and `inode-vnd.kde.service.unknown.svg` symlink to it and pick up the change.
- Removed `text-x-generic.svapplication-x-awk.svg`, a typo duplicate of the existing `application-x-awk.svg`.
- `neo-candy-icons/mimetypes` is a symlink to `al-beautyline/mimetypes`, so neo-candy gets all of this.

### Files Modified

- usr/share/icons/al-beautyline/mimetypes/scalable/application-x-zerosize.svg
- usr/share/icons/al-beautyline/mimetypes/scalable/text-x-shellscript.svg (new symlink)
- usr/share/icons/al-beautyline/mimetypes/scalable/text-x-sh.svg (new symlink)
- usr/share/icons/al-beautyline/mimetypes/scalable/text-x-generic.svapplication-x-awk.svg (removed)

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
- Added a real red *full* glyph at 48px too (`48/user-trash-full.svg`, copied from the scalable 16px source) plus the full-state aliases mirroring 48px's empty set (`trash-full`, `gnome-fs-trash-full`, `gnome-stock-trash-full`, `trashcan_full`, `xfce-trash_full`). Also fixed `48/user-trash-full-symbolic.svg`, which had pointed at the green *empty* icon, to point at the red full glyph. So full-trash is red at every size, not just 16px.
- 33 SVGs restored, 47 PNGs removed, +6 SVGs at 48px for the full state. `check-icons.sh` passes clean on all five themes.

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
