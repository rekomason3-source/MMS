# CODEX BUILD BRIEF — BITLINGS: FIRST SPARK FOR R36S

## Objective
Build the smallest playable native R36S proof of Bitlings.

## Runtime
LÖVE 11.5 / Lua.

## Canvas
640×480, 4:3.

## Build V0.1 only
1. boot/title
2. one Lounge room
3. Sparkbit placeholder sprite system
4. hero-direct movement
5. collision
6. idle state
7. pet/interact
8. 3 collectible fragments
9. terminal repair
10. FlowSort
11. Loop Glitch encounter
12. XP
13. versioned local save
14. gateway activation
15. controller navigation
16. pause/quit
17. performance overlay

## Suggested modules
- src/core
- src/input
- src/entities
- src/states
- src/ui
- src/save
- src/data
- assets

## Sparkbit states
idle, move, curious, happy, pet, sorting, building, focus, hurt, celebrate

## Rules
- controller mapping must be abstracted
- preserve compatible saves with migrations
- no expensive shaders or huge textures
- no campaign expansion until this loop runs on real R36S hardware
- no multiplayer, online AI, monetization, or extra species in V0.1

## Deliverables
- desktop LÖVE build for iteration
- PortMaster-compatible package layout
- README
- controls reference
- save schema
- performance notes
- known issues
