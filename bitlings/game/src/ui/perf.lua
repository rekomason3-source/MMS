-- Performance overlay (F3 / R3, or Pause > Perf Overlay).
-- Budget targets (docs/PERFORMANCE.md): 60 FPS, frame < 16.7 ms, small Lua heap.

local UI = require("src.ui.ui")
local C = require("src.data.config")

local Perf = {
  enabled = false,
  samples = {}, idx = 0, N = 120,
  update_ms = 0, draw_ms = 0,
}

function Perf.frame(dt)
  Perf.idx = Perf.idx % Perf.N + 1
  Perf.samples[Perf.idx] = dt
end

function Perf.stats()
  local sum, mx, n = 0, 0, 0
  for _, s in ipairs(Perf.samples) do
    sum = sum + s
    if s > mx then mx = s end
    n = n + 1
  end
  local avg = n > 0 and sum / n or 0
  return avg * 1000, mx * 1000
end

function Perf.draw(state_name, entities)
  local avg, mx = Perf.stats()
  local gs = love.graphics.getStats()
  local lines = {
    string.format("FPS   %d", love.timer.getFPS()),
    string.format("frame %.1f ms (max %.1f)", avg, mx),
    string.format("upd   %.2f ms  draw %.2f ms", Perf.update_ms, Perf.draw_ms),
    string.format("lua   %.0f KB", collectgarbage("count")),
    string.format("tex   %.1f MB", gs.texturememory / 1048576),
    string.format("draws %d (batched %d)", gs.drawcalls, gs.drawcallsbatched or 0),
    string.format("state %s  ents %d", state_name, entities or 0),
  }
  local w, h = 196, 8 + #lines * 15
  local x, y = C.WIDTH - w - 6, 60
  love.graphics.setColor(0, 0, 0, 0.72)
  love.graphics.rectangle("fill", x, y, w, h, 4, 4)
  love.graphics.setFont(UI.font_small)
  for i, l in ipairs(lines) do
    local col = C.colors.green
    if i == 1 and love.timer.getFPS() < 55 then col = C.colors.amber end
    if i == 1 and love.timer.getFPS() < 30 then col = C.colors.glitch end
    UI.setColor(col)
    love.graphics.print(l, x + 8, y + 4 + (i - 1) * 15)
  end
end

return Perf
