# Known Issues & Unverified Assumptions — V0.1

## Not yet verified on real hardware (top priority)

| # | Item | Risk | How to verify |
|---|---|---|---|
| 1 | **Never run on an actual R36S.** All testing was desktop LÖVE 11.5 (Linux, software renderer) | Medium | Install `dist/bitlings.zip` via PortMaster; play the full prologue |
| 2 | **`Bitlings.sh` launcher.** Written from the standard PortMaster LÖVE template (`runtimes/love_11.5/love.txt`, `$LOVE_RUN`, `$GPTOKEYB`) but not run on ArkOS | Medium | Check `ports/bitlings/log.txt` after launch. Compare against a current LÖVE port in the PortMaster repo if it fails |
| 3 | **A/B face-button mapping.** SDL "a" may land on the physical B on some R36S firmware/SDL maps | Low | If confirm feels backwards: Pause → Swap A/B (saved) |
| 4 | **Performance on Mali-G31.** CPU cost measured tiny; GPU fill rate unknown | Low | Perf overlay (R3), see `PERFORMANCE.md` |
| 5 | **Default font readability on a 3.5" screen.** Smallest text is 13 px | Low | Visual check. Bump `UI.font_small` to 14–15 if needed |

## Gameplay limitations (by design for V0.1)

- Loop seal progress isn't saved mid-encounter. Quitting during the Loop restarts the encounter (the fragments, terminal and FlowSort stay done).
- Sparkbit's position isn't saved. Continuing places Sparkbit beside the sleep pad.
- No music, only procedural UI sounds.
- One room, one Glitch type, one improvement choice. Per the brief: **no expansion until this loop runs on device.**
- Commander stats only track `mastery` (incremented on level up). The rest are reserved.
- `evolution` is in the save schema but nothing offers an evolution yet.

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
