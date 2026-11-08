-- Expedition field (Chapter 1: Signals). Screen-based exploration with
-- visible Glitches, caches, a hidden Bitling to befriend, a boss, and a
-- caged Bitling to rescue. HP carries between battles; home heals.

local C = require("src.data.config")
local K = require("src.data.content")
local REGIONS = require("src.data.regions")
local U = require("src.core.util")
local Collision = require("src.core.collision")
local Growth = require("src.systems.growth")
local Input = require("src.input.input")
local UI = require("src.ui.ui")
local Sfx = require("src.core.sfx")
local SM = require("src.core.state")
local Hud = require("src.ui.hud")
local Dialog = require("src.ui.dialog")
local Sparkbit = require("src.entities.sparkbit")
local FieldEnemy = require("src.entities.field_enemy")
local Npc = require("src.entities.npc")
local Battle = require("src.states.battle")

local Field = {}
Field.__index = Field
Field.name = "field"
Field.gameplay = true

local BOUNDS = { x = 32, y = 72, w = 576, h = 360 }
local REVEAL_R = 96

-- run: per-expedition state shared across screens ({ cleared = {} })
function Field.new(game, region_id, screen_id, spawn, run)
  Battle.define_sprites()
  local self = setmetatable({}, Field)
  local region = assert(REGIONS[region_id])
  screen_id = screen_id or region.start.screen
  spawn = spawn or region.start
  self.game, self.data, self.region_id, self.region = game, game.data, region_id, region
  self.screen_id, self.sc = screen_id, region.screens[screen_id]
  self.run = run or { cleared = {} }
  self.t = 0
  self.dialog = Dialog.new()
  self.floaters = {}
  self.scan_t, self.scan_cd = 0, 0
  self.grace = 1.0
  self.title_t = 2.0
  self.last_pet = -999
  self.app_t = 0

  self.spark = Sparkbit.new(spawn.x, spawn.y)
  self.spark:set_state("idle")
  self.spark:set_appearance(Growth.appearance(self.data))

  self:build_solids()
  self.enemies = {}
  for i, def in ipairs(self.sc.enemies or {}) do
    local key = screen_id .. ":" .. i
    if not self.run.cleared[key] then self.enemies[#self.enemies + 1] = FieldEnemy.new(def, key) end
  end
  local boss = self.sc.boss
  if boss and not self.data.missions.completed.corruptor then
    self.boss = FieldEnemy.new({ id = boss.id, path = { { boss.x, boss.y } }, boss = true }, "boss")
  end
  self.caches = {}
  for _, c in ipairs(self.sc.caches or {}) do
    if not self.data.discoveries[c.id] then
      self.caches[#self.caches + 1] = { def = c, x = c.x, y = c.y, revealed = not c.hidden, t = 0 }
    end
  end
  local fr = self.sc.friend
  if fr and not self.data.residents[fr.id] then
    self.friend = Npc.new(fr.id, fr.x, fr.y, { hidden = fr.hidden, wander = false })
  end
  if self.sc.cage and not self.data.residents.barkbit then
    self.caged = Npc.new("barkbit", self.sc.cage.x + 20, self.sc.cage.y + 34, { wander = false })
  end
  self:render_floor()
  return self
end

function Field:build_solids()
  local b = BOUNDS
  self.solids = {
    { x = 0, y = 0, w = C.WIDTH, h = b.y },
    { x = 0, y = b.y + b.h, w = C.WIDTH, h = C.HEIGHT - (b.y + b.h) },
    { x = 0, y = 0, w = b.x, h = C.HEIGHT },
    { x = b.x + b.w, y = 0, w = C.WIDTH - (b.x + b.w), h = C.HEIGHT },
  }
  for _, o in ipairs(self.sc.obstacles or {}) do self.solids[#self.solids + 1] = o end
  if self.sc.cage and not self.data.residents.barkbit then self.solids[#self.solids + 1] = self.sc.cage end
end

function Field:move(e, dx, dy) return Collision.move(e, dx, dy, self.solids) end

function Field:entity_count() return #self.enemies + #self.caches + (self.boss and 1 or 0) + 1 end

function Field:render_floor()
  local lg = love.graphics
  if not self.floor_canvas then self.floor_canvas = lg.newCanvas(C.WIDTH, C.HEIGHT) end
  local prev = lg.getCanvas()
  lg.setCanvas(self.floor_canvas)
  lg.clear(C.colors.bg)
  local f1, f2 = C.hex(self.sc.floor[1]), C.hex(self.sc.floor[2])
  local acc = C.hex(self.sc.accent)
  local b = BOUNDS
  for ty = 0, math.floor(b.h / 32) - 1 do
    for tx = 0, math.floor(b.w / 32) - 1 do
      local x, y = b.x + tx * 32, b.y + ty * 32
      local h = U.hash2(tx + #self.screen_id * 7, ty)
      UI.setColor((tx + ty) % 2 == 0 and f1 or f2)
      lg.rectangle("fill", x, y, 32, 32)
      UI.setColor(acc, 0.08)
      lg.rectangle("line", x + 0.5, y + 0.5, 31, 31)
      if h > 0.9 then
        UI.setColor(acc, 0.3)
        lg.rectangle("fill", x + 12, y + 12, 4, 4)
      end
    end
  end
  UI.setColor(C.colors.wall)
  lg.rectangle("fill", 0, 40, C.WIDTH, b.y - 40)
  lg.rectangle("fill", 0, b.y + b.h, C.WIDTH, 8)
  lg.rectangle("fill", b.x - 10, 40, 10, b.h + 40)
  lg.rectangle("fill", b.x + b.w, 40, 10, b.h + 40)
  UI.setColor(acc, 0.5)
  lg.rectangle("fill", 0, b.y - 6, C.WIDTH, 3)
  -- exits glow
  for _, ex in ipairs(self.sc.exits or {}) do
    UI.setColor(acc, 0.55)
    if ex.side == "right" then lg.rectangle("fill", b.x + b.w - 4, ex.a, 14, ex.b - ex.a)
    elseif ex.side == "left" then lg.rectangle("fill", b.x - 10, ex.a, 14, ex.b - ex.a)
    elseif ex.side == "top" then lg.rectangle("fill", ex.a, b.y - 10, ex.b - ex.a, 14)
    elseif ex.side == "bottom" then lg.rectangle("fill", ex.a, b.y + b.h - 4, ex.b - ex.a, 12) end
  end
  if self.sc.home then
    local h = self.sc.home
    UI.setColor(C.colors.cyan, 0.35)
    lg.ellipse("fill", h.x, h.y, 26, 12)
    UI.setColor(C.colors.cyan)
    lg.ellipse("line", h.x, h.y, 26, 12)
  end
  lg.setCanvas(prev)
  lg.setColor(1, 1, 1, 1)
end

function Field:floater(text, x, y, color)
  self.floaters[#self.floaters + 1] = { text = text, x = x, y = y, t = 1.3, color = color or C.colors.cyan }
end

-- Transitions ----------------------------------------------------------------------
function Field:go_screen(ex)
  local nf = Field.new(self.game, self.region_id, ex.to, { x = ex.sx, y = ex.sy }, self.run)
  SM.switch(nf)
end

function Field:go_home(reason)
  local d = self.data
  d.expedition.runs = d.expedition.runs + 1
  if d.residents.barkbit then d.expedition.fetch_ready = true end
  self.game.save()
  local Lounge = require("src.states.lounge")
  SM.switch(Lounge.new(self.game, { from = reason or "expedition" }))
end

-- Battles --------------------------------------------------------------------------
function Field:start_battle(fe)
  local floor = C.hex(self.sc.floor[1])
  SM.push(Battle.new(self.game, fe.id, {
    boss = fe.boss,
    bg = { floor[1] * 0.6, floor[2] * 0.6, floor[3] * 0.6, 1 },
    on_done = function(res) self:battle_done(fe, res) end,
  }))
end

function Field:battle_done(fe, res)
  self.grace = 1.5
  self.spark:set_appearance(Growth.appearance(self.data))
  if not res.won then
    self:go_home("defeat")
    return
  end
  if fe.boss then
    self.boss = nil
    self.data.missions.completed.corruptor = true
    self.dialog:push({
      { "Sparkbit", "The Corruptor is gone. Its data is part of me now... and it left a module behind." },
      { nil, "New aspect: Overclock Coil. Install it at the Upload Station." },
      { "Sparkbit", "The cage lock is fried. Let's get that Bitling out!" },
    })
  else
    self.run.cleared[fe.key] = true
    for i, e in ipairs(self.enemies) do if e == fe then table.remove(self.enemies, i) break end end
  end
  self.game.save()
end

-- Interactions ---------------------------------------------------------------------------
function Field:interaction()
  local s = self.spark
  if self.sc.home and U.dist(s.x, s.y, self.sc.home.x, self.sc.home.y) < 34 then
    return { label = "Return home", x = self.sc.home.x, y = self.sc.home.y - 60, fn = function() self:go_home() end }
  end
  for _, c in ipairs(self.caches) do
    if c.revealed and U.dist(s.x, s.y, c.x, c.y) < 34 then
      return { label = "Open cache", x = c.x, y = c.y - 50, fn = function() self:open_cache(c) end }
    end
  end
  local f = self.friend
  if f and f.revealed and U.dist(s.x, s.y, f.x, f.y) < 44 then
    return { label = "Approach", x = f.x, y = f.y - 76, fn = function() self:befriend() end }
  end
  if self.caged and not self.boss and U.dist(s.x, s.y, self.caged.x, self.caged.y + 30) < 60 then
    return { label = "Free Bitling", x = self.caged.x, y = self.caged.y - 80, fn = function() self:rescue() end }
  end
  return nil
end

function Field:open_cache(c)
  local d = self.data
  d.discoveries[c.def.id] = true
  d.settlement.resources.bits = d.settlement.resources.bits + c.def.bits
  local text = "+" .. c.def.bits .. " Bits"
  if c.def.card then
    d.cards[c.def.card] = (d.cards[c.def.card] or 0) + 1
    text = text .. ", +1 " .. K.CARDS[c.def.card].name
  end
  for i, cc in ipairs(self.caches) do if cc == c then table.remove(self.caches, i) break end end
  self:floater(text, c.x, c.y - 60, C.colors.amber)
  self.spark:set_state("happy")
  Sfx.play("pickup")
  self.game.save()
end

function Field:befriend()
  local d, f = self.data, self.friend
  if d.settlement.resources.bits < K.FOODS.snack.cost then
    self.dialog:push({
      { "Sparkbit", "A shy Bitling. It looks hungry..." },
      { "Sparkbit", "If only we had a Byte Snack to share (5 Bits)." },
    })
    return
  end
  d.settlement.resources.bits = d.settlement.resources.bits - K.FOODS.snack.cost
  d.residents.purrbit = { joined = os.time() }
  d.bitdex.seen.purrbit = true
  d.traits.social = d.traits.social + 2
  Growth.care_action(d, 5)
  f:say("heart", 1.5)
  self.spark:set_state("happy")
  Sfx.play("pet")
  self.dialog:push({
    { "Sparkbit", "Here, share my Byte Snack. (-5 Bits)" },
    { "Purrbit", "...mrrp. You read patterns too. I'll watch yours, at your Lounge." },
    { nil, "Purrbit joined the Lounge! It can read where Sparkbit's evolution is heading." },
  }, function()
    self.friend = nil
    self.game.save()
  end)
end

function Field:rescue()
  local d = self.data
  d.residents.barkbit = { joined = os.time() }
  d.missions.completed.signals = true
  local has
  for _, r in ipairs(d.regions.unlocked) do if r == "archive" then has = true end end
  if not has then table.insert(d.regions.unlocked, "archive") end
  self.caged:say("heart", 2)
  self.spark:set_state("celebrate")
  Sfx.play("level")
  self.dialog:push({
    { "Barkbit", "Free! You beat the Corruptor! I'm Barkbit. I fetch things. Good things!" },
    { "Barkbit", "Take me home? I'll bring you back something every time you explore." },
  }, function()
    self.caged = nil
    self:build_solids()
    self.game.save()
    local Endcard = require("src.states.endcard")
    SM.push(Endcard.new(self.game, function() self:go_home("chapter") end, {
      title = "SIGNALS", subtitle = "Chapter 1 complete", next = "Next: Chapter 2 - The Archive",
      memory = "Signals",
    }))
  end)
  table.insert(d.memories, {
    id = "signals", title = "Signals", text = "We cleared the Relay Tower and freed Barkbit.",
    level = d.companion.level, at = os.time(),
  })
end

-- Update ------------------------------------------------------------------------------------
function Field:objective()
  local d = self.data
  if not d.missions.completed.corruptor then
    return self.sc.title .. ": find what's jamming the Relay Tower", { { "skill1", "Scan" }, { "pause", "Menu" } }
  end
  if not d.residents.barkbit then return "Free the caged Bitling in the Relay Tower", { { "confirm", "Interact" } } end
  return self.sc.title .. ": explore, or head home through Signal Fields", { { "skill1", "Scan" }, { "skill2", "Pet" } }
end

function Field:update(dt)
  self.t = self.t + dt
  if self.title_t > 0 then self.title_t = self.title_t - dt end
  if self.grace > 0 then self.grace = self.grace - dt end
  self.app_t = self.app_t - dt
  if self.app_t <= 0 then self.app_t = 0.5; self.spark:set_appearance(Growth.appearance(self.data)) end
  for i = #self.floaters, 1, -1 do
    local f = self.floaters[i]
    f.t = f.t - dt
    f.y = f.y - dt * 24
    if f.t <= 0 then table.remove(self.floaters, i) end
  end
  for _, c in ipairs(self.caches) do c.t = c.t + dt end
  if self.friend then self.friend:update(dt) end
  if self.caged then self.caged:update(dt) end

  if self.dialog:active() then
    self.dialog:update(dt)
    self.spark:update(dt, 0, 0, self)
    if Input.pressed("confirm") or Input.pressed("cancel") then
      self.dialog:advance()
      if not self.dialog:active() then Input.flush() end
    end
    return
  end
  if Input.pressed("pause") then SM.push(require("src.states.pause").new(self.game, self)) return end

  if self.scan_cd > 0 then self.scan_cd = self.scan_cd - dt end
  if self.scan_t > 0 then self.scan_t = self.scan_t - dt end
  if Input.pressed("skill1") and self.scan_cd <= 0 and self.spark:controllable() then
    self.scan_cd, self.scan_t = C.timing.scan_cooldown, C.timing.scan_duration
    self.spark:set_state("sorting", 0.6)
    Sfx.play("blip")
  end
  if Input.pressed("skill2") and self.spark:controllable() then
    self.spark:set_state("pet")
    self.spark:say("heart", 1.2)
    Sfx.play("pet")
    self.data.relationship.pets = self.data.relationship.pets + 1
    if self.t - self.last_pet >= C.timing.pet_cooldown then
      self.last_pet = self.t
      self.data.relationship.affinity = self.data.relationship.affinity + 1
      Growth.care_action(self.data, 5)
    end
  end

  local mx, my = Input.move()
  self.spark:update(dt, mx, my, self)
  local s = self.spark

  -- curiosity reveals
  for _, c in ipairs(self.caches) do
    if not c.revealed and U.dist(s.x, s.y, c.x, c.y) < REVEAL_R then
      c.revealed = true
      s:set_state("curious")
      s:say("?", 1.2)
      self.data.traits.curiosity = self.data.traits.curiosity + 1
      self:floater("Curiosity: hidden cache!", s.x, s.y - 80, C.colors.violet)
      Sfx.play("good")
    end
  end
  local f = self.friend
  if f and not f.revealed and U.dist(s.x, s.y, f.x, f.y) < REVEAL_R + 20 then
    f.revealed = true
    s:set_state("curious")
    s:say("?", 1.2)
    self.data.traits.curiosity = self.data.traits.curiosity + 1
    self:floater("Curiosity: someone's hiding!", s.x, s.y - 80, C.colors.violet)
    Sfx.play("good")
  end

  -- enemies
  for _, e in ipairs(self.enemies) do
    e:update(dt, s)
    if self.grace <= 0 and U.dist(s.x, s.y, e.x, e.y) < 26 then
      self:start_battle(e)
      return
    end
  end
  if self.boss then
    self.boss:update(dt, s)
    if self.grace <= 0 and U.dist(s.x, s.y, self.boss.x, self.boss.y) < 90 then
      local boss = self.boss
      self.dialog:push({
        { "Sparkbit", "That's what's jamming the relay. It's converting everything it touches!" },
        { "Sparkbit", "And it caged a Bitling. Watch for its charge attack. Guard when it glows!" },
      }, function() self:start_battle(boss) end)
      self.grace = 99
      return
    end
  end

  -- interactions
  self.current = self:interaction()
  if self.current and Input.pressed("confirm") and s:controllable() then
    Sfx.play("blip")
    self.current.fn()
    return
  end

  -- exits
  local b = BOUNDS
  for _, ex in ipairs(self.sc.exits or {}) do
    local hit = false
    if ex.side == "right" then hit = s.x + s.w / 2 >= b.x + b.w - 2 and s.y >= ex.a and s.y <= ex.b
    elseif ex.side == "left" then hit = s.x - s.w / 2 <= b.x + 2 and s.y >= ex.a and s.y <= ex.b
    elseif ex.side == "top" then hit = s.y - s.h <= b.y + 2 and s.x >= ex.a and s.x <= ex.b
    elseif ex.side == "bottom" then hit = s.y >= b.y + b.h - 2 and s.x >= ex.a and s.x <= ex.b end
    if hit then self:go_screen(ex) return end
  end
end

-- Draw ---------------------------------------------------------------------------------------
local function draw_obstacle(o, acc, t)
  local lg = love.graphics
  UI.setColor(C.colors.outline, 0.5)
  lg.rectangle("fill", o.x + 3, o.y + o.h - 4, o.w, 8, 3, 3)
  UI.setColor(C.colors.outline)
  lg.rectangle("fill", o.x, o.y, o.w, o.h, 3, 3)
  UI.setColor(C.colors.wall)
  lg.rectangle("fill", o.x + 3, o.y + 3, o.w - 6, o.h - 6, 2, 2)
  if o.kind == "pylon" then
    UI.setColor(acc, 0.5 + 0.3 * math.sin(t * 2 + o.x))
    lg.rectangle("fill", o.x + o.w / 2 - 2, o.y + 8, 4, o.h - 16)
  else
    UI.setColor(acc, 0.4)
    lg.line(o.x + 4, o.y + 4, o.x + o.w - 4, o.y + o.h - 4)
  end
end

function Field:draw()
  local lg = love.graphics
  lg.setColor(1, 1, 1, 1)
  lg.draw(self.floor_canvas, 0, 0)
  local acc = C.hex(self.sc.accent)

  local list = { { y = self.spark.y, d = self.spark } }
  for _, e in ipairs(self.enemies) do list[#list + 1] = { y = e.y, d = e } end
  if self.boss then list[#list + 1] = { y = self.boss.y, d = self.boss } end
  if self.friend then list[#list + 1] = { y = self.friend.y, d = self.friend } end
  if self.caged then list[#list + 1] = { y = self.caged.y, d = self.caged } end
  for _, o in ipairs(self.sc.obstacles or {}) do list[#list + 1] = { y = o.y + o.h, o = o } end
  table.sort(list, function(a, b) return a.y < b.y end)

  -- caches (floor-level)
  for _, c in ipairs(self.caches) do
    if c.revealed then
      UI.setColor(C.colors.outline)
      lg.rectangle("fill", c.x - 14, c.y - 20, 28, 20, 3, 3)
      UI.setColor(C.colors.amber, 0.8 + 0.2 * math.sin(c.t * 4))
      lg.rectangle("fill", c.x - 12, c.y - 18, 24, 6, 2, 2)
    end
  end
  -- cage bars
  if self.caged then
    local cg = self.sc.cage
    UI.setColor(C.colors.glitch, 0.8)
    for i = 0, 4 do lg.rectangle("fill", cg.x + i * 9, cg.y - 10, 3, cg.h + 10) end
    lg.rectangle("fill", cg.x - 2, cg.y - 12, cg.w + 4, 4)
  end

  for _, e in ipairs(list) do
    if e.o then draw_obstacle(e.o, acc, self.t) else e.d:draw() end
  end

  if self.scan_t > 0 then
    local a = math.min(1, self.scan_t)
    for _, e in ipairs(self.enemies) do e:draw_scan(a) end
    if self.boss then self.boss:draw_scan(a) end
    for _, c in ipairs(self.caches) do
      if not c.revealed then UI.text("?", c.x - 10, c.y - 30, { C.colors.violet[1], C.colors.violet[2], C.colors.violet[3], a }, UI.font_big, "center", 20) end
    end
    if self.friend and not self.friend.revealed then
      UI.text("?", self.friend.x - 10, self.friend.y - 40, { C.colors.violet[1], C.colors.violet[2], C.colors.violet[3], a }, UI.font_big, "center", 20)
    end
  end

  local it = self.current
  if it and not self.dialog:active() then
    local w = UI.font_small:getWidth(it.label) + 34
    local x, y = math.floor(U.clamp(it.x - w / 2, 4, C.WIDTH - w - 4)), math.floor(it.y)
    UI.panel(x, y, w, 24)
    UI.glyph("confirm", x + 4, y + 3)
    UI.text(it.label, x + 26, y + 4, C.colors.text, UI.font_small)
  end
  for _, f in ipairs(self.floaters) do
    local c = f.color
    UI.text(f.text, U.clamp(f.x - 150, 4, C.WIDTH - 304), f.y, { c[1], c[2], c[3], math.min(1, f.t * 2) }, UI.font, "center", 300)
  end

  local obj, prompts = self:objective()
  Hud.draw(self.data, self.spark, (not self.dialog:active()) and obj or nil, prompts, self.t)
  if self.title_t > 0 then
    local a = math.min(1, self.title_t)
    UI.text(self.sc.title:upper(), 0, 96, { acc[1], acc[2], acc[3], a }, UI.font_big, "center", C.WIDTH)
  end
  self.dialog:draw()
end

function Field:save() self.game.save() end

return Field
