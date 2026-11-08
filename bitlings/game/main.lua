-- Bitlings: First Spark — entry point
-- All logic lives in src/; this file only forwards LÖVE callbacks.

local Game = require("src.core.game")

function love.load(args) Game.load(args) end
-- BITLINGS_SPEED=n runs n simulation steps per frame (tests only).
local SPEED = tonumber(os.getenv("BITLINGS_SPEED") or "1") or 1
function love.update(dt)
  for _ = 1, SPEED do Game.update(dt) end
end
function love.draw() Game.draw() end
function love.resize(w, h) Game.resize(w, h) end
function love.joystickadded(j) Game.joystickadded(j) end
function love.keypressed(k) Game.keypressed(k) end
function love.quit() return Game.quit() end
