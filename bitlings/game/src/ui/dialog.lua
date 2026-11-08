-- Dialog queue with typewriter text. Confirm completes the line, then advances.

local C = require("src.data.config")
local UI = require("src.ui.ui")
local Sfx = require("src.core.sfx")

local Dialog = {}
Dialog.__index = Dialog

local CPS = 75 -- characters per second

function Dialog.new()
  return setmetatable({ queue = {}, cur = nil, shown = 0, on_done = nil, t = 0 }, Dialog)
end

-- lines = { {speaker_or_nil, text}, ... }
function Dialog:push(lines, on_done)
  for _, l in ipairs(lines) do table.insert(self.queue, l) end
  if on_done then
    local prev = self.on_done
    self.on_done = prev and function() prev(); on_done() end or on_done
  end
  if not self.cur then self:next() end
end

function Dialog:next()
  self.cur = table.remove(self.queue, 1)
  self.shown, self.t = 0, 0
  if not self.cur then
    local cb = self.on_done
    self.on_done = nil
    if cb then cb() end
  end
end

function Dialog:active() return self.cur ~= nil end

function Dialog:update(dt)
  if not self.cur then return end
  self.t = self.t + dt
  self.shown = math.min(#self.cur[2], self.shown + dt * CPS)
end

function Dialog:advance()
  if not self.cur then return end
  if self.shown < #self.cur[2] then
    self.shown = #self.cur[2]
  else
    Sfx.play("blip")
    self:next()
  end
end

function Dialog:draw()
  if not self.cur then return end
  local x, y, w, h = 20, 352, 600, 112
  UI.panel(x, y, w, h, self.cur[1] and C.colors.cyan or C.colors.violet)
  local tx = x + 16
  if self.cur[1] then
    UI.text(self.cur[1], tx, y + 10, C.colors.cyan, UI.font)
  end
  local text = self.cur[2]:sub(1, math.floor(self.shown))
  local ty = self.cur[1] and y + 34 or y + 18
  UI.text(text, tx, ty, self.cur[1] and C.colors.text or C.colors.violet, UI.font, "left", w - 32)
  if self.shown >= #self.cur[2] then
    local bob = math.floor(math.sin(self.t * 6) * 2)
    UI.glyph("confirm", x + w - 32, y + h - 28 + bob)
  end
end

return Dialog
