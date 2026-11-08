# Controller & Hotkey Mapping

## ArkOS defaults (candidate — verify with `inspect_r36s.sh`)

Source: dArkOS `retroarch.cfg.rg351mp` + `controller/GO-Super Gamepad.cfg` @ `83244776`. That your R36S reports itself as "GO-Super Gamepad" is **ASSUMED**.

| Hold Select + … | Button index | RetroArch action | Risk |
|---|---|---|---|
| Start | 13 | Exit emulator | 🟠 |
| **L1** | 4 | **Load State** | 🔴 |
| **R1** | 5 | **Save State** | 🔴 |
| **B** | 0 | **Reset** | 🔴 |
| X | 2 | Open RetroArch menu | ✅ |
| Y | 3 | Screenshot | ✅ |
| A (idx 1) | 1 | Pause | ✅ |
| D-pad Up / Down | 8 / 9 | State slot − / + | 🟡 |
| L2 / R2 | 6 / 7 | Brightness +/− (ArkOS) | ✅ |
| L3 | 14 | Fast-forward toggle | ✅ |

Not yet resolved: the GO-Super profile maps both `a` and `r3` to index 15, and ArkOS binds Pause to index 1. The physical A button index must be confirmed on the device.

## Fix options for the Select + L problem

| Option | Change | Pros | Cons | Reversible |
|---|---|---|---|---|
| **A. Re-map cheat activators** (in our curated `.cht`) | Cheats use L + R + direction (no Select) | Fixes the cause; RetroArch untouched; works even if the config resets | Requires editing codes (KEYINPUT values) | ✅ Delete file |
| **B. Unbind Load State hotkey** | `input_load_state_btn = "nul"` + **Save Current Configuration** | One setting, removes the worst risk | Persistence must be confirmed; you lose quick-load | ✅ |
| C. Move Hotkey Enable off Select (e.g. to L3) | `input_enable_hotkey_btn` | Frees all Select combos | Changes every ArkOS hotkey habit, including exit (Select+Start); affects all systems | ✅ but disruptive |
| D. Only use cheats with safe combos | Discipline | No changes | Fragile; human error repeats the incident | — |

**Recommendation: A + B.**
- A removes the conflict at its source.
- B is a safety net if a conflicting cheat is ever loaded again.

Option C is the cleanest but changes global ArkOS controls. That conflicts with "do not modify unrelated ArkOS controls".

Optional addition: also unbind **Reset (Select + B)** if you never use it. Keep Save State if you rely on it. Overwriting a state slot doesn't touch your in-game `.srm` save.

## Safe activator combos (no RetroArch hotkey on defaults)

| Combo | KEYINPUT value (`74000130 vvvv`) | Note |
|---|---|---|
| L + R + Up | `00BF` | Upstream "Access Birch's Bag" uses it (old file) |
| L + R + Down | `007F` | Upstream "Receive Starter" uses it (old file) |
| L + R + Left | `00DF` | Free |
| L + R + Right | `00EF` | Free |

Formula: `vvvv = 0x3FF & ~(bits of held buttons)`, with bits A0 B1 Sel2 St3 →4 ←5 ↑6 ↓7 R8 L9. The values above were computed, **not tested in-game**. The curated library will give each preset its own combo, so the same combo is never reused within one loaded file.
