-- Scripted end-to-end playthrough. Enabled with BITLINGS_AUTOTEST=1.
-- Drives the real game through virtual input (teleporting only to skip
-- walking), asserts state + save contents, captures screenshots, and exits
-- with code 0 (pass) or 1 (fail). Used by tools/autotest.sh.

local Input = require("src.input.input")
local SM = require("src.core.state")
local ROOM = require("src.data.room")
local Save = require("src.save.save")
local json = require("src.core.json")
local Perf = require("src.ui.perf")
local U = require("src.core.util")
local K = require("src.data.content")
local Growth = require("src.systems.growth")

local AT = {}
AT.__index = AT

local TIMEOUT = 900

function AT.new(game)
  local self = setmetatable({ game = game, t = 0, checks = 0, done = false }, AT)
  Save.delete() -- clean profile every run
  game.data = Save.new_default()
  game.has_save = false
  self.co = coroutine.create(function()
    local ok, err = xpcall(function() self:script() end, debug.traceback)
    if not ok then error(err, 0) end
  end)
  return self
end

function AT:finish(code, msg)
  if self.done then return end
  self.done = true
  print(msg)
  io.stdout:flush()
  love.event.quit(code)
end

function AT:update(dt)
  if self.done then return end
  self.t = self.t + dt
  if self.t > TIMEOUT then return self:finish(1, "AUTOTEST FAIL: global timeout") end
  local ok, err = coroutine.resume(self.co)
  if not ok then return self:finish(1, "AUTOTEST FAIL: " .. tostring(err)) end
  if coroutine.status(self.co) == "dead" then
    self:finish(0, string.format("AUTOTEST PASS (%d checks, %.1fs simulated)", self.checks, self.t))
  end
end

-- helpers (run inside the coroutine) ---------------------------------------
function AT:frames(n) for _ = 1, n do coroutine.yield() end end
function AT:sec(s) local t0 = self.t; while self.t - t0 < s do coroutine.yield() end end
function AT:tap(a) Input.inject(a, 1); self:frames(3) end
function AT:hold(a, s) Input.hold(a, true); self:sec(s); Input.hold(a, false); self:frames(2) end
function AT:wait_for(cond, timeout, what)
  local t0 = self.t
  while not cond() do
    if self.t - t0 > (timeout or 10) then error("timed out waiting for " .. what, 0) end
    coroutine.yield()
  end
end
function AT:check(c, msg)
  if not c then error("check failed: " .. msg, 0) end
  self.checks = self.checks + 1
  print("  ok " .. self.checks .. " - " .. msg)
end
function AT:shot(name)
  love.graphics.captureScreenshot("shot_" .. name .. ".png")
  -- wait for real drawn frames (BITLINGS_SPEED runs several updates per draw)
  local f0 = self.game.frames_drawn or 0
  while (self.game.frames_drawn or 0) < f0 + 2 do coroutine.yield() end
end
function AT:top() return SM.top() end
function AT:teleport(L, x, y)
  L.spark.x, L.spark.y, L.spark.vx, L.spark.vy = x, y, 0, 0
  self:frames(2)
end
function AT:clear_dialogs(L)
  local n = 0
  while L.dialog:active() or L.banner do
    if L.banner then self:sec(0.55) end
    self:tap("confirm")
    n = n + 1
    if n > 80 then error("dialog never closed", 0) end
  end
  self:frames(2)
end

-- Plays a battle like a skilled player: perfect syncs/braces, heals when low,
-- guards charge attacks, overclocks when full, uses a super-effective skill.
function AT:fight(shot_name)
  self:wait_for(function() return SM.name() == "battle" end, 3, "battle")
  local B = self:top()
  local guard, shot_done = 0, false
  while B.phase ~= "win" and B.phase ~= "lose" do
    guard = guard + 1
    if guard > 20000 then error("battle stuck in phase " .. B.phase, 0) end
    local ph = B.phase
    if ph == "menu" then
      if shot_name and not shot_done then shot_done = true; self:shot(shot_name) end
      local items = B:menu_items()
      local want, skill = "strike", nil
      for _, id in ipairs(self.game.data.skills.equipped) do
        local sk = K.SKILLS[id]
        if sk.kind == "attack" and B.en >= sk.en and Growth.type_mult(sk.type, B.enemy.type) > 1 then skill = id end
      end
      if skill then want = "skills" end
      if B.enemy.charging then want = "guard" end
      if items[1].id == "overclock" then want = "overclock" end
      if B.hp < B.st.hp_max * 0.4 and (self.game.data.cards.heal or 0) > 0 and not B.card_used then want = "cards" end
      local idx
      for i, it in ipairs(items) do if it.id == want then idx = i end end
      while B.menu_sel ~= idx do self:tap("down") end
      self:tap("confirm")
      if want == "cards" then
        local hi
        for i, id in ipairs(K.CARD_ORDER) do if id == "heal" then hi = i end end
        while B.sub_sel ~= hi do self:tap("down") end
        self:tap("confirm")
      elseif want == "skills" then
        local si
        for i, id in ipairs(self.game.data.skills.equipped) do if id == skill then si = i end end
        while B.sub_sel ~= si do self:tap("down") end
        self:tap("confirm")
      end
    elseif ph == "strike" then
      if B:in_sync_window() then Input.inject("confirm", 1) end
      coroutine.yield()
    elseif ph == "brace" then
      if B:in_brace_window() then Input.inject("confirm", 1) end
      coroutine.yield()
    else
      coroutine.yield()
    end
  end
  local won = B.phase == "win"
  self:sec(1.3)
  self:tap("confirm")
  self:wait_for(function() return SM.name() ~= "battle" end, 3, "battle closes")
  self.battles = (self.battles or 0) + 1
  return won
end

-- the playthrough ----------------------------------------------------------
function AT:script()
  local g = self.game
  print("AUTOTEST start")
  self:wait_for(function() return SM.name() == "boot" end, 2, "boot")
  self:sec(0.6); self:shot("00_boot_pixel")
  self:sec(1.6); self:shot("01_boot_signal")
  self:wait_for(function() return self:top().phase == "title" end, 4, "title")
  self:sec(0.6); self:shot("02_title")
  local boot = self:top()
  self:check(boot.items[1].act == "new", "fresh profile offers Wake Sparkbit first")
  self:tap("confirm")
  self:wait_for(function() return SM.name() == "lounge" end, 2, "lounge")
  local L = self:top()

  -- 1 wake
  self:check(L.spark.state == "sleep", "Sparkbit starts asleep")
  self:sec(0.4); self:shot("03_asleep")
  self:tap("confirm")
  self:check(L.p.awake, "A wakes Sparkbit")
  self:sec(0.8); self:shot("04_wake_dialog")
  self:clear_dialogs(L)
  self:check(Save.fs.getInfo(Save.FILE) ~= nil, "save written after waking")

  -- 2 movement + collision + idle
  local x0 = L.spark.x
  self:hold("right", 0.6)
  self:check(L.spark.x > x0 + 40, "hero-direct movement (moved " .. math.floor(L.spark.x - x0) .. "px)")
  self:hold("left", 3.0)
  self:check(L.spark.x - L.spark.w / 2 >= ROOM.bounds.x - 0.01, "left wall blocks movement")
  local crate = ROOM.obstacles[1]
  self:teleport(L, crate.x + crate.w / 2, crate.y - 12)
  self:hold("down", 0.8)
  self:check(L.spark.y <= crate.y + 0.01, "crate blocks movement")
  self:sec(1.0)
  self:check(L.spark.state == "idle", "returns to idle when still")
  self:sec(4.0)
  self:check(L.spark.idle_t > 4, "idle timer drives idle life")

  -- 3 pet
  local aff = g.data.relationship.affinity
  self:tap("skill2")
  self:check(L.spark.state == "pet", "Y pets Sparkbit")
  self:sec(0.3); self:shot("05_pet")
  self:check(g.data.relationship.affinity == aff + 1, "pet raises bond")
  self:sec(1.5)
  self:check(L.spark:controllable(), "pet reaction finished")
  self:tap("skill2")
  self:check(g.data.relationship.affinity == aff + 1, "pet spam does not farm bond (cooldown)")
  self:sec(1.4)

  -- 4 FlowSort scan + fragments
  self:teleport(L, 200, 360)
  self:tap("skill1")
  self:check(L.scan_t > 0, "X starts FlowSort scan")
  self:sec(0.5); self:shot("06_scan")
  self:sec(0.8)
  for _, f in ipairs(ROOM.fragments) do
    if f.hidden then
      self:teleport(L, f.x + 70, f.y - 10)
      self:frames(3)
      local obj
      for _, ff in ipairs(L.fragments) do if ff.id == f.id then obj = ff end end
      self:check(obj and obj.revealed, "Curiosity reveals hidden fragment " .. f.id)
      self:check(g.data.discoveries.hidden_fragment == true, "hidden fragment recorded as discovery")
      self:sec(1.3)
    end
    self:teleport(L, f.x, f.y)
    self:frames(3)
    self:check(L.p.fragments[f.id] == true, "collected fragment " .. f.id)
    self:sec(1.0)
  end
  self:check(L:fragment_count() == 3, "3/3 fragments")
  self:clear_dialogs(L)

  -- 5 terminal repair (hold A)
  local tx, ty = L.terminal:point()
  self:teleport(L, tx, ty)
  self:sec(0.2); self:shot("07_terminal_prompt")
  Input.hold("confirm", true)
  self:sec(1.0)
  self:check(L.spark.state == "building", "holding A at terminal = building state")
  self:shot("08_repairing")
  self:sec(1.3)
  Input.hold("confirm", false)
  self:frames(2)
  self:check(L.p.terminal_repaired, "terminal repaired")
  self:clear_dialogs(L)

  -- 6 FlowSort minigame (first run fails on purpose, then retry and win)
  self:wait_for(function() return SM.name() == "flowsort" end, 3, "flowsort")
  local F = self:top()
  self:sec(0.3); self:shot("09_flowsort_intro")
  self:tap("confirm")
  self:wait_for(function() return F.phase == "result" end, 60, "flowsort fail run")
  self:check(not F.result.success, "doing nothing fails FlowSort")
  self:tap("confirm") -- Retry
  local DIR = { build = "left", archive = "up", pulse = "right", noise = "cancel" }
  local shot_taken = false
  self:wait_for(function()
    local p = F.packet
    if F.phase == "result" then return true end
    if p and not p.resolved and p.t > 0.25 then
      if F.idx == 6 and not shot_taken then
        shot_taken = true
        love.graphics.captureScreenshot("shot_10_flowsort_play.png")
      end
      Input.inject(DIR[p.kind], 1)
    end
    return false
  end, 90, "flowsort result")
  self:check(F.result.success and F.result.perfect, "correct sorting = perfect FlowSort")
  self:sec(0.4); self:shot("11_flowsort_result")
  self:tap("confirm")
  self:wait_for(function() return SM.name() == "lounge" end, 2, "back to lounge")
  self:check(L.p.flowsort_done and L.glitch ~= nil, "FlowSort reveals the Loop Glitch")
  self:sec(0.5); self:shot("12_loop_reveal")
  self:clear_dialogs(L)

  -- 7 break the Loop: seal nodes away from the glitch
  local hits = 0
  local guard = 0
  local orig_hit = L.glitch_hit
  L.glitch_hit = function(self_) hits = hits + 1; orig_hit(self_) end
  while not L.p.loop_broken do
    guard = guard + 1
    if guard > 30 then error("could not break the loop", 0) end
    local G = L.glitch
    local best, bd = nil, -1
    local avoid = G.target
    for i, nd in ipairs(G.nodes) do
      if not nd.sealed and i ~= avoid then
        local d = U.dist(nd.x, nd.y, G.x, G.y)
        if d > bd then best, bd = i, d end
      end
    end
    best = best or G:next_unsealed(1)
    local nd = G.nodes[best]
    -- player strategy: commit only once the Loop is heading away
    self:wait_for(function() return G.target ~= best and U.dist(G.x, G.y, nd.x, nd.y) > 60 end, 8, "safe window")
    self:teleport(L, nd.x, nd.y + 4)
    self:wait_for(function() return L.spark:controllable() end, 3, "controllable")
    Input.hold("confirm", true)
    self:wait_for(function() return nd.sealed or L.spark.state == "hurt" end, 3, "seal or hit")
    Input.hold("confirm", false)
    self:frames(3)
    if os.getenv("AT_DEBUG") then print(string.format("    loop iter %d node %d sealed=%s state=%s energy=%d count=%d hold=%s", guard, best, tostring(nd.sealed), L.spark.state, L.spark.energy, G:sealed_count(), tostring(L.hold.key))) end
    if G:sealed_count() == 1 and not self.sealed_shot then self.sealed_shot = true; self:shot("13_loop_sealing") end
    self:clear_dialogs(L)
    if SM.name() == "battle" then
      local won = self:fight("13b_battle_tutorial")
      self:check(won, "won the Loop tutorial battle")
      self:wait_for(function() return SM.name() == "lounge" end, 3, "lounge after loop battle")
    end
  end
  self:check(g.data.data_core.lifetime.pulse >= 10, "FlowSort + Loop battle absorbed data (pulse " .. g.data.data_core.lifetime.pulse .. ")")
  self:check(L.p.loop_broken, "Loop broken after 3 seals (" .. hits .. " hits taken)")
  self:check(g.data.settlement.resources.core_shards >= 1, "Loop drops a Core Shard")
  self:clear_dialogs(L)
  self:sec(1.2)
  self:check(L.glitch == nil, "Loop Glitch dissolves")

  -- 8 gateway restore
  local gx, gy = L.gateway:point()
  self:teleport(L, gx, gy)
  if os.getenv("AT_DEBUG") then
    local it = L:interaction()
    print("    gateway: spark", L.spark.x, L.spark.y, L.spark.state, "it", it and it.key, "mode", L.gateway.mode, "dialog", L.dialog:active())
  end
  Input.hold("confirm", true)
  self:wait_for(function() return L.p.gateway_active end, 6, "gateway restore while holding A")
  if os.getenv("AT_DEBUG") then print("    after hold:", L.spark.state, L.hold.key, L.hold.t, L.current and L.current.key, SM.name()) end
  Input.hold("confirm", false)
  self:frames(2)
  self:check(L.p.gateway_active, "gateway restored")
  self:check(g.data.companion.level >= 2, "first level up reached (Lv " .. g.data.companion.level .. ")")
  self:clear_dialogs(L)

  -- 9 improvement choice
  self:wait_for(function() return SM.name() == "choice" end, 3, "choice")
  self:sec(0.4)
  self:tap("right")
  self:sec(0.2); self:shot("14_choice")
  self:tap("confirm")
  self:check(L.p.improvement == "workbench", "chose Forge Workbench")
  self:check(g.data.traits.build >= 5, "choice pushes Build trait")

  -- 10 memory
  self:wait_for(function() return L.banner ~= nil end, 2, "memory banner")
  self:sec(0.6); self:shot("15_memory")
  self:check(#g.data.memories == 1 and g.data.memories[1].id == "first_spark", "first Memory stored")
  self:clear_dialogs(L)
  self:check(L.p.gateway_open, "gateway opens")

  -- 11 step through
  self:teleport(L, gx - 70, gy)
  self:hold("right", 1.2)
  self:wait_for(function() return SM.name() == "endcard" end, 3, "endcard")
  self:sec(2.6); self:shot("16_endcard")
  self:tap("confirm")
  self:wait_for(function() return SM.name() == "lounge" end, 2, "lounge after endcard")
  self:clear_dialogs(L)
  self:check(L.p.prologue_complete, "prologue complete")
  self:sec(0.6); self:shot("17_lounge_after")

  -- 12 save contents on disk
  local raw = love.filesystem.read(Save.FILE)
  local d = json.decode(raw)
  self:check(d.save_version == Save.VERSION, "save_version on disk = " .. Save.VERSION)
  self:check(d.progress.prologue_complete == true, "prologue flag persisted")
  self:check(d.missions.completed.first_spark == true, "mission completion persisted")
  self:check(d.settlement.improvement == "workbench", "improvement persisted")
  self:check(#d.memories == 1, "memory persisted")
  self:check(love.filesystem.getInfo(Save.BACKUP) ~= nil, "backup slot written")
  local d2 = Save.load()
  self:check(d2 and d2.companion.xp == g.data.companion.xp and d2.companion.level == g.data.companion.level, "reload round-trips XP/level")

  -- 13 pause, perf overlay, objectives
  self:tap("pause")
  self:check(SM.name() == "pause", "Start opens pause")
  self:sec(0.2); self:shot("18_pause")
  local P = self:top()
  for i, it in ipairs(P.items) do if it.id == "perf" then while P.sel ~= i do self:tap("down") end end end
  self:tap("confirm")
  self:check(Perf.enabled, "perf overlay toggled on")
  self:tap("cancel")
  self:check(SM.name() == "lounge", "B resumes")
  self:sec(1.0); self:shot("19_perf_overlay")
  self:tap("map")
  self:check(L.show_objectives, "Select opens objectives/status")
  self:sec(0.2); self:shot("20_objectives")
  self:tap("cancel")

  -- 14 swap A/B
  self:tap("pause")
  P = self:top()
  for i, it in ipairs(P.items) do if it.id == "swap" then while P.sel ~= i do self:tap("down") end end end
  self:tap("confirm")
  self:check(Input.swap_ab, "A/B swap enabled")
  self:check(SM.name() == "pause", "swap does not leak a cancel press")
  self:tap("confirm")
  self:check(not Input.swap_ab, "A/B swap disabled")
  self:tap("cancel")

  -- 15 Chapter 1: Upload Station -> Signals -> evolution ----------------------
  local d = g.data
  Perf.enabled = false
  local Lx = self:top()
  self:check(SM.name() == "lounge", "back in lounge for chapter 1")
  self:clear_dialogs(Lx)
  local tx2, ty2 = Lx.terminal:point()
  self:teleport(Lx, tx2, ty2)
  self:tap("confirm")
  self:check(SM.name() == "station", "terminal opens the Upload Station")
  local S = self:top()
  self:sec(0.3); self:shot("23_station_status")
  self:tap("r1")
  local rows = S:rows()
  local pi
  for i, r in ipairs(rows) do if r.id == "pulse_dash" then pi = i end end
  while S.sel ~= pi do self:tap("down") end
  self:tap("confirm")
  self:check(Growth.is_equipped(d, "pulse_dash"), "uploaded + equipped Pulse Dash with banked data")
  self:sec(0.2); self:shot("24_station_skills")
  self:tap("r1")
  rows = S:rows()
  for i, r in ipairs(rows) do if r.id == "sync_lens" then pi = i end end
  while S.sel ~= pi do self:tap("down") end
  self:tap("confirm"); self:tap("confirm")
  self:check(Growth.has_aspect(d, "sync_lens"), "bought + installed Sync Lens aspect")
  rows = S:rows()
  while S.sel ~= #rows do self:tap("down") end
  self:tap("confirm")
  self:check(d.aspects.scarf ~= "blue", "scarf color changed to " .. d.aspects.scarf)
  self:sec(0.2); self:shot("25_station_aspects")
  self:tap("r1")
  d.care.hunger = 50
  local bits0 = d.settlement.resources.bits
  self:tap("confirm")
  self:check(d.settlement.resources.bits == bits0 - 5 and d.care.hunger > 50, "fed a Byte Snack")
  self:sec(0.2); self:shot("26_station_care")
  self:tap("r1")
  self:sec(0.2); self:shot("27_bitdex")
  self:tap("cancel")
  self:check(SM.name() == "lounge", "B closes the station")

  local gx2, gy2 = Lx.gateway:point()
  self:teleport(Lx, gx2, gy2)
  self:tap("confirm")
  self:wait_for(function() return SM.name() == "field" end, 2, "Signals")
  local F1 = self:top()
  self:check(F1.screen_id == "fields", "gateway leads to Signal Fields")
  self:sec(1.2); self:shot("28_signals_fields")
  local function clear_screen(Fs, shotname)
    local n = 0
    while #Fs.enemies > 0 do
      n = n + 1
      if n > 12 then error("could not clear screen", 0) end
      self:wait_for(function() return Fs.grace <= 0 end, 3, "grace")
      local e = Fs.enemies[1]
      self:teleport(Fs, e.x, e.y)
      local won = self:fight(n == 1 and shotname or nil)
      self:check(won, "won vs " .. e.E.name)
      self:wait_for(function() return SM.name() == "field" end, 2, "field after battle")
    end
  end
  clear_screen(F1, "29_battle_noise")
  local c1 = F1.caches[1]
  self:teleport(F1, c1.x, c1.y + 10)
  self:tap("confirm")
  self:check(d.discoveries.cache_fields == true, "opened data cache")
  self:teleport(F1, 594, 262)
  self:wait_for(function() return SM.name() == "field" and self:top().screen_id == "marsh" end, 2, "marsh")
  local F2 = self:top()
  self:sec(1.2); self:shot("30_static_marsh")
  clear_screen(F2, nil)
  self:check(d.bitdex.defeated.mimic_node and d.bitdex.defeated.fragment_crab, "Bitdex records absorbed Glitches")
  self:teleport(F2, 470, 262)
  self:frames(3)
  self:check(F2.friend and F2.friend.revealed, "Curiosity reveals the hidden Bitling")
  self:teleport(F2, 540, 262)
  self:tap("confirm")
  self:clear_dialogs(F2)
  self:check(d.residents.purrbit ~= nil, "befriended Purrbit with a snack")
  self:teleport(F2, 140, 400)
  self:frames(3)
  self:teleport(F2, 84, 420)
  self:tap("confirm")
  self:check(d.discoveries.cache_marsh == true, "found the hidden cache")
  self:teleport(F2, 320, 86)
  self:wait_for(function() return SM.name() == "field" and self:top().screen_id == "tower" end, 2, "tower")
  local F3 = self:top()
  self:sec(1.2); self:shot("31_relay_tower")
  Input.hold("up", true)
  self:wait_for(function() return F3.dialog:active() end, 6, "boss encounter")
  Input.hold("up", false)
  self:clear_dialogs(F3)
  local bwon = self:fight("32_boss_battle")
  self:check(bwon, "defeated the Corruptor (Lv " .. d.companion.level .. ")")
  self:check(d.aspects.owned.overclock_coil == true, "boss drops Overclock Coil")
  self:clear_dialogs(F3)
  self:teleport(F3, 320, 170)
  self:tap("confirm")
  self:clear_dialogs(F3)
  self:wait_for(function() return SM.name() == "endcard" end, 3, "chapter endcard")
  self:sec(2.6); self:shot("33_signals_endcard")
  self:tap("confirm")
  self:wait_for(function() return SM.name() == "lounge" end, 3, "home after chapter")
  local L3 = self:top()
  self:check(d.residents.barkbit and d.missions.completed.signals, "rescued Barkbit, chapter 1 complete")
  self:check(#L3.npcs == 2, "both residents live in the Lounge")
  self:clear_dialogs(L3)
  local bark
  for _, n in ipairs(L3.npcs) do if n.id == "barkbit" then bark = n end end
  local cards0 = 0
  for _, v in pairs(d.cards) do cards0 = cards0 + v end
  self:teleport(L3, bark.x - 20, bark.y)
  self:tap("confirm")
  self:clear_dialogs(L3)
  local cards1 = 0
  for _, v in pairs(d.cards) do cards1 = cards1 + v end
  self:check(cards1 == cards0 + 1 and not d.expedition.fetch_ready, "Barkbit's Loyal Fetch brought a card")
  self:sec(0.5); self:shot("34_lounge_residents")

  -- Evolution. Test shortcut: top up to the thresholds a long play session
  -- would reach (levels/data/care), then evolve through the real UI.
  d.companion.level = math.max(d.companion.level, 5)
  Growth.absorb(d, { pulse = 40 })
  d.care.score = math.max(d.care.score, 12)
  d.care.mistakes = 0
  d.care.mood = 85
  local ev = Growth.evolution_status(d)
  self:check(ev.ready and ev.form == "pulsebit", "evolution ready, leaning Pulse")
  self:teleport(L3, tx2, ty2)
  self:tap("confirm")
  S = self:top()
  self:sec(0.3); self:shot("35_station_evolve_ready")
  self:tap("confirm")
  self:wait_for(function() return SM.name() == "evolution" end, 2, "evolution sequence")
  self:sec(1.2); self:shot("36_evolving")
  self:wait_for(function() return self:top().phase == "reveal" end, 6, "reveal")
  self:sec(1.0); self:shot("37_pulsebit")
  self:tap("confirm")
  self:check(d.companion.stage == "pulsebit" and Growth.is_learned(d, "tempo_rush"), "evolved into Pulsebit with Tempo Rush")
  self:tap("cancel")
  self:sec(0.6); self:shot("38_lounge_pulsebit")
  local raw2 = json.decode(love.filesystem.read(Save.FILE))
  self:check(raw2.companion.stage == "pulsebit" and raw2.residents.barkbit ~= nil, "evolution + residents saved")
  print("  battles fought: " .. (self.battles or 0))

  -- 16 migrations + newer-save guard
  local backup_main = love.filesystem.read(Save.FILE)
  love.filesystem.write(Save.FILE, '{"level":3,"xp":40,"affinity":2,"awake":true}')
  local m = Save.load()
  self:check(m and m.save_version == 1 and m.companion.level == 3 and m.relationship.affinity == 2, "v0 save migrates to v1")
  love.filesystem.write(Save.FILE, '{"save_version":99}')
  local nd, _, kind = Save.load()
  self:check(nd == nil and kind == "newer", "newer save detected, not loaded")
  love.filesystem.write(Save.FILE, "{broken json")
  local bd, _, bkind = Save.load()
  self:check(bd ~= nil and bkind == "backup", "corrupt save falls back to backup")
  love.filesystem.write(Save.FILE, backup_main)

  -- 16 title shows Continue
  g.to_title()
  self:frames(3)
  self:check(SM.name() == "boot" and self:top().items[1].act == "continue", "title offers Continue")
  self:sec(0.5); self:shot("21_title_continue")

  -- 17 desktop scaled path (non-native window -> canvas + integer scale)
  love.window.setMode(1280, 960, { resizable = true })
  g.resize(1280, 960)
  self:frames(3)
  self:check(g.scale == 2 and g.ox == 0 and g.oy == 0, "1280x960 window scales canvas 2x")
  self:sec(0.3); self:shot("22_scaled_2x")
end

return AT
