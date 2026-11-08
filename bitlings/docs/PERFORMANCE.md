# Performance Notes

## Budget (design §26)

| Target | Value |
|---|---|
| Frame rate | 60 FPS preferred, 30 FPS fallback |
| Working memory | < 250 MB |
| Textures | No huge textures; atlases when real art lands |
| Effects | No shaders, no post-processing, limited particles |

## Measured: desktop, software renderer (NOT the device)

Captured with the in-game overlay during the automated playthrough. The renderer was Mesa llvmpipe (CPU rasterizer) under Xvfb with vsync off. Treat these as relative numbers only.

| Metric | Lounge | FlowSort | Title |
|---|---|---|---|
| Frame time (avg) | 4–5 ms | — | 2.7 ms |
| Update CPU | 0.04 ms | — | — |
| Draw submit CPU | 0.4–1.1 ms | — | 0.25 ms |
| Draw calls | 26–60 | — | 14 |
| Lua heap | ~4 MB | — | ~4.5 MB |
| Texture memory | 2.4 MB | — | 2.4 MB |

**Read:** CPU work per frame is tiny. Update + draw submission is ~1 ms on x86. Even at a pessimistic 10× slowdown on a Cortex-A35 that's ~10 ms, inside the 16.7 ms budget. The GPU side (Mali-G31 fill rate) can **only** be confirmed on hardware.

## Design choices that keep it cheap

| Choice | Why |
|---|---|
| **Native 640×480 draws straight to the backbuffer** | No offscreen canvas or extra full-screen blit on device. Desktop windows of other sizes go through one scaled canvas |
| **Static room baked to a canvas** | Floor, walls, pad and processor are one draw call. Re-baked only at milestones (the "room heals" effect) |
| **Sprites baked once** | Character-grid art is baked into nearest-filtered images at first use (`src/entities/sprite.lua`) |
| **Lighting = one 128×128 gradient image + 4 rects** | No shaders or stencil buffer |
| **No particle systems** | Aura, sparks and trails are a handful of rectangles; the Loop trail is a 12-entry ring buffer |
| **dt clamped to 1/20 s** | A hitch can't tunnel collisions (unit test enforces step < thinnest solid) |
| **Procedural audio** | ~1.5 s of PCM generated at boot, no audio files. Fails silently without a device |
| **Unused LÖVE modules disabled** | physics, video, touch, thread |
| **Small world** | ~10 entities in the room; nothing simulates off-screen |

## How to profile on the R36S

1. Install the PortMaster package and launch.
2. Press **R3** (or Pause → Perf Overlay) for FPS, avg/max frame ms, update/draw ms, Lua KB, texture MB, draw calls and state.
3. Things to check:
   - Lounge with the Loop Glitch active (worst case: most entities + scan lines + lighting)
   - FlowSort play (full-screen redraw, scanlines)
   - FPS stays ≥ 55 and frame max < 25 ms (no GC spikes)
4. `ports/bitlings/log.txt` captures stdout/stderr from each run.

## If the device misses 60 FPS

Cheapest fixes first:
1. Drop the FlowSort scanline loop (120 thin rects) to every 8 px.
2. Halve aura particles (3 → 2 idle).
3. Bake the Loop path dashes once per seal instead of per frame.
4. Swap `love.graphics.printf` for pre-rendered `Text` objects in the HUD.
