-- Broken terminal: repaired with 3 fragments, then runs FlowSort.

local C = require("src.data.config")
local UI = require("src.ui.ui")

local Terminal = {}
Terminal.__index = Terminal

function Terminal.new(rect, repaired)
  return setmetatable({
    x = rect.x, y = rect.y, w = rect.w, h = rect.h,
    repaired = repaired, t = 0, boot_t = repaired and 1 or 0,
  }, Terminal)
end

function Terminal:repair() self.repaired = true; self.boot_t = 0 end

-- Interaction point (just below the screen).
function Terminal:point() return self.x + self.w / 2, self.y + self.h + 16 end
function Terminal:sort_y() return self.y + self.h end

function Terminal:update(dt)
  self.t = self.t + dt
  if self.repaired and self.boot_t < 1 then self.boot_t = math.min(1, self.boot_t + dt) end
end

function Terminal:draw()
  local lg = love.graphics
  local x, y, w, h = self.x, self.y, self.w, self.h
  -- base / desk
  UI.setColor(C.colors.outline)
  lg.rectangle("fill", x - 2, y + h - 12, w + 4, 14, 3, 3)
  UI.setColor(C.colors.wall_top)
  lg.rectangle("fill", x, y + h - 12, w, 10, 2, 2)
  -- monitor
  UI.setColor(C.colors.outline)
  lg.rectangle("fill", x + 4, y, w - 8, h - 10, 4, 4)
  local sx, sy, sw, sh = x + 9, y + 5, w - 18, h - 22
  if self.repaired then
    UI.setColor(C.hex("0d2a3a"))
    lg.rectangle("fill", sx, sy, sw, sh)
    UI.setColor(C.colors.cyan, 0.85 * self.boot_t)
    for i = 0, 3 do
      local lw = (math.sin(self.t * 2 + i * 1.7) * 0.5 + 0.5) * (sw - 8) + 4
      lg.rectangle("fill", sx + 3, sy + 3 + i * 5, lw, 2)
    end
  else
    UI.setColor(C.hex("1b1d2e"))
    lg.rectangle("fill", sx, sy, sw, sh)
    -- crack + flicker
    if math.floor(self.t * 7) % 9 == 0 then
      UI.setColor(C.colors.glitch, 0.6)
      lg.rectangle("fill", sx + 4, sy + 6, sw - 8, 2)
    end
    UI.setColor(C.colors.dim)
    lg.line(sx + 6, sy + 2, sx + 16, sy + 12, sx + 12, sy + sh - 2)
  end
  -- status LED
  UI.setColor(self.repaired and C.colors.green or C.colors.glitch, 0.6 + 0.4 * math.sin(self.t * 4))
  lg.rectangle("fill", x + w - 14, y + h - 9, 4, 4)
end

return Terminal
