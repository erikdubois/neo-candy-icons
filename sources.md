# Sources

neo-candy-icons combines two icon themes. Their upstream copies live in
`usr/share/icons/or-candy-icons` and `usr/share/icons/or-beautyline`, and are
synced by `update-upstream.sh`. Our own work lives in the `al-*` themes.

| Theme | Source | Synced to | Upstream date |
|---|---|---|---|
| Candy icons | https://github.com/EliverLara/candy-icons (also https://www.pling.com/p/1305251/) | master `750fe2c` | 2026-10-26 |
| BeautyLine | https://www.pling.com/p/1425426/ (original by sajjad606) | V2.4 | 2024-08-09 |

Extras: Garuda's BeautyLine fork
https://gitlab.com/garuda-linux/themes-and-settings/artwork/beautyline (3.0.5 `07e3736`).
Only the icon names none of the four layers above has are copied into the hidden theme
`usr/share/icons/or-beautyline-garuda` (rebuilt on every run). Our own icons are never replaced.
The `beautyline` and `candy-icons-git` packages are not needed; hq keeps them installed as a reference.

Last upstream check: 2026-11-07
