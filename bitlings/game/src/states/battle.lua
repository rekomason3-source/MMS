-- Turn-based battle.
--
-- Player turn:  Strike (Sync Strike chain) | Skills | Patch (free, 1/turn) |
--               Guard | Overclock (free, when the meter is full)
-- Enemy turn:   telegraphed attack; press A on the "!" flash to Brace (-50%)
-- Win:          Sparkbit ABSORBS the foe's data (lifetime + bank), XP, Bits.
--
-- Sync Strike: the first hit always lands; then a ring closes on the foe up to
-- 3 more times. Press A as it meets the core to chain the next hit. Miss once
-- and the chain ends.

local C = require("src.data.config")
local K = require("src.data.content")
local U = require("src.core.util")
local Growth = require("src.systems.growth")
local Input = require("src.input.input")
local UI = require("src.ui.ui")
local Sfx = require("src.core.sfx")
local SM = require("src.core.state")
local Sprite = require("src.entities.sprite")
local Sparkbit = require("src.entities.sparkbit")

local Battle = {}
Battle.__index = Battle
Battle.name = "battle"
Battle.gameplay = true

local EX, EY = 470, 236          -- enemy center
local STRIKE_POWER = { 8, 6, 8, 12 }
local BEAT_DUR = { 0.6, 0.52, 0.45 }

local sprites_defined = false
local function define_sprites()
  if sprites_defined then return end
  sprites_defined = true
  for id, s in pairs(K.SPRITES) do
    local pal = {}
    for k, hex in pairs(s.pal) do pal[k] = C.hex(hex) end
    Sprite.define(id, s.rows, pal)
  end
end
Battle.define_sprites = define_sprites

function Battle.new(game, enemy_id, opts)
  define_sprites()
  local self = setmetatable({}, Battle)
  opts = opts or {}
  local E = assert(K.ENEMIES[enemy_id], "unknown enemy " .. tostring(enemy_id))
  local d = game.data
  self.game, self.data, self.opts, self.eid, self.E = game, d, opts, enemy_id, E
  self.t = 0
  self.st = Growth.stats(d)
  self.hp = U.clamp(d.companion.hp or self.st.hp_max, 1, self.st.hp_max)
  self.en = self.st.en_max
  self.meter = 0
  self.coil = Growth.has_aspect(d, "overclock_coil") and 1.5 or 1
  self.lens = Growth.has_aspect(d, "sync_lens")
  self.b = { atk_t = 0, boost_t = 0, shield_t = 0, oc_t = 0, drone_t = 0, guard = false, shield_card = false }
  self.enemy = { hp = E.hp, max = E.hp, type = E.type, vuln_t = 0, charging = nil, flash = 0, shake = 0 }
  self.spark = Sparkbit.new(170, 300)
  self.spark.scale = 4
  self.spark:set_appearance(Growth.appearance(d))
  self.spark:set_state("idle")
  self.floaters = {}
  self.particles = {}
  self.queue, self.msg, self.msg_t = {}, nil, 0
  self.menu_sel, self.sub_sel = 1, 1
  self.card_used = false
  self.turns = 0
  d.bitdex.seen[enemy_id] = true
  self.phase = "busy"
  local intro = E.boss and ("The " .. E.name .. " blocks the way!") or (E.name .. " appears!")
  local steps = { { "msg", intro, 1.1 } }
  if opts.tutorial then
    steps[#steps + 1] = { "msg", "Strike first. Then press A each time a ring closes on the foe.", 2.6 }
  end
  self:run(steps, function() self:to_menu() end)
  Sfx.play("confirm")
  return self
end

-- Sequencer -------------------------------------------------------------------
function Battle:run(steps, after)
  self.phase = "busy"
  self.queue = steps
  self.after = after
  self.msg = nil
end

function Battle:step_queue(dt)
  while #self.queue > 0 do
    local s = self.queue[1]
    if s[1] == "call" then
      table.remove(self.queue, 1)
      s[2]()
      if self.phase ~= "busy" then return end
    elseif s[1] == "msg" then
      if self.msg ~= s then self.msg, self.msg_t = s, 0 end
      self.msg_t = self.msg_t + dt
      if self.msg_t >= s[3] or (self.msg_t > 0.25 and Input.pressed("confirm")) then
        table.remove(self.queue, 1)
        dt = 0
      else
        return
      end
    elseif s[1] == "wait" then
      s[2] = s[2] - dt
      if s[2] > 0 then return end
      table.remove(self.queue, 1)
      dt = 0
    end
  end
  local a = self.after
  self.after = nil
  if a then a() end
end

-- Helpers -----------------------------------------------------------------------
function Battle:floater(text, x, y, color)
  self.floaters[#self.floaters + 1] = { text = text, x = x, y = y, t = 1.0, color = color or C.colors.white }
end

function Battle:atk_eff()
  local a = self.st.atk
  if self.b.atk_t > 0 then a = a * 1.5 end
  if self.b.boost_t > 0 then a = a * 1.5 end
  if self.b.oc_t > 0 then a = a * 1.5 end
  return a
end

function Battle:def_eff()
  return self.b.oc_t > 0 and self.st.def * 1.5 or self.st.def
end

function Battle:add_meter(n)
  if self.b.oc_t > 0 then return end
  self.meter = math.min(100, self.meter + n * self.coil)
end

-- Returns damage dealt.
function Battle:hit_enemy(power, typ)
  local e = self.enemy
  local mult = Growth.type_mult(typ or self.st.type, e.type)
  if e.vuln_t > 0 then mult = mult * 1.5 end
  local dmg = Growth.damage(power, self:atk_eff(), self.E.def, mult, love.math.random())
  e.hp = math.max(0, e.hp - dmg)
  e.flash, e.shake = 0.18, 0.2
  self:floater(tostring(dmg), EX + love.math.random(-20, 20), EY - 50, mult > 1.01 and C.colors.amber or C.colors.white)
  self:add_meter(6)
  Sfx.play("good")
  return dmg, mult
end

function Battle:menu_items()
  local items = {
    { id = "strike", label = "Strike" },
    { id = "skills", label = "Skills" },
    { id = "cards", label = "Patch" .. (self.card_used and " (used)" or "") },
    { id = "guard", label = "Guard" },
  }
  if self.meter >= 100 and self.b.oc_t == 0 then table.insert(items, 1, { id = "overclock", label = "OVERCLOCK!" }) end
  return items
end

function Battle:to_menu()
  self.phase = "menu"
  self.msg = nil
  local n = #self:menu_items()
  self.menu_sel = U.clamp(self.menu_sel, 1, n)
end

-- Player actions -----------------------------------------------------------------
function Battle:start_strike()
  self.phase = "strike"
  self.spark:set_state("sorting", 999)
  local dmg = self:hit_enemy(STRIKE_POWER[1])
  self.strike = { beat = 1, t = 0, hits = 1, total = dmg, gap = 0.18 }
end

function Battle:sync_window()
  return self.lens and 0.11 or 0.075
end

-- true when pressing A now lands the current beat (used by the autotest bot)
function Battle:in_sync_window()
  local s = self.strike
  if self.phase ~= "strike" or not s or s.gap > 0 then return false end
  local dur = BEAT_DUR[s.beat]
  return math.abs(s.t - dur) <= self:sync_window() * 0.6
end

function Battle:update_strike(dt)
  local s = self.strike
  if s.gap > 0 then
    s.gap = s.gap - dt
    return
  end
  s.t = s.t + dt
  local dur = BEAT_DUR[s.beat]
  local w = self:sync_window()
  local pressed = Input.pressed("confirm")
  if pressed and math.abs(s.t - dur) <= w then
    s.hits = s.hits + 1
    local dmg = self:hit_enemy(STRIKE_POWER[s.hits])
    s.total = s.total + dmg
    self:floater("SYNC x" .. s.hits, 170, 200, C.colors.cyan)
    if self.enemy.hp <= 0 or s.beat >= #BEAT_DUR then
      if s.hits == 4 then
        self:floater("PERFECT SYNC!", 170, 176, C.colors.amber)
        self:add_meter(15)
      end
      return self:end_strike()
    end
    s.beat, s.t, s.gap = s.beat + 1, 0, 0.14
  elseif pressed or s.t > dur + w then
    self:floater("out of sync", 170, 200, C.colors.dim)
    return self:end_strike()
  end
end

function Battle:end_strike()
  local s = self.strike
  self.strike = nil
  self.spark:set_state(s.hits >= 3 and "happy" or "idle")
  self:run({ { "msg", string.format("%d-hit Sync Strike! %d damage.", s.hits, s.total), 0.9 } },
    function() self:end_player_turn() end)
end

function Battle:use_skill(id)
  local sk = K.SKILLS[id]
  self.en = self.en - sk.en
  self.turns = self.turns + 1
  self.spark:set_state(sk.kind == "attack" and "focus" or "sorting", 0.8)
  local steps = { { "msg", "Sparkbit uses " .. sk.name .. "!", 0.7 } }
  steps[#steps + 1] = { "call", function()
    local e = self.enemy
    if sk.kind == "attack" then
      local last_mult = 1
      for _ = 1, (sk.hits or 1) do
        local _, m = self:hit_enemy(sk.power, sk.type ~= "neutral" and sk.type or nil)
        last_mult = m
      end
      if sk.meter then self:add_meter(sk.meter) end
      if last_mult > 1.01 then table.insert(self.queue, 1, { "msg", "It's strong against " .. K.TYPE_NAME[e.type] .. "!", 0.8 })
      elseif last_mult < 0.99 then table.insert(self.queue, 1, { "msg", "It's weak against " .. K.TYPE_NAME[e.type] .. "...", 0.8 }) end
    elseif sk.kind == "shield" then
      self.b.shield_t = sk.turns
      table.insert(self.queue, 1, { "msg", "A firewall goes up.", 0.7 })
    elseif sk.kind == "drone" then
      self.b.drone_t = sk.turns
      table.insert(self.queue, 1, { "msg", "A drone assembles itself!", 0.7 })
    elseif sk.kind == "buff_atk" then
      self.b.atk_t = sk.turns
      table.insert(self.queue, 1, { "msg", "Tempo rising! ATK up.", 0.7 })
    elseif sk.kind == "debuff_def" then
      e.vuln_t = sk.turns
      table.insert(self.queue, 1, { "msg", "Weak point exposed!", 0.7 })
    elseif sk.kind == "heal" then
      local n = math.floor(self.st.hp_max * sk.amount)
      self.hp = math.min(self.st.hp_max, self.hp + n)
      self:floater("+" .. n, 170, 220, C.colors.green)
    end
  end }
  self:run(steps, function() self:end_player_turn() end)
end

function Battle:use_card(id)
  self.data.cards[id] = self.data.cards[id] - 1
  self.card_used = true
  local text
  if id == "heal" then
    local n = math.floor(self.st.hp_max * 0.4)
    self.hp = math.min(self.st.hp_max, self.hp + n)
    self:floater("+" .. n, 170, 220, C.colors.green)
    text = "Heal Patch! +" .. n .. " HP"
  elseif id == "energy" then
    self.en = math.min(self.st.en_max, self.en + 6)
    text = "Charge Patch! +6 EN"
  elseif id == "boost" then
    self.b.boost_t = 2
    text = "Boost Patch! ATK up for 2 turns"
  elseif id == "shield" then
    self.b.shield_card = true
    text = "Shield Patch! The next hit is blocked"
  end
  Sfx.play("seal")
  self.spark:set_state("happy")
  self:run({ { "msg", text, 0.8 } }, function() self:to_menu() end)
end

function Battle:guard()
  self.b.guard = true
  self.en = math.min(self.st.en_max, self.en + 3)
  self:add_meter(10)
  self.spark:set_state("focus", 0.8)
  self:run({ { "msg", "Sparkbit guards. +3 EN", 0.7 } }, function() self:end_player_turn() end)
end

function Battle:overclock()
  self.b.oc_t = 3
  self.meter = 0
  self.spark.overclock = true
  self.spark:set_state("celebrate", 1.2)
  Sfx.play("level")
  self:run({ { "msg", "OVERCLOCK! Sparkbit's core burns bright. (3 turns)", 1.2 } }, function() self:to_menu() end)
end

function Battle:end_player_turn()
  if self.enemy.hp <= 0 then return self:win() end
  if self.b.drone_t > 0 then
    self:run({ { "msg", "The drone strikes!", 0.5 }, { "call", function() self:hit_enemy(9, "build") end } },
      function()
        if self.enemy.hp <= 0 then return self:win() end
        self:enemy_turn()
      end)
    return
  end
  self:enemy_turn()
end

-- Enemy turn ------------------------------------------------------------------------
function Battle:enemy_turn()
  local E, e = self.E, self.enemy
  local steps = {}
  if E.mimic then
    local t = K.TYPES[love.math.random(1, 3)]
    e.type = t
    steps[#steps + 1] = { "msg", E.name .. " shifts to " .. K.TYPE_NAME[t] .. "!", 0.7 }
  end
  local atk
  if e.charging then
    atk = e.charging
    e.charging = nil
  else
    local charge
    for _, a in ipairs(E.attacks) do if a.charge then charge = a end end
    if charge and e.hp < e.max * 0.7 and not e.charged_recently and love.math.random() < 0.5 then
      e.charging = charge
      e.charged_recently = true
      steps[#steps + 1] = { "msg", E.name .. " is charging " .. charge.name .. "! Guard!", 1.2 }
      self:run(steps, function() self:round_end() end)
      return
    end
    local pool = {}
    for _, a in ipairs(E.attacks) do if not a.charge then pool[#pool + 1] = a end end
    atk = pool[love.math.random(1, #pool)]
    e.charged_recently = false
  end
  steps[#steps + 1] = { "msg", E.name .. " uses " .. atk.name .. "!", 0.6 }
  self:run(steps, function() self:start_brace(atk) end)
end

function Battle:start_brace(atk)
  self.phase = "brace"
  self.msg = nil
  self.brace = {
    atk = atk, t = 0, flash_at = 0.35 + love.math.random() * 0.6,
    window = self.lens and 0.3 or 0.22, ok = false, early = false,
  }
end

function Battle:in_brace_window()
  local b = self.brace
  return self.phase == "brace" and b and not b.early and not b.ok
    and b.t >= b.flash_at + 0.02 and b.t <= b.flash_at + b.window * 0.6
end

function Battle:update_brace(dt)
  local b = self.brace
  b.t = b.t + dt
  if Input.pressed("confirm") and not b.ok and not b.early then
    if b.t < b.flash_at then b.early = true
    elseif b.t <= b.flash_at + b.window then b.ok = true; Sfx.play("blip") end
  end
  if b.t >= b.flash_at + b.window + 0.05 then
    self.brace = nil
    self:resolve_enemy_attack(b)
  end
end

function Battle:resolve_enemy_attack(b)
  local atk = b.atk
  local total = 0
  local blocked = false
  for _ = 1, (atk.hits or 1) do
    local dmg = Growth.damage(atk.power, self.E.atk, self:def_eff(), Growth.type_mult(self.enemy.type, self.st.type),
      love.math.random())
    if b.ok then dmg = dmg * 0.5 end
    if self.b.guard then dmg = dmg * 0.5 end
    if self.b.shield_t > 0 then dmg = dmg * 0.5 end
    if self.b.shield_card then dmg = 0; self.b.shield_card = false; blocked = true end
    dmg = math.floor(dmg + 0.5)
    total = total + dmg
    self.hp = math.max(0, self.hp - dmg)
  end
  if atk.drain_en then self.en = math.max(0, self.en - atk.drain_en) end
  self:add_meter(total * 0.6 + (b.ok and 10 or 0))
  if total > 0 then
    self.spark:hurt(self.spark.x + 40, self.spark.y)
    self.spark.vx, self.spark.vy, self.spark.invuln = 0, 0, 0.4
    Sfx.play("hurt")
  end
  self:floater(blocked and "BLOCKED" or ("-" .. total), 170, 210, blocked and C.colors.cyan or C.colors.glitch)
  local steps = {}
  if b.ok then steps[#steps + 1] = { "msg", "Braced! Damage halved.", 0.6 }
  elseif b.early then steps[#steps + 1] = { "msg", "Too early to brace.", 0.6 } end
  steps[#steps + 1] = { "msg", string.format("Sparkbit takes %d damage.", total), 0.6 }
  if atk.drain_en then steps[#steps + 1] = { "msg", "It drained " .. atk.drain_en .. " EN!", 0.6 } end
  self:run(steps, function()
    if self.hp <= 0 then return self:lose() end
    self:round_end()
  end)
end

function Battle:round_end()
  local b = self.b
  for _, k in ipairs({ "atk_t", "boost_t", "shield_t", "drone_t" }) do b[k] = math.max(0, b[k] - 1) end
  if b.oc_t > 0 then
    b.oc_t = b.oc_t - 1
    if b.oc_t == 0 then self.spark.overclock = false end
  end
  self.enemy.vuln_t = math.max(0, self.enemy.vuln_t - 1)
  b.guard = false
  self.card_used = false
  self.en = math.min(self.st.en_max, self.en + 1)
  self:to_menu()
end

-- Outcomes ------------------------------------------------------------------------------
function Battle:win()
  local d, E = self.data, self.E
  self.phase = "win"
  self.win_t = 0
  self.spark.overclock = false
  self.spark:set_state("celebrate", 999)
  d.bitdex.defeated[self.eid] = true
  local bits = E.bits
  if Growth.has_aspect(d, "lucky_byte") then bits = math.floor(bits * 1.5) end
  d.settlement.resources.bits = d.settlement.resources.bits + bits
  local absorbed = Growth.absorb(d, E.data)
  local levels = Growth.add_xp(d, E.xp)
  local card = E.card
  if not card and love.math.random() < 0.25 then card = K.CARD_ORDER[love.math.random(1, #K.CARD_ORDER)] end
  if card then d.cards[card] = (d.cards[card] or 0) + 1 end
  if E.aspect and not d.aspects.owned[E.aspect] then d.aspects.owned[E.aspect] = true end
  Growth.add_mood(d, 5)
  if levels > 0 then
    self.st = Growth.stats(d)
    self.hp = self.st.hp_max
  end
  d.companion.hp = self.hp
  self.rewards = { bits = bits, data = absorbed, xp = E.xp, levels = levels, card = card, aspect = E.aspect }
  -- data particles flow from the foe into Sparkbit
  for i = 1, 24 do
    local t = K.TYPES[(i % 3) + 1]
    if absorbed[t] then
      self.particles[#self.particles + 1] = { type = t, delay = i * 0.04, p = 0,
        ox = love.math.random(-30, 30), oy = love.math.random(-30, 30) }
    end
  end
  Sfx.play("level")
end

function Battle:lose()
  self.phase = "lose"
  self.win_t = 0
  self.spark:set_state("hurt", 999)
  local d = self.data
  d.companion.hp = Growth.stats(d).hp_max
  Growth.add_mood(d, -15)
  Sfx.play("error")
end

function Battle:finish(won)
  SM.pop()
  if self.opts.on_done then self.opts.on_done({ won = won, rewards = self.rewards, enemy = self.eid }) end
end

-- Update ---------------------------------------------------------------------------------
function Battle:update(dt)
  self.t = self.t + dt
  self.spark:update(dt, 0, 0, nil)
  self.spark.x, self.spark.y = 170, 300
  local e = self.enemy
  if e.flash > 0 then e.flash = e.flash - dt end
  if e.shake > 0 then e.shake = e.shake - dt end
  for i = #self.floaters, 1, -1 do
    local f = self.floaters[i]
    f.t = f.t - dt
    f.y = f.y - dt * 30
    if f.t <= 0 then table.remove(self.floaters, i) end
  end

  local ph = self.phase
  if ph == "busy" then
    self:step_queue(dt)
  elseif ph == "strike" then
    self:update_strike(dt)
  elseif ph == "brace" then
    self:update_brace(dt)
  elseif ph == "menu" then
    local items = self:menu_items()
    if Input.repeat_pressed("up") then self.menu_sel = (self.menu_sel - 2) % #items + 1; Sfx.play("blip") end
    if Input.repeat_pressed("down") then self.menu_sel = self.menu_sel % #items + 1; Sfx.play("blip") end
    if Input.pressed("confirm") then
      local id = items[self.menu_sel].id
      Sfx.play("confirm")
      if id == "strike" then self.turns = self.turns + 1; self:start_strike()
      elseif id == "skills" then self.phase, self.sub_sel = "skills", 1
      elseif id == "cards" then
        if self.card_used then Sfx.play("error") else self.phase, self.sub_sel = "cards", 1 end
      elseif id == "guard" then self.turns = self.turns + 1; self:guard()
      elseif id == "overclock" then self:overclock() end
    end
  elseif ph == "skills" or ph == "cards" then
    local list = ph == "skills" and self.data.skills.equipped or K.CARD_ORDER
    if Input.repeat_pressed("up") then self.sub_sel = (self.sub_sel - 2) % #list + 1; Sfx.play("blip") end
    if Input.repeat_pressed("down") then self.sub_sel = self.sub_sel % #list + 1; Sfx.play("blip") end
    if Input.pressed("cancel") then self.phase = "menu" return end
    if Input.pressed("confirm") then
      local id = list[self.sub_sel]
      if ph == "skills" then
        if self.en >= K.SKILLS[id].en then self:use_skill(id) else Sfx.play("error") end
      else
        if (self.data.cards[id] or 0) > 0 then self:use_card(id) else Sfx.play("error") end
      end
    end
  elseif ph == "win" or ph == "lose" then
    self.win_t = self.win_t + dt
    for _, p in ipairs(self.particles) do
      if self.win_t > p.delay then p.p = math.min(1, p.p + dt * 1.6) end
    end
    if self.win_t > 1.2 and Input.pressed("confirm") then
      Sfx.play("confirm")
      self:finish(ph == "win")
    end
  end
end

-- Draw -------------------------------------------------------------------------------------
local function type_badge(t, x, y)
  local col = C.hex(K.TYPE_COLOR[t] or "e8ecff")
  local name = K.TYPE_NAME[t] or t
  local w = UI.font_small:getWidth(name) + 12
  UI.setColor(col)
  love.graphics.rectangle("fill", x, y, w, 16, 8, 8)
  UI.setColor(C.colors.outline)
  love.graphics.setFont(UI.font_small)
  love.graphics.print(name, x + 6, y)
  return w
end

function Battle:draw()
  local lg = love.graphics
  local bg = self.opts.bg or C.colors.bg
  lg.clear(bg)
  UI.setColor(C.colors.grid, 0.35)
  for x = 0, C.WIDTH, 40 do lg.line(x, 0, x, C.HEIGHT) end
  for y = 0, C.HEIGHT, 40 do lg.line(0, y, C.WIDTH, y) end
  -- floor discs
  UI.setColor(C.colors.outline, 0.7)
  lg.ellipse("fill", 170, 304, 60, 14)
  lg.ellipse("fill", EX, EY + 56, 70, 16)

  self:draw_enemy()
  self.spark:draw()
  self:draw_particles()

  -- Sync Strike ring
  if self.phase == "strike" and self.strike and self.strike.gap <= 0 then
    local s = self.strike
    local dur = BEAT_DUR[s.beat]
    local r = 16 + 56 * (1 - s.t / dur)
    UI.setColor(C.colors.cyan, 0.9)
    lg.setLineWidth(3)
    lg.circle("line", EX, EY, math.max(2, r))
    lg.setLineWidth(1)
    UI.setColor(C.colors.amber, 0.9)
    lg.circle("line", EX, EY, 16)
    UI.text("A", EX - 10, EY - 9, C.colors.amber, UI.font_small, "center", 20)
  end
  -- Brace flash
  if self.phase == "brace" and self.brace then
    local b = self.brace
    if b.t >= b.flash_at and b.t <= b.flash_at + b.window then
      UI.setColor(C.colors.amber)
      lg.circle("fill", 170, 210, 18)
      UI.text("!", 160, 198, C.colors.outline, UI.font_big, "center", 20)
    end
    UI.text(b.early and "too early" or (b.ok and "BRACED" or "Brace: press A on the flash!"), 40, 330,
      b.ok and C.colors.green or C.colors.dim, UI.font_small, "center", 260)
  end

  for _, f in ipairs(self.floaters) do
    local c = f.color
    UI.text(f.text, f.x - 80, f.y, { c[1], c[2], c[3], math.min(1, f.t * 2) }, UI.font_big, "center", 160)
  end

  self:draw_status()
  self:draw_panel()
end

function Battle:draw_enemy()
  local lg = love.graphics
  local e, E = self.enemy, self.E
  if self.phase == "win" then
    local a = math.max(0, 1 - self.win_t * 1.5)
    if a <= 0 then return end
    lg.setColor(1, 1, 1, a)
  else
    lg.setColor(1, 1, 1, 1)
  end
  local img = Sprite.get(E.sprite)
  local sc = E.boss and 7 or 7
  local w, h = img:getWidth() * sc, img:getHeight() * sc
  local sx = e.shake > 0 and math.sin(self.t * 80) * 5 or 0
  local bob = math.sin(self.t * 2.5) * 4
  lg.draw(img, math.floor(EX - w / 2 + sx), math.floor(EY - h / 2 + bob), 0, sc, sc)
  if e.flash > 0 then
    lg.setColor(1, 1, 1, e.flash * 3)
    lg.draw(img, math.floor(EX - w / 2 + sx), math.floor(EY - h / 2 + bob), 0, sc, sc)
  end
  if e.charging then
    UI.setColor(C.colors.glitch, 0.4 + 0.3 * math.sin(self.t * 10))
    lg.setLineWidth(3)
    lg.circle("line", EX, EY, 70 + math.sin(self.t * 8) * 6)
    lg.setLineWidth(1)
  end
end

function Battle:draw_particles()
  local lg = love.graphics
  for _, p in ipairs(self.particles) do
    if p.p > 0 and p.p < 1 then
      local x = U.lerp(EX + p.ox, 170, p.p)
      local y = U.lerp(EY + p.oy, 270, p.p) - math.sin(p.p * math.pi) * 60
      UI.setColor(C.hex(K.TYPE_COLOR[p.type]))
      lg.rectangle("fill", x - 3, y - 3, 6, 6)
    end
  end
end

function Battle:draw_status()
  local lg = love.graphics
  local d = self.data
  -- player
  UI.panel(8, 8, 270, 78)
  UI.text(d.companion.name .. "  Lv " .. d.companion.level, 18, 12, C.colors.text, UI.font)
  if self.st.type ~= "neutral" then type_badge(self.st.type, 200, 14) end
  UI.text("HP", 18, 36, C.colors.dim, UI.font_small)
  UI.bar(46, 40, 160, 8, self.hp / self.st.hp_max, self.hp / self.st.hp_max > 0.3 and C.colors.green or C.colors.glitch)
  UI.text(self.hp .. "/" .. self.st.hp_max, 212, 34, C.colors.text, UI.font_small)
  UI.text("EN", 18, 52, C.colors.dim, UI.font_small)
  UI.bar(46, 56, 160, 6, self.en / self.st.en_max, C.colors.violet)
  UI.text(self.en .. "/" .. self.st.en_max, 212, 50, C.colors.text, UI.font_small)
  UI.text("OC", 18, 66, C.colors.dim, UI.font_small)
  local full = self.meter >= 100
  UI.bar(46, 70, 160, 6, self.b.oc_t > 0 and 1 or self.meter / 100,
    (full or self.b.oc_t > 0) and (math.floor(self.t * 6) % 2 == 0 and C.colors.amber or C.colors.white) or C.colors.amber)
  local bx = 212
  local buffs = {}
  if self.b.atk_t > 0 or self.b.boost_t > 0 then buffs[#buffs + 1] = "ATK+" end
  if self.b.shield_t > 0 or self.b.shield_card then buffs[#buffs + 1] = "SHD" end
  if self.b.drone_t > 0 then buffs[#buffs + 1] = "DRN" end
  if self.b.oc_t > 0 then buffs[#buffs + 1] = "OC" .. self.b.oc_t end
  UI.text(table.concat(buffs, " "), bx, 64, C.colors.cyan, UI.font_small)
  -- enemy
  local e = self.enemy
  UI.panel(C.WIDTH - 258, 8, 250, 58, C.hex(self.E.color))
  UI.text(self.E.name, C.WIDTH - 246, 12, C.colors.text, UI.font)
  type_badge(e.type, C.WIDTH - 90, 14)
  UI.bar(C.WIDTH - 246, 40, 200, 8, e.hp / e.max, C.colors.glitch)
  UI.text(tostring(e.hp), C.WIDTH - 42, 34, C.colors.text, UI.font_small)
  if e.vuln_t > 0 then UI.text("EXPOSED", C.WIDTH - 246, 48, C.colors.amber, UI.font_small) end
  if self.opts.tutorial or d.bitdex.defeated[self.eid] then
    local weak
    for k, v in pairs(K.BEATS) do if v == e.type then weak = k end end
    if weak then UI.text("Weak to " .. K.TYPE_NAME[weak], C.WIDTH - 160, 48, C.colors.dim, UI.font_small) end
  end
end

function Battle:draw_panel()
  local lg = love.graphics
  UI.panel(8, 352, C.WIDTH - 16, 120)
  local ph = self.phase
  if ph == "menu" or ph == "skills" or ph == "cards" then
    local items = self:menu_items()
    for i, it in ipairs(items) do
      local y = 362 + (i - 1) * 21
      local sel = i == self.menu_sel and ph == "menu"
      local col = it.id == "overclock" and C.colors.amber or (sel and C.colors.white or C.colors.dim)
      UI.text(it.label, 30, y, col, UI.font)
      if sel then UI.focus(22, y - 1, 150, 21, self.t) end
    end
    if ph == "menu" then
      local hint = ({
        strike = "Sync Strike: press A each time the ring closes on the foe.",
        skills = "Use an uploaded skill (costs EN).",
        cards = "Play a Patch Card. Free, once per turn.",
        guard = "Halve the next attack and recover 3 EN.",
        overclock = "Transform: x1.5 ATK and DEF for 3 turns. Free action.",
      })[items[self.menu_sel].id]
      UI.text(hint or "", 200, 366, C.colors.text, UI.font_small, "left", 410)
      UI.prompts({ { "confirm", "Select" } }, C.WIDTH - 22, 444, true)
    else
      local list = ph == "skills" and self.data.skills.equipped or K.CARD_ORDER
      for i, id in ipairs(list) do
        local y = 362 + (i - 1) * 21
        local sel = i == self.sub_sel
        local label, usable, col
        if ph == "skills" then
          local sk = K.SKILLS[id]
          label = string.format("%s  %dEN", sk.name, sk.en)
          usable = self.en >= sk.en
          col = C.hex(K.TYPE_COLOR[sk.type])
        else
          local n = self.data.cards[id] or 0
          label = string.format("%s x%d", K.CARDS[id].name, n)
          usable = n > 0
          col = C.colors.text
        end
        UI.text(label, 200, y, usable and (sel and col or C.colors.dim) or C.colors.outline, UI.font_small)
        if sel then UI.focus(192, y - 1, 200, 20, self.t) end
      end
      local id = list[self.sub_sel]
      local desc = ph == "skills" and K.SKILLS[id].desc or K.CARDS[id].desc
      UI.text(desc, 410, 366, C.colors.text, UI.font_small, "left", 200)
      UI.prompts({ { "confirm", "Use" }, { "cancel", "Back" } }, C.WIDTH - 22, 444, true)
    end
  elseif ph == "busy" and self.msg then
    UI.text(self.msg[2], 30, 372, C.colors.text, UI.font, "left", C.WIDTH - 60)
  elseif ph == "strike" then
    UI.text("SYNC STRIKE - press A as the ring meets the core!", 30, 372, C.colors.cyan, UI.font)
  elseif ph == "win" then
    local r = self.rewards
    UI.text("VICTORY - data absorbed", 30, 360, C.colors.green, UI.font)
    local parts = {}
    for _, k in ipairs(K.TYPES) do
      if r.data[k] then parts[#parts + 1] = "+" .. r.data[k] .. " " .. K.TYPE_NAME[k] end
    end
    UI.text(table.concat(parts, "   "), 30, 384, C.colors.cyan, UI.font_small)
    UI.text(string.format("+%d XP   +%d Bits%s%s", r.xp, r.bits,
      r.card and ("   +1 " .. K.CARDS[r.card].name) or "",
      r.levels > 0 and "   LEVEL UP!" or ""), 30, 404, C.colors.text, UI.font_small)
    if r.aspect then UI.text("New aspect: " .. K.ASPECTS[r.aspect].name, 30, 424, C.colors.amber, UI.font_small) end
    if self.win_t > 1.2 then UI.prompts({ { "confirm", "Continue" } }, C.WIDTH - 22, 444, true) end
  elseif ph == "lose" then
    UI.text("Sparkbit's core destabilized...", 30, 366, C.colors.glitch, UI.font)
    UI.text(self.opts.tutorial and "The Loop rewinds. Try again." or "Returning home to recover.", 30, 392, C.colors.text, UI.font_small)
    if self.win_t > 1.2 then UI.prompts({ { "confirm", "Continue" } }, C.WIDTH - 22, 444, true) end
  end
end

return Battle
