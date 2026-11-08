# Emulator Configuration — RetroArch 1.20.0 / mGBA on ArkOS

## Cheat lifecycle (from RetroArch v1.20.0 source)

| Step | What RetroArch does | Code |
|---|---|---|
| 1. Game starts | Looks for `<cheat_database_path>/<core library name>/<ROM basename>.cht` and loads it if present | `command_event_init_cheats()` → `cheat_manager_load_game_specific_cheats()` |
| 2. | Applies enabled cheats **only if** `apply_cheats_after_load = true` (ArkOS: false) | `command.c` |
| 3. You use Quick Menu → Cheats → **Load Cheat File (Replace)** | Replaces the list with a database file (usually from `cheats/`) | menu |
| 4. You toggle a cheat | Takes effect only after **Apply Changes** (ArkOS `apply_cheats_after_toggle = false`) | menu |
| 5. Game closes | A file loaded in step 3 is **not** remembered unless you **Save Cheat File As** to the game-specific name | — |

That's why "cheat files may not automatically reload after restarting." Step 1 only finds a file saved under the game-specific name.

**Planned install target** (Phase 3, after your approval):
`/home/ark/.config/retroarch/cheats/mGBA/<exact ROM basename>.cht`, with all cheats disabled.

The core's library name is expected to be `mGBA`. Confirm in RetroArch → Information → Core Information.

## Config persistence

| Setting (ArkOS default) | Effect |
|---|---|
| `config_save_on_exit = "false"` | Menu changes are **lost at exit** unless you choose Main Menu → Configuration File → **Save Current Configuration** |
| `global_core_options = "true"` | Core options shared across cores in one file |
| `savefiles_in_content_dir = "true"` | `.srm` sits next to the ROM |
| `savestates_in_content_dir = "true"` | `.state*` files sit next to the ROM |
| `savestate_auto_load/save = "false"` | No automatic state load at boot (good) |
| `block_sram_overwrite = "false"` | Loading a state may overwrite SRAM → see save-recovery.md |

## Change procedure (applies to every device change)

1. Run `inspect_r36s.sh` and send the report.
2. Run `backup_saves.sh`, then copy the backup to a PC.
3. Get a written proposal of the exact lines to change, and approve it.
4. Apply the change, then **Save Current Configuration**.
5. Reboot, re-run `inspect_r36s.sh` and confirm the change persisted.
