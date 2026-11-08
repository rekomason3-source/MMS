-- Bitlings: First Spark — entry point
-- All logic lives in src/; this file only forwards LÖVE callbacks.

local Game = require("src.core.game")

function love.load(args) Game.load(args) end
function love.update(dt) Game.update(dt) end
function love.draw() Game.draw() end
function love.resize(w, h) Game.resize(w, h) end
function love.joystickadded(j) Game.joystickadded(j) end
function love.keypressed(k) Game.keypressed(k) end
function love.quit() return Game.quit() end
