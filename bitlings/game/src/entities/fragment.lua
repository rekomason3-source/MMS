-- Data fragment pickup. Hidden fragments stay invisible until Sparkbit's
-- Curiosity passive reveals them (proximity) or a FlowSort scan marks them.

local C = require("src.data.config")
local UI = require("src.ui.ui")

local Fragment = {}
Fragment.__index = Fragment

Fragment.REVEAL_RADIUS = 96
Fragment.PICKUP_RADIUS = 24

function Fragment.new(def)
  return setmetatable({
    id = def.id, x = def.x, y = def.y,
    hidden = def.hidden == true, revealed = not def.hidden,
    t = math.random() * 6, reveal_t = 0,
  }, Fragment)
end

function Fragment:update(dt)
  self.t = self.t + dt
  if self.revealed and self.reveal_t < 1 then self.reveal_t = math.min(1, self.reveal_t + dt * 2) end
end

function Fragment:draw()
  if not self.revealed then return end
  local lg = love.graphics
  local a = self.hidden and self.reveal_t or 1
  local bob = math.sin(self.t * 3) * 3
  local cx, cy = self.x, self.y - 14 + bob
  UI.setColor(C.colors.outline, 0.5 * a)
  lg.ellipse("fill", self.x, self.y, 8, 3)
  -- glow
  UI.setColor(C.colors.cyan, (0.18 + 0.1 * math.sin(self.t * 5)) * a)
  lg.circle("fill", cx, cy, 14)
  -- diamond
  UI.setColor(C.colors.cyan, a)
  lg.polygon("fill", cx, cy - 9, cx + 7, cy, cx, cy + 9, cx - 7, cy)
  UI.setColor(C.colors.white, a)
  lg.polygon("fill", cx, cy - 5, cx + 3, cy, cx, cy + 2, cx - 3, cy)
  UI.setColor(C.colors.violet, a)
  lg.rectangle("fill", cx + 6, cy - 10 + math.sin(self.t * 4) * 2, 2, 2)
end

-- Scan marker for not-yet-revealed fragments.
function Fragment:draw_hint(alpha)
  local lg = love.graphics
  UI.setColor(C.colors.violet, alpha)
  lg.setLineWidth(2)
  lg.circle("line", self.x, self.y - 12, 12 + math.sin(self.t * 6) * 2)
  lg.setLineWidth(1)
  UI.text("?", self.x - 10, self.y - 22, { C.colors.violet[1], C.colors.violet[2], C.colors.violet[3], alpha }, UI.font, "center", 20)
end

return Fragment
