-- First Node / Lounge layout (640x480). Coordinates are canvas pixels.
-- Entities use feet-anchored positions (x = center, y = bottom).

return {
  bounds = { x = 32, y = 72, w = 576, h = 360 }, -- walkable interior

  spawn = { x = 104, y = 262 },                  -- asleep on the pad
  sleep_pad = { x = 72, y = 232, w = 64, h = 40 },

  terminal = { x = 288, y = 80, w = 64, h = 48 },
  gateway = { x = 552, y = 196, w = 48, h = 100 },
  processor = { x = 56, y = 356, w = 64, h = 48 },

  obstacles = {
    { x = 196, y = 280, w = 40, h = 40, kind = "crate" },
    { x = 404, y = 104, w = 36, h = 56, kind = "pillar" },
    { x = 404, y = 380, w = 56, h = 32, kind = "crate" },
  },

  fragments = {
    { id = "f1", x = 216, y = 180 },
    { id = "f2", x = 528, y = 416 },               -- corner, behind the crate
    { id = "f3", x = 156, y = 420, hidden = true },-- revealed by Curiosity
  },

  -- Loop Glitch circuit (travel order 1 -> 2 -> 3 -> 4 -> 1)
  loop_nodes = {
    { x = 340, y = 214 },
    { x = 480, y = 204 },
    { x = 484, y = 336 },
    { x = 336, y = 344 },
  },

  -- Decorative spots for the first Lounge improvement
  improvements = {
    cushion   = { x = 104, y = 252 },
    workbench = { x = 150, y = 130 },
    shelf     = { x = 220, y = 96 },
  },
}
