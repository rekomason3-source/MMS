# Save Protection — initial (Phase 4 expands this)

## What your progress actually lives in

| File | What it is | Priority |
|---|---|---|
| `<ROM>.srm` (128 KB flash image for Emerald) | The **in-game save** (what "Save" in the Pokémon menu writes) | 🔴 This is your game |
| `<ROM>.state`, `.state1`… | RetroArch snapshots of the whole emulator | 🟡 Convenience only; tied to core version |
| `<ROM>.state.auto` | Auto state (disabled on ArkOS defaults) | 🟡 |

## Rules

- [ ] Back up **before** every cheat session and every config change.
- [ ] Close the game (Select + Start) before backing up. The `.srm` on disk may be stale while the game runs.
- [ ] Keep at least one backup **off the device** (PC or cloud).
- [ ] Never load a state from a different mGBA/RetroArch version without a backup.
- [ ] After any accidental state load, **don't save in-game and don't quit normally** until you've decided what to keep. Copy the `.srm` first. (Behavior to be confirmed in Phase 4 tests; see the environment report, item 1.7.)

## Tool: `scripts/backup-saves/backup_saves.sh`

```bash
bash backup_saves.sh --src /roms/gba --name "<ROM basename without .gba>" --dest /roms/backups/emerald
```

| Behavior | |
|---|---|
| New timestamped folder per run | Never overwrites, never deletes |
| SHA-256 manifest + `sha256sum -c` verification | Fails loudly on mismatch |
| Refuses to run while RetroArch is open | Prevents a stale `.srm` |

Phase 4 will add: rotation policy, a restore script with a dry run, state-load detection and a restore drill.
