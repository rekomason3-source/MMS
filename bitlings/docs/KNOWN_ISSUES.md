# Known Issues & Unverified Assumptions — V0.2

## Not yet verified on real hardware (top priority)

| # | Item | Risk | How to verify |
|---|---|---|---|
| 1 | **Never run on an actual R36S.** All testing was desktop LÖVE 11.5 (Linux, software renderer) | Medium | Install `dist/bitlings.zip` via PortMaster; play the full prologue |
| 2 | **`Bitlings.sh` launcher.** Written from the standard PortMaster LÖVE template (`runtimes/love_11.5/love.txt`, `$LOVE_RUN`, `$GPTOKEYB`) but not run on ArkOS | Medium | Check `ports/bitlings/log.txt` after launch. Compare against a current LÖVE port in the PortMaster repo if it fails |
| 3 | **A/B face-button mapping.** SDL "a" may land on the physical B on some R36S firmware/SDL maps | Low | If confirm feels backwards: Pause → Swap A/B (saved) |
| 4 | **Performance on Mali-G31.** CPU cost measured tiny; GPU fill rate unknown | Low | Perf overlay (R3), see `PERFORMANCE.md` |
| 5 | **Default font readability on a 3.5" screen.** Smallest text is 13 px | Low | Visual check. Bump `UI.font_small` to 14–15 if needed |

## V0.2: balance not yet human-tested

| Item | Status |
|---|---|
| Battle difficulty | The bot wins every fight with **perfect** Sync/Brace timing (Corruptor beaten at Lv 3). Real players will miss timings; the Corruptor may need a few tries. Tune `hp`/`atk` in `src/data/content.lua` |
| Sync window | 75 ms base (110 ms with Sync Lens). Brace window 220 ms (300 ms). May feel tight on a handheld; widen in `battle.lua` if needed |
| Evolution pacing | Gate is Level 3 so evolving lands right after Chapter 1. Care quality 8 needs ~8 good-care acts (feed when hungry, pet, rest). Verify this feels earned, not grindy |
| Hunger rate | Full → empty in ~20 min of play. Only ticks after the Upload Station exists |
| Placeholder art | Enemy, resident and evolved-form sprites are 12–16 px grid placeholders |

## Gameplay limitations (by design)

- Loop seal progress isn't saved mid-encounter. Quitting during the Loop restarts the encounter (the fragments, terminal and FlowSort stay done).
- Sparkbit's position isn't saved. Continuing places Sparkbit beside the sleep pad.
- No music, only procedural UI sounds.
- Expedition progress isn't saved mid-run: quitting in Signals restarts the run (rewards, residents and boss kill are saved immediately).
- Glitches respawn on each new expedition (from the Lounge), so players can farm data on purpose.
- One evolution stage. Second-stage forms are a design question (see the growth design doc §10).
- Commander stats only track `mastery` (incremented on level up). The rest are reserved.

## Technical notes

- Empty Lua tables serialize as `[]` in JSON (see `SAVE_SCHEMA.md`).
- Gamepads without an SDL mapping (`isGamepad() == false`) are ignored. PortMaster exports `SDL_GAMECONTROLLERCONFIG`, so the R36S pad should be mapped.
- No audio device → audio is disabled silently (seen under Xvfb: an ALSA warning in stderr is expected and harmless).
- `src/dev/autotest.lua` ships inside the `.love`. It only activates with `BITLINGS_AUTOTEST=1` **and deletes the save on start**. Never set that env var on a real profile.

## Fixed during development (worth knowing)

| Bug | Fix |
|---|---|
| At 2 unsealed nodes the Loop shuttled non-stop at 1.5× speed, leaving almost no safe window for the last seal | Loop now pauses 0.35 s at each node (a learnable "rewind tick"); per-seal speed-up cut from +25% to +20% |
| A-presses during the level-up celebration were swallowed, so holds wouldn't start | Holds start while A is down once Sparkbit is free; the button that closes a dialog is flushed so it can't leak into an interaction |
| XP floaters stacked unreadably | Proximity-based vertical stacking |
