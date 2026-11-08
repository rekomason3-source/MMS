# Controls — Bitlings: First Spark

Controller-first. Every action is an abstract **action** (`src/input/input.lua`). Game code never reads raw buttons, so remapping happens in one table.

## In the Lounge

| Action | R36S / gamepad | Keyboard (desktop) | What it does |
|---|---|---|---|
| Move | D-pad / left stick | Arrows / WASD | Hero-direct movement (analog speed on the stick) |
| Confirm | **A** | Z / Enter / Space | Interact. **Hold** to repair / seal / restore |
| Cancel | **B** | X / Backspace | Back, close panels |
| FlowSort scan | **X** | C | Draws lines to objectives, marks hidden fragments, shows the Loop's next 2 nodes |
| Pet | **Y** | V | Pet Sparkbit (bond +1 every 8 s at most; restores 1 Core when hurt) |
| Pause | **Start** | Esc / P | Pause menu |
| Objectives | **Select** | Tab / M | Checklist + Sparkbit status (traits, bond, memories) |
| Save & quit | **Select + Start** | — | Saves, then exits cleanly |
| Perf overlay | **R3** | F3 | Toggle the FPS / memory / draw-call overlay |
| Fullscreen | — | F11 | Desktop only |

## FlowSort (terminal event)

| Input | Channel |
|---|---|
| Left | BUILD (amber square) |
| Up (or Down) | KNOWLEDGE (violet diamond) |
| Right | FOCUS (cyan triangle) |
| B | Discard NOISE (static packet) |

Sort 9 of 12 to pass. All 12 = *Perfect Flow* (+10 XP, extra Efficiency).

## Menus

D-pad / stick navigates (with auto-repeat), A selects, B backs out.

## Pause menu settings (saved per profile)

| Setting | Notes |
|---|---|
| Perf Overlay | Same as R3 / F3 |
| Swap A/B | For firmware whose SDL map puts confirm on the other face button. Takes effect immediately; the held button is ignored until it is released |
| Sound | Procedural UI sounds on/off |

Button glyphs on screen follow the last device used (gamepad letters or keyboard keys) and respect Swap A/B.
