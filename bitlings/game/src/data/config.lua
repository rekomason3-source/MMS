-- Global tuning constants. Gameplay numbers live here so balance passes
-- never require touching state/entity code.

local function hex(h, a)
  h = h:gsub("#", "")
  return {
    tonumber(h:sub(1, 2), 16) / 255,
    tonumber(h:sub(3, 4), 16) / 255,
    tonumber(h:sub(5, 6), 16) / 255,
    a or 1,
  }
end

local C = {}

C.VERSION = "0.1.0"
C.WIDTH, C.HEIGHT = 640, 480
C.hex = hex

C.colors = {
  bg         = hex("0b0d1f"),
  floor      = hex("141838"),
  floor2     = hex("181d44"),
  floor_dmg  = hex("0d1029"),
  grid       = hex("232b60"),
  wall       = hex("262b63"),
  wall_top   = hex("39418c"),
  outline    = hex("1a1c3a"),
  white      = hex("f2f6ff"),
  cyan       = hex("5fe3ff"),
  blue       = hex("2f6bff"),
  violet     = hex("9b7bff"),
  pink       = hex("ff8fb8"),
  glitch     = hex("ff3d7f"),
  amber      = hex("ffc857"),
  green      = hex("6dff9e"),
  dim        = hex("6b74b8"),
  text       = hex("e8ecff"),
  panel      = hex("0f1230", 0.94),
  panel_edge = hex("5fe3ff"),
}

C.player = {
  speed = 150,        -- px/s at full stick
  accel = 1400,       -- px/s^2 smoothing
  max_energy = 5,     -- Core energy pips
}

C.xp = {
  fragment = 10,
  discovery = 5,
  terminal = 25,
  flowsort = 30,
  flowsort_perfect = 10,
  loop = 40,
  gateway = 25,
}

function C.xp_to_next(level) return 100 * level end

C.timing = {
  repair = 2.0,          -- hold A at terminal
  seal = 1.2,            -- hold A on a Loop anchor node
  gateway = 2.0,         -- hold A at gateway
  scan_cooldown = 2.5,   -- FlowSort scan (X)
  scan_duration = 3.0,
  pet_cooldown = 8,      -- seconds between affinity gains (no spam-grinding)
  rest_cooldown = 30,
  autosave = 60,
}

C.glitch = {
  speed = 70,            -- base px/s
  speed_per_seal = 0.20, -- +20% per sealed node
  node_pause = 0.35,     -- readable "rewind tick" at every node
  hit_radius = 24,
  seals_to_break = 3,
}

return C
