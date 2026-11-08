-- Resident / friendly Bitling: wanders gently inside a home area.

local C = require("src.data.config")
local K = require("src.data.content")
local UI = require("src.ui.ui")
local Sprite = require("src.entities.sprite")

local Npc = {}
Npc.__index = Npc

function Npc.new(id, x, y, opts)
  opts = opts or {}
  return setmetatable({
    id = id, R = K.RESIDENTS[id], x = x, y = y, hx = x, hy = y,
    tx = x, ty = y, t = math.random() * 5, wait = 1 + math.random() * 2,
    wander = opts.wander ~= false, hidden = opts.hidden == true, revealed = not opts.hidden,
    facing = 1, emote = nil, emote_t = 0,
  }, Npc)
end

function Npc:say(e, dur) self.emote, self.emote_t = e, dur or 1.2 end

function Npc:update(dt)
  self.t = self.t + dt
  if self.emote then
    self.emote_t = self.emote_t - dt
    if self.emote_t <= 0 then self.emote = nil end
  end
  if not self.wander then return end
  local dx, dy = self.tx - self.x, self.ty - self.y
  local d = math.sqrt(dx * dx + dy * dy)
  if d < 2 then
    self.wait = self.wait - dt
    if self.wait <= 0 then
      self.tx = self.hx + math.random(-50, 50)
      self.ty = self.hy + math.random(-30, 30)
      self.wait = 1.5 + math.random() * 3
    end
  else
    local s = 30 * dt
    self.x, self.y = self.x + dx / d * s, self.y + dy / d * s
    if math.abs(dx) > 1 then self.facing = dx > 0 and 1 or -1 end
  end
end

function Npc:draw()
  if not self.revealed then return end
  local lg = love.graphics
  local img = Sprite.get(self.R.sprite)
  local sc = 3
  local w, h = img:getWidth() * sc, img:getHeight() * sc
  local bob = math.abs(math.sin(self.t * 4)) * 3
  UI.setColor(C.colors.outline, 0.5)
  lg.ellipse("fill", self.x, self.y, 12, 4)
  lg.setColor(1, 1, 1, 1)
  lg.draw(img, math.floor(self.x + (self.facing < 0 and w / 2 or -w / 2)), math.floor(self.y - h - bob), 0, sc * self.facing, sc)
  if self.emote then
    local x, y = math.floor(self.x), math.floor(self.y - h - 30)
    UI.setColor(C.colors.white)
    lg.rectangle("fill", x - 12, y, 24, 22, 5, 5)
    if self.emote == "heart" then UI.heart(x - 7, y + 5, 2, C.colors.pink)
    else UI.text(self.emote, x - 12, y + 1, C.colors.outline, UI.font, "center", 24) end
  end
end

return Npc
