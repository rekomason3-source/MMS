# Cheat Compatibility — RetroArch 1.20.0 + mGBA core

## 1. File format (`.cht`)

```ini
cheats = 2

cheat0_desc = "Human readable name"
cheat0_code = "XXXXXXXX+YYYY+XXXXXXXX+YYYY"
cheat0_enable = false

cheat1_desc = "..."
cheat1_code = "..."
cheat1_enable = false
```

| Rule | Why | Evidence |
|---|---|---|
| Separate code lines with `+` (or space) | mGBA's libretro core rebuilds lines from `+`/space | `libretro.c retro_cheat_set()` |
| CodeBreaker line = 8 hex + 4 hex | Autodetect: `XXXXXXXX YYYY` → CodeBreaker | `gba/cheats.c GBACheatAddLine()` |
| GameShark / Action Replay line = 8 hex + 8 hex | Autodetect tries GSA v1 / PAR v3, encrypted and raw | `GBACheatAddAutodetect()` |
| **Never use `++`, 9-digit or 12-digit groups** | The splitter is position-based, so one bad group shifts every following line | Upstream "Have Surf Ability" (`++`) and "Berry Blender Max Direct Hits" (`372002EFA`) are broken this way |
| Ship every cheat with `enable = false` | `apply_cheats_after_load=false` on ArkOS anyway; explicit opt-in is safer | — |

## 2. How the mGBA core really applies cheats

| Behavior | Consequence |
|---|---|
| `retro_cheat_set()` **ignores the index and enable flags** and appends every code to **one shared cheat set** | Cheats are not isolated. A CodeBreaker `9xxxxxxx` (encryption) line or an unfinished fill in one cheat changes how the **next** cheat is parsed |
| On every change RetroArch calls `retro_cheat_reset()`, then re-sends the enabled cheats | Order matters: cheats are applied in file order |
| CodeBreaker type `0` (game ID) is ignored; type `1` installs a ROM hook (only one allowed) | Master codes are **optional** in mGBA. Without a hook, cheats run every frame |
| Type `D0000020 mask` = "if these buttons are held"; `74000130 vvvv` = "if KEYINPUT == vvvv" (exact combo) | These are the button activators |
| Type `4` (fill) consumes the **next line** as its parameters; type `5` consumes following lines as data | Origin of the "swallowed line" problem below |

## 3. The `449E9E7D+3CD9` prefix problem (device's cheat file)

136 of the 137 cheats in the pre-2021 file start with `449E9E7D+3CD9`. mGBA treats it as a CodeBreaker **fill** (type 4) at an unmapped I/O address, then **eats the next line** as its count/step.

Battle Mew, as mGBA actually parses it:

| Line | mGBA interpretation |
|---|---|
| `449E9E7D 3CD9` | FILL @ 0x049E9E7D (unmapped I/O) — junk write |
| `74000130 01FB` | **Swallowed** as fill parameters — this button gate never runs |
| `83000E48 7DFE` | 16-bit write to IWRAM 0x03000E48 — **runs every frame, ungated** |
| `74000130 01FB` | IF KEYINPUT == 01FB (**Select + L exactly**) |
| `83000E4A 0826` | 16-bit write to 0x03000E4A — gated |

Net effect: the Select + L press completes a 32-bit value `0x08267DFE` (a ROM address) in IWRAM. It probably redirects a script or callback pointer. **INFERRED; the target structure is not yet identified.** It worked for you, but it's an arbitrary-pointer cheat, so it's high risk by nature.

| Impact (from `analyze_cht.py`) | Count |
|---|---|
| Cheats whose only real writes are swallowed → **complete no-ops in mGBA** (e.g. No Random Battles, Infinite PP, Max Stats ×6, Free Daycare) | 11 |
| Cheats where a button gate is swallowed → part of the cheat runs every frame | 33 flagged |
| Cheats that end inside a fill → swallow the first line of the **next enabled cheat** | 1 ("Copy Battle PKMN Part 2/2") |

Upstream fixed this in Nov 2021 (commit `95f050f`). The prefix was removed, and so were many cheats, **including all "Battle X" legendary encounters**.

## 4. Hotkey conflicts (ArkOS defaults)

Hotkey Enable = Select. Any cheat combo with **Select + L / R / B / Start / Up / Down** also fires a RetroArch hotkey.

| GBA combo used by cheats | RetroArch action on ArkOS defaults | Severity |
|---|---|---|
| Select + L (+ anything) | **Load State** | 🔴 Progress loss |
| Select + R (+ anything) | **Save State** (overwrites the current slot) | 🔴 Overwrites a state |
| Select + B (+ anything) | **Reset game** | 🔴 Loses unsaved progress |
| Select + Start | Exit emulator | 🟠 |
| Select + Up / Down | State slot − / + | 🟡 Moves the slot silently, so the next save/load hits a different slot |
| Select + A, Select + Left/Right, L+R+…, no Select | none | ✅ Safe |

Full per-cheat tables: `generated/analysis-libretro-pre-2021-11.md` (device file) and `generated/analysis-libretro-current.md` (current upstream).

Upstream label errors found:
- "Have Ability: Flash [L+Sel]" (old) and "Have Flash [Press L+Select]" (current) actually test **Select + Up** (`03BB`).

## 5. ROM dependence

| Rule | Detail |
|---|---|
| Fixed-address codes are tied to one ROM build | The libretro file targets **BPEE (USA/Europe)**. Japanese/European-language builds have different layouts |
| Emerald has only one BPEE revision | So a clean BPEE dump (SHA-1 `f3ae0881…`) is the only "compatible" target |
| ROM hacks / patched ROMs | Assume **incompatible** until tested |
| Emerald save-block shifting | SaveBlock1/2 and PC storage move by a random 0–124 bytes (`SetSaveBlocksPointers`). Fixed EWRAM writes (items, money, party) can land on the wrong field. That's why "Anti-DMA" codes exist |

## 6. Verification levels used in this project

| Level | Meaning | How achieved |
|---|---|---|
| `parsed` | mGBA parses it as intended (no swallowed lines, no hotkey conflict) | `analyze_cht.py` (offline) |
| `documented` | Appears in a named source with a matching ROM target | Source citation |
| `tested` | Observed working on a verified ROM, on a **copy** of your save, with result recorded | Test checklist (Phase 3/4) |
| `unverified` | Anything else | — |

No cheat in this repo is `tested` yet.

## 7. Implications for the curated library (Phase 3 plan)

1. Base the library on the **current** upstream file. It has no prefix problem and the cheats parse cleanly.
2. Re-add encounter cheats (Mew, etc.) **only** in a cleaned form: prefix removed, button gate fixed, activator moved off Select+L/R/B/Start/Up/Down. Label them `experimental` until tested.
3. Re-map every activator to a hotkey-safe combo (e.g. **L + R + direction**, which uses no Select).
4. Ship one file per preset, all disabled by default. Each preset gets its own `.cht`, so incompatible cheats are never loaded together.
5. Install to `cheats/mGBA/<exact ROM basename>.cht` so it auto-loads (still disabled).

The encounter, shiny, level, item and money codes requested in the master prompt are **not yet researched**. No code will be added without a source and a `parsed` check.
