-- Game context: owns the save data, canvas scaling, global overlays and the
-- state stack. States receive this table and read/write `Game.data`.

local C = require("src.data.config")
local Input = require("src.input.input")
local SM = require("src.core.state")
local UI = require("src.ui.ui")
local Perf = require("src.ui.perf")
local Save = require("src.save.save")
local Sfx = require("src.core.sfx")

local Game = {
  data = nil,
  has_save = false,
  time = 0,
  scale = 1, ox = 0, oy = 0,
  toasts = {},
  autosave_t = 0,
}

function Game.load()
  love.graphics.setDefaultFilter("nearest", "nearest")
  love.graphics.setLineStyle("rough")
  UI.init()
  Sfx.init()
  Game.canvas = love.graphics.newCanvas(C.WIDTH, C.HEIGHT)
  Game.resize(love.graphics.getDimensions())

  local data, err, kind = Save.load()
  Game.load_note = nil
  if data then
    Game.data, Game.has_save = data, true
    if kind == "backup" then Game.load_note = err end
  else
    Game.data, Game.has_save = Save.new_default(), false
    if kind == "newer" then
      Save.read_only = true
      Game.load_note = "Save is from a newer build. Saving disabled."
    elseif kind == "corrupt" then
      Game.load_note = "Save unreadable (" .. tostring(err) .. "). Starting fresh."
    end
  end
  Game.apply_settings()
  if #Input.gamepads() > 0 then Input.last_device = "gamepad" end

  if os.getenv("BITLINGS_AUTOTEST") == "1" then
    Game.autotest = require("src.dev.autotest").new(Game)
  end

  SM.switch(require("src.states.boot").new(Game))
end

function Game.apply_settings()
  local s = Game.data.settings
  Perf.enabled = s.perf_overlay == true
  Input.swap_ab = s.swap_ab == true
  Sfx.muted = s.sfx == false
end

function Game.save()
  local ok, err = Save.write(Game.data)
  if ok then Game.has_save = true
  elseif not Save.read_only then Game.toast("Save failed: " .. tostring(err), C.colors.glitch) end
  return ok, err
end

function Game.new_game()
  Save.read_only = false
  Game.data = Save.new_default()
  Game.apply_settings()
  Game.save()
end

function Game.start_lounge(new)
  if new then Game.new_game() end
  SM.switch(require("src.states.lounge").new(Game))
end

function Game.to_title()
  Game.save()
  SM.switch(require("src.states.boot").new(Game, true))
end

function Game.toast(text, color)
  table.insert(Game.toasts, { text = text, color = color or C.colors.cyan, t = 2.2 })
end

function Game.update(dt)
  dt = math.min(dt, 1 / 20)
  Game.time = Game.time + dt
  local t0 = love.timer.getTime()
  Perf.frame(dt)

  if Game.autotest then Game.autotest:update(dt) end
  Input.update(dt)

  if Input.pressed("debug") then
    Perf.enabled = not Perf.enabled
    Game.data.settings.perf_overlay = Perf.enabled
  end
  -- Device hotkey: Select + Start saves and exits cleanly.
  if Input.down("map") and Input.down("pause") then
    Game.save()
    love.event.quit()
    return
  end

  SM.update(dt)

  local top = SM.top()
  if top and top.gameplay then
    Game.data.player.playtime = (Game.data.player.playtime or 0) + dt
    Game.autosave_t = Game.autosave_t + dt
    if Game.autosave_t >= C.timing.autosave then
      Game.autosave_t = 0
      Game.save()
    end
  end

  for i = #Game.toasts, 1, -1 do
    local t = Game.toasts[i]
    t.t = t.t - dt
    if t.t <= 0 then table.remove(Game.toasts, i) end
  end
  Perf.update_ms = (love.timer.getTime() - t0) * 1000
end

local function draw_scene()
  love.graphics.clear(C.colors.bg)
  local t0 = love.timer.getTime()
  SM.draw()
  for i, t in ipairs(Game.toasts) do
    local a = math.min(1, t.t * 3)
    local w = UI.font:getWidth(t.text) + 24
    local x, y = (C.WIDTH - w) / 2, 66 + (i - 1) * 30
    UI.panel(x, y, w, 26, t.color, a)
    UI.text(t.text, x, y + 4, { 1, 1, 1, a }, UI.font, "center", w)
  end
  Perf.draw_ms = (love.timer.getTime() - t0) * 1000
  if Perf.enabled then
    local top = SM.top()
    Perf.draw(SM.name(), top and top.entity_count and top:entity_count() or 0)
  end
end

function Game.draw()
  local w, h = love.graphics.getDimensions()
  if w == C.WIDTH and h == C.HEIGHT then
    -- Native 640x480 (R36S): draw straight to the backbuffer, no extra blit.
    draw_scene()
  else
    love.graphics.setCanvas(Game.canvas)
    draw_scene()
    love.graphics.setCanvas()
    love.graphics.clear(0, 0, 0, 1)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(Game.canvas, Game.ox, Game.oy, 0, Game.scale, Game.scale)
  end
end

function Game.resize(w, h)
  local s = math.min(w / C.WIDTH, h / C.HEIGHT)
  if s >= 1 then s = math.floor(s) end
  Game.scale = s
  Game.ox = math.floor((w - C.WIDTH * s) / 2)
  Game.oy = math.floor((h - C.HEIGHT * s) / 2)
end

function Game.joystickadded() Input.last_device = "gamepad" end

function Game.keypressed(k)
  -- Desktop convenience only; the device uses the window size it boots with.
  if k == "f11" then love.window.setFullscreen(not love.window.getFullscreen()) end
end

function Game.quit()
  local top = SM.top()
  if top and top.gameplay and not Save.read_only then Game.save() end
  return false
end

return Game
