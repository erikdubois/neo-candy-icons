# CLAUDE.md — neo-candy-icons

## Project overview

See [README.md](./README.md) for the user-facing description of this repo.

## Current state

Standard EDU scaffold (`setup.sh`, `up.sh`, optional `cleanup.sh`) plus the five required markdown files. Content lives where the repo actually ships files (typically `etc/skel/` or `usr/share/`).

## Patterns & decisions

- Bash scripts follow the canonical template from Kiro-HQ — see [Kiro-HQ/CLAUDE.md](/home/erik/Insync/Kiro/Kiro-HQ/CLAUDE.md) and the canonical [up.sh](/home/erik/Insync/Kiro/Kiro-HQ/up.sh) / [setup.sh](/home/erik/Insync/Kiro/Kiro-HQ/setup.sh) / [cleanup.sh](/home/erik/Insync/Kiro/Kiro-HQ/cleanup.sh).
- README + CHANGELOG + IDEAS + TODO are the four other required scaffold files per the ecosystem MD-scaffold rule.
- `or-candy-icons` / `or-beautyline` are exact upstream mirrors managed by `update-upstream.sh`. Never hand-edit them: the next sync overwrites them. Put every fix in `al-*`, and make bulk fixes a step in `tools/neo_candy_plasma.py` so the sync re-applies them.
- Session/power icons (quit, lock, hibernate, log out, …) stay exactly as drawn (Erik, 2026-11-07); the tool's `PROTECT` pattern enforces it.
- neo-candy-icons and Surfn Kiro (`~/KIRO/surfn-kiro`) are Kiro's two future icon themes and must live together (Erik, 2026-11-07). Never ship a folder or icon name that package owns. Keep the fallback to the original `Surfn` / `Surfn-Arc` in `al-candy-icons`. The XFCE tray stays white and the Plasma tray is candy. On the shared VM, check the active icon theme before blaming this repo for a look.
- Never `cd` below the repo root: Claude Code leaves `.claude/` folders in the icon tree, and `up.sh` commits everything.

## Next steps

See [TODO.md](./TODO.md) for active work.
