-- Pause menu (Start). Controller-navigable settings + save/quit.

local C = require("src.data.config")
local UI = require("src.ui.ui")
local Input = require("src.input.input")
local Sfx = require("src.core.sfx")
local SM = require("src.core.state")
local Perf = require("src.ui.perf")

local Pause = {}
Pause.__index = Pause
Pause.name = "pause"
Pause.transparent = true

function Pause.new(game, under)
  local self = setmetatable({ game = game, under = under, sel = 1, t = 0, confirm_quit = false }, Pause)
  self.items = {
    { id = "resume", label = function() return "Resume" end },
    { id = "objectives", label = function() return "Objectives & Status" end },
    { id = "perf", label = function() return "Perf Overlay: " .. (Perf.enabled and "ON" or "OFF") end },
    { id = "swap", label = function() return "Swap A/B: " .. (Input.swap_ab and "ON" or "OFF") end },
    { id = "sfx", label = function() return "Sound: " .. (game.data.settings.sfx == false and "OFF" or "ON") end },
    { id = "save", label = function() return "Save Game" end },
    { id = "title", label = function() return "Save & Return to Title" end },
    { id = "quit", label = function() return "Save & Quit" end },
  }
  return self
end

function Pause:update(dt)
  self.t = self.t + dt
  local n = #self.items
  if Input.pressed("pause") or Input.pressed("cancel") then SM.pop() return end
  if Input.repeat_pressed("up") then self.sel = (self.sel - 2) % n + 1; Sfx.play("blip") end
  if Input.repeat_pressed("down") then self.sel = self.sel % n + 1; Sfx.play("blip") end
  if not Input.pressed("confirm") then return end
  local id = self.items[self.sel].id
  local s = self.game.data.settings
  Sfx.play("confirm")
  if id == "resume" then
    SM.pop()
  elseif id == "objectives" then
    SM.pop()
    if self.under then self.under.show_objectives = true end
  elseif id == "perf" then
    Perf.enabled = not Perf.enabled
    s.perf_overlay = Perf.enabled
  elseif id == "swap" then
    s.swap_ab = not s.swap_ab
    Input.swap_ab = s.swap_ab
    Input.flush() -- the held button must not fire its new meaning
  elseif id == "sfx" then
    s.sfx = s.sfx == false
    self.game.apply_settings()
  elseif id == "save" then
    if self.under and self.under.save then self.under:save() else self.game.save() end
    self.game.toast("Saved")
  elseif id == "title" then
    if self.under and self.under.save then self.under:save() end
    self.game.to_title()
  elseif id == "quit" then
    if self.under and self.under.save then self.under:save() else self.game.save() end
    love.event.quit()
  end
end

function Pause:draw()
  local lg = love.graphics
  UI.setColor(C.colors.bg, 0.75)
  lg.rectangle("fill", 0, 0, C.WIDTH, C.HEIGHT)
  local w, h = 320, 92 + #self.items * 34
  local x, y = (C.WIDTH - w) / 2, (C.HEIGHT - h) / 2
  UI.panel(x, y, w, h, C.colors.cyan)
  UI.text("PAUSED", x, y + 12, C.colors.cyan, UI.font_big, "center", w)
  for i, it in ipairs(self.items) do
    local iy = y + 50 + (i - 1) * 34
    local sel = i == self.sel
    UI.text(it.label(), x, iy + 4, sel and C.colors.white or C.colors.dim, UI.font, "center", w)
    if sel then UI.focus(x + 20, iy, w - 40, 28, self.t) end
  end
  UI.prompts({ { "confirm", "Select" }, { "cancel", "Back" } }, x + w - 16, y + h - 30, true)
end

return Pause
