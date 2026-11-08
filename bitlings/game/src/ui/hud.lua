-- In-world HUD: portrait, level/XP, HP, hunger, Core pips (Loop encounter),
-- resources, objective strip.

local C = require("src.data.config")
local UI = require("src.ui.ui")
local Growth = require("src.systems.growth")
local Sparkbit = require("src.entities.sparkbit")

local Hud = {}

-- opts: { core = bool (show Core pips), frags = bool (show fragment count) }
function Hud.draw(data, spark, objective, prompts, t, opts)
  opts = opts or {}
  local lg = love.graphics
  local c = data.companion
  UI.panel(8, 8, 224, 56)
  UI.setColor(C.colors.bg)
  lg.rectangle("fill", 14, 13, 42, 46, 4, 4)
  Sparkbit.draw_portrait(19, 16, 2, spark.state == "hurt" and "hurt" or (spark.state == "sleep" and "closed" or "open"), spark.app)
  UI.text(c.name, 64, 11, C.colors.text, UI.font)
  UI.text("Lv " .. c.level, 176, 12, C.colors.cyan, UI.font_small, "right", 48)
  UI.bar(64, 32, 158, 4, c.xp / Growth.xp_to_next(c.level), C.colors.cyan)
  if opts.core then
    for i = 1, spark.max_energy do
      local x, y = 68 + (i - 1) * 16, 48
      UI.setColor(i <= spark.energy and C.colors.violet or C.colors.outline)
      lg.polygon("fill", x, y - 5, x + 5, y, x, y + 5, x - 5, y)
    end
    UI.text("CORE", 152, 41, C.colors.dim, UI.font_small)
  else
    local hpmax = Growth.stats(data).hp_max
    local hp = math.min(c.hp or hpmax, hpmax)
    UI.bar(64, 42, 110, 6, hp / hpmax, hp / hpmax > 0.3 and C.colors.green or C.colors.glitch)
    UI.text("HP", 178, 37, C.colors.dim, UI.font_small)
  end
  -- hunger chip
  if data.progress.loop_broken then
    local h = data.care.hunger / 100
    UI.setColor(C.colors.outline)
    lg.rectangle("fill", 202, 38, 22, 20, 3, 3)
    UI.setColor(h < 0.3 and C.colors.glitch or C.colors.amber, h < 0.3 and (0.5 + 0.5 * math.sin(t * 8)) or 1)
    lg.rectangle("fill", 205, 41 + 14 * (1 - h), 16, 14 * h + 0.5)
  end

  local r = data.settlement.resources
  UI.panel(C.WIDTH - 184, 8, 176, 56)
  UI.setColor(C.colors.amber)
  lg.rectangle("fill", C.WIDTH - 172, 18, 8, 8)
  UI.text("Bits " .. r.bits, C.WIDTH - 158, 13, C.colors.text, UI.font_small)
  if opts.frags then
    local frag = 0
    for _ in pairs(data.progress.fragments) do frag = frag + 1 end
    UI.setColor(C.colors.cyan)
    lg.polygon("fill", C.WIDTH - 168, 36, C.WIDTH - 164, 40, C.WIDTH - 168, 44, C.WIDTH - 172, 40)
    UI.text("Frag " .. frag .. "/3", C.WIDTH - 158, 33, C.colors.text, UI.font_small)
  else
    local cards = 0
    for _, n in pairs(data.cards) do cards = cards + n end
    UI.setColor(C.colors.cyan)
    lg.rectangle("fill", C.WIDTH - 172, 37, 8, 10, 1, 1)
    UI.text("Patch " .. cards, C.WIDTH - 158, 33, C.colors.text, UI.font_small)
  end
  UI.setColor(C.colors.violet)
  lg.rectangle("fill", C.WIDTH - 88, 18, 7, 7)
  UI.text("Shard " .. r.core_shards, C.WIDTH - 76, 13, C.colors.text, UI.font_small)
  UI.heart(C.WIDTH - 89, 36, 1.3, C.colors.pink)
  UI.text("Bond " .. data.relationship.affinity, C.WIDTH - 76, 33, C.colors.text, UI.font_small)

  if objective then
    UI.panel(8, C.HEIGHT - 38, C.WIDTH - 16, 30)
    UI.setColor(C.colors.amber, 0.7 + 0.3 * math.sin(t * 3))
    lg.rectangle("fill", 18, C.HEIGHT - 27, 8, 8)
    UI.text(objective, 34, C.HEIGHT - 32, C.colors.text, UI.font)
    if prompts then UI.prompts(prompts, C.WIDTH - 18, C.HEIGHT - 32, true) end
  end
end

return Hud
