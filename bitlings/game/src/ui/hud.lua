-- In-room HUD: portrait, level/XP, Core energy, resources, objective strip.

local C = require("src.data.config")
local UI = require("src.ui.ui")
local Sparkbit = require("src.entities.sparkbit")

local Hud = {}

function Hud.draw(data, spark, objective, prompts, t)
  local lg = love.graphics
  local c = data.companion
  -- top-left companion panel
  UI.panel(8, 8, 224, 52)
  UI.setColor(C.colors.bg)
  lg.rectangle("fill", 14, 13, 42, 42, 4, 4)
  Sparkbit.draw_portrait(19, 14, 2, spark.state == "hurt" and "hurt" or (spark.state == "sleep" and "closed" or "open"))
  UI.text(c.name, 64, 12, C.colors.text, UI.font)
  UI.text("Lv " .. c.level, 176, 13, C.colors.cyan, UI.font_small, "right", 48)
  local need = C.xp_to_next(c.level)
  UI.bar(64, 33, 158, 6, c.xp / need, C.colors.cyan)
  for i = 1, spark.max_energy do
    local x, y = 68 + (i - 1) * 16, 48
    if i <= spark.energy then UI.setColor(C.colors.violet) else UI.setColor(C.colors.outline) end
    lg.polygon("fill", x, y - 5, x + 5, y, x, y + 5, x - 5, y)
  end
  UI.text("CORE", 152, 41, C.colors.dim, UI.font_small)

  -- top-right resources
  local r = data.settlement.resources
  UI.panel(C.WIDTH - 184, 8, 176, 52)
  local frag = 0
  for _ in pairs(data.progress.fragments) do frag = frag + 1 end
  UI.setColor(C.colors.amber)
  lg.rectangle("fill", C.WIDTH - 172, 18, 8, 8)
  UI.text("Bits " .. r.bits, C.WIDTH - 158, 13, C.colors.text, UI.font_small)
  UI.setColor(C.colors.cyan)
  lg.polygon("fill", C.WIDTH - 168, 36, C.WIDTH - 164, 40, C.WIDTH - 168, 44, C.WIDTH - 172, 40)
  UI.text("Frag " .. frag .. "/3", C.WIDTH - 158, 33, C.colors.text, UI.font_small)
  UI.setColor(C.colors.violet)
  lg.rectangle("fill", C.WIDTH - 88, 18, 7, 7)
  UI.text("Shard " .. r.core_shards, C.WIDTH - 76, 13, C.colors.text, UI.font_small)
  UI.heart(C.WIDTH - 89, 36, 1.3, C.colors.pink)
  UI.text("Bond " .. data.relationship.affinity, C.WIDTH - 76, 33, C.colors.text, UI.font_small)

  -- bottom objective strip
  if objective then
    UI.panel(8, C.HEIGHT - 38, C.WIDTH - 16, 30)
    UI.setColor(C.colors.amber, 0.7 + 0.3 * math.sin(t * 3))
    lg.rectangle("fill", 18, C.HEIGHT - 27, 8, 8)
    UI.text(objective, 34, C.HEIGHT - 32, C.colors.text, UI.font)
    if prompts then UI.prompts(prompts, C.WIDTH - 18, C.HEIGHT - 32, true) end
  end
end

return Hud
