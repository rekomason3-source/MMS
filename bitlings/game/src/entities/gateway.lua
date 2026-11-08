-- Gateway: broken -> (Loop broken) dormant -> active (restored) -> open.

local C = require("src.data.config")
local UI = require("src.ui.ui")

local Gateway = {}
Gateway.__index = Gateway

function Gateway.new(rect, mode)
  return setmetatable({
    x = rect.x, y = rect.y, w = rect.w, h = rect.h,
    mode = mode or "broken", t = 0, flicker = 0, open_t = 0,
  }, Gateway)
end

function Gateway:point() return self.x - 18, self.y + self.h / 2 + 10 end
function Gateway:sort_y() return self.y + self.h end
function Gateway:set_mode(m) self.mode = m; if m == "open" then self.open_t = 0 end end
function Gateway:reset_pulse() self.flicker = 0.4 end

function Gateway:update(dt)
  self.t = self.t + dt
  if self.flicker > 0 then self.flicker = self.flicker - dt end
  if self.mode == "open" then self.open_t = math.min(1, self.open_t + dt * 0.8) end
end

function Gateway:draw()
  local lg = love.graphics
  local x, y, w, h = self.x, self.y, self.w, self.h
  local frame = C.colors.dim
  if self.mode == "active" or self.mode == "open" then frame = C.colors.cyan end
  if self.flicker > 0 then frame = C.colors.glitch end
  -- inner field
  local ix, iy, iw, ih = x + 10, y + 12, w - 20, h - 20
  if self.mode == "open" then
    for i = 0, 5 do
      local p = (self.t * 0.8 + i / 6) % 1
      UI.setColor(i % 2 == 0 and C.colors.cyan or C.colors.violet, (1 - p) * 0.7 * self.open_t)
      lg.rectangle("fill", ix + iw / 2 - p * iw / 2, iy + ih / 2 - p * ih / 2, p * iw, p * ih)
    end
  elseif self.mode == "active" then
    UI.setColor(C.colors.cyan, 0.12 + 0.06 * math.sin(self.t * 3))
    lg.rectangle("fill", ix, iy, iw, ih)
  else
    UI.setColor(C.colors.bg)
    lg.rectangle("fill", ix, iy, iw, ih)
    if math.floor(self.t * 5) % 7 == 0 then
      UI.setColor(C.colors.glitch, 0.4)
      lg.rectangle("fill", ix, iy + (self.t * 40) % ih, iw, 3)
    end
  end
  -- arch frame
  UI.setColor(C.colors.outline)
  lg.rectangle("fill", x, y, 10, h)
  lg.rectangle("fill", x + w - 10, y, 10, h)
  lg.rectangle("fill", x, y, w, 12)
  UI.setColor(frame)
  lg.rectangle("fill", x + 2, y + 2, 6, h - 4)
  lg.rectangle("fill", x + w - 8, y + 2, 6, h - 4)
  lg.rectangle("fill", x + 2, y + 2, w - 4, 8)
  -- broken segments
  if self.mode == "broken" or self.mode == "dormant" then
    UI.setColor(C.colors.bg)
    lg.rectangle("fill", x + 2, y + 34, 6, 10)
    lg.rectangle("fill", x + w - 8, y + 60, 6, 14)
    lg.rectangle("fill", x + 18, y + 2, 10, 8)
  end
  -- glyph lights
  local lit = (self.mode == "active" or self.mode == "open") and 3 or (self.mode == "dormant" and 1 or 0)
  for i = 0, 2 do
    UI.setColor(i < lit and C.colors.green or C.colors.outline)
    lg.rectangle("fill", x + 12 + i * 9, y + 4, 5, 4)
  end
end

return Gateway
