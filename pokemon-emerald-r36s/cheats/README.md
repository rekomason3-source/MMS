# Cheats

## `upstream/` — reference only, do not install

| File | Source | Notes |
|---|---|---|
| `libretro-pre-2021-11 …(Code Breaker).cht` | libretro-database, parent of commit `95f050f` (2021-11-09) | 137 cheats; **matches the file on your device** (#37 "Battle Mew [L+Sel]") |
| `libretro-current …(Code Breaker).cht` | libretro-database `master` @ `c4e17d41` (2026-11-07) | 74 cheats; cleaned up for mGBA, with no legendary-encounter cheats |

Both files target **Pokémon Emerald (USA, Europe) — BPEE**. They're kept unmodified so every curated code can be traced back to them.

Analysis tables: `../docs/generated/`.

## Curated folders (Phase 3, empty until ROM is verified)

| Folder | Rule for entry |
|---|---|
| `verified/` | `tested` on your verified ROM, using a copy of your save |
| `experimental/` | Sourced and `parsed` clean, but not yet tested |
| `pokemon-encounters/`, `items/`, `gameplay/` | Category sources with a per-code metadata table |
| `presets/` | One installable `.cht` per preset, all `enable = false`, hotkey-safe activators only |
