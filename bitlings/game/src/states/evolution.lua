-- Evolution sequence: data converges, core flashes, Sparkbit becomes its
-- new form. Identity and memories carry over (design §14).

local C = require("src.data.config")
local K = require("src.data.content")
local Growth = require("src.systems.growth")
local Input = require("src.input.input")
local UI = require("src.ui.ui")
local Sfx = require("src.core.sfx")
local SM = require("src.core.state")
local Sparkbit = require("src.entities.sparkbit")

local Evolution = {}
Evolution.__index = Evolution
Evolution.name = "evolution"

function Evolution.new(game, on_done)
  local self = setmetatable({ game = game, data = game.data, on_done = on_done, t = 0, phase = "charge" }, Evolution)
  local st = Growth.evolution_status(game.data)
  self.target = st.form
  self.type = st.type
  self.old_name = game.data.companion.name
  self.spark = Sparkbit.new(320, 300)
  self.spark.scale = 6
  self.spark:set_appearance(Growth.appearance(game.data))
  self.spark:set_state("focus", 999)
  Sfx.play("seal")
  return self
end

function Evolution:update(dt)
  self.t = self.t + dt
  self.spark:update(dt, 0, 0, nil)
  self.spark.x, self.spark.y = 320, 300
  if self.phase == "charge" and self.t > 2.6 then
    self.phase = "flash"
    Sfx.play("level")
    local ok = Growth.evolve(self.data)
    assert(ok, "evolution was not ready")
    local f = K.FORMS[self.target]
    table.insert(self.data.memories, {
      id = "evolved_" .. self.target, title = "Evolution",
      text = self.old_name .. " became " .. f.name .. ".", level = self.data.companion.level, at = os.time(),
    })
    self.spark:set_appearance(Growth.appearance(self.data))
    self.spark:set_state("celebrate", 999)
    self.game.save()
  elseif self.phase == "flash" and self.t > 3.2 then
    self.phase = "reveal"
  elseif self.phase == "reveal" and self.t > 4.0 and Input.pressed("confirm") then
    Sfx.play("confirm")
    SM.pop()
    if self.on_done then self.on_done(self.target) end
  end
end

function Evolution:draw()
  local lg = love.graphics
  lg.clear(0, 0, 0, 1)
  local col = C.hex(K.TYPE_COLOR[self.type] or "5fe3ff")
  -- converging data
  if self.phase == "charge" then
    for i = 1, 40 do
      local a = i / 40 * math.pi * 2 + self.t
      local r = 260 * (1 - ((self.t * 0.6 + i / 40) % 1))
      UI.setColor(col, 0.8)
      lg.rectangle("fill", 320 + math.cos(a) * r, 260 + math.sin(a) * r * 0.8, 5, 5)
    end
    UI.setColor(col, 0.15 + 0.15 * math.sin(self.t * 10))
    lg.circle("fill", 320, 260, 60 + self.t * 20)
  end
  self.spark:draw()
  if self.phase == "flash" then
    lg.setColor(1, 1, 1, math.max(0, 1 - (self.t - 2.6) / 0.6))
    lg.rectangle("fill", 0, 0, C.WIDTH, C.HEIGHT)
  end
  if self.phase == "charge" then
    UI.text("...something is changing.", 0, 400, C.colors.dim, UI.font, "center", C.WIDTH)
  elseif self.phase == "reveal" then
    local f = K.FORMS[self.target]
    UI.text(self.old_name .. " evolved into", 0, 60, C.colors.text, UI.font, "center", C.WIDTH)
    UI.text(f.name:upper(), 0, 84, col, UI.font_title, "center", C.WIDTH)
    UI.text(f.desc, 0, 380, C.colors.text, UI.font, "center", C.WIDTH)
    UI.text("New skill: " .. K.SKILLS[f.signature].name, 0, 406, col, UI.font_small, "center", C.WIDTH)
    if self.t > 4.0 then UI.prompts({ { "confirm", "Continue" } }, C.WIDTH - 20, C.HEIGHT - 30, true) end
  end
end

return Evolution
