-- Shared UI primitives: fonts, panels, text, bars and button glyphs.
-- Console UI rules: large text, visible glyphs, clear focus outlines.

local C = require("src.data.config")
local Input = require("src.input.input")

local UI = {}

function UI.init()
  UI.font_small = love.graphics.newFont(13)
  UI.font = love.graphics.newFont(16)
  UI.font_big = love.graphics.newFont(24)
  UI.font_title = love.graphics.newFont(52)
  love.graphics.setFont(UI.font)
end

local GLYPH_COLORS = {
  A = C.colors.green, B = C.colors.pink, X = C.colors.cyan, Y = C.colors.amber,
}

function UI.setColor(c, a)
  love.graphics.setColor(c[1], c[2], c[3], (c[4] or 1) * (a or 1))
end

function UI.panel(x, y, w, h, edge, alpha)
  alpha = alpha or 1
  UI.setColor(C.colors.panel, alpha)
  love.graphics.rectangle("fill", x, y, w, h, 6, 6)
  UI.setColor(edge or C.colors.panel_edge, 0.85 * alpha)
  love.graphics.setLineWidth(2)
  love.graphics.rectangle("line", x + 1, y + 1, w - 2, h - 2, 6, 6)
  love.graphics.setLineWidth(1)
end

-- Text with a 1px drop shadow. align/width optional (printf when width given).
function UI.text(str, x, y, color, font, align, width)
  font = font or UI.font
  love.graphics.setFont(font)
  local a = (color and color[4]) or 1
  love.graphics.setColor(0, 0, 0, 0.6 * a)
  if width then
    love.graphics.printf(str, math.floor(x + 1), math.floor(y + 1), width, align or "left")
  else
    love.graphics.print(str, math.floor(x + 1), math.floor(y + 1))
  end
  UI.setColor(color or C.colors.text)
  if width then
    love.graphics.printf(str, math.floor(x), math.floor(y), width, align or "left")
  else
    love.graphics.print(str, math.floor(x), math.floor(y))
  end
end

function UI.bar(x, y, w, h, frac, color, bg)
  UI.setColor(bg or C.colors.outline)
  love.graphics.rectangle("fill", x, y, w, h, 2, 2)
  if frac > 0 then
    UI.setColor(color or C.colors.cyan)
    love.graphics.rectangle("fill", x, y, math.max(2, w * math.min(1, frac)), h, 2, 2)
  end
end

-- Draws a button glyph for an ACTION (label follows device + A/B swap).
-- Returns its width.
function UI.glyph(action, x, y)
  local label = Input.label(action)
  local f = UI.font_small
  love.graphics.setFont(f)
  local col = GLYPH_COLORS[label] or C.colors.dim
  if #label == 1 then
    UI.setColor(col)
    love.graphics.circle("fill", x + 9, y + 9, 9)
    UI.setColor(C.colors.outline)
    love.graphics.print(label, math.floor(x + 9 - f:getWidth(label) / 2), math.floor(y + 9 - f:getHeight() / 2))
    return 18
  end
  local w = f:getWidth(label) + 12
  UI.setColor(col)
  love.graphics.rectangle("fill", x, y + 1, w, 16, 8, 8)
  UI.setColor(C.colors.outline)
  love.graphics.print(label, math.floor(x + 6), math.floor(y + 9 - f:getHeight() / 2))
  return w
end

-- prompts = { {action, "text"}, ... }. Returns total width.
function UI.prompts_width(prompts)
  local w = 0
  local f = UI.font_small
  for _, p in ipairs(prompts) do
    local label = Input.label(p[1])
    local gw = #label == 1 and 18 or (f:getWidth(label) + 12)
    w = w + gw + 5 + f:getWidth(p[2]) + 14
  end
  return math.max(0, w - 14)
end

function UI.prompts(prompts, x, y, align_right)
  if align_right then x = x - UI.prompts_width(prompts) end
  for _, p in ipairs(prompts) do
    local gw = UI.glyph(p[1], x, y)
    x = x + gw + 5
    UI.text(p[2], x, y + 1, C.colors.text, UI.font_small)
    x = x + UI.font_small:getWidth(p[2]) + 14
  end
end

-- Pixel heart (used by pet emotes and affinity readouts).
function UI.heart(x, y, s, color)
  UI.setColor(color or C.colors.pink)
  local rows = { ".xx.xx.", "xxxxxxx", "xxxxxxx", ".xxxxx.", "..xxx..", "...x..." }
  for ry, row in ipairs(rows) do
    for rx = 1, #row do
      if row:sub(rx, rx) == "x" then
        love.graphics.rectangle("fill", x + (rx - 1) * s, y + (ry - 1) * s, s, s)
      end
    end
  end
end

-- Focus outline for the selected menu item / card.
function UI.focus(x, y, w, h, t)
  local pulse = 0.6 + 0.4 * math.sin((t or 0) * 6)
  UI.setColor(C.colors.cyan, pulse)
  love.graphics.setLineWidth(2)
  love.graphics.rectangle("line", x, y, w, h, 6, 6)
  love.graphics.setLineWidth(1)
end

return UI
