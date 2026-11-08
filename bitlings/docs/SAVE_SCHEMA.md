# Bitcore Save Schema (v1)

**File:** `bitcore.json` (+ `bitcore.bak.json` backup) in the LÖVE save directory for identity `bitlings_first_spark`.

| Platform | Location |
|---|---|
| R36S (PortMaster) | `ports/bitlings/saves/love/bitlings_first_spark/` (the launcher sets `XDG_DATA_HOME`) |
| Linux desktop | `~/.local/share/love/bitlings_first_spark/` |
| Windows | `%APPDATA%\LOVE\bitlings_first_spark\` |
| macOS | `~/Library/Application Support/LOVE/bitlings_first_spark/` |

The format is JSON on purpose. It's data only (never executed), and the future desktop/web Bitlings Lounge can read it directly (design §22, "portable identity").

## Guarantees

| Rule | Implementation (`src/save/save.lua`) |
|---|---|
| Versioned | Integer `save_version`; current `Save.VERSION = 1` |
| Migrations | `Save.migrations[n]` upgrades n → n+1 and runs in a chain. The v0 → v1 migration (flat prototype saves) ships and is tested |
| Forward-compatible | After migrating, missing fields are filled from `new_default()`; existing values are never overwritten |
| Never clobber the future | A save with `save_version` > build version is **not loaded** and the session becomes **read-only** (no writes) |
| Crash-safe | Every write copies the current file to `bitcore.bak.json` first. A corrupt main file falls back to the backup automatically |
| When it saves | Each prologue milestone, every 60 s of gameplay, Pause → Save, Select+Start, and window close |

## Shape

```jsonc
{
  "save_version": 1,
  "created_at": 1762600000, "updated_at": 1762600123,   // unix seconds
  "player":    { "name": "Commander", "playtime": 78.4 },// seconds
  "commander": { "recall": 0, "clarity": 0, "focus": 0, "execution": 0, "mastery": 1 },
  "companion": {
    "species": "Sparkbit", "name": "Sparkbit", "stage": "Sparkbit",
    "level": 2, "xp": 65, "energy": 5, "max_energy": 5
  },
  "traits": {                    // trait pressure, driven by behaviour
    "build": 5, "knowledge": 1, "focus": 4, "curiosity": 2, "creativity": 1, "social": 1,
    "recovery": 0, "defense": 1, "aggression": 0, "support": 0, "exploration": 5, "efficiency": 2
  },
  "skills": {
    "flowsort":  { "unlocked": true, "level": 1, "uses": 3 },
    "curiosity": { "unlocked": true, "passive": true }
  },
  "memories": [
    { "id": "first_spark", "title": "First Spark", "text": "...", "level": 2,
      "improvement": "workbench", "at": 1762600100 }
  ],
  "evolution":    { "offered": [], "chosen": "", "flags": {} },  // reserved: Hackbit / Archivebit / Pulsebit
  "relationship": { "affinity": 1, "pets": 2 },
  "settlement": {
    "buildings": {
      "core_nest": { "level": 1 }, "archive_hall": { "level": 0 },
      "forge_node": { "level": 1 }, "gateway": { "level": 1 }
    },
    "resources": { "bits": 47, "core_shards": 1, "data_fragments": 0, "energy": 0, "memory_fragments": 1 },
    "improvement": "workbench"   // "" | "cushion" | "workbench" | "shelf"
  },
  "missions":    { "completed": { "break_the_loop": true, "first_spark": true } },
  "regions":     { "unlocked": ["lounge", "signals"] },
  "discoveries": { "hidden_fragment": true, "old_processor": true },
  "progress": {                  // V0.1 prologue state machine
    "awake": true, "fragments": { "f1": true, "f2": true, "f3": true },
    "terminal_repaired": true, "flowsort_done": true, "loop_broken": true,
    "gateway_active": true, "improvement": "workbench", "memory_stored": true,
    "gateway_open": true, "prologue_complete": true
  },
  "settings": { "perf_overlay": false, "swap_ab": false, "sfx": true }
}
```

Empty objects may serialize as `[]` (Lua can't tell an empty array from an empty map). Readers should treat `[]` and `{}` the same for map-typed fields.

## V0.2 additions (additive: still `save_version` 1)

These fields were added with defaults, so v1 saves from V0.1 load and get them filled in automatically (covered by a unit test).

```jsonc
{
  "companion":  { "stage": "sparkbit|hackbit|pulsebit|archivebit", "hp": 76 },
  "data_core":  { "lifetime": { "build": 20, "pulse": 68, "archive": 14 },   // never spent
                  "bank":     { "build": 20, "pulse": 62, "archive": 14 } }, // spent on uploads
  "care":       { "hunger": 64.2, "mood": 85, "score": 12, "mistakes": 0, "starving": false, "fed": 3 },
  "skills":     { "learned": { "flowsort": true, "pulse_dash": true }, "equipped": ["flowsort", "pulse_dash"] },
  "aspects":    { "owned": { "sync_lens": true }, "equipped": ["sync_lens"], "scarf": "red" },
  "cards":      { "heal": 2, "energy": 1, "boost": 0, "shield": 1 },
  "bitdex":     { "seen": { "loop": true }, "defeated": { "loop": true } },
  "residents":  { "barkbit": { "joined": 1762600000 }, "purrbit": { "joined": 1762600000 } },
  "expedition": { "fetch_ready": false, "runs": 1 }
}
```

## Adding a field or changing the shape

1. **Additive field** (new key with a default): add it to `new_default()`. No version bump needed; old saves get it from the defaults fill.
2. **Breaking change** (rename, move, retype): bump `Save.VERSION`, add `Save.migrations[old]`, and add a case to `tests/test_core.lua`.
3. Never reuse a removed key with a different meaning.
