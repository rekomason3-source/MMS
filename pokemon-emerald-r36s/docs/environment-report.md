# Environment Report — Phase One

Status: **Draft from research only.** No device access yet. Nothing has been inspected on the R36S.
Date: 2026-11-08

## 0. Access status

| Resource | Access | Consequence |
|---|---|---|
| R36S storage / SD card | ❌ None | All device facts below are *candidates* until `inspect_r36s.sh` output is returned |
| ROM file | ❌ None | ROM identity unknown → no cheat can be marked "verified for your ROM" |
| Save files | ❌ None | No backups taken yet |
| Upstream sources (libretro, mGBA, RetroArch, ArkOS) | ✅ Cloned and read | Findings below are cited to source commits |

Evidence labels used throughout:

| Label | Meaning |
|---|---|
| **SOURCE** | Read directly in upstream source code / shipped config (commit cited) |
| **DOC** | Community or official documentation, not source |
| **INFERRED** | Reasoned from SOURCE facts, not directly observed |
| **ASSUMED** | Plausible, unverified; needs device output |

## 1. Root cause of the save loss (L + Select)

| # | Finding | Evidence |
|---|---|---|
| 1 | ArkOS sets **Select as the Hotkey Enable** button: `input_enable_hotkey_btn = "12"` | SOURCE — dArkOS `retroarch/configs/retroarch.cfg.rg351mp` @ `83244776` |
| 2 | ArkOS binds **Load State to button 4** (`input_load_state_btn = "4"`) and **Save State to button 5** | SOURCE — same file |
| 3 | On the `GO-Super Gamepad` profile, 12 = Select, 4 = L1, 5 = R1 | SOURCE — dArkOS `controller/GO-Super Gamepad.cfg` |
| 4 | ⇒ **Select + L = Load State, Select + R = Save State, Select + B = Reset** | INFERRED from 1–3 (matches what you experienced) |
| 5 | "Battle Mew [L+Sel]" fires exactly when KEYINPUT = `0x01FB` = **Select + L held** | SOURCE — decoded with `analyze_cht.py` (port of mGBA parser) |
| 6 | So the cheat and the Load State hotkey use the **same physical combo** | INFERRED |
| 7 | A loaded state also restores the cartridge save memory in RAM; quitting afterwards can write that *older* data to `.srm` | ASSUMED — mGBA serializes savedata into states; confirm in Phase 4 tests |

**This is not a one-off:** 20 cheats in the device's cheat file (and 12 in the current upstream file) use combos that also fire a RetroArch hotkey. See `generated/analysis-libretro-pre-2021-11.md`.

## 2. Does clearing the Load State hotkey persist?

| Question | Answer | Evidence |
|---|---|---|
| Does RetroArch save menu changes automatically on ArkOS? | **No** — ArkOS ships `config_save_on_exit = "false"` | SOURCE |
| So did your "Load State → None" change survive a restart? | **Probably not**, unless you ran *Save Current Configuration* | INFERRED |
| How to make it persist | Main Menu → **Configuration File → Save Current Configuration** (exact RetroArch 1.20.0 labels) | SOURCE — RetroArch v1.20.0 `intl/msg_hash_us.h` |
| What can still undo it | A core/game override file, an ArkOS "restore default RetroArch settings" option, or an ArkOS update replacing `retroarch.cfg` | DOC / ASSUMED |
| How to verify | After reboot: Settings → Input → Hotkeys → Load State shows **None**, *and* `inspect_r36s.sh` shows `input_load_state_btn = "nul"` | — |

Don't re-test with L + Select until both checks pass and a verified backup exists.

## 3. Hardware (R36S)

| Item | Value | Evidence |
|---|---|---|
| SoC | Rockchip RK3326, 4× Cortex-A35 (genuine units) | DOC |
| RAM | 1 GB (some clones 512 MB or 2 GB) | DOC |
| Clones | Many "R36S" clones exist, some on different SoCs (RK3128, A33), with different DTB/panel | DOC — handhelds.wiki R36S Clones |
| ArkOS lineage | Original R36S community ArkOS builds (e.g. ArkOS-R3XS) are archived; current forks are dArkOSRE-R36 and ArkOS4Clone | DOC |
| Which build you run | **Unknown** | Needs `inspect_r36s.sh` (reads `/boot/*.dtb`, device-tree model, input device name) |

## 4. Software stack

| Item | Value | Evidence |
|---|---|---|
| RetroArch | 1.20.0 (reported); 64-bit `retroarch` and 32-bit `retroarch32` builds both exist on ArkOS | User / SOURCE (dArkOS has both config trees) |
| GBA core | mGBA libretro (`mgba`, also `mgba_rumble`) | SOURCE — dArkOS `retroarch_cores.txt` |
| Menu driver | RGUI | SOURCE |
| Cheat auto-apply on load | `apply_cheats_after_load = "false"` | SOURCE |
| Apply after toggle | `apply_cheats_after_toggle = "false"` → must press **Apply Changes** | SOURCE |

## 5. Filesystem candidates (verify on device)

| Purpose | Candidate path | Basis |
|---|---|---|
| ROMs | `/roms/gba/` (second card: `/roms2/gba/`) | ArkOS convention, ASSUMED |
| In-game save | `/roms/gba/<ROM name>.srm` | SOURCE: `savefiles_in_content_dir = "true"` |
| Save states | `/roms/gba/<ROM name>.state`, `.state1`…, `.state.auto` | SOURCE: `savestates_in_content_dir = "true"` |
| RetroArch config | `/home/ark/.config/retroarch/retroarch.cfg` (or `retroarch32/`) | SOURCE: `~/.config/retroarch`, ArkOS user `ark` ASSUMED |
| Cheat database | `/home/ark/.config/retroarch/cheats/` | SOURCE: `cheat_database_path` |
| **Auto-loaded per-game cheats** | `…/cheats/mGBA/<ROM basename>.cht` | SOURCE: RetroArch v1.20.0 `cheat_manager_get_game_specific_filename()` joins `cheat_database_path / core library_name / content name + .cht` |
| Overrides | `…/retroarch/config/mGBA/` | RetroArch convention, ASSUMED |
| Controller profiles | `…/retroarch/autoconfig/udev/` | ASSUMED |

Verification commands are in `scripts/inspect-environment/inspect_r36s.sh` (read-only).

## 6. ROM identity requirements

Emerald has **one English release and no revisions**. Cheats with fixed addresses target exactly that ROM.

| Release | Game code | SHA-1 (No-Intro) |
|---|---|---|
| **USA, Europe — target of the libretro cheat file** | **BPEE** | `f3ae088181bf583e55daf962a92bb46f4f1d07b7` |
| Japan | BPEJ | `d7cf8f156ba9c455d164e1ea780a6bf1945465c2` |
| Germany | BPED | `61c2eb2b380b1a75f0c94b767a2d4c26cd7ce4e3` |
| France | BPEF | `ca666651374d89ca439007bed54d839eb7bd14d0` |
| Italy | BPEI | `1692db322400c3141c5de2db38469913ceb1f4d4` |
| Spain | BPES | `fe1558a3dcb0360ab558969e09b690888b846dd9` |

Source: libretro-database `metadat/no-intro/Nintendo - Game Boy Advance.dat` @ `c4e17d41`.

To verify, you need either of these:
- [ ] The output of `identify_rom.py <rom>` (run on a PC), or
- [ ] The `ROMs` section of `inspect_r36s.sh`

A hash mismatch with header `BPEE` means a hack, patch, trim or bad dump. **Treat every cheat as unverified** in that case.

## 7. Cheat system facts (summary; details in `cheat-compatibility.md`)

| Fact | Evidence |
|---|---|
| The device's file is the **pre-Nov-2021** libretro file (137 cheats; #37 = "Battle Mew [L+Sel]") | SOURCE — matches your description exactly; upstream history commit `95f050f^` |
| Upstream **removed** Battle Mew/Deoxys/Ho-Oh/etc. in Nov 2021: "removed many of the broken cheat that don't even work … in mGBA core" | SOURCE — commit `95f050f` |
| 136/137 of those cheats start with `449E9E7D+3CD9`, which mGBA parses as a CodeBreaker **fill** that swallows the next line | SOURCE — mGBA `codebreaker.c` @ `662dada8` |
| Effect: 11 cheats are complete no-ops in mGBA (e.g. "No Random Battles", "Infinite PP", "Max Stats"), and others lose a button gate | INFERRED via `analyze_cht.py` |
| The mGBA libretro core puts **all enabled cheats into one shared set** (ignores index/enable) | SOURCE — `libretro.c retro_cheat_set()` |
| ⇒ Enabling several cheats at once can interfere (shared encryption seed / fill state) | INFERRED |
| Emerald **shifts SaveBlock1/2 and PC storage by a random 0–124 bytes** after load/warp | SOURCE — pokeemerald `src/load_save.c SetSaveBlocksPointers()` |
| ⇒ Fixed-address EWRAM item/party cheats are unreliable unless they read the pointer or use "Anti-DMA" | INFERRED |

## 8. Missing information — needed from you

| # | Item | How | Priority |
|---|---|---|---|
| 1 | Output of `inspect_r36s.sh` | Run on the handheld (SSH or terminal) → send `r36s-report.txt` | 🔴 High |
| 2 | ROM hash | Covered by #1, or `identify_rom.py` on a PC | 🔴 High |
| 3 | Which ArkOS build (boot splash / Options → version) | Photo or text | 🟡 Medium |
| 4 | Is Load State still "None" after a reboot? | Check Settings → Input → Hotkeys | 🔴 High |
| 5 | Do you have SSH/Wi-Fi on the R36S, or only SD-card access via a PC? | Tell me | 🟡 Medium |
| 6 | Do you also use the Save State hotkey (Select + R) intentionally? | Yes/No → shapes the hotkey fix | 🟡 Medium |

## Sources

- libretro-database: https://github.com/libretro/libretro-database (cht + metadat, commit `c4e17d41`; history commit `95f050f`)
- mGBA: https://github.com/mgba-emu/mgba (`src/platform/libretro/libretro.c`, `src/gba/cheats/codebreaker.c`, `src/gba/cheats.c`, commit `662dada8`)
- RetroArch v1.20.0: https://github.com/libretro/RetroArch/tree/v1.20.0 (`cheat_manager.c`, `command.c`, `runloop.c`, `intl/msg_hash_us.h`)
- dArkOS: https://github.com/christianhaitian/dArkOS (`retroarch/configs/*`, commit `83244776`)
- pokeemerald: https://github.com/pret/pokeemerald (`src/load_save.c`, `include/load_save.h`)
- R36S hardware/clones: https://handhelds.wiki/R36S_Clones , https://handhelds.wiki/R36S_Overview , https://techtactician.com/r36s-vs-r36xx-r36plus-max-ultra-explained/
- RetroArch config persistence discussion: https://github.com/libretro/RetroArch/issues/7286
