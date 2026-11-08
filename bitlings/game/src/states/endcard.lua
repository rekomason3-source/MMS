-- FIRST SPARK end card: chapter recap of what this save became.

local C = require("src.data.config")
local U = require("src.core.util")
local UI = require("src.ui.ui")
local Input = require("src.input.input")
local Sfx = require("src.core.sfx")
local SM = require("src.core.state")
local Sparkbit = require("src.entities.sparkbit")

local Endcard = {}
Endcard.__index = Endcard
Endcard.name = "endcard"

local TITLE = "FIRST SPARK"
local NAMES = { cushion = "Core Nest Cushion", workbench = "Forge Workbench", shelf = "Archive Shelf" }

function Endcard.new(game, on_close, opts)
  opts = opts or {}
  local self = setmetatable({ game = game, on_close = on_close, t = 0 }, Endcard)
  self.title = opts.title or TITLE
  self.subtitle = opts.subtitle or "Chapter 0 complete"
  self.next = opts.next or "Next: Chapter 1 - Signals"
  self.memory = opts.memory or "First Spark"
  self.spark = Sparkbit.new(C.WIDTH / 2, 250)
  self.spark:set_state("celebrate", 999)
  self.spark:set_appearance(require("src.systems.growth").appearance(game.data))
  local traits = {}
  for k, v in pairs(game.data.traits) do if v > 0 then traits[#traits + 1] = { k, v } end end
  table.sort(traits, function(a, b) return a[2] > b[2] or (a[2] == b[2] and a[1] < b[1]) end)
  self.traits = traits
  Sfx.play("level")
  return self
end

function Endcard:update(dt)
  self.t = self.t + dt
  self.spark:update(dt, 0, 0, nil)
  if self.t > 1.5 and Input.pressed("confirm") then
    Sfx.play("confirm")
    SM.pop()
    if self.on_close then self.on_close() end
  end
end

function Endcard:draw()
  local lg = love.graphics
  lg.clear(0, 0, 0, 1)
  for i = 1, 40 do
    local x = (i * 151) % C.WIDTH
    local y = (i * 89 + self.t * (10 + i % 7 * 6)) % C.HEIGHT
    UI.setColor(i % 2 == 0 and C.colors.cyan or C.colors.violet, 0.3)
    lg.rectangle("fill", math.floor(x), math.floor(C.HEIGHT - y), 2, 2)
  end
  local n = math.min(#self.title, math.floor(self.t * 10))
  lg.setFont(UI.font_title)
  local shown = self.title:sub(1, n)
  UI.setColor(C.colors.cyan, 0.35)
  lg.printf(shown, 0, 74, C.WIDTH, "center")
  UI.setColor(C.colors.white)
  lg.printf(shown, 0, 70, C.WIDTH, "center")
  if self.t < 1.0 then return end

  UI.text(self.subtitle, 0, 136, C.colors.cyan, UI.font, "center", C.WIDTH)
  self.spark:draw()
  local d = self.game.data
  local rows = {
    { "Time", U.format_time(d.player.playtime) },
    { "Sparkbit", string.format("Lv %d  (%d XP to next)", d.companion.level, C.xp_to_next(d.companion.level) - d.companion.xp) },
    { "Bond", tostring(d.relationship.affinity) },
    { "Improvement", NAMES[d.progress.improvement] or "-" },
    { "Memory", self.memory },
  }
  local top = {}
  for i = 1, math.min(3, #self.traits) do top[#top + 1] = self.traits[i][1] end
  rows[#rows + 1] = { "Leaning", #top > 0 and table.concat(top, ", ") or "-" }
  UI.panel(150, 276, 340, 24 + #rows * 22, C.colors.violet)
  for i, r in ipairs(rows) do
    local y = 288 + (i - 1) * 22
    UI.text(r[1], 168, y, C.colors.dim, UI.font_small)
    UI.text(r[2], 270, y, C.colors.text, UI.font_small)
  end
  UI.text(self.next, 0, 438, C.colors.dim, UI.font_small, "center", C.WIDTH)
  if self.t > 1.5 then UI.prompts({ { "confirm", "Continue" } }, C.WIDTH - 20, C.HEIGHT - 28, true) end
end

return Endcard
