-- The Lounge / First Node: the V0.1 playable loop.
--
-- Prologue (design §16):
--  wake -> move -> 3 fragments -> repair terminal -> FlowSort -> identify Loop
--  -> break Loop -> restore Gateway -> first XP -> choose improvement
--  -> store first Memory -> Gateway opens -> FIRST SPARK end card

local C = require("src.data.config")
local ROOM = require("src.data.room")
local U = require("src.core.util")
local Collision = require("src.core.collision")
local Input = require("src.input.input")
local UI = require("src.ui.ui")
local Sfx = require("src.core.sfx")
local SM = require("src.core.state")
local Hud = require("src.ui.hud")
local Dialog = require("src.ui.dialog")
local Sparkbit = require("src.entities.sparkbit")
local Fragment = require("src.entities.fragment")
local Terminal = require("src.entities.terminal")
local Gateway = require("src.entities.gateway")
local LoopGlitch = require("src.entities.loop_glitch")
local Npc = require("src.entities.npc")
local Growth = require("src.systems.growth")
local K = require("src.data.content")

local Lounge = {}
Lounge.__index = Lounge
Lounge.name = "lounge"
Lounge.gameplay = true

local INTERACT_R = 44
local SEAL_R = 26

function Lounge.new(game, opts)
  opts = opts or {}
  require("src.states.battle").define_sprites()
  local self = setmetatable({}, Lounge)
  self.game = game
  self.data = game.data
  self.p = game.data.progress
  self.t = 0
  self.dialog = Dialog.new()
  self.floaters = {}
  self.scan_t, self.scan_cd = 0, 0
  self.hold = { key = nil, t = 0 }
  self.banner = nil
  self.levelup_t = 0
  self.show_objectives = false
  self.last_pet, self.last_rest = -999, -999
  self.pet_fx = 0
  self.darkness = self:target_darkness()

  self:build_solids()

  self.spark = Sparkbit.new(ROOM.spawn.x, ROOM.spawn.y)
  if self.p.awake then
    self.spark.x, self.spark.y = 168, 270
    self.spark:set_state("idle")
  end
  self.spark.energy = U.clamp(self.data.companion.energy or C.player.max_energy, 1, C.player.max_energy)
  self.spark:set_appearance(Growth.appearance(self.data))
  self.app_t, self.hunger_t = 0, 0
  -- home heals
  self.data.companion.hp = Growth.stats(self.data).hp_max
  if opts.from then
    self.spark.x, self.spark.y, self.spark.facing = 470, 262, -1
  end
  self.npcs = {}
  if self.data.residents.barkbit then self.npcs[#self.npcs + 1] = Npc.new("barkbit", 500, 340) end
  if self.data.residents.purrbit then self.npcs[#self.npcs + 1] = Npc.new("purrbit", 250, 200) end

  self.fragments = {}
  for _, f in ipairs(ROOM.fragments) do
    if not self.p.fragments[f.id] then self.fragments[#self.fragments + 1] = Fragment.new(f) end
  end
  self.terminal = Terminal.new(ROOM.terminal, self.p.terminal_repaired)
  local gmode = "broken"
  if self.p.gateway_open then gmode = "open"
  elseif self.p.gateway_active then gmode = "active"
  elseif self.p.loop_broken then gmode = "dormant" end
  self.gateway = Gateway.new(ROOM.gateway, gmode)
  if self.p.flowsort_done and not self.p.loop_broken then self:spawn_glitch() end

  self:render_floor()

  if opts.from == "defeat" then
    self.dialog:push({
      { "Sparkbit", "...rebooted. Home again." },
      { nil, "Sparkbit retreated to the Lounge and recovered. Feed it, upload skills, then try again." },
    })
  elseif opts.from == "chapter" then
    self.dialog:push({
      { "Barkbit", "So this is home! Smells like fresh data." },
      { nil, "Barkbit moved into the Lounge. Talk to residents after expeditions." },
    })
  elseif opts.from == "expedition" then
    self.dialog:push({ { "Sparkbit", "Home. Let's rest up and see what we can upload." } })
  elseif self.p.awake and not self.p.prologue_complete then
    self.dialog:push({ { "Sparkbit", "You're back! Let's keep going." } })
  end
  -- Resume edge case: quit during improvement choice.
  if self.p.gateway_active and self.p.improvement == "" then
    self.pending_choice = true
  elseif self.p.improvement ~= "" and not self.p.memory_stored then
    self.pending_memory = true
  end
  return self
end

-- World -------------------------------------------------------------------

function Lounge:build_solids()
  local b = ROOM.bounds
  self.solids = {
    { x = 0, y = 0, w = C.WIDTH, h = b.y },
    { x = 0, y = b.y + b.h, w = C.WIDTH, h = C.HEIGHT - (b.y + b.h) },
    { x = 0, y = 0, w = b.x, h = C.HEIGHT },
    { x = b.x + b.w, y = 0, w = C.WIDTH - (b.x + b.w), h = C.HEIGHT },
  }
  for _, o in ipairs(ROOM.obstacles) do self.solids[#self.solids + 1] = o end
  self.solids[#self.solids + 1] = ROOM.terminal
  self.solids[#self.solids + 1] = ROOM.gateway
  self.solids[#self.solids + 1] = ROOM.processor
end

function Lounge:move(e, dx, dy) return Collision.move(e, dx, dy, self.solids) end

function Lounge:target_darkness()
  local p = self.p
  if not p.awake then return 0.93 end
  if p.prologue_complete then return 0.12 end
  if p.gateway_active then return 0.22 end
  if p.loop_broken then return 0.3 end
  if p.terminal_repaired then return 0.42 end
  return 0.55
end

-- Damage level drives how many floor tiles are broken: the room visibly heals.
function Lounge:damage_level()
  local p, d = self.p, 0.34
  if p.terminal_repaired then d = d - 0.08 end
  if p.loop_broken then d = d - 0.1 end
  if p.gateway_active then d = d - 0.08 end
  if p.prologue_complete then d = d - 0.06 end
  return d
end

function Lounge:render_floor()
  local lg = love.graphics
  if not self.floor_canvas then self.floor_canvas = lg.newCanvas(C.WIDTH, C.HEIGHT) end
  local prev = lg.getCanvas()
  lg.setCanvas(self.floor_canvas)
  lg.clear(C.colors.bg)
  local b = ROOM.bounds
  local dmg = self:damage_level()
  for ty = 0, math.floor(b.h / 32) - 1 do
    for tx = 0, math.floor(b.w / 32) - 1 do
      local x, y = b.x + tx * 32, b.y + ty * 32
      local h = U.hash2(tx, ty)
      if h < dmg then
        UI.setColor(C.colors.floor_dmg)
        lg.rectangle("fill", x + 2, y + 2, 28, 28)
        UI.setColor(C.colors.grid, 0.4)
        lg.rectangle("fill", x + 6 + (h * 97) % 14, y + 8 + (h * 53) % 12, 4, 4)
      else
        UI.setColor((tx + ty) % 2 == 0 and C.colors.floor or C.colors.floor2)
        lg.rectangle("fill", x, y, 32, 32)
        UI.setColor(C.colors.grid, 0.55)
        lg.rectangle("line", x + 0.5, y + 0.5, 31, 31)
        if h > 0.93 then
          UI.setColor(C.colors.cyan, 0.25)
          lg.rectangle("fill", x + 14, y + 14, 4, 4)
        end
      end
    end
  end
  -- walls
  UI.setColor(C.colors.wall)
  lg.rectangle("fill", 0, 40, C.WIDTH, b.y - 40)
  lg.rectangle("fill", 0, b.y + b.h, C.WIDTH, 8)
  lg.rectangle("fill", b.x - 10, 40, 10, b.h + 40)
  lg.rectangle("fill", b.x + b.w, 40, 10, b.h + 40)
  UI.setColor(C.colors.wall_top)
  lg.rectangle("fill", 0, b.y - 6, C.WIDTH, 6)
  -- wall data lines
  for i = 0, 18 do
    local h = U.hash2(i, 99)
    UI.setColor(h > 0.5 and C.colors.cyan or C.colors.violet, 0.18 + h * 0.2)
    lg.rectangle("fill", 20 + i * 33, 48 + (h * 12), 14 + h * 10, 2)
  end
  -- sleep pad (Core Nest)
  local sp = ROOM.sleep_pad
  UI.setColor(C.colors.outline)
  lg.ellipse("fill", sp.x + sp.w / 2, sp.y + sp.h / 2, sp.w / 2 + 2, sp.h / 2 + 2)
  UI.setColor(C.colors.blue, 0.55)
  lg.ellipse("fill", sp.x + sp.w / 2, sp.y + sp.h / 2, sp.w / 2, sp.h / 2)
  UI.setColor(C.colors.cyan, 0.35)
  lg.ellipse("line", sp.x + sp.w / 2, sp.y + sp.h / 2, sp.w / 2 - 6, sp.h / 2 - 5)
  -- resource processor (broken, decorative / lore)
  local pr = ROOM.processor
  UI.setColor(C.colors.outline)
  lg.rectangle("fill", pr.x, pr.y, pr.w, pr.h, 4, 4)
  UI.setColor(C.colors.wall_top)
  lg.rectangle("fill", pr.x + 4, pr.y + 4, pr.w - 8, pr.h - 18, 3, 3)
  UI.setColor(C.colors.amber, 0.5)
  lg.rectangle("fill", pr.x + 10, pr.y + pr.h - 10, 10, 4)
  UI.setColor(C.colors.dim)
  lg.line(pr.x + 8, pr.y + 8, pr.x + 26, pr.y + 20)
  lg.setCanvas(prev)
  lg.setColor(1, 1, 1, 1)
end

function Lounge:spawn_glitch()
  self.glitch = LoopGlitch.new(ROOM.loop_nodes)
  self.glitch.on_lap = function() self.gateway:reset_pulse() end
end

function Lounge:fragment_count() return U.count(self.p.fragments) end

function Lounge:entity_count()
  return #self.fragments + 3 + (self.glitch and 1 or 0) + #self.floaters
end

-- Progression helpers -----------------------------------------------------

function Lounge:floater(text, x, y, color)
  -- stack floaters spawned together so they never overlap
  local moved = true
  while moved do
    moved = false
    for _, f in ipairs(self.floaters) do
      if math.abs(f.y - y) < 20 and math.abs(f.x - x) < 120 then y = f.y - 20; moved = true end
    end
  end
  self.floaters[#self.floaters + 1] = { text = text, x = x, y = y, t = 1.3, color = color or C.colors.cyan }
end

function Lounge:add_xp(n)
  self:floater("+" .. n .. " XP", self.spark.x, self.spark.y - 70, C.colors.cyan)
  if Growth.add_xp(self.data, n) > 0 then
    self.levelup_t = 2.6
    self.data.companion.hp = Growth.stats(self.data).hp_max
    self.spark:set_state("celebrate")
    Sfx.play("level")
  end
end

function Lounge:trait(name, n)
  self.data.traits[name] = (self.data.traits[name] or 0) + (n or 1)
end

function Lounge:discover(id, label)
  if self.data.discoveries[id] then return false end
  self.data.discoveries[id] = true
  self:trait("curiosity", 1)
  self:add_xp(C.xp.discovery)
  self:floater(label or "Discovery!", self.spark.x, self.spark.y - 88, C.colors.violet)
  return true
end

function Lounge:save()
  self.data.companion.energy = self.spark.energy
  self.game.save()
end

function Lounge:show_banner(title, subtitle, text, on_close)
  self.banner = { title = title, subtitle = subtitle, text = text, on_close = on_close, t = 0 }
end

-- Objectives ----------------------------------------------------------------

function Lounge:objective()
  local p = self.p
  if not p.awake then return "A faint signal... wake Sparkbit", { { "confirm", "Wake" } } end
  local n = self:fragment_count()
  if n < 3 then
    return string.format("Collect data fragments (%d/3)", n), { { "skill1", "Scan" }, { "skill2", "Pet" } }
  end
  if not p.terminal_repaired then return "Repair the terminal", { { "confirm", "Hold" }, { "skill1", "Scan" } } end
  if not p.flowsort_done then return "Run FlowSort at the terminal", { { "confirm", "FlowSort" } } end
  if not p.loop_broken then
    local s = self.glitch and self.glitch:sealed_count() or 0
    return string.format("Break the Loop: seal anchor nodes (%d/3)", s), { { "confirm", "Hold" }, { "skill1", "Scan" } }
  end
  if not p.gateway_active then return "Restore the Gateway", { { "confirm", "Hold" } } end
  if p.improvement == "" then return "Choose a Lounge improvement", nil end
  if not p.gateway_open then return "Store the memory", nil end
  if not p.prologue_complete then return "Step into the open Gateway", { { "skill2", "Pet" } } end
  if not self.data.missions.completed.signals then
    return "Upload skills at the terminal, then explore Signals", { { "skill2", "Pet" }, { "map", "Status" } }
  end
  return "Raise Sparkbit. Chapter 2 opens in a later build.", { { "skill2", "Pet" }, { "map", "Status" } }
end

function Lounge:checklist()
  local p = self.p
  return {
    { "Wake Sparkbit", p.awake },
    { "Collect 3 fragments", self:fragment_count() >= 3 },
    { "Repair the terminal", p.terminal_repaired },
    { "FlowSort the data stream", p.flowsort_done },
    { "Break the Loop Glitch", p.loop_broken },
    { "Restore the Gateway", p.gateway_active },
    { "Choose a Lounge improvement", p.improvement ~= "" },
    { "Store the first Memory", p.memory_stored },
    { "Step through the Gateway", p.prologue_complete },
  }
end

-- Interaction targets: returns { key, label, hold = seconds | nil, fn, x, y }
function Lounge:interaction()
  local p, s = self.p, self.spark
  if not p.awake then return nil end
  -- loop nodes take priority during the Loop encounter
  if self.glitch and not self.glitch.dying then
    for i, nd in ipairs(self.glitch.nodes) do
      if not nd.sealed and U.dist(s.x, s.y, nd.x, nd.y) < SEAL_R then
        return { key = "seal" .. i, label = "Seal node", hold = C.timing.seal, node = i, x = nd.x, y = nd.y - 30,
          fn = function() self:seal_node(i) end }
      end
    end
  end
  local tx, ty = self.terminal:point()
  if U.dist(s.x, s.y, tx, ty) < INTERACT_R then
    if not p.terminal_repaired then
      if self:fragment_count() >= 3 then
        return { key = "repair", label = "Repair", hold = C.timing.repair, x = tx, y = ty - 70,
          fn = function() self:repair_terminal() end }
      end
      return { key = "terminal_locked", label = "Inspect", x = tx, y = ty - 70, fn = function()
        self.dialog:push({ { "Sparkbit", string.format("It's dead. I need %d more data fragment%s to patch it.",
          3 - self:fragment_count(), 3 - self:fragment_count() == 1 and "" or "s") } })
      end }
    end
    if not p.flowsort_done then
      return { key = "flowsort", label = "FlowSort", x = tx, y = ty - 70, fn = function() self:start_flowsort() end }
    end
    if p.loop_broken then
      return { key = "station", label = "Upload Station", x = tx, y = ty - 70, fn = function() self:open_station() end }
    end
    return { key = "terminal_read", label = "Read", x = tx, y = ty - 70, fn = function()
      self.dialog:push({ { "Terminal", "NODE 0 // STATUS: UNSTABLE. A repeating signal is corrupting the gateway." } })
    end }
  end
  local gx, gy = self.gateway:point()
  if U.dist(s.x, s.y, gx, gy) < INTERACT_R + 6 then
    if not p.loop_broken then
      return { key = "gateway_blocked", label = "Inspect", x = gx, y = gy - 80, fn = function()
        local line = p.flowsort_done and "The Loop keeps resetting it. Break the Loop first!"
          or "The gateway is dark. Something keeps resetting its charge..."
        self.dialog:push({ { "Sparkbit", line } })
      end }
    end
    if not p.gateway_active then
      return { key = "gateway", label = "Restore", hold = C.timing.gateway, x = gx, y = gy - 80,
        fn = function() self:restore_gateway() end }
    end
    if p.prologue_complete then
      return { key = "gateway_next", label = "Enter Signals", x = gx - 30, y = gy - 80, fn = function()
        self:enter_signals()
      end }
    end
  end
  for _, n in ipairs(self.npcs) do
    if U.dist(s.x, s.y, n.x, n.y) < 40 then
      return { key = "npc_" .. n.id, label = "Talk", x = n.x, y = n.y - 76, fn = function() self:talk(n) end }
    end
  end
  local pr = ROOM.processor
  if U.dist(s.x, s.y, pr.x + pr.w / 2, pr.y - 4) < INTERACT_R then
    return { key = "processor", label = "Inspect", x = pr.x + pr.w / 2, y = pr.y - 40, fn = function()
      self.dialog:push({
        { "Sparkbit", "A resource processor. Cold, but the parts are all here." },
        { "Sparkbit", "Someone built this place before us. I wonder who." },
      })
      self:discover("old_processor", "Discovery: Old Processor")
    end }
  end
  local sp = ROOM.sleep_pad
  if p.terminal_repaired and U.dist(s.x, s.y, sp.x + sp.w / 2, sp.y + sp.h / 2) < 30 then
    return { key = "rest", label = "Rest", x = sp.x + sp.w / 2, y = sp.y - 40, fn = function() self:rest() end }
  end
  return nil
end

-- Actions -------------------------------------------------------------------

function Lounge:wake()
  self.p.awake = true
  self.spark:set_state("curious", 1.4)
  self.spark:say("!", 1.4)
  Sfx.play("confirm")
  self.dialog:push({
    { "Sparkbit", "...signal... restored? Where am I?" },
    { "Sparkbit", "A broken node. Dark, quiet, and full of scattered data." },
    { "Sparkbit", "Let's build something better together." },
    { nil, "Move with the D-pad or left stick. Find the 3 glowing data fragments. X scans for them." },
  }, function() self:save() end)
end

function Lounge:pet()
  local s = self.spark
  if not s:controllable() then return end
  s:set_state("pet")
  s:say("heart", 1.2)
  self.pet_fx = 1.2
  Sfx.play("pet")
  local r = self.data.relationship
  r.pets = r.pets + 1
  if self.t - self.last_pet >= C.timing.pet_cooldown then
    self.last_pet = self.t
    r.affinity = r.affinity + 1
    self:trait("social", 1)
    Growth.care_action(self.data, 5)
    self:floater("Bond +1", s.x, s.y - 76, C.colors.pink)
    if s.energy < s.max_energy then
      s.energy = s.energy + 1
      self:trait("recovery", 1)
      self:floater("+1 Core", s.x, s.y - 94, C.colors.violet)
    end
  end
end

function Lounge:rest()
  local s = self.spark
  if self.t - self.last_rest < C.timing.rest_cooldown then
    self.dialog:push({ { "Sparkbit", "I'm not tired yet. Let's do something!" } })
    return
  end
  self.last_rest = self.t
  local bonus = self.p.improvement == "cushion" and 2 or 1
  s.energy = math.min(s.max_energy, s.energy + 2 * bonus)
  self:trait("recovery", bonus)
  self.data.companion.hp = Growth.stats(self.data).hp_max
  Growth.care_action(self.data, 10)
  s:set_state("sleep")
  s.state_dur = 1.6
  s:say("z", 1.6)
end

function Lounge:flowsort_scan()
  local s = self.spark
  if self.scan_cd > 0 or not s:controllable() then return end
  self.scan_cd, self.scan_t = C.timing.scan_cooldown, C.timing.scan_duration
  self.ring = { x = s.x, y = s.y - 20, r = 0 }
  s:set_state("sorting", 0.6)
  Sfx.play("blip")
  local sk = self.data.skills.flowsort
  sk.uses = (sk.uses or 0) + 1
  self:trait("efficiency", 0) -- scanning itself grants nothing (no fake progress)
end

function Lounge:scan_targets()
  local out, p = {}, self.p
  if self:fragment_count() < 3 then
    for _, f in ipairs(self.fragments) do out[#out + 1] = { x = f.x, y = f.y - 12, frag = f } end
  elseif not p.terminal_repaired or not p.flowsort_done then
    local x, y = self.terminal:point(); out[#out + 1] = { x = x, y = y - 20 }
  elseif self.glitch and not p.loop_broken then
    for _, nd in ipairs(self.glitch.nodes) do
      if not nd.sealed then out[#out + 1] = { x = nd.x, y = nd.y } end
    end
  elseif not p.gateway_active or (p.gateway_open and not p.prologue_complete) then
    local x, y = self.gateway:point(); out[#out + 1] = { x = x, y = y - 30 }
  end
  return out
end

function Lounge:collect(f)
  self.p.fragments[f.id] = true
  for i, ff in ipairs(self.fragments) do if ff == f then table.remove(self.fragments, i) break end end
  local r = self.data.settlement.resources
  r.data_fragments = r.data_fragments + 1
  r.bits = r.bits + 5
  self.spark:set_state("happy")
  Sfx.play("pickup")
  self:add_xp(C.xp.fragment)
  self:trait("exploration", 1)
  local n = self:fragment_count()
  if n == 3 then
    self.dialog:push({
      { "Sparkbit", "That's all three! They fit together like a key." },
      { "Sparkbit", "The terminal at the top of the room. Let's patch it." },
    }, function() self:save() end)
  else
    self:save()
  end
end

function Lounge:repair_terminal()
  self.p.terminal_repaired = true
  self.terminal:repair()
  self.data.settlement.resources.data_fragments = 0
  self:add_xp(C.xp.terminal)
  self:trait("build", 2)
  Sfx.play("confirm")
  self.spark:set_state("happy")
  self:render_floor()
  self.dialog:push({
    { "Sparkbit", "It's booting! But the data stream is scrambled..." },
    { "Sparkbit", "Time for FlowSort. I'll organize it into channels." },
  }, function() self:save(); self:start_flowsort() end)
end

function Lounge:start_flowsort()
  local FlowSort = require("src.states.flowsort")
  SM.push(FlowSort.new(self.game, function(result) self:flowsort_result(result) end))
end

function Lounge:flowsort_result(r)
  if not r.success then
    self.dialog:push({ { "Sparkbit", "Too much noise. Let's try that again when you're ready." } })
    return
  end
  self.p.flowsort_done = true
  self:add_xp(C.xp.flowsort + (r.perfect and C.xp.flowsort_perfect or 0))
  self:trait("knowledge", 1)
  self:trait("efficiency", r.perfect and 2 or 1)
  if r.misses == 0 then self:trait("focus", 1) end
  self.data.settlement.resources.bits = self.data.settlement.resources.bits + r.score
  if r.sorted then Growth.absorb(self.data, r.sorted) end
  self:spawn_glitch()
  self.spark:set_state("curious", 1.6)
  self.spark:say("?", 1.6)
  self.dialog:push({
    { "Sparkbit", "Sorted! Wait... one pattern keeps repeating. Over and over." },
    { "Sparkbit", "That's not data. It's a Loop Glitch, resetting the gateway every lap!" },
    { nil, "Seal 3 of the 4 anchor nodes to break the Loop. Hold A on a node. Each seal makes the Loop faster. Avoid touching it." },
  }, function() self:save() end)
end

function Lounge:seal_node(i)
  self.glitch:seal(i)
  Sfx.play("seal")
  self:trait("focus", 1)
  self:floater("SEALED", self.glitch.nodes[i].x, self.glitch.nodes[i].y - 40, C.colors.cyan)
  self.spark:set_state("happy")
  if self.glitch:sealed_count() >= C.glitch.seals_to_break then self:start_loop_battle() end
end

-- The sealed Loop can't close its pattern: corner it and fight (battle tutorial).
function Lounge:start_loop_battle()
  self.dialog:push({
    { "Sparkbit", "It can't close the loop anymore. It's cornered!" },
    { nil, "Battle! Strike, then press A as each ring closes. Brace with A when the foe flashes." },
  }, function()
    local Battle = require("src.states.battle")
    SM.push(Battle.new(self.game, "loop", { tutorial = true, on_done = function(res)
      self.spark:set_appearance(Growth.appearance(self.data))
      if res.won then
        self:break_loop()
      else
        self.glitch:reset_seals()
        self.spark.energy = self.spark.max_energy
        self.dialog:push({ { "Sparkbit", "It rewound and slipped away! The seals are open again. Corner it once more." } })
      end
    end }))
  end)
end

function Lounge:break_loop()
  self.glitch:die()
  self.p.loop_broken = true
  local r = self.data.settlement.resources
  r.core_shards = r.core_shards + 1
  r.bits = r.bits + 20
  self:add_xp(C.xp.loop)
  self:trait("defense", 1)
  self:trait("focus", 1)
  self.gateway:set_mode("dormant")
  self.data.missions.completed.break_the_loop = true
  self.spark:set_state("celebrate")
  self:render_floor()
  self.dialog:push({
    { "Sparkbit", "The Loop is broken! The pattern can't close anymore." },
    { "Sparkbit", "It left a Core Shard behind. Now the gateway can hold a charge." },
    { "Sparkbit", "And I absorbed its data! The terminal can turn data into skills now. It's an Upload Station." },
  }, function() self:save() end)
end

function Lounge:glitch_hit()
  local g, s = self.glitch, self.spark
  if not s:hurt(g.x, g.y) then return end
  Sfx.play("hurt")
  self:floater("-1 Core", s.x, s.y - 70, C.colors.glitch)
  self.hold.key, self.hold.t = nil, 0
  for _, nd in ipairs(g.nodes) do nd.seal_t = 0 end
  if s.energy <= 0 then
    s.energy = s.max_energy
    g:reset_seals()
    self:trait("recovery", 1)
    self.dialog:push({
      { "Sparkbit", "Ugh... core overloaded. Rebooting..." },
      { "Sparkbit", "The Loop rewound itself and undid our seals. Let's watch its path this time." },
    })
  end
end

function Lounge:restore_gateway()
  self.p.gateway_active = true
  self.gateway:set_mode("active")
  self.data.settlement.buildings.gateway.level = 1
  self:add_xp(C.xp.gateway)
  self:trait("exploration", 1)
  Sfx.play("confirm")
  self:render_floor()
  self.dialog:push({
    { "Sparkbit", "The gateway is stable!" },
    { "Sparkbit", "Before we go... let's make this place a little more ours." },
  }, function() self:save(); self:open_choice() end)
end

function Lounge:open_choice()
  local Choice = require("src.states.choice")
  SM.push(Choice.new(self.game, function(opt) self:choose_improvement(opt) end))
end

function Lounge:choose_improvement(opt)
  self.p.improvement = opt.id
  self.data.settlement.improvement = opt.id
  local b = self.data.settlement.buildings[opt.building]
  if b then b.level = math.max(b.level, 1) end
  for k, v in pairs(opt.traits) do self:trait(k, v) end
  self.spark:set_state("happy")
  self:save()
  self:store_memory()
end

function Lounge:store_memory()
  local text = "We woke in a broken node, gathered the pieces, and fixed it together."
  table.insert(self.data.memories, {
    id = "first_spark", title = "First Spark", text = text,
    level = self.data.companion.level, improvement = self.p.improvement, at = os.time(),
  })
  self.data.settlement.resources.memory_fragments = self.data.settlement.resources.memory_fragments + 1
  self.p.memory_stored = true
  self:save()
  self:show_banner("MEMORY STORED", "First Spark", text, function()
    self.p.gateway_open = true
    self.gateway:set_mode("open")
    Sfx.play("level")
    self.dialog:push({
      { "Sparkbit", "The gateway is open. Wherever it leads, we'll figure it out together." },
    }, function() self:save() end)
  end)
end

function Lounge:enter_gateway()
  local p = self.p
  p.prologue_complete = true
  self.data.missions.completed.first_spark = true
  local has = false
  for _, r in ipairs(self.data.regions.unlocked) do if r == "signals" then has = true end end
  if not has then table.insert(self.data.regions.unlocked, "signals") end
  self:render_floor()
  self:save()
  local Endcard = require("src.states.endcard")
  SM.push(Endcard.new(self.game, function()
    self.spark.x, self.spark.y = 470, 262
    self.spark.vx, self.spark.vy = 0, 0
    self.spark.facing = -1
    self.dialog:push({
      { "Sparkbit", "The gateway leads to a region called Signals. Something there is jamming everything." },
      { nil, "Visit the Upload Station (terminal) to upload skills and feed Sparkbit. Then enter the gateway." },
    })
  end))
end

-- Update --------------------------------------------------------------------

function Lounge:resume()
  Input.flush()
  self.spark:set_appearance(Growth.appearance(self.data))
end

function Lounge:open_station()
  local Station = require("src.states.station")
  SM.push(Station.new(self.game, function() self.spark:set_appearance(Growth.appearance(self.data)) end))
end

function Lounge:enter_signals()
  self:save()
  local Field = require("src.states.field")
  SM.switch(Field.new(self.game, "signals"))
end

function Lounge:talk(n)
  local d = self.data
  n:say("heart", 1.2)
  if n.id == "barkbit" then
    if d.expedition.fetch_ready then
      d.expedition.fetch_ready = false
      local card = K.CARD_ORDER[love.math.random(1, #K.CARD_ORDER)]
      d.cards[card] = (d.cards[card] or 0) + 1
      d.settlement.resources.bits = d.settlement.resources.bits + 10
      Sfx.play("pickup")
      self.dialog:push({ { "Barkbit", "Fetched it! Fetched it! +10 Bits and a " .. K.CARDS[card].name .. "!" } },
        function() self:save() end)
    else
      self.dialog:push({ { "Barkbit", "Go explore! I'll fetch something good while you're out." } })
    end
  elseif n.id == "purrbit" then
    local ev = Growth.evolution_status(d)
    if ev.evolved then
      self.dialog:push({ { "Purrbit", "Your pattern settled. " .. d.companion.name .. " suits you." } })
    elseif ev.ready then
      self.dialog:push({ { "Purrbit", "Your core is ready. Evolve at the Upload Station: you'll become " .. K.FORMS[ev.form].name .. "." } })
    elseif ev.type then
      self.dialog:push({
        { "Purrbit", string.format("You lean %s (%d%%). Keep that up and you'll become %s.", K.TYPE_NAME[ev.type],
          math.floor(ev.share * 100), K.FORMS[ev.form].name) },
        { "Purrbit", "Data treats and the Glitches you absorb change the pattern. So does how you're cared for." },
      })
    else
      self.dialog:push({ { "Purrbit", "No pattern yet. Absorb some data." } })
    end
  end
end

function Lounge:update(dt)
  self.t = self.t + dt
  self.darkness = U.approach(self.darkness, self:target_darkness(), dt * 0.35)
  if self.levelup_t > 0 then self.levelup_t = self.levelup_t - dt end
  if self.pet_fx > 0 then self.pet_fx = self.pet_fx - dt end
  for i = #self.floaters, 1, -1 do
    local f = self.floaters[i]
    f.t = f.t - dt
    f.y = f.y - dt * 24
    if f.t <= 0 then table.remove(self.floaters, i) end
  end
  self.terminal:update(dt)
  self.gateway:update(dt)
  for _, f in ipairs(self.fragments) do f:update(dt) end
  for _, n in ipairs(self.npcs) do n:update(dt) end
  self.app_t = self.app_t - dt
  if self.app_t <= 0 then
    self.app_t = 0.5
    self.spark:set_appearance(Growth.appearance(self.data))
  end
  if self.data.care.hunger < 30 and self.p.loop_broken then
    self.hunger_t = self.hunger_t + dt
    if self.hunger_t > 7 and not self.spark.emote then
      self.hunger_t = 0
      self.spark:say("hungry", 1.4)
    end
  end

  if self.banner then
    self.banner.t = self.banner.t + dt
    self.spark:update(dt, 0, 0, self)
    if self.banner.t > 0.5 and Input.pressed("confirm") then
      local cb = self.banner.on_close
      self.banner = nil
      Input.flush()
      Sfx.play("confirm")
      if cb then cb() end
    end
    return
  end
  if self.dialog:active() then
    self.dialog:update(dt)
    self.spark:update(dt, 0, 0, self)
    if self.glitch and self.glitch.dying then self.glitch:update(dt) end
    if Input.pressed("confirm") or Input.pressed("cancel") then
      self.dialog:advance()
      -- the button that closed the dialog must not start a hold/interaction
      if not self.dialog:active() then Input.flush() end
    end
    return
  end
  if self.pending_choice then self.pending_choice = false; self:open_choice() return end
  if self.pending_memory then self.pending_memory = false; self:store_memory() return end

  if Input.pressed("pause") then
    SM.push(require("src.states.pause").new(self.game, self))
    return
  end
  if Input.pressed("map") then self.show_objectives = not self.show_objectives end
  if self.show_objectives then
    if Input.pressed("cancel") or Input.pressed("confirm") then self.show_objectives = false end
    return
  end

  if not self.p.awake then
    self.spark:update(dt, 0, 0, self)
    if Input.pressed("confirm") then self:wake() end
    return
  end

  if self.scan_cd > 0 then self.scan_cd = self.scan_cd - dt end
  if self.scan_t > 0 then self.scan_t = self.scan_t - dt end
  if self.ring then
    self.ring.r = self.ring.r + dt * 420
    if self.ring.r > 360 then self.ring = nil end
  end
  if Input.pressed("skill1") then self:flowsort_scan() end
  if Input.pressed("skill2") then self:pet() end

  local mx, my = Input.move()
  self.spark:update(dt, mx, my, self)
  self:update_interaction(dt)
  self:update_fragments()

  if self.glitch then
    self.glitch:update(dt)
    if self.glitch.dead then
      self.glitch = nil
    elseif not self.glitch.dying and U.dist(self.spark.x, self.spark.y, self.glitch.x, self.glitch.y) < C.glitch.hit_radius then
      self:glitch_hit()
    end
  end

  if self.p.gateway_open and not self.p.prologue_complete then
    local gx, gy = self.gateway:point()
    if self.spark.x > gx - 4 and math.abs(self.spark.y - gy) < 40 then self:enter_gateway() end
  end
end

function Lounge:update_interaction(dt)
  local it = self:interaction()
  self.current = it
  local s = self.spark
  if not it then
    if self.hold.key then self:end_hold() end
    return
  end
  if it.hold then
    if self.hold.key ~= it.key then
      if self.hold.key then self:end_hold() end
      if Input.down("confirm") and s:controllable() then
        self.hold.key, self.hold.t = it.key, 0
        s.vx, s.vy = 0, 0
        s:set_state(it.node and "focus" or "building", 999)
      end
    elseif Input.down("confirm") then
      self.hold.t = self.hold.t + dt
      if it.node then self.glitch.nodes[it.node].seal_t = self.hold.t end
      if self.hold.t >= it.hold then
        self.hold.key, self.hold.t = nil, 0
        s:set_state("idle")
        it.fn()
      end
    else
      self:end_hold()
    end
  elseif Input.pressed("confirm") and s:controllable() then
    Sfx.play("blip")
    it.fn()
  end
end

function Lounge:end_hold()
  if self.glitch then
    for _, nd in ipairs(self.glitch.nodes) do if not nd.sealed then nd.seal_t = 0 end end
  end
  self.hold.key, self.hold.t = nil, 0
  local st = self.spark.state
  if st == "building" or st == "focus" then self.spark:set_state("idle") end
end

function Lounge:update_fragments()
  local s = self.spark
  for i = #self.fragments, 1, -1 do
    local f = self.fragments[i]
    local d = U.dist(s.x, s.y, f.x, f.y)
    if not f.revealed and d < Fragment.REVEAL_RADIUS then
      f.revealed = true
      s:set_state("curious")
      s:say("?", 1.2)
      Sfx.play("good")
      self:discover("hidden_fragment", "Curiosity: hidden fragment!")
    end
    if f.revealed and d < Fragment.PICKUP_RADIUS then self:collect(f) end
  end
end

-- Draw ----------------------------------------------------------------------

local function draw_improvement(id, t)
  local lg = love.graphics
  local spot = ROOM.improvements[id]
  if not spot then return end
  local x, y = spot.x, spot.y
  if id == "cushion" then
    UI.setColor(C.colors.pink, 0.85)
    lg.ellipse("fill", x, y - 6, 22, 9)
    UI.setColor(C.colors.white, 0.5)
    lg.ellipse("fill", x - 6, y - 9, 8, 3)
  elseif id == "workbench" then
    UI.setColor(C.colors.outline)
    lg.rectangle("fill", x - 28, y - 24, 56, 26, 3, 3)
    UI.setColor(C.colors.dim)
    lg.rectangle("fill", x - 24, y - 12, 6, 12)
    lg.rectangle("fill", x + 18, y - 12, 6, 12)
    UI.setColor(C.colors.amber)
    lg.rectangle("fill", x - 26, y - 22, 52, 8, 2, 2)
    UI.setColor(C.colors.white, 0.8)
    lg.rectangle("fill", x - 16, y - 30, 12, 4)
    lg.rectangle("fill", x - 12, y - 34, 4, 8)
    UI.setColor(C.colors.cyan, 0.6 + 0.4 * math.sin(t * 5))
    lg.rectangle("fill", x + 8, y - 30, 8, 8)
  elseif id == "shelf" then
    UI.setColor(C.colors.outline)
    lg.rectangle("fill", x - 24, y - 30, 48, 30, 3, 3)
    for i = 0, 4 do
      UI.setColor(i % 2 == 0 and C.colors.violet or C.colors.cyan)
      lg.rectangle("fill", x - 20 + i * 9, y - 26, 6, 10)
      lg.rectangle("fill", x - 20 + i * 9, y - 13, 6, 10)
    end
  end
end

function Lounge:draw_light()
  local lg = love.graphics
  local d = self.darkness
  if d <= 0.01 then return end
  if not Lounge.light_img then
    local n = 128
    local id = love.image.newImageData(n, n)
    for y = 0, n - 1 do
      for x = 0, n - 1 do
        local dx, dy = (x + 0.5) / n * 2 - 1, (y + 0.5) / n * 2 - 1
        local r = math.min(1, math.sqrt(dx * dx + dy * dy))
        id:setPixel(x, y, 0, 0, 0, r * r * (3 - 2 * r))
      end
    end
    Lounge.light_img = lg.newImage(id)
    Lounge.light_img:setFilter("linear", "linear")
  end
  local radius = self.p.awake and 260 or 110
  local cx, cy = math.floor(self.spark.x), math.floor(self.spark.y - 20)
  local x0, y0, x1, y1 = cx - radius, cy - radius, cx + radius, cy + radius
  lg.setColor(1, 1, 1, d)
  lg.draw(Lounge.light_img, x0, y0, 0, radius * 2 / 128, radius * 2 / 128)
  lg.setColor(0, 0, 0, d)
  if y0 > 0 then lg.rectangle("fill", 0, 0, C.WIDTH, y0) end
  if y1 < C.HEIGHT then lg.rectangle("fill", 0, y1, C.WIDTH, C.HEIGHT - y1) end
  if x0 > 0 then lg.rectangle("fill", 0, math.max(0, y0), x0, y1 - math.max(0, y0)) end
  if x1 < C.WIDTH then lg.rectangle("fill", x1, math.max(0, y0), C.WIDTH - x1, y1 - math.max(0, y0)) end
end

function Lounge:draw()
  local lg = love.graphics
  lg.setColor(1, 1, 1, 1)
  lg.draw(self.floor_canvas, 0, 0)

  if self.p.improvement ~= "" then draw_improvement(self.p.improvement, self.t) end
  if self.glitch then self.glitch:draw_nodes(self.current and self.current.node) end

  -- y-sorted props + actors
  local list = {
    { y = self.terminal:sort_y(), d = self.terminal },
    { y = self.gateway:sort_y(), d = self.gateway },
    { y = self.spark.y, d = self.spark },
  }
  for _, f in ipairs(self.fragments) do list[#list + 1] = { y = f.y, d = f } end
  if self.glitch then list[#list + 1] = { y = self.glitch.y, d = self.glitch } end
  for _, n in ipairs(self.npcs) do list[#list + 1] = { y = n.y, d = n } end
  for _, o in ipairs(ROOM.obstacles) do list[#list + 1] = { y = o.y + o.h, o = o } end
  table.sort(list, function(a, b) return a.y < b.y end)
  for _, e in ipairs(list) do
    if e.o then self:draw_obstacle(e.o) else e.d:draw() end
  end

  if self.pet_fx > 0 then self:draw_pet_hand() end
  self:draw_scan()
  self:draw_light()

  -- prompt bubble over the current interaction
  local it = self.current
  if it and not self.dialog:active() and not self.banner and self.p.awake then
    local label = it.hold and ("Hold: " .. it.label) or it.label
    local w = UI.font_small:getWidth(label) + 34
    local x, y = math.floor(it.x - w / 2), math.floor(it.y)
    UI.panel(x, y, w, 24)
    UI.glyph("confirm", x + 4, y + 3)
    UI.text(label, x + 26, y + 4, C.colors.text, UI.font_small)
    if it.hold and self.hold.key == it.key then
      UI.bar(x + 4, y + 26, w - 8, 4, self.hold.t / it.hold, C.colors.cyan)
    end
  end

  for _, f in ipairs(self.floaters) do
    local c = f.color
    local fx = U.clamp(f.x - 150, 4, C.WIDTH - 304)
    UI.text(f.text, fx, f.y, { c[1], c[2], c[3], math.min(1, f.t * 2) }, UI.font, "center", 300)
  end

  local obj, prompts = self:objective()
  Hud.draw(self.data, self.spark, (not self.dialog:active()) and obj or nil, prompts, self.t,
    { core = self.glitch ~= nil, frags = not self.p.terminal_repaired })

  if self.levelup_t > 0 then
    local a = math.min(1, self.levelup_t * 2)
    UI.panel(240, 12, 208, 40, C.colors.amber, a)
    UI.text("LEVEL UP!  Lv " .. self.data.companion.level, 240, 18, { C.colors.amber[1], C.colors.amber[2], C.colors.amber[3], a }, UI.font_big, "center", 208)
  end

  self.dialog:draw()
  if self.banner then self:draw_banner() end
  if self.show_objectives then self:draw_objectives() end
end

function Lounge:draw_obstacle(o)
  local lg = love.graphics
  UI.setColor(C.colors.outline, 0.5)
  lg.rectangle("fill", o.x + 3, o.y + o.h - 4, o.w, 8, 3, 3)
  UI.setColor(C.colors.outline)
  lg.rectangle("fill", o.x, o.y, o.w, o.h, 3, 3)
  if o.kind == "pillar" then
    UI.setColor(C.colors.wall_top)
    lg.rectangle("fill", o.x + 3, o.y + 3, o.w - 6, o.h - 6, 2, 2)
    UI.setColor(C.colors.violet, 0.5 + 0.3 * math.sin(self.t * 2))
    lg.rectangle("fill", o.x + o.w / 2 - 2, o.y + 8, 4, o.h - 16)
  else
    UI.setColor(C.colors.wall)
    lg.rectangle("fill", o.x + 3, o.y + 3, o.w - 6, o.h - 6, 2, 2)
    UI.setColor(C.colors.dim, 0.6)
    lg.line(o.x + 4, o.y + 4, o.x + o.w - 4, o.y + o.h - 4)
    lg.line(o.x + o.w - 4, o.y + 4, o.x + 4, o.y + o.h - 4)
  end
end

function Lounge:draw_pet_hand()
  local lg = love.graphics
  local s = self.spark
  local wob = math.sin(self.t * 14) * 4
  local x, y = s.x + wob, s.y - 58 - math.abs(wob)
  UI.setColor(C.colors.amber, math.min(1, self.pet_fx * 2))
  lg.rectangle("fill", x - 9, y, 18, 10, 4, 4)
  for i = 0, 3 do lg.rectangle("fill", x - 8 + i * 4.5, y - 6, 3.5, 8, 2, 2) end
end

function Lounge:draw_scan()
  local lg = love.graphics
  if self.ring then
    UI.setColor(C.colors.cyan, math.max(0, 1 - self.ring.r / 360) * 0.7)
    lg.setLineWidth(2)
    lg.circle("line", self.ring.x, self.ring.y, self.ring.r)
    lg.setLineWidth(1)
  end
  if self.scan_t <= 0 then return end
  local a = math.min(1, self.scan_t)
  local s = self.spark
  for _, tg in ipairs(self:scan_targets()) do
    local d = U.dist(s.x, s.y - 20, tg.x, tg.y)
    local segs = math.floor(d / 10)
    UI.setColor(C.colors.cyan, 0.5 * a)
    for i = 0, segs - 1, 2 do
      local p0, p1 = i / segs, (i + 1) / segs
      lg.line(s.x + (tg.x - s.x) * p0, s.y - 20 + (tg.y - s.y + 20) * p0, s.x + (tg.x - s.x) * p1, s.y - 20 + (tg.y - s.y + 20) * p1)
    end
    if tg.frag and not tg.frag.revealed then
      tg.frag:draw_hint(a)
    else
      local r = 14 + math.sin(self.t * 8) * 2
      UI.setColor(C.colors.cyan, a)
      lg.rectangle("line", tg.x - r, tg.y - r, r * 2, r * 2)
    end
  end
  -- Pattern Echo: show where the Loop goes next
  if self.glitch and not self.glitch.dying then
    for k, idx in ipairs(self.glitch:forecast(2)) do
      local nd = self.glitch.nodes[idx]
      UI.text(tostring(k), nd.x - 10, nd.y - 8, { C.colors.glitch[1], C.colors.glitch[2], C.colors.glitch[3], a }, UI.font, "center", 20)
    end
  end
end

function Lounge:draw_banner()
  local b = self.banner
  local a = math.min(1, b.t * 3)
  UI.setColor(C.colors.bg, 0.6 * a)
  love.graphics.rectangle("fill", 0, 0, C.WIDTH, C.HEIGHT)
  UI.panel(100, 140, 440, 200, C.colors.violet, a)
  UI.text(b.title, 100, 158, { C.colors.violet[1], C.colors.violet[2], C.colors.violet[3], a }, UI.font, "center", 440)
  UI.text(b.subtitle, 100, 184, { 1, 1, 1, a }, UI.font_big, "center", 440)
  UI.text(b.text, 130, 230, { C.colors.text[1], C.colors.text[2], C.colors.text[3], a }, UI.font, "center", 380)
  if b.t > 0.5 then UI.prompts({ { "confirm", "Continue" } }, 520, 306, true) end
end

function Lounge:draw_objectives()
  local lg = love.graphics
  UI.setColor(C.colors.bg, 0.7)
  lg.rectangle("fill", 0, 0, C.WIDTH, C.HEIGHT)
  UI.panel(40, 70, 560, 360, C.colors.cyan)
  UI.text("FIRST SPARK // OBJECTIVES", 60, 84, C.colors.cyan, UI.font)
  for i, row in ipairs(self:checklist()) do
    local y = 116 + (i - 1) * 26
    UI.setColor(row[2] and C.colors.green or C.colors.dim)
    lg.rectangle(row[2] and "fill" or "line", 62, y + 3, 12, 12, 2, 2)
    UI.text(row[1], 84, y, row[2] and C.colors.text or C.colors.dim, UI.font_small)
  end
  -- status column
  local d = self.data
  local x = 340
  UI.text("SPARKBIT", x, 116, C.colors.cyan, UI.font_small)
  UI.text(string.format("Level %d   XP %d/%d", d.companion.level, d.companion.xp, C.xp_to_next(d.companion.level)), x, 136, C.colors.text, UI.font_small)
  UI.text(string.format("Bond %d   Pets %d", d.relationship.affinity, d.relationship.pets), x, 156, C.colors.text, UI.font_small)
  UI.text("Trait pressure", x, 186, C.colors.cyan, UI.font_small)
  local traits = {}
  for k, v in pairs(d.traits) do if v > 0 then traits[#traits + 1] = { k, v } end end
  table.sort(traits, function(a, b) return a[2] > b[2] or (a[2] == b[2] and a[1] < b[1]) end)
  for i = 1, math.min(6, #traits) do
    local y = 206 + (i - 1) * 20
    UI.text(traits[i][1]:sub(1, 1):upper() .. traits[i][1]:sub(2), x, y, C.colors.text, UI.font_small)
    UI.bar(x + 92, y + 5, 130, 6, traits[i][2] / 8, C.colors.violet)
  end
  if #traits == 0 then UI.text("(none yet: play shapes Sparkbit)", x, 206, C.colors.dim, UI.font_small) end
  UI.text(string.format("Memories %d   Discoveries %d", #d.memories, U.count(d.discoveries)), x, 340, C.colors.text, UI.font_small)
  UI.text("Playtime " .. U.format_time(d.player.playtime), x, 360, C.colors.text, UI.font_small)
  UI.prompts({ { "cancel", "Close" } }, 586, 400, true)
end

return Lounge
