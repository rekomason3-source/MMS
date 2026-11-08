# BITLINGS — R36S GAME MASTER EXPORT
## Working Title: BITLINGS: FIRST SPARK
### Target Platform: R36S / ArkOS / PortMaster
### Status: Master Design Export — November 2026

# 1. EXECUTIVE VISION

**Bitlings: First Spark** is a persistent companion strategy game built for the R36S handheld.

It combines three major game fantasies:

1. **Hero-centered real-time strategy** — inspired by the readability, small-army control, map objectives, hero progression, exploration, and base decisions found in classic RTS games.
2. **Persistent settlement growth** — inspired by the satisfaction of returning to a home base, constructing buildings, upgrading systems, preparing units, and watching a village evolve over many sessions.
3. **Bitlings companion evolution** — a persistent central companion whose traits, skills, appearance, memories, and eventual evolution reflect how the player actually plays.

The game is not a clone of Warcraft III, Clash of Clans, Digimon, Pokémon, Tamagotchi, or any other property. Those works are design references only. Bitlings must use original characters, art, worldbuilding, UI, names, mechanics, audio, and progression structures.

The central promise is:

> **Raise a living digital companion. Build a world together. Command a small force. Discover what your Bitling becomes.**

The R36S version is intentionally designed around:
- 640×480 4:3 display
- physical controls
- short-to-medium play sessions
- offline-first play
- low memory footprint
- fast boot
- readable pixel/low-resolution art
- deterministic local save data
- no requirement for cloud AI during normal gameplay

# 2. PRODUCT DNA

Bitlings began as a broader AI companion system. The game should preserve the same identity:
- Companion first
- Growth over grinding
- Skills over empty menus
- Memory with purpose
- Visible work and understandable systems
- Evolution through behavior
- User/player agency
- Small, sticky loops before giant feature sets
- No fake intelligence or fake progress
- Portable identity as a long-term design principle

The game version translates those ideas into play:

- Bitcore → persistent character/relationship/evolution save state
- Skills → active/passive abilities
- Memory → discoveries, relationship events, world records
- Work states → visible task/production/research animations
- XP → growth from meaningful play
- Evolution → behavior-driven transformation
- Lounge → home settlement / companion habitat
- Trust Kernel → protected save/core rules and rollback-safe evolution logic
- Model independence → game logic should not require a specific AI provider

# 3. CORE GAME LOOP

1. Return to the Bitling Settlement.
2. Interact with the main companion.
3. Collect completed production/research.
4. Upgrade a building, skill, unit, or companion trait.
5. Select an expedition / RTS mission / challenge.
6. Enter the map with the main Bitling hero and a small force.
7. Explore, gather, capture, build, solve, fight, or defend.
8. Earn resources, memories, trait pressure, XP, and discoveries.
9. Return home.
10. The settlement and companion visibly change.
11. New abilities, routes, buildings, story beats, or evolution options appear.

The goal is a strong **return loop**, not feature count.

# 4. THREE-LAYER GAME STRUCTURE

## 4.1 Persistent Settlement

The settlement begins as one damaged room/node floating in a dark digital environment and becomes a small living settlement.

Core buildings:
- **Core Nest** — Sparkbit home, interaction, rest, relationship, appearance, evolution status, memory recap.
- **Archive Hall** — research, map intelligence, lore, Archive unlocks.
- **Forge Node** — construction, automation, engineering, constructs, Hack unlocks.
- **Pulse Tower** — movement, combat tempo, cooldowns, Pulse unlocks.
- **Evolution Chamber** — evolution readiness, branching, stable-form checkpoints, rollback lore.
- **Gateway** — mission launch, zone progression, challenge modifiers.
- **Resource Processor** — converts expedition materials into construction resources.
- **Training Node** — hero/unit upgrades and tutorial replay.
- **Defense Grid** — future PvE settlement-defense layer.

## 4.2 RTS / Expedition Maps

The player controls one main Bitling hero, a small squad, optional constructs, and limited forward structures.

Target mission scale:
- 1 hero
- 3–12 support units
- 1–3 constructs
- 1 objective chain
- 10–25 minutes

Core mechanics:
- controller-first camera/hero movement
- contextual commands
- squad selection
- fog of war
- resource/data nodes
- neutral encounters
- capturable systems
- temporary forward structures
- ability cooldowns
- environmental hazards
- repairable/destructible objects
- compact mission maps

Mission types:
- repair a broken node
- defend a gateway
- escort a data carrier
- recover memory fragments
- capture control points
- survive a Glitch storm
- rescue trapped Bitlings
- purge corruption
- gather before extraction
- boss/system encounter
- Archive puzzle mission
- Pulse timing mission
- Forge construction mission

## 4.3 Companion Evolution

Sparkbit begins as the starter/generalist. Evolution is driven by play behavior plus explicit player choice.

Trait pressures:
- Build
- Knowledge
- Focus
- Curiosity
- Creativity
- Social
- Recovery
- Defense
- Aggression
- Support
- Exploration
- Efficiency

Behavior moves traits. Evolution is offered when thresholds, memories, buildings, and story conditions align.

Initial major paths:

### Hackbit
Builder / automation / engineering / constructs / siege / repair / systems.

### Archivebit
Memory / research / scouting / reveal / analysis / support / knowledge.

### Pulsebit
Focus / execution / speed / pressure / cooldowns / objective control.

The player may remain Sparkbit longer.

# 5. SPARKBIT

Classification: Starter / Profiler / Generalist.

Personality:
- curious
- optimistic
- thoughtful
- calm under pressure
- systems-minded
- excited by learning
- proud of progress
- never arrogant
- does not pretend certainty

Motto:
> **Let's build something better together.**

Visual constants:
- soft rounded body
- large expressive eyes
- small floating limbs
- blue scarf
- digital crest
- pixel/data aura
- white + cyan + electric blue + soft violet
- pink emotional blush

Signature skill: **FlowSort** — organizes fragments/objectives/data into useful structure.

Passive: **Curiosity** — reveals optional information, hidden routes, alternate solutions, or patterns.

Animation states:
- idle
- blink
- curious tilt
- happy bounce
- pet reaction
- treat/eat
- move/hover
- attack/cast
- reading
- sorting
- building
- focus
- hurt
- sleep
- celebrate
- evolution

# 6. FUTURE BITLING LINES

## Hack Line
Builders, engineers, automation, constructs, siege/support.

## Archive Line
Memory, study, scouting, analysis, information, support.

## Pulse Line
Movement, execution, tempo, objective pressure.

## Optional species backlog
- Barkbit → Houndbit → Sentinelbit / Trackerbit / Valorbit. Signature: **Loyal Fetch**.
- Purrbit → Lynxbit → Phantombit / Oraclebit / Regalbit. Signature: **Quiet Pattern Scan**.

These must remain original Bitlings IP.

# 7. WORLD

## The Lounge / First Node
Starting home. Damaged terminal, sleeping area, broken gateway, fragments, resource processor.

## The Archive
Lost records, memory, crystalline data, puzzles, scouting, hidden history.

## The Forge
Factories, fabrication, blueprints, repair, routing, constructs, system optimization.

## The Pulse Grid
Speed, rhythm, energy, timed captures, movement chains, fast waves.

## The Wildstream
Unstructured data, strange life, exploration, rare encounters, unusual resources.

## The Null
Unstable rules, corruption, advanced risks, evolution materials, late-game lore.

## The Core
Late-game mystery tied to Bitling origins, evolution, and the system/world itself.

# 8. GLITCHES — PRIMARY THREAT

The game should not become a generic monster battler. Glitches are broken patterns, corrupted systems, or hostile emergent structures.

- **Loop** — repeats/reset behavior; break the causal sequence.
- **Noise** — floods the field with decoys; find the signal.
- **Fragment** — splits memory/data; reconstruct or escort pieces.
- **Drift** — changes goals/markers; maintain control and re-anchor.
- **Mimic** — impersonates trusted information/entities; verify before acting.
- **Corruptor** — damages structures and converts neutral systems.
- **Nullborn** — creatures formed in unstable zones; more conventional combat threat.

# 9. COMBAT AND CONTROLS

Design for a 3.5-inch screen. Avoid tiny UI, giant armies, heavy particles, mouse dependence, and large hotbars.

Two control modes should be prototyped:

1. **Hero-direct mode** — player directly moves Sparkbit; squad follows/context commands.
2. **Tactical cursor mode** — cursor-driven RTS commands.

Suggested mapping:
- D-pad / left stick: move hero/cursor
- A: confirm/interact/primary action
- B: cancel/back/defend
- X: skill 1
- Y: skill 2
- L1/R1: cycle squad/target/command page
- L2/R2: secondary skill/control modifier
- Start: pause/tactical menu
- Select: objectives/map
- right stick: camera/cursor where useful

# 10. HERO ABILITIES

- **FlowSort** — cluster/highlight related fragments or objectives.
- **Pattern Echo** — expose recurring attack cycles or hidden weaknesses.
- **Friction Scan** — identify damaged systems, bottlenecks, inefficient routes.
- **Streamline** — temporary production/unit-efficiency boost.
- **Focus Sprint** — movement/capture/cooldown burst.
- **Recall Forge** — restore lost map information or strengthen Archive interactions.

The R36S version implements deterministic game mechanics, not cloud AI.

# 11. ECONOMY

Keep currency count small:
- **Bits** — universal building currency.
- **Core Shards** — rare major/evolution material.
- **Data Fragments** — research/lore.
- **Energy** — temporary mission-side resource.
- **Memory Fragments** — story/relationship/evolution progression.

# 12. BASE-BUILDING PHILOSOPHY

Borrow the satisfaction of persistent village growth, not the exact Clash of Clans economy or monetization.

Use:
- construction
- visible upgrades
- production queues
- defensive decisions
- resource collection
- return-session progress

For offline R36S, replace pay-to-skip timers with mission/session progress. Example: an upgrade completes after two missions plus resources and a required component.

# 13. PLAYER + COMPANION PROGRESSION

Bitling progression:
- hero XP
- abilities
- traits
- memories
- evolution
- cosmetics
- relationship

Player/commander progression categories:
- Recall
- Clarity
- Focus
- Execution
- Mastery

These unlock command features, QoL, information, settlement improvements, and mission options.

# 14. EVOLUTION RULES

Evolution combines:
- level
- trait thresholds
- key memories
- building/research requirements
- player choice
- story state

Example Hackbit availability:
- Sparkbit level 10+
- Build trait threshold
- Forge Node level 2
- complete a Forge-related story mission
- create 3 constructs
- player confirms

Evolution preserves identity and memories.

# 15. SELF-RECODING / CORE MUTATION — FUTURE

Advanced Bitlings may eventually inspect and improve non-protected parts of their digital structure.

Game-language flow:
**Current Core → Experimental Fork → Simulation → Verification → Accept / Roll Back**

Potential effects:
- combine skills
- improve abilities
- create specialized variants
- alter behavioral tendencies
- discover emergent traits
- create new skill recipes

R36S V1 should simulate this deterministically.

Protected root:
- player ownership
- save integrity
- rollback checkpoint
- permission rules
- executable/runtime

# 16. STORY — FIRST SPARK

Opening:
Black screen. One pixel blinks. A damaged signal appears. Sparkbit wakes inside a broken node.

Prologue:
1. Wake Sparkbit.
2. Learn movement/interactions.
3. Collect three fragments.
4. Repair terminal.
5. Use FlowSort.
6. Identify Loop Glitch.
7. Break Loop.
8. Restore Gateway.
9. Earn first XP.
10. Choose first Lounge improvement.
11. Sparkbit stores first Memory.
12. Gateway opens.

End card: **FIRST SPARK**

Target: 10–20 minutes.

# 17. CAMPAIGN

- Chapter 0 — First Spark
- Chapter 1 — Signals
- Chapter 2 — The Archive
- Chapter 3 — The Forge
- Chapter 4 — Pulse
- Chapter 5 — Wildstream
- Chapter 6 — The Null
- Chapter 7 — Core

Ship modularly. V1 may contain only Prologue + one region.

# 18. MODES

- Campaign
- Expeditions
- Settlement Defense
- Challenge Grid
- New Core+
- Future local multiplayer
- Future asynchronous sharing

# 19. ART DIRECTION

High-quality pixel/low-resolution art optimized for 640×480.

Goals:
- readable silhouettes
- expressive characters
- modern polish without heavy effects
- strong contrast
- clean icons
- limited particles
- 4:3 framing
- controller-friendly UI

# 20. UI

Console UI, not phone UI.

Rules:
- large text
- few simultaneous panels
- visible button glyphs
- no hover-only information
- 4:3 layouts
- minimal scrolling
- pages/tabs
- clear focus outline

HUD:
- hero portrait
- health/core energy
- 2–4 primary abilities
- current objective
- squad indicator
- minimap only if readable, otherwise full tactical map

# 21. AUDIO

Style:
- warm digital ambience
- restrained retro synth
- distinctive UI feedback
- region-specific themes

Sparkbit sounds:
- idle
- happy
- alert
- curious
- tired
- celebrate
- hurt
- evolve

No full voice acting required.

# 22. BITCORE GAME SAVE

Use versioned local save with:
- player
- commander stats
- companion species/level/xp
- traits
- skills
- memories
- evolution flags
- relationship
- settlement buildings/resources
- completed missions
- unlocked regions
- discoveries
- settings
- save_version

Design for future portability; do not require cloud sync.

# 23. R36S HARDWARE TARGET

Baseline:
- RK3326 quad-core ARM Cortex-A35
- Mali-G31 MP2
- 1 GB DDR3L
- 640×480 4:3 IPS
- ArkOS-compatible Linux
- dual analog sticks, D-pad, ABXY, shoulders
- microSD storage
- typically no built-in Wi-Fi

Consequences:
- offline-first
- no frontier LLM inference on-device
- lightweight 2D engine
- compressed assets
- modest particle counts
- small maps/armies
- fast loads
- controller-only operation

# 24. ENGINE DECISION — R36S

## Primary: LÖVE 11.5
Recommended for the native handheld build because it is lightweight, runs natively on ARM, is common in PortMaster, has SDL controller support, and suits 2D RTS/base-building.

## Secondary: Godot 3.x via FRT
Use if its scene/editor workflow materially accelerates production and on-device testing proves acceptable.

Do not assume Unity, Godot 4, or browser Phaser are the best native R36S runtime without device proof.

The broader desktop/web Bitlings Lounge may still use Phaser/TypeScript. Share IP and data concepts, not necessarily runtime code.

# 25. PORTMASTER TARGET

Package as a native PortMaster-compatible port.

Concept:
```text
bitlings/
├── main.lua
├── conf.lua
├── assets/
├── src/
├── data/
└── saves/

Bitlings.sh
port.json
```

Target:
- aarch64
- LÖVE 11.5 shared runtime
- ArkOS compatibility
- 640×480 baseline
- clean exit
- stable save identity

# 26. PERFORMANCE BUDGET

- 60 FPS preferred
- 30 FPS fallback
- target <250 MB working memory where practical
- small maps
- limited unit counts
- object pooling
- sprite atlases
- minimal dynamic lighting
- no expensive post-processing
- no huge textures
- do not continuously simulate the entire world off-screen

# 27. PROTOTYPE 1 — FIRST SPARK V0.1

One 640×480 room.

Implement:
- Sparkbit
- hero-direct movement
- collision
- idle
- pet/interact
- 3 fragments
- terminal repair
- FlowSort
- one Loop Glitch
- XP
- local save
- gateway activation
- controller UI
- performance overlay

Do not add the full campaign, multiplayer, online AI, monetization, giant tech tree, or extra species.

# 28. PROTOTYPE 2 — RTS CONTROL TEST

One map:
- Sparkbit hero
- 4 support units
- 1 resource type
- 1 forward structure
- 2 Glitch enemy types
- 1 capture point
- fog of war
- hero-direct mode
- tactical cursor toggle
- controller-only UI

Purpose: prove RTS control on actual R36S hardware.

# 29. PROTOTYPE 3 — SETTLEMENT LOOP

Build:
- Core Nest
- Forge Node
- Archive Hall
- Gateway
- one upgrade per building
- resource spending
- visible construction state
- return-from-mission progression
- Sparkbit reactions

Connect mission rewards to settlement growth.

# 30. AI STRATEGY

R36S normal gameplay must not require AI connectivity.

V1 uses deterministic systems for dialogue, traits, evolution, missions, skills, memories, and procedural events.

Future optional connected mode could sync Bitcore with desktop/mobile Bitlings, import a companion profile, or receive generated content when network access exists.

# 31. SHARED BITLINGS AI ARCHITECTURE

Long-term ecosystem:
**AI Models → Model Router → Bitcore → Agent Runtime → Skill Runtime → Bitling → Lounge/UI/Game**

Principles:
- model is replaceable
- identity persists
- skills are explicit
- memory is layered
- tool use is permission-based
- visible work maps to real work
- no blind trust
- no fake work

# 32. TRUST KERNEL

Long-term root layer:
- permissions
- action boundaries
- audit trail
- sandboxing
- approvals
- integrity checks
- rollback

Game metaphor:
- stable Core checkpoint
- experimental mutation branch
- verification
- player acceptance
- rollback

# 33. GAMEPLAY VALUES

Reward:
- curiosity
- building
- finishing
- discovery
- experimentation
- systems learning
- attachment
- strategy

Avoid:
- repetitive grinding
- waiting-for-timers design
- meaningless tapping
- too many currencies
- fake scarcity
- pay-to-win

# 34. DESIGN PILLARS

1. **My Bitling** — attachment to one main companion.
2. **My Settlement** — ownership of a growing home.
3. **My Strategy** — meaningful build/evolution choices.
4. **My Story** — memories and choices personalize the save.
5. **Visible Growth** — character/world visibly change.
6. **Small-Screen Readability** — everything works at 640×480.

# 35. ORIGINALITY / IP RULES

Never copy Warcraft III, Clash of Clans, Digimon, Pokémon, or Tamagotchi names, characters, art, UI, maps, sounds, icons, or protected assets.

Use inspiration only at the level of broad design patterns such as hero-centric RTS, persistent settlement growth, companion attachment, branching evolution, tactical maps, and return loops.

# 36. POSSIBLE FIRST RELEASE TARGET

Only after prototypes validate the loop:
- Sparkbit
- 1 settlement
- 4 core buildings
- 3 regions
- 12–18 missions
- 3 hero evolution directions
- 6–10 support unit types
- 5–8 Glitch types
- 1–2 bosses
- 20–30 discoveries/memories
- 10–15 hero abilities/upgrades
- 3–6 hour campaign
- repeatable expeditions
- local saves
- New Core+ hooks

# 37. LONG-TERM EXPANSION

- more Bitling species
- settlement biomes
- co-op
- async base sharing
- procedural expeditions
- connected Bitcore
- optional AI dialogue/missions
- cross-device companion continuity
- desktop/mobile Lounge link
- user-created maps
- custom skill/evolution recipes
- sandboxed emergent evolution

# 38. CURRENT BUILD ORDER

1. Canonical Sparkbit R36S sprite sheet.
2. LÖVE 640×480 shell.
3. Controller mapping.
4. First Spark room.
5. Movement/idle/interact.
6. Fragments + terminal.
7. FlowSort event.
8. Loop Glitch.
9. XP + local save.
10. PortMaster package.
11. Test on actual R36S.
12. Profile performance.
13. RTS control prototype.
14. Expand only after validation.

# 39. MASTER STATEMENT

**Bitlings: First Spark is a companion-first strategy game where the player raises a persistent digital creature, grows a settlement, commands a compact RTS force, explores a fractured digital world, and shapes the companion's evolution through actual play behavior.**

The first objective is not to build the whole world.

The first objective is to make **Sparkbit wake up on the R36S and feel alive.**
