# Bot Architecture — not started (Phase 5)

Status: **planning notes only.** Nothing below has been tested.

## Leads to research

| Lead | Why it matters | Status |
|---|---|---|
| RetroArch network commands (`network_cmd_enable`, UDP 55355): `READ_CORE_MEMORY`, `WRITE_CORE_MEMORY`, `GET_STATUS` | Would let a PC read Emerald RAM from RetroArch on the R36S over Wi-Fi, without modifying the core (Option C) | Unverified for RetroArch 1.20.0 + mGBA on ArkOS |
| Standalone mGBA Lua scripting (0.10+) | Richest API (memory, input, callbacks). Desktop only; **not** exposed through the RetroArch core | DOC |
| pokeemerald decompilation symbols | Exact RAM layout (party, bag, map, battle) for a BPEE ROM | Available upstream |
| Save-block shifting (0–124 bytes) | The state reader must follow `gSaveBlock1Ptr`/`gSaveBlock2Ptr`, never fixed addresses | SOURCE confirmed |

## Working hypothesis

Simplest demonstrable path is **Option B** (desktop mGBA + Lua): read state, then suggest actions. Same ROM; your `.srm` can be copied to the PC.

Option C (R36S + PC over RetroArch network commands) comes after that, once the command interface is verified on-device.

Safety constraints from the master prompt carry over unchanged: no state loading, no save writes, stop on unknown screens, log everything.
