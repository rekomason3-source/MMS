# Pokémon Emerald on R36S: Cheat Manager + Bot Foundation

Target: R36S · ArkOS · RetroArch 1.20.0 · mGBA core · Pokémon Emerald.
Rule #1: **save integrity beats convenience.**

## Status

| Phase | Scope | Status |
|---|---|---|
| 1. Environment discovery | Stack, paths, formats, ROM identity, root cause of the save loss | ✅ Research done · ⏳ waiting on device report |
| 2. Cheat research | Sourced codes per category | ⏳ Not started (needs ROM hash) |
| 3. Cheat library | Curated, hotkey-safe `.cht` presets | ⏳ |
| 4. Save protection | Backup ✅ (script) · restore / rotation / detection ⏳ | 🟡 Partial |
| 5. Bot | Architecture notes only | ⏳ |

## Key findings so far

1. **Select + L = Load State on ArkOS defaults.** Hotkey Enable is Select and Load State is L1. "Battle Mew [L+Sel]" uses exactly that combo.
2. **Your Load State fix probably didn't persist.** ArkOS sets `config_save_on_exit = false`, so the change has to be saved via *Save Current Configuration*.
3. **Your cheat file is the pre-2021 libretro file**, which upstream later pruned as broken in mGBA. A prefix on 136/137 of its cheats makes mGBA swallow a code line, and 11 cheats do nothing at all.
4. **20 cheats in that file trigger Load State, Save State or Reset** on ArkOS defaults.
5. **Only one ROM is compatible:** Emerald USA/Europe `BPEE`, SHA-1 `f3ae088181bf583e55daf962a92bb46f4f1d07b7`.

Details: [`docs/environment-report.md`](docs/environment-report.md) · [`docs/cheat-compatibility.md`](docs/cheat-compatibility.md) · [`docs/controller-mapping.md`](docs/controller-mapping.md)

## Layout

| Path | Contents |
|---|---|
| `docs/` | Reports; `docs/generated/` = per-cheat analysis tables |
| `cheats/upstream/` | Reference libretro files (unmodified; see `cheats/README.md`) |
| `cheats/{verified,experimental,presets,…}/` | Curated library (Phase 3) |
| `scripts/inspect-environment/` | `inspect_r36s.sh` (read-only device report), `identify_rom.py` |
| `scripts/backup-saves/` | `backup_saves.sh` (copy + SHA-256 verify, never deletes) |
| `scripts/validate-cheats/` | `analyze_cht.py` (mGBA-accurate parser + hotkey conflict check) |
| `scripts/install-cheats/` | Phase 3 |
| `bot/` | Phase 5 |
| `tests/` | `python3 -m unittest discover -s tests -v` |

## What to run on the handheld (read-only)

```bash
# copy scripts/inspect-environment/inspect_r36s.sh to /roms/ (SD card), then on the R36S:
bash /roms/inspect_r36s.sh --out /roms/r36s-report.txt
```

Send back `r36s-report.txt`. It contains file names, sizes, hashes and config values. It doesn't contain any save contents.

## Offline tools

```bash
python3 scripts/inspect-environment/identify_rom.py "path/to/emerald.gba"
python3 scripts/validate-cheats/analyze_cht.py my.cht --retroarch-cfg retroarch.cfg --autoconfig "GO-Super Gamepad.cfg"
bash scripts/validate-cheats/generate_reports.sh
```
