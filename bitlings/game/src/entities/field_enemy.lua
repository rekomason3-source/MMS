-- Overworld Glitch: patrols a path; chasers home in when Sparkbit is near.
-- Touching it starts a battle. No random encounters: everything is visible.

local C = require("src.data.config")
local K = require("src.data.content")
local U = require("src.core.util")
local UI = require("src.ui.ui")
local Sprite = require("src.entities.sprite")

local FE = {}
FE.__index = FE

FE.PATROL_SPEED, FE.CHASE_SPEED, FE.CHASE_R = 40, 62, 110

function FE.new(def, key)
  local E = K.ENEMIES[def.id]
  local p1 = def.path[1]
  return setmetatable({
    id = def.id, E = E, key = key, path = def.path, seg = 2,
    x = p1[1], y = p1[2], t = math.random() * 6, boss = def.boss,
  }, FE)
end

function FE:update(dt, spark)
  self.t = self.t + dt
  if self.boss or not self.path then return end
  local tx, ty
  if self.E.chase and spark and U.dist(self.x, self.y, spark.x, spark.y) < FE.CHASE_R then
    tx, ty = spark.x, spark.y
    local d = U.dist(self.x, self.y, tx, ty)
    if d > 1 then
      self.x = self.x + (tx - self.x) / d * FE.CHASE_SPEED * dt
      self.y = self.y + (ty - self.y) / d * FE.CHASE_SPEED * dt
    end
    return
  end
  local p = self.path[self.seg]
  tx, ty = p[1], p[2]
  local d = U.dist(self.x, self.y, tx, ty)
  local step = FE.PATROL_SPEED * dt
  if d <= step then
    self.x, self.y = tx, ty
    self.seg = self.seg % #self.path + 1
  else
    self.x = self.x + (tx - self.x) / d * step
    self.y = self.y + (ty - self.y) / d * step
  end
end

function FE:draw()
  local lg = love.graphics
  local img = Sprite.get(self.E.sprite)
  local sc = self.boss and 5 or 3
  local w, h = img:getWidth() * sc, img:getHeight() * sc
  local bob = math.sin(self.t * 3) * 3
  UI.setColor(C.colors.outline, 0.5)
  lg.ellipse("fill", self.x, self.y, w * 0.35, 5)
  lg.setColor(1, 1, 1, 1)
  lg.draw(img, math.floor(self.x - w / 2), math.floor(self.y - h - 4 + bob), 0, sc, sc)
end

function FE:draw_scan(alpha)
  local col = C.hex(K.TYPE_COLOR[self.E.type])
  UI.setColor(col, alpha)
  love.graphics.rectangle("line", self.x - 22, self.y - 50, 44, 50)
  UI.text(K.TYPE_NAME[self.E.type], self.x - 40, self.y - 70, { col[1], col[2], col[3], alpha }, UI.font_small, "center", 80)
end

return FE
