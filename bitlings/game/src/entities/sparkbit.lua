-- Sparkbit: starter / profiler / generalist. The hero the player directly moves.
-- Brief states: idle, move, curious, happy, pet, sorting, building, focus,
-- hurt, celebrate (+ sleep for the opening).
--
-- Visual constants: soft rounded white body, big eyes, floating limbs,
-- blue scarf, digital crest, pixel aura, pink blush.

local C = require("src.data.config")
local U = require("src.core.util")
local UI = require("src.ui.ui")
local Sprite = require("src.entities.sprite")

local Sparkbit = {}
Sparkbit.__index = Sparkbit

local S = 3 -- pixel scale (16px art -> 48px on screen)

-- Faces right. Eyes and blush are drawn procedurally on top.
Sprite.define("sparkbit", {
  ".......vv.......",
  "......vccv......",
  "....oooccooo....",
  "...owwwwwwwwo...",
  "..owwwwwwwwwwo..",
  "..owwwwwwwwwwo..",
  ".owwwwwwwwwwwwo.",
  ".owwwwwwwwwwwwo.",
  ".owwwwwwwwwwwwo.",
  ".owlwwwwwwwwlwo.",
  "..owwwwwwwwwwo..",
  "..osSSSSSSSSso..",
  ".Sossssssssssso.",
  "SS.owwwwwwwwo...",
  "....oowwwwoo....",
  "......oooo......",
}, {
  o = C.colors.outline, w = C.colors.white, c = C.colors.cyan, v = C.colors.violet,
  l = C.hex("d6e4ff"), s = C.hex("2a62e0"), S = C.hex("4f8cff"),
})

Sparkbit.STATES = {
  idle = true, move = true, curious = true, happy = true, pet = true,
  sorting = true, building = true, focus = true, hurt = true,
  celebrate = true, sleep = true,
}
local TIMED = { curious = 1.2, happy = 0.9, pet = 1.3, hurt = 0.6, celebrate = 2.2 }
local CONTROLLABLE = { idle = true, move = true, curious = true }

function Sparkbit.new(x, y)
  local self = setmetatable({}, Sparkbit)
  self.x, self.y = x, y
  self.w, self.h = 26, 14
  self.vx, self.vy = 0, 0
  self.facing = 1
  self.state, self.state_t, self.state_dur = "sleep", 0, nil
  self.t = 0
  self.idle_t = 0
  self.blink_t, self.blink = 2.5, 0
  self.look = 0
  self.invuln = 0
  self.emote, self.emote_t = nil, 0
  self.max_energy = C.player.max_energy
  self.energy = self.max_energy
  return self
end

function Sparkbit:set_state(s, dur)
  assert(Sparkbit.STATES[s], "unknown sparkbit state " .. tostring(s))
  if self.state ~= s then self.state_t = 0 end
  self.state = s
  self.state_dur = dur or TIMED[s]
  if s ~= "idle" then self.idle_t = 0 end
end

function Sparkbit:say(emote, dur) self.emote, self.emote_t = emote, dur or 1.2 end

function Sparkbit:controllable() return CONTROLLABLE[self.state] == true end

function Sparkbit:hurt(from_x, from_y)
  if self.invuln > 0 then return false end
  local dx, dy = self.x - from_x, self.y - from_y
  local d = math.sqrt(dx * dx + dy * dy)
  if d < 0.001 then dx, dy, d = -1, 0, 1 end
  self.vx, self.vy = dx / d * 300, dy / d * 300
  self.energy = math.max(0, self.energy - 1)
  self.invuln = 1.4
  self:set_state("hurt")
  return true
end

-- mx, my: movement intent in [-1, 1]. room: object with :move(e, dx, dy).
function Sparkbit:update(dt, mx, my, room)
  self.t = self.t + dt
  self.state_t = self.state_t + dt
  if self.invuln > 0 then self.invuln = self.invuln - dt end
  if self.emote then
    self.emote_t = self.emote_t - dt
    if self.emote_t <= 0 then self.emote = nil end
  end

  if self.blink > 0 then self.blink = self.blink - dt end
  self.blink_t = self.blink_t - dt
  if self.blink_t <= 0 then
    self.blink = 0.12
    self.blink_t = 2 + love.math.random() * 3
  end

  if self.state_dur and self.state_t >= self.state_dur then self:set_state("idle") end

  local tx, ty = 0, 0
  if self:controllable() then tx, ty = mx * C.player.speed, my * C.player.speed end
  if self.state == "hurt" then
    self.vx = U.approach(self.vx, 0, 900 * dt)
    self.vy = U.approach(self.vy, 0, 900 * dt)
  else
    local a = C.player.accel * dt
    self.vx = U.approach(self.vx, tx, a)
    self.vy = U.approach(self.vy, ty, a)
  end
  if room and (self.vx ~= 0 or self.vy ~= 0) then
    room:move(self, self.vx * dt, self.vy * dt)
  end
  if self:controllable() and math.abs(mx) > 0.2 then self.facing = mx > 0 and 1 or -1 end

  local moving = (mx ~= 0 or my ~= 0) and (math.abs(self.vx) + math.abs(self.vy)) > 15
  if self.state == "idle" or self.state == "move" then
    if moving then
      self.state = "move"
      self.idle_t = 0
    else
      if self.state == "move" then self.state, self.state_t = "idle", 0 end
      self.idle_t = self.idle_t + dt
    end
  end

  -- Idle life: occasional glances after a few seconds of stillness.
  if self.state == "idle" and self.idle_t > 4 then
    local s = math.sin(self.idle_t * 0.9)
    self.look = s > 0.4 and 1 or (s < -0.4 and -1 or 0)
  else
    self.look = 0
  end
end

local function eyes_for(self)
  local st = self.state
  if st == "sleep" then return "closed" end
  if st == "happy" or st == "pet" or st == "celebrate" then return "happy" end
  if st == "hurt" then return "hurt" end
  if st == "focus" or st == "sorting" or st == "building" then return "focus" end
  if st == "curious" then return "wide" end
  if self.blink > 0 then return "closed" end
  return "open"
end

-- Draws the face in sprite-local pixel space (1 unit = 1 art pixel).
function Sparkbit:draw_face(eyes, look)
  local lg = love.graphics
  local dark = C.colors.outline
  local q = 1 / S -- one screen pixel
  for _, bx in ipairs({ 5, 10 }) do
    local x, y = bx + (look or 0) * 2 * q, 6
    if eyes == "open" or eyes == "wide" then
      UI.setColor(dark)
      lg.rectangle("fill", x, y, 2, 3)
      UI.setColor(C.colors.white)
      lg.rectangle("fill", x + 1, y, 2 * q, 2 * q)
      if eyes == "wide" then
        UI.setColor(C.colors.cyan)
        lg.rectangle("fill", x, y + 3 - 2 * q, 2 * q, 2 * q)
      end
    elseif eyes == "closed" then
      UI.setColor(dark)
      lg.rectangle("fill", x, y + 2, 2, 2 * q)
    elseif eyes == "happy" then
      UI.setColor(dark)
      lg.rectangle("fill", x, y + 1, 2, 2 * q)
      lg.rectangle("fill", x - q, y + 1 + 2 * q, 2 * q, 2 * q)
      lg.rectangle("fill", x + 2 - q, y + 1 + 2 * q, 2 * q, 2 * q)
    elseif eyes == "focus" then
      UI.setColor(dark)
      lg.rectangle("fill", x, y + 1, 2, 2)
      UI.setColor(C.colors.cyan)
      lg.rectangle("fill", x + 1, y + 1, 2 * q, 2 * q)
    elseif eyes == "hurt" then
      UI.setColor(dark)
      for i = 0, 2 do
        lg.rectangle("fill", x + i * 2 * q, y + 1 + i * 2 * q, 2 * q, 2 * q)
        lg.rectangle("fill", x + (2 - i) * 2 * q, y + 1 + i * 2 * q, 2 * q, 2 * q)
      end
    end
  end
  if eyes == "happy" then
    UI.setColor(C.colors.pink)
    lg.rectangle("fill", 3, 9, 1.4, 1)
    lg.rectangle("fill", 11.6, 9, 1.4, 1)
    UI.setColor(dark)
    lg.rectangle("fill", 7.3, 9.4, 1.4, 1)
    UI.setColor(C.colors.pink)
    lg.rectangle("fill", 7.3 + q, 9.4 + 2 * q, 1.4 - 2 * q, q)
  elseif eyes == "hurt" then
    UI.setColor(dark)
    lg.rectangle("fill", 7, 9.6, 2, q)
  end
end

function Sparkbit:pose()
  local st, t, s = self.state, self.t, self.state_t
  local hover = -3 - math.sin(t * 3) * 2
  local sx, sy, rot, ox = 1, 1, 0, 0
  if st == "sleep" then
    hover = 0
    local b = math.sin(t * 1.6) * 0.04
    sx, sy = 1 + b, 1 - b
  elseif st == "move" then
    rot = 0.08 * self.facing
    hover = hover - math.abs(math.sin(t * 12)) * 2
  elseif st == "happy" then
    hover = -3 - math.abs(math.sin(s * 12)) * 10
  elseif st == "celebrate" then
    hover = -4 - math.abs(math.sin(s * 9)) * 16
    rot = math.sin(s * 9) * 0.15
  elseif st == "pet" then
    local w = math.sin(s * 14) * 0.06
    sx, sy = 1.06 + w, 0.94 - w
    hover = -2
  elseif st == "curious" then
    rot = 0.22 * self.facing * math.min(1, s * 6)
  elseif st == "sorting" then
    hover = -7 - math.sin(t * 20) * 1.5
  elseif st == "building" then
    rot = math.sin(s * 16) * 0.12 * self.facing
    hover = -2
  elseif st == "focus" then
    sx, sy = 0.95, 1.05
    hover = -6 - math.sin(t * 8)
  elseif st == "hurt" then
    ox = math.sin(s * 60) * 3
    sx, sy = 1.1, 0.9
  elseif st == "idle" and self.idle_t > 8 then
    rot = math.sin(self.idle_t * 0.6) * 0.14
  end
  return hover, sx, sy, rot, ox
end

function Sparkbit:draw_aura(cx, cy)
  local st = self.state
  local busy = st == "sorting" or st == "focus" or st == "celebrate"
  local n = st == "sleep" and 1 or (busy and 6 or 3)
  local spd = busy and 4 or 1.2
  for i = 1, n do
    local a = self.t * spd + i * (math.pi * 2 / n)
    local r = 26 + math.sin(self.t * 2 + i) * 3
    local px, py = cx + math.cos(a) * r, cy + math.sin(a) * r * 0.55
    local col = (i % 2 == 0) and C.colors.cyan or C.colors.violet
    UI.setColor(col, 0.35 + 0.35 * math.sin(self.t * 3 + i))
    love.graphics.rectangle("fill", math.floor(px), math.floor(py), 3, 3)
  end
end

function Sparkbit:draw()
  local lg = love.graphics
  local hover, sx, sy, rot, ox = self:pose()

  UI.setColor(C.colors.outline, 0.55)
  lg.ellipse("fill", self.x, self.y, 15 + hover * 0.3, 5)

  if self.invuln > 0 and math.floor(self.invuln * 20) % 2 == 0 then return end

  local cy = self.y + hover - 24
  self:draw_aura(self.x, cy)

  lg.push()
  lg.translate(math.floor(self.x + ox + 0.5), math.floor(self.y + hover + 0.5))
  lg.rotate(rot)
  lg.scale(S * self.facing * sx, S * sy)
  lg.translate(-8, -16)
  local lb = math.sin(self.t * 4) * 0.8
  UI.setColor(C.colors.cyan)
  lg.rectangle("fill", 0, 10 + lb, 2, 2)
  lg.rectangle("fill", 14, 10 - lb, 2, 2)
  lg.setColor(1, 1, 1, 1)
  lg.draw(Sprite.get("sparkbit"), 0, 0)
  self:draw_face(eyes_for(self), self.look)
  lg.pop()

  self:draw_work_fx(cy)
  self:draw_emote(self.y + hover - 66)
end

function Sparkbit:draw_work_fx(cy)
  local lg = love.graphics
  if self.state == "sorting" then
    for i = 0, 2 do
      local p = (self.t * 2 + i / 3) % 1
      local cols = { C.colors.amber, C.colors.violet, C.colors.cyan }
      UI.setColor(cols[i + 1], 1 - p)
      lg.rectangle("fill", self.x - 14 + i * 12, cy - 22 - p * 14, 6, 6)
    end
  elseif self.state == "building" then
    for i = 1, 3 do
      local p = (self.t * 3 + i * 0.33) % 1
      UI.setColor(C.colors.amber, 1 - p)
      lg.rectangle("fill", self.x + self.facing * (20 + p * 10), cy + 10 - p * 18 + i * 3, 2, 2)
    end
  end
end

function Sparkbit:draw_emote(y)
  if not self.emote then return end
  local lg = love.graphics
  local x = math.floor(self.x)
  local pop = math.min(1, (1.2 - math.max(0, self.emote_t - 0.0)) * 8)
  local w, h = 24, 22
  UI.setColor(C.colors.white, pop)
  lg.rectangle("fill", x - w / 2, y, w, h, 5, 5)
  lg.polygon("fill", x - 4, y + h, x + 4, y + h, x, y + h + 5)
  UI.setColor(C.colors.outline, pop)
  if self.emote == "heart" then
    UI.heart(x - 7, y + 5, 2, C.colors.pink)
  elseif self.emote == "z" then
    UI.text("z", x - w / 2, y + 1, C.colors.violet, UI.font, "center", w)
  else
    UI.text(self.emote, x - w / 2, y + 1, C.colors.outline, UI.font, "center", w)
  end
end

-- Small static portrait for HUD / menus.
function Sparkbit.draw_portrait(x, y, scale, eyes)
  local lg = love.graphics
  lg.push()
  lg.translate(x, y)
  lg.scale(scale, scale)
  lg.setColor(1, 1, 1, 1)
  lg.draw(Sprite.get("sparkbit"), 0, 0)
  Sparkbit.draw_face(nil, eyes or "open", 0)
  lg.pop()
end

return Sparkbit
