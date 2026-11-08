-- Upload Station: the repaired terminal becomes the Lounge's control hub.
-- Tabs (L1/R1 or Left/Right):
--   STATUS  stats, absorbed data, care, evolution readiness (+ Evolve)
--   SKILLS  upload skills with banked data; equip up to 4
--   ASPECTS buy/install passive modules (2 slots); change scarf
--   CARE    feed (snacks, data treats that steer evolution), buy Patch Cards
--   BITDEX  every Glitch and Bitling you've met

local C = require("src.data.config")
local K = require("src.data.content")
local Growth = require("src.systems.growth")
local Input = require("src.input.input")
local UI = require("src.ui.ui")
local Sfx = require("src.core.sfx")
local SM = require("src.core.state")
local Sprite = require("src.entities.sprite")
local Sparkbit = require("src.entities.sparkbit")

local Station = {}
Station.__index = Station
Station.name = "station"

Station.TABS = { "STATUS", "SKILLS", "ASPECTS", "CARE", "BITDEX" }

function Station.new(game, on_close)
  require("src.states.battle").define_sprites()
  local self = setmetatable({ game = game, data = game.data, on_close = on_close, t = 0, tab = 1, sel = 1 }, Station)
  self.preview = Sparkbit.new(116, 236)
  self.preview.scale = 5
  self.preview:set_state("idle")
  self:refresh()
  return self
end

function Station:refresh()
  self.preview:set_appearance(Growth.appearance(self.data))
end

function Station:say(text, ok)
  self.msg = { text = text, color = ok and C.colors.green or C.colors.glitch, t = 2.2 }
  Sfx.play(ok and "confirm" or "error")
end

function Station:rows()
  local d, rows = self.data, {}
  local tab = Station.TABS[self.tab]
  if tab == "STATUS" then
    if Growth.evolution_status(d).ready then rows[1] = { kind = "evolve" } end
  elseif tab == "SKILLS" then
    for _, id in ipairs(K.SKILL_ORDER) do
      if K.SKILLS[id].learn or Growth.is_learned(d, id) then rows[#rows + 1] = { kind = "skill", id = id } end
    end
  elseif tab == "ASPECTS" then
    for _, id in ipairs(K.ASPECT_ORDER) do rows[#rows + 1] = { kind = "aspect", id = id } end
    rows[#rows + 1] = { kind = "scarf" }
  elseif tab == "CARE" then
    for _, id in ipairs(K.FOOD_ORDER) do rows[#rows + 1] = { kind = "food", id = id } end
    for _, id in ipairs(K.CARD_ORDER) do rows[#rows + 1] = { kind = "card", id = id } end
  elseif tab == "BITDEX" then
    for _, id in ipairs(K.ENEMY_ORDER) do rows[#rows + 1] = { kind = "enemy", id = id } end
    for _, id in ipairs(K.RESIDENT_ORDER) do rows[#rows + 1] = { kind = "resident", id = id } end
  end
  return rows
end

function Station:act(row)
  local d = self.data
  local ok, msg
  if row.kind == "evolve" then
    local Evolution = require("src.states.evolution")
    SM.push(Evolution.new(self.game, function() self:refresh() end))
    return
  elseif row.kind == "skill" then
    if Growth.is_learned(d, row.id) then ok, msg = Growth.toggle_equip(d, row.id)
    else ok, msg = Growth.learn(d, row.id) end
  elseif row.kind == "aspect" then
    if d.aspects.owned[row.id] then ok, msg = Growth.toggle_aspect(d, row.id)
    else ok, msg = Growth.buy_aspect(d, row.id) end
  elseif row.kind == "scarf" then
    ok, msg = Growth.cycle_scarf(d), "Scarf changed"
  elseif row.kind == "food" then
    ok, msg = Growth.feed(d, row.id)
    if ok then self.preview:set_state("happy"); self.preview:say("heart", 1.0) end
  elseif row.kind == "card" then
    ok, msg = Growth.buy_card(d, row.id)
  else
    return
  end
  self:say(msg, ok)
  self:refresh()
end

function Station:resume() self:refresh() end

function Station:update(dt)
  self.t = self.t + dt
  self.preview:update(dt, 0, 0, nil)
  self.preview.x, self.preview.y = 116, 236
  if self.msg then
    self.msg.t = self.msg.t - dt
    if self.msg.t <= 0 then self.msg = nil end
  end
  local n = #Station.TABS
  if Input.pressed("r1") or Input.repeat_pressed("right") then self.tab = self.tab % n + 1; self.sel = 1; Sfx.play("blip") end
  if Input.pressed("l1") or Input.repeat_pressed("left") then self.tab = (self.tab - 2) % n + 1; self.sel = 1; Sfx.play("blip") end
  local rows = self:rows()
  if #rows > 0 then
    if Input.repeat_pressed("down") then self.sel = self.sel % #rows + 1; Sfx.play("blip") end
    if Input.repeat_pressed("up") then self.sel = (self.sel - 2) % #rows + 1; Sfx.play("blip") end
    self.sel = math.min(self.sel, #rows)
    if Input.pressed("confirm") then self:act(rows[self.sel]) end
  end
  if Input.pressed("cancel") then
    self.game.save()
    SM.pop()
    if self.on_close then self.on_close() end
  end
end

-- Draw ------------------------------------------------------------------------------
local function tcol(t) return C.hex(K.TYPE_COLOR[t] or "e8ecff") end

function Station:draw()
  local lg = love.graphics
  local d = self.data
  lg.clear(C.hex("07101c"))
  UI.setColor(C.colors.cyan, 0.035)
  for y = 0, C.HEIGHT, 4 do lg.rectangle("fill", 0, y, C.WIDTH, 1) end

  -- header + tabs
  UI.text("UPLOAD STATION", 16, 10, C.colors.cyan, UI.font)
  local x = 196
  UI.glyph("l1", x - 30, 11)
  for i, name in ipairs(Station.TABS) do
    local w = UI.font_small:getWidth(name) + 16
    local sel = i == self.tab
    UI.setColor(sel and C.colors.cyan or C.colors.outline)
    lg.rectangle("fill", x, 10, w, 20, 4, 4)
    UI.setColor(sel and C.colors.outline or C.colors.dim)
    lg.setFont(UI.font_small)
    lg.print(name, x + 8, 12)
    x = x + w + 6
  end
  UI.glyph("r1", x + 2, 11)

  -- left: Sparkbit preview + wallet
  UI.panel(8, 40, 208, 392)
  local form = K.FORMS[Growth.form(d)]
  UI.text(d.companion.name, 8, 52, C.colors.white, UI.font_big, "center", 208)
  UI.text(form.type == "neutral" and "Starter / Generalist" or (K.TYPE_NAME[form.type] .. " form"), 8, 80, C.colors.dim, UI.font_small, "center", 208)
  self.preview:draw()
  UI.text("Lv " .. d.companion.level, 20, 262, C.colors.cyan, UI.font)
  UI.bar(70, 268, 132, 6, d.companion.xp / Growth.xp_to_next(d.companion.level), C.colors.cyan)
  UI.text("Bits  " .. d.settlement.resources.bits, 20, 290, C.colors.amber, UI.font)
  UI.text("DATA BANK", 20, 318, C.colors.dim, UI.font_small)
  for i, t in ipairs(K.TYPES) do
    UI.setColor(tcol(t))
    lg.rectangle("fill", 22, 340 + (i - 1) * 22, 10, 10, 2, 2)
    UI.text(K.TYPE_NAME[t] .. "  " .. d.data_core.bank[t], 40, 335 + (i - 1) * 22, C.colors.text, UI.font_small)
  end
  local dom, share = Growth.dominant(d)
  if dom then UI.text("Leaning " .. K.TYPE_NAME[dom] .. " " .. math.floor(share * 100) .. "%", 20, 404, tcol(dom), UI.font_small) end

  UI.panel(224, 40, 408, 392)
  local tab = Station.TABS[self.tab]
  if tab == "STATUS" then self:draw_status() else self:draw_list(tab) end

  -- footer
  if self.msg then
    UI.text(self.msg.text, 16, 446, self.msg.color, UI.font)
  end
  UI.prompts({ { "confirm", "Select" }, { "cancel", "Back to Lounge" } }, C.WIDTH - 12, 448, true)
end

function Station:draw_status()
  local lg = love.graphics
  local d = self.data
  local st = Growth.stats(d)
  local x0, y = 240, 50
  UI.text("STATS", x0, y, C.colors.cyan, UI.font_small)
  local stats = { { "HP", st.hp_max }, { "ATK", st.atk }, { "DEF", st.def }, { "SPD", st.spd }, { "EN", st.en_max } }
  for i, s in ipairs(stats) do
    local cx = x0 + ((i - 1) % 3) * 128
    local cy = y + 18 + math.floor((i - 1) / 3) * 18
    UI.text(s[1], cx, cy, C.colors.dim, UI.font_small)
    UI.text(tostring(s[2]), cx + 40, cy, C.colors.text, UI.font_small)
  end
  y = 116
  UI.text("ABSORBED DATA (shapes looks, stats and evolution)", x0, y, C.colors.cyan, UI.font_small)
  local press, total = Growth.pressure(d)
  for i, t in ipairs(K.TYPES) do
    local yy = y + 18 + (i - 1) * 18
    UI.text(K.TYPE_NAME[t], x0, yy, tcol(t), UI.font_small)
    UI.bar(x0 + 64, yy + 4, 220, 7, total > 0 and press[t] / total or 0, tcol(t))
    UI.text(tostring(d.data_core.lifetime[t]), x0 + 296, yy, C.colors.text, UI.font_small)
  end
  y = 196
  UI.text("CARE", x0, y, C.colors.cyan, UI.font_small)
  UI.text("Hunger", x0, y + 18, C.colors.dim, UI.font_small)
  UI.bar(x0 + 64, y + 22, 120, 7, d.care.hunger / 100, d.care.hunger < 30 and C.colors.glitch or C.colors.amber)
  UI.text("Mood", x0 + 196, y + 18, C.colors.dim, UI.font_small)
  UI.bar(x0 + 240, y + 22, 120, 7, d.care.mood / 100, C.colors.pink)
  UI.text(string.format("Care quality %d   (good acts %d, mistakes %d)", Growth.care_quality(d), d.care.score, d.care.mistakes),
    x0, y + 38, C.colors.text, UI.font_small)
  y = 262
  local ev = Growth.evolution_status(d)
  UI.text("EVOLUTION", x0, y, C.colors.cyan, UI.font_small)
  if ev.evolved then
    UI.text("Evolved: " .. d.companion.name .. ". Next stage arrives in a later build.", x0, y + 20, C.colors.text, UI.font_small, "left", 380)
    return
  end
  for i, c in ipairs(ev.checks) do
    local yy = y + 18 + (i - 1) * 17
    UI.setColor(c.ok and C.colors.green or C.colors.dim)
    lg.rectangle(c.ok and "fill" or "line", x0, yy + 3, 10, 10, 2, 2)
    UI.text(c.label, x0 + 18, yy, c.ok and C.colors.text or C.colors.dim, UI.font_small)
    UI.text(c.detail, x0 + 230, yy, C.colors.dim, UI.font_small)
  end
  local fy = y + 108
  if ev.form then
    UI.text("Forecast: " .. K.FORMS[ev.form].name .. " (" .. K.FORMS[ev.form].desc .. ")", x0, fy, tcol(ev.type), UI.font_small, "left", 380)
  else
    UI.text("Forecast: absorb data to choose a direction.", x0, fy, C.colors.dim, UI.font_small)
  end
  if ev.ready then
    local sel = self.sel == 1
    UI.text("EVOLVE NOW", x0, fy + 30, C.colors.amber, UI.font_big)
    if sel then UI.focus(x0 - 6, fy + 28, 170, 32, self.t) end
  end
end

function Station:row_text(row)
  local d = self.data
  if row.kind == "skill" then
    local sk = K.SKILLS[row.id]
    local status
    if Growth.is_equipped(d, row.id) then status = "EQUIPPED"
    elseif Growth.is_learned(d, row.id) then status = "uploaded"
    else
      local parts = {}
      for k, v in pairs(sk.learn) do parts[#parts + 1] = v .. " " .. K.TYPE_NAME[k] end
      status = "upload: " .. table.concat(parts, ", ")
    end
    return sk.name .. "  " .. sk.en .. "EN", status, tcol(sk.type), sk.desc
  elseif row.kind == "aspect" then
    local a = K.ASPECTS[row.id]
    local status
    if Growth.has_aspect(d, row.id) then status = "INSTALLED"
    elseif d.aspects.owned[row.id] then status = "owned"
    elseif a.cost then status = a.cost .. " Bits"
    else status = "locked" end
    return a.name, status, C.colors.text, a.desc
  elseif row.kind == "scarf" then
    local name = d.aspects.scarf
    for _, s in ipairs(K.SCARVES) do if s.id == name then name = s.name end end
    return "Scarf color", name, C.colors.pink, "Cosmetic. A changes color."
  elseif row.kind == "food" then
    local f = K.FOODS[row.id]
    local extra = ""
    if f.data then for k, v in pairs(f.data) do extra = " +" .. v .. " " .. K.TYPE_NAME[k] .. " data" end end
    return f.name, f.cost .. " Bits", C.colors.amber, "+" .. f.hunger .. " hunger, +" .. f.mood .. " mood" .. extra .. ". Feeding when hungry raises care quality."
  elseif row.kind == "card" then
    local c = K.CARDS[row.id]
    return c.name .. "  x" .. (d.cards[row.id] or 0), c.cost .. " Bits", C.colors.cyan, c.desc
  elseif row.kind == "enemy" then
    local E = K.ENEMIES[row.id]
    if not d.bitdex.seen[row.id] then return "???", "", C.colors.outline, "Not yet encountered." end
    local status = d.bitdex.defeated[row.id] and "absorbed" or "seen"
    local desc = E.desc
    if d.bitdex.defeated[row.id] then
      local weak
      for k, v in pairs(K.BEATS) do if v == E.type then weak = k end end
      local drops = {}
      for k, v in pairs(E.data) do drops[#drops + 1] = v .. " " .. K.TYPE_NAME[k] end
      desc = desc .. "  Weak to " .. K.TYPE_NAME[weak] .. ". Drops " .. table.concat(drops, ", ") .. " data."
    end
    return E.name, status, tcol(E.type), desc, E.sprite
  elseif row.kind == "resident" then
    local R = K.RESIDENTS[row.id]
    if not d.residents[row.id] then return "???", "", C.colors.outline, "A Bitling not yet met." end
    return R.name, "resident", C.colors.green, R.desc, R.sprite
  end
end

function Station:draw_list(tab)
  local lg = love.graphics
  local d = self.data
  local rows = self:rows()
  local x0, y0 = 240, 50
  if tab == "SKILLS" then
    UI.text("Loadout " .. #d.skills.equipped .. "/" .. K.MAX_EQUIPPED .. "   (upload with banked data)", x0, y0, C.colors.cyan, UI.font_small)
  elseif tab == "ASPECTS" then
    UI.text("Installed " .. #d.aspects.equipped .. "/" .. K.MAX_ASPECTS .. "   (passive modules)", x0, y0, C.colors.cyan, UI.font_small)
  elseif tab == "CARE" then
    UI.text("Hunger", x0, y0, C.colors.dim, UI.font_small)
    UI.bar(x0 + 54, y0 + 4, 110, 7, d.care.hunger / 100, d.care.hunger < 30 and C.colors.glitch or C.colors.amber)
    UI.text("Mood", x0 + 180, y0, C.colors.dim, UI.font_small)
    UI.bar(x0 + 220, y0 + 4, 110, 7, d.care.mood / 100, C.colors.pink)
  elseif tab == "BITDEX" then
    local seen = 0
    for _ in pairs(d.bitdex.seen) do seen = seen + 1 end
    UI.text("Glitches seen " .. seen .. "/" .. #K.ENEMY_ORDER, x0, y0, C.colors.cyan, UI.font_small)
  end
  local detail, sprite
  for i, row in ipairs(rows) do
    local y = y0 + 22 + (i - 1) * 24
    local name, status, col, desc, spr = self:row_text(row)
    local sel = i == self.sel
    UI.text(name, x0, y, sel and col or C.colors.dim, UI.font_small)
    UI.text(status, x0 + 200, y, sel and C.colors.white or C.colors.dim, UI.font_small, "right", 180)
    if sel then
      UI.focus(x0 - 6, y - 2, 392, 22, self.t)
      detail, sprite = desc, spr
    end
  end
  if detail then
    local dy = 360
    UI.setColor(C.colors.outline)
    lg.rectangle("fill", 232, dy - 6, 392, 70, 4, 4)
    local tw = sprite and 300 or 376
    UI.text(detail, 240, dy, C.colors.text, UI.font_small, "left", tw)
    if sprite then
      lg.setColor(1, 1, 1, 1)
      local img = Sprite.get(sprite)
      local sc = 52 / img:getHeight()
      lg.draw(img, 560, dy - 2, 0, sc, sc)
    end
  end
end

return Station
