-- Expedition regions beyond the Lounge gateway.
-- Each screen is one 640x480 room. Exits connect screens; enemies patrol
-- paths (and some chase). Caches are one-time rewards. Hidden things are
-- revealed by Sparkbit's Curiosity passive or the FlowSort scan.

return {
  signals = {
    name = "Signals", chapter = 1,
    start = { screen = "fields", x = 96, y = 262 },
    screens = {
      fields = {
        title = "Signal Fields",
        floor = { "112634", "132c3c" }, accent = "5fe3ff",
        obstacles = {
          { x = 196, y = 112, w = 36, h = 52, kind = "pylon" },
          { x = 328, y = 292, w = 56, h = 32, kind = "crate" },
          { x = 470, y = 140, w = 36, h = 52, kind = "pylon" },
        },
        exits = { { side = "right", a = 210, b = 310, to = "marsh", sx = 72, sy = 262 } },
        home = { x = 62, y = 262 },
        enemies = {
          { id = "noise_mote", path = { { 300, 200 }, { 420, 236 } } },
          { id = "noise_mote", path = { { 230, 392 }, { 380, 404 } } },
          { id = "drift_wisp", path = { { 548, 372 }, { 548, 200 } } },
        },
        caches = { { id = "cache_fields", x = 572, y = 104, bits = 15, card = "heal" } },
      },
      marsh = {
        title = "Static Marsh",
        floor = { "1c1734", "221c40" }, accent = "9b7bff",
        obstacles = {
          { x = 150, y = 140, w = 48, h = 48, kind = "crate" },
          { x = 300, y = 246, w = 40, h = 80, kind = "pylon" },
          { x = 452, y = 332, w = 60, h = 32, kind = "crate" },
        },
        exits = {
          { side = "left", a = 210, b = 310, to = "fields", sx = 568, sy = 262 },
          { side = "top", a = 270, b = 370, to = "tower", sx = 320, sy = 404 },
        },
        enemies = {
          { id = "fragment_crab", path = { { 200, 330 }, { 250, 410 } } },
          { id = "mimic_node", path = { { 430, 150 }, { 548, 150 } } },
          { id = "noise_mote", path = { { 380, 410 }, { 560, 420 } } },
        },
        caches = { { id = "cache_marsh", x = 84, y = 414, bits = 25, card = "energy", hidden = true } },
        friend = { id = "purrbit", x = 566, y = 262, hidden = true },
      },
      tower = {
        title = "Relay Tower",
        floor = { "28101f", "2e1426" }, accent = "ff3d7f",
        obstacles = {
          { x = 120, y = 140, w = 36, h = 56, kind = "pylon" },
          { x = 484, y = 140, w = 36, h = 56, kind = "pylon" },
          { x = 120, y = 320, w = 36, h = 56, kind = "pylon" },
          { x = 484, y = 320, w = 36, h = 56, kind = "pylon" },
        },
        exits = { { side = "bottom", a = 270, b = 370, to = "marsh", sx = 320, sy = 116 } },
        boss = { id = "corruptor", x = 320, y = 236 },
        cage = { x = 300, y = 96, w = 40, h = 36 },
      },
    },
  },
}
