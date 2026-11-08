-- Boot / title. Opening per design: black screen, one pixel blinks, a
-- damaged signal appears, then the title. Any button skips to the menu.

local C = require("src.data.config")
local UI = require("src.ui.ui")
local Input = require("src.input.input")
local Sfx = require("src.core.sfx")
local Sparkbit = require("src.entities.sparkbit")

local Boot = {}
Boot.__index = Boot
Boot.name = "boot"

local SIGNAL = "> damaged signal detected . . . 1 core found"

function Boot.new(game, skip_intro)
  local self = setmetatable({ game = game, t = 0, tt = 0, phase = skip_intro and "title" or "pixel" }, Boot)
  self.spark = Sparkbit.new(C.WIDTH / 2, 262)
  self.spark:set_state(game.data.progress.awake and "idle" or "sleep")
  self:build_menu()
  return self
end

function Boot:build_menu()
  local g = self.game
  self.items = {}
  if g.has_save then self.items[#self.items + 1] = { label = "Continue", act = "continue" } end
  self.items[#self.items + 1] = { label = g.has_save and "New Core" or "Wake Sparkbit", act = "new" }
  self.items[#self.items + 1] = { label = "Controls", act = "controls" }
  self.items[#self.items + 1] = { label = "Quit", act = "quit" }
  self.menu_i, self.confirm_new, self.confirm_i, self.show_controls = 1, false, 2, false
end

function Boot:update(dt)
  self.t = self.t + dt
  self.spark:update(dt, 0, 0, nil)
  if self.phase ~= "title" then
    if Input.pressed("confirm") or Input.pressed("pause") or Input.pressed("cancel") then
      self.phase, self.tt = "title", 0
      return
    end
    if self.phase == "pixel" and self.t > 1.6 then self.phase = "signal" end
    if self.t > 3.4 then self.phase, self.tt = "title", 0 end
    return
  end
  self.tt = self.tt + dt

  if self.show_controls then
    if Input.pressed("cancel") or Input.pressed("confirm") then self.show_controls = false end
    return
  end
  if self.confirm_new then
    if Input.repeat_pressed("left") or Input.repeat_pressed("right") then
      self.confirm_i = 3 - self.confirm_i
      Sfx.play("blip")
    end
    if Input.pressed("cancel") then self.confirm_new = false end
    if Input.pressed("confirm") then
      if self.confirm_i == 1 then Sfx.play("confirm"); self.game.start_lounge(true)
      else self.confirm_new = false end
    end
    return
  end
  if Input.repeat_pressed("up") then self.menu_i = (self.menu_i - 2) % #self.items + 1; Sfx.play("blip") end
  if Input.repeat_pressed("down") then self.menu_i = self.menu_i % #self.items + 1; Sfx.play("blip") end
  if Input.pressed("confirm") then
    local act = self.items[self.menu_i].act
    Sfx.play("confirm")
    if act == "continue" then
      self.game.start_lounge(false)
    elseif act == "new" then
      if self.game.has_save then self.confirm_new, self.confirm_i = true, 2
      else self.game.start_lounge(true) end
    elseif act == "controls" then
      self.show_controls = true
    elseif act == "quit" then
      love.event.quit()
    end
  end
end

local function draw_backdrop(t)
  local lg = love.graphics
  UI.setColor(C.colors.grid, 0.35)
  for x = 0, C.WIDTH, 32 do lg.line(x, 0, x, C.HEIGHT) end
  for y = 0, C.HEIGHT, 32 do lg.line(0, y, C.WIDTH, y) end
  for i = 1, 24 do
    local x = (i * 97 + t * (8 + i % 5 * 4)) % C.WIDTH
    local y = (i * 53) % C.HEIGHT
    UI.setColor(i % 3 == 0 and C.colors.violet or C.colors.cyan, 0.25 + 0.2 * math.sin(t * 2 + i))
    lg.rectangle("fill", math.floor(x), math.floor(y), 2, 2)
  end
end

function Boot:draw()
  local lg = love.graphics
  lg.clear(0, 0, 0, 1)
  if self.phase == "pixel" then
    local on = math.floor(self.t * 3) % 2 == 0
    if on then
      UI.setColor(C.colors.cyan, math.min(1, self.t))
      lg.rectangle("fill", C.WIDTH / 2 - 2, C.HEIGHT / 2 - 2, 4, 4)
    end
    return
  elseif self.phase == "signal" then
    local p = (self.t - 1.6) / 1.8
    for i = 0, 14 do
      local y = (i * 37 + math.floor(self.t * 30) * 11) % C.HEIGHT
      UI.setColor(C.colors.cyan, 0.05 + 0.08 * love.math.noise(i, self.t * 4))
      lg.rectangle("fill", 0, y, C.WIDTH, 2 + i % 3)
    end
    local n = math.floor(#SIGNAL * math.min(1, p * 1.4))
    UI.text(SIGNAL:sub(1, n), 80, C.HEIGHT / 2 - 10, C.colors.cyan, UI.font)
    return
  end

  lg.clear(C.colors.bg)
  draw_backdrop(self.t)
  -- title with chromatic split + occasional glitch jitter
  local jit = (math.floor(self.t * 2) % 9 == 0) and math.sin(self.t * 80) * 3 or 0
  local ty = 70
  UI.setColor(C.colors.violet, 0.8)
  lg.setFont(UI.font_title)
  lg.printf("BITLINGS", -3 + jit, ty, C.WIDTH, "center")
  UI.setColor(C.colors.cyan, 0.8)
  lg.printf("BITLINGS", 3 - jit, ty, C.WIDTH, "center")
  UI.setColor(C.colors.white)
  lg.printf("BITLINGS", 0, ty, C.WIDTH, "center")
  UI.text("F I R S T   S P A R K", 0, ty + 64, C.colors.cyan, UI.font, "center", C.WIDTH)

  self.spark:draw()

  if self.show_controls then
    self:draw_controls()
  elseif self.confirm_new then
    UI.panel(150, 300, 340, 110, C.colors.amber)
    UI.text("Start a new Core?", 150, 314, C.colors.text, UI.font, "center", 340)
    UI.text("This replaces your current save.", 150, 338, C.colors.amber, UI.font_small, "center", 340)
    for i, l in ipairs({ "Yes", "No" }) do
      local bx = 190 + (i - 1) * 150
      UI.text(l, bx, 368, i == self.confirm_i and C.colors.cyan or C.colors.dim, UI.font, "center", 110)
      if i == self.confirm_i then UI.focus(bx, 364, 110, 28, self.tt) end
    end
  else
    for i, it in ipairs(self.items) do
      local y = 300 + (i - 1) * 32
      local sel = i == self.menu_i
      UI.text(it.label, 0, y, sel and C.colors.cyan or C.colors.dim, UI.font_big, "center", C.WIDTH)
      if sel then UI.focus(220, y - 2, 200, 32, self.tt) end
    end
  end

  if self.game.load_note then
    UI.text(self.game.load_note, 0, 430, C.colors.amber, UI.font_small, "center", C.WIDTH)
  end
  UI.text("v" .. C.VERSION .. "  R36S prototype", 12, C.HEIGHT - 22, C.colors.dim, UI.font_small)
  UI.prompts({ { "confirm", "Select" }, { "cancel", "Back" } }, C.WIDTH - 12, C.HEIGHT - 24, true)
end

function Boot:draw_controls()
  UI.panel(90, 150, 460, 290, C.colors.cyan)
  UI.text("Controls", 90, 160, C.colors.cyan, UI.font_big, "center", 460)
  local rows = {
    { "D-pad / L-stick", "Move Sparkbit / navigate" },
    { "A", "Interact / confirm (hold to work)" },
    { "B", "Back / discard noise (FlowSort)" },
    { "X", "FlowSort scan (highlight objectives)" },
    { "Y", "Pet Sparkbit" },
    { "Start", "Pause menu" },
    { "Select", "Objectives & status" },
    { "Select + Start", "Save and quit" },
    { "R3 / F3", "Performance overlay" },
  }
  for i, r in ipairs(rows) do
    local y = 196 + (i - 1) * 24
    UI.text(r[1], 110, y, C.colors.amber, UI.font_small)
    UI.text(r[2], 250, y, C.colors.text, UI.font_small)
  end
end

return Boot
