-- First Lounge improvement: an explicit player choice that pushes traits.

local C = require("src.data.config")
local UI = require("src.ui.ui")
local Input = require("src.input.input")
local Sfx = require("src.core.sfx")
local SM = require("src.core.state")
local Sparkbit = require("src.entities.sparkbit")

local Choice = {}
Choice.__index = Choice
Choice.name = "choice"
Choice.transparent = true
Choice.gameplay = true

Choice.OPTIONS = {
  {
    id = "cushion", name = "Core Nest Cushion", building = "core_nest", color = C.colors.pink,
    desc = "A soft place to recharge. Resting restores twice the Core.",
    traits = { recovery = 3, social = 1 },
  },
  {
    id = "workbench", name = "Forge Workbench", building = "forge_node", color = C.colors.amber,
    desc = "Tools for tinkering. Sparkbit starts leaning toward building.",
    traits = { build = 3, creativity = 1 },
  },
  {
    id = "shelf", name = "Archive Shelf", building = "archive_hall", color = C.colors.violet,
    desc = "Somewhere to keep what we learn. Feeds curiosity.",
    traits = { knowledge = 3, curiosity = 1 },
  },
}

function Choice.new(game, on_choose)
  local self = setmetatable({ game = game, on_choose = on_choose, sel = 1, t = 0 }, Choice)
  self.spark = Sparkbit.new(320, 440)
  self.spark:set_state("curious", 999)
  return self
end

function Choice:update(dt)
  self.t = self.t + dt
  self.spark:update(dt, 0, 0, nil)
  self.spark.facing = self.sel == 1 and -1 or 1
  local n = #Choice.OPTIONS
  if Input.repeat_pressed("left") then self.sel = (self.sel - 2) % n + 1; Sfx.play("blip") end
  if Input.repeat_pressed("right") then self.sel = self.sel % n + 1; Sfx.play("blip") end
  if Input.pressed("confirm") and self.t > 0.3 then
    Sfx.play("confirm")
    local opt = Choice.OPTIONS[self.sel]
    SM.pop()
    if self.on_choose then self.on_choose(opt) end
  end
end

function Choice:draw()
  local lg = love.graphics
  UI.setColor(C.colors.bg, 0.85)
  lg.rectangle("fill", 0, 0, C.WIDTH, C.HEIGHT)
  UI.text("Choose your first Lounge improvement", 0, 64, C.colors.cyan, UI.font_big, "center", C.WIDTH)
  UI.text("This shapes what Sparkbit becomes.", 0, 98, C.colors.dim, UI.font_small, "center", C.WIDTH)
  for i, o in ipairs(Choice.OPTIONS) do
    local x, y, w, h = 30 + (i - 1) * 200, 130, 180, 230
    local sel = i == self.sel
    if sel then y = y - 6 end
    UI.panel(x, y, w, h, sel and o.color or C.colors.dim)
    -- icon
    UI.setColor(o.color, sel and 1 or 0.6)
    lg.rectangle("fill", x + w / 2 - 22, y + 18, 44, 44, 8, 8)
    UI.setColor(C.colors.outline)
    lg.rectangle("fill", x + w / 2 - 10, y + 30, 20, 20, 3, 3)
    UI.text(o.name, x + 8, y + 72, sel and C.colors.white or C.colors.text, UI.font, "center", w - 16)
    UI.text(o.desc, x + 12, y + 118, C.colors.dim, UI.font_small, "center", w - 24)
    local ty = y + h - 46
    for k, v in pairs(o.traits) do
      UI.text("+" .. v .. " " .. k:sub(1, 1):upper() .. k:sub(2), x + 8, ty, o.color, UI.font_small, "center", w - 16)
      ty = ty + 18
    end
    if sel then UI.focus(x - 3, y - 3, w + 6, h + 6, self.t) end
  end
  self.spark:draw()
  UI.prompts({ { "confirm", "Choose" } }, C.WIDTH - 20, C.HEIGHT - 30, true)
end

return Choice
