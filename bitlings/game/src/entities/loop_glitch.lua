-- Loop Glitch: a broken pattern that circles anchor nodes and resets the
-- gateway every lap. Break the causal sequence by sealing nodes; each seal
-- shortens the loop and speeds it up. At 3 seals the loop cannot close.

local C = require("src.data.config")
local U = require("src.core.util")
local UI = require("src.ui.ui")

local Loop = {}
Loop.__index = Loop

function Loop.new(node_defs)
  local nodes = {}
  for i, n in ipairs(node_defs) do
    nodes[i] = { x = n.x, y = n.y, sealed = false, seal_t = 0, flash = 0 }
  end
  local self = setmetatable({
    nodes = nodes, from = 1, target = 2,
    x = nodes[1].x, y = nodes[1].y,
    t = 0, trail = {}, trail_t = 0, laps = 0,
    dying = false, die_t = 0, dead = false, pulse = 0,
    on_lap = nil, wait = 0,
  }, Loop)
  return self
end

function Loop:sealed_count()
  local n = 0
  for _, nd in ipairs(self.nodes) do if nd.sealed then n = n + 1 end end
  return n
end

function Loop:speed()
  return C.glitch.speed * (1 + C.glitch.speed_per_seal * self:sealed_count())
end

-- Next unsealed node after index i in loop order (may return i itself).
function Loop:next_unsealed(i)
  local n = #self.nodes
  for k = 1, n do
    local j = (i + k - 1) % n + 1
    if not self.nodes[j].sealed then return j end
  end
  return nil
end

-- The next `count` node indices the glitch will visit (Pattern Echo preview).
function Loop:forecast(count)
  local out, i = {}, self.target
  for _ = 1, count do
    if not i then break end
    out[#out + 1] = i
    i = self:next_unsealed(i)
  end
  return out
end

function Loop:seal(i)
  local nd = self.nodes[i]
  if nd.sealed then return end
  nd.sealed, nd.flash = true, 0.6
  if self.target == i then self.target = self:next_unsealed(i) end
end

function Loop:reset_seals()
  for _, nd in ipairs(self.nodes) do nd.sealed, nd.seal_t = false, 0 end
  self.target = self:next_unsealed(self.from) or 1
end

function Loop:die() self.dying, self.die_t = true, 0 end

function Loop:update(dt)
  self.t = self.t + dt
  if self.pulse > 0 then self.pulse = self.pulse - dt end
  for _, nd in ipairs(self.nodes) do if nd.flash > 0 then nd.flash = nd.flash - dt end end
  if self.dying then
    self.die_t = self.die_t + dt
    if self.die_t > 1.0 then self.dead = true end
    return
  end
  -- trail ring buffer (cheap "echo" of the repeating path)
  self.trail_t = self.trail_t + dt
  if self.trail_t > 0.05 then
    self.trail_t = 0
    table.insert(self.trail, 1, { x = self.x, y = self.y })
    if #self.trail > 12 then self.trail[#self.trail] = nil end
  end
  if self.wait > 0 then self.wait = self.wait - dt return end
  if not self.target then return end
  local tn = self.nodes[self.target]
  local d = U.dist(self.x, self.y, tn.x, tn.y)
  local step = self:speed() * dt
  if d <= step then
    self.x, self.y = tn.x, tn.y
    if self.target <= self.from then
      self.laps = self.laps + 1
      self.pulse = 0.5
      if self.on_lap then self.on_lap(self) end
    end
    self.from = self.target
    self.wait = C.glitch.node_pause
    self.target = self:next_unsealed(self.target)
    if self.target == self.from then self.target = nil end
  else
    self.x = self.x + (tn.x - self.x) / d * step
    self.y = self.y + (tn.y - self.y) / d * step
  end
end

function Loop:draw_nodes(active_seal)
  local lg = love.graphics
  local n = #self.nodes
  -- loop path between unsealed nodes
  if not self.dying then
    local order = {}
    for i = 1, n do if not self.nodes[i].sealed then order[#order + 1] = self.nodes[i] end end
    UI.setColor(C.colors.glitch, 0.25)
    for i = 1, #order do
      local a, b = order[i], order[i % #order + 1]
      if #order > 1 then
        local segs = math.floor(U.dist(a.x, a.y, b.x, b.y) / 12)
        for s = 0, segs - 1, 2 do
          local p0, p1 = s / segs, math.min(1, (s + 1) / segs)
          lg.line(a.x + (b.x - a.x) * p0, a.y + (b.y - a.y) * p0, a.x + (b.x - a.x) * p1, a.y + (b.y - a.y) * p1)
        end
      end
    end
  end
  for i, nd in ipairs(self.nodes) do
    local x, y = nd.x, nd.y
    if nd.sealed then
      UI.setColor(C.colors.cyan, 0.9)
      lg.polygon("fill", x - 16, y, x - 8, y - 9, x + 8, y - 9, x + 16, y, x + 8, y + 9, x - 8, y + 9)
      UI.setColor(C.colors.white)
      lg.rectangle("fill", x - 4, y - 3, 8, 6)
      if nd.flash > 0 then
        UI.setColor(C.colors.white, nd.flash)
        lg.circle("line", x, y, 18 + (0.6 - nd.flash) * 40)
      end
    else
      local pulse = 0.5 + 0.5 * math.sin(self.t * 4 + i)
      UI.setColor(C.colors.glitch, 0.35 + 0.3 * pulse)
      lg.setLineWidth(2)
      lg.polygon("line", x - 16, y, x - 8, y - 9, x + 8, y - 9, x + 16, y, x + 8, y + 9, x - 8, y + 9)
      lg.setLineWidth(1)
      if active_seal == i and nd.seal_t > 0 then
        local frac = nd.seal_t / C.timing.seal
        UI.setColor(C.colors.cyan)
        lg.setLineWidth(3)
        lg.arc("line", "open", x, y, 20, -math.pi / 2, -math.pi / 2 + frac * math.pi * 2, 24)
        lg.setLineWidth(1)
      end
    end
  end
end

function Loop:draw()
  local lg = love.graphics
  if self.dead then return end
  if self.dying then
    local p = self.die_t
    for i = 0, 11 do
      local a = i / 12 * math.pi * 2
      UI.setColor(i % 2 == 0 and C.colors.glitch or C.colors.white, 1 - p)
      lg.rectangle("fill", self.x + math.cos(a) * p * 60, self.y - 18 + math.sin(a) * p * 60, 5, 5)
    end
    return
  end
  for i, tp in ipairs(self.trail) do
    UI.setColor(C.colors.glitch, 0.25 * (1 - i / #self.trail))
    lg.rectangle("fill", tp.x - 8, tp.y - 26, 16, 16)
  end
  local cx, cy = self.x, self.y - 18
  UI.setColor(C.colors.outline, 0.5)
  lg.ellipse("fill", self.x, self.y, 12, 4)
  lg.push()
  lg.translate(cx, cy)
  lg.rotate(self.t * 2.5)
  UI.setColor(C.colors.glitch)
  lg.rectangle("fill", -11, -11, 22, 22)
  UI.setColor(C.colors.outline)
  lg.rectangle("fill", -6, -6, 12, 12)
  lg.pop()
  -- jitter pixels
  for i = 1, 5 do
    local jx = math.sin(self.t * 13 + i * 2.1) * 16
    local jy = math.cos(self.t * 11 + i * 1.3) * 14
    UI.setColor(i % 2 == 0 and C.colors.white or C.colors.glitch, 0.8)
    lg.rectangle("fill", math.floor(cx + jx), math.floor(cy + jy), 3, 3)
  end
  -- looping "eye"
  UI.setColor(C.colors.white)
  local ea = self.t * 6
  lg.rectangle("fill", cx + math.cos(ea) * 3 - 2, cy + math.sin(ea) * 3 - 2, 4, 4)
  if self.pulse > 0 then
    UI.setColor(C.colors.glitch, self.pulse * 1.5)
    lg.circle("line", cx, cy, 20 + (0.5 - self.pulse) * 80)
  end
end

return Loop
