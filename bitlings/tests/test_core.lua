-- Pure-Lua unit tests (no LÖVE needed). Run: luajit tests/test_core.lua
-- from the bitlings/ directory (or via tools/test.sh).

package.path = "game/?.lua;game/?/init.lua;" .. package.path

local json = require("src.core.json")
local U = require("src.core.util")
local Collision = require("src.core.collision")
local Save = require("src.save.save")

local passed, failed = 0, 0
local function test(name, fn)
  local ok, err = pcall(fn)
  if ok then passed = passed + 1; print("ok   " .. name)
  else failed = failed + 1; print("FAIL " .. name .. "\n     " .. tostring(err)) end
end
local function eq(a, b, msg) if a ~= b then error((msg or "") .. " expected " .. tostring(b) .. ", got " .. tostring(a), 2) end end

-- json ----------------------------------------------------------------------
test("json round-trip nested", function()
  local t = { a = 1, b = { 1, 2, 3 }, c = { d = "x\"y\n\\z" }, e = true, f = false, g = 1.5, h = -3 }
  local s = json.encode(t, true)
  local r = json.decode(s)
  eq(r.a, 1); eq(#r.b, 3); eq(r.b[3], 3); eq(r.c.d, "x\"y\n\\z"); eq(r.e, true); eq(r.f, false); eq(r.g, 1.5); eq(r.h, -3)
end)
test("json stable key order", function()
  eq(json.encode({ b = 1, a = 2 }), '{"a":2,"b":1}')
end)
test("json unicode escape", function()
  eq(json.decode('"caf\\u00e9"'), "caf\195\169")
end)
test("json rejects garbage", function()
  for _, bad in ipairs({ "{", "[1,", '{"a" 1}', "nul", '"open', "1 2" }) do
    local ok = pcall(json.decode, bad)
    if ok then error("accepted: " .. bad) end
  end
end)
test("json rejects NaN", function()
  local ok = pcall(json.encode, { x = 0 / 0 })
  eq(ok, false)
end)

-- util ----------------------------------------------------------------------
test("fill_defaults keeps values, adds missing", function()
  local t = { a = 5, nested = { x = 1 } }
  U.fill_defaults(t, { a = 1, b = 2, nested = { x = 9, y = 3 } })
  eq(t.a, 5); eq(t.b, 2); eq(t.nested.x, 1); eq(t.nested.y, 3)
end)
test("approach / clamp", function()
  eq(U.approach(0, 10, 3), 3); eq(U.approach(10, 0, 30), 0); eq(U.clamp(5, 0, 3), 3)
end)

-- collision -----------------------------------------------------------------
test("collision blocks on x and y", function()
  local e = { x = 0, y = 0, w = 10, h = 10 }
  local solids = { { x = 20, y = -20, w = 10, h = 40 } }
  Collision.move(e, 30, 0, solids)
  eq(e.x, 15, "x stops at wall:")
  local f = { x = 0, y = 0, w = 10, h = 10 }
  Collision.move(f, 0, 25, { { x = -50, y = 20, w = 100, h = 10 } })
  eq(f.y, 20, "y stops at floor:")
end)
test("collision slides along wall", function()
  local e = { x = 0, y = 0, w = 10, h = 10 }
  Collision.move(e, 30, 7, { { x = 20, y = -100, w = 10, h = 200 } })
  eq(e.x, 15); eq(e.y, 7)
end)

test("max per-frame step stays below thinnest solid (no tunneling)", function()
  local C = require("src.data.config")
  local ROOM = require("src.data.room")
  local step = 320 * (1 / 20) -- knockback speed * clamped dt
  local thinnest = 1e9
  for _, o in ipairs(ROOM.obstacles) do thinnest = math.min(thinnest, o.w, o.h) end
  assert(step < thinnest, "step " .. step .. " >= thinnest " .. thinnest)
  assert(C.player.speed / 20 < thinnest)
end)

-- save ----------------------------------------------------------------------
local function memfs()
  local files = {}
  return {
    files = files,
    getInfo = function(p) return files[p] and { type = "file", size = #files[p] } or nil end,
    read = function(p) return files[p] end,
    write = function(p, s) files[p] = s; return true end,
    remove = function(p) files[p] = nil; return true end,
  }
end

test("save default has every schema section", function()
  local d = Save.new_default()
  for _, k in ipairs({ "player", "commander", "companion", "traits", "skills", "memories", "evolution",
    "relationship", "settlement", "missions", "regions", "discoveries", "settings", "save_version", "progress" }) do
    if d[k] == nil then error("missing " .. k) end
  end
  eq(U.count(d.traits), 12)
end)
test("save write/load round-trip with backup", function()
  Save.fs = memfs(); Save.read_only = false
  local d = Save.new_default()
  d.companion.xp = 42
  assert(Save.write(d))
  d.companion.xp = 43
  assert(Save.write(d))
  eq(json.decode(Save.fs.files[Save.BACKUP]).companion.xp, 42, "backup holds previous:")
  local l = Save.load()
  eq(l.companion.xp, 43)
end)
test("save v0 migration", function()
  Save.fs = memfs()
  Save.fs.files[Save.FILE] = '{"level":4,"xp":12,"affinity":3}'
  local d = Save.load()
  eq(d.save_version, 1); eq(d.companion.level, 4); eq(d.companion.xp, 12); eq(d.relationship.affinity, 3)
end)
test("save fills fields added later", function()
  Save.fs = memfs()
  Save.fs.files[Save.FILE] = '{"save_version":1,"companion":{"level":2,"xp":5}}'
  local d = Save.load()
  eq(d.companion.level, 2); eq(d.companion.species, "Sparkbit"); eq(d.progress.awake, false)
end)
test("newer save is refused and never overwritten", function()
  Save.fs = memfs(); Save.read_only = false
  Save.fs.files[Save.FILE] = '{"save_version":99,"x":1}'
  local d, _, kind = Save.load()
  eq(d, nil); eq(kind, "newer")
  Save.read_only = true
  local ok = Save.write(Save.new_default())
  eq(ok, false)
  eq(Save.fs.files[Save.FILE], '{"save_version":99,"x":1}')
  Save.read_only = false
end)
test("corrupt save falls back to backup", function()
  Save.fs = memfs()
  Save.fs.files[Save.FILE] = "{nope"
  local b = Save.new_default(); b.companion.level = 7
  Save.fs.files[Save.BACKUP] = json.encode(b)
  local d, _, kind = Save.load()
  eq(kind, "backup"); eq(d.companion.level, 7)
end)
test("missing migration is an error, not a crash", function()
  local saved = Save.migrations[0]
  Save.migrations[0] = nil
  local d, _, kind = Save.migrate({ level = 1 })
  Save.migrations[0] = saved
  eq(d, nil); eq(kind, "corrupt")
end)


-- growth / content -----------------------------------------------------------
local K = require("src.data.content")
local Growth = require("src.systems.growth")

test("every sprite grid is rectangular", function()
  local function check(name, rows)
    local w = #rows[1]
    for i, r in ipairs(rows) do
      if #r ~= w then error(name .. " row " .. i .. " width " .. #r .. " ~= " .. w) end
    end
  end
  for id, sp in pairs(K.SPRITES) do
    check(id, sp.rows)
    for _, r in ipairs(sp.rows) do
      for ch in r:gmatch("[^%.]") do
        if not sp.pal[ch] then error(id .. " uses unknown palette key " .. ch) end
      end
    end
  end
  for id, rows in pairs(K.FORM_SPRITES) do check(id, rows); eq(#rows, 16); eq(#rows[1], 16) end
end)

test("content references are valid", function()
  for id, E in pairs(K.ENEMIES) do
    assert(K.SPRITES[E.sprite], id .. " sprite")
    assert(K.TYPE_NAME[E.type], id .. " type")
    if E.card then assert(K.CARDS[E.card], id .. " card") end
    if E.aspect then assert(K.ASPECTS[E.aspect], id .. " aspect") end
  end
  for _, id in ipairs(K.SKILL_ORDER) do assert(K.SKILLS[id], "skill " .. id) end
  for _, f in pairs(K.FORMS) do if f.signature then assert(K.SKILLS[f.signature]) end end
end)

test("type triangle", function()
  eq(Growth.type_mult("build", "pulse"), 1.5)
  eq(Growth.type_mult("pulse", "archive"), 1.5)
  eq(Growth.type_mult("archive", "build"), 1.5)
  eq(Growth.type_mult("pulse", "build"), 0.67)
  eq(Growth.type_mult("neutral", "build"), 1)
end)

test("absorbed data raises stats and drives appearance", function()
  local d = Save.new_default()
  local s0 = Growth.stats(d)
  Growth.absorb(d, { build = 20 })
  local s1 = Growth.stats(d)
  assert(s1.def > s0.def and s1.hp_max > s0.hp_max, "build data -> def/hp")
  eq(d.data_core.bank.build, 20)
  local app = Growth.appearance(d)
  eq(app.crest, "build"); eq(app.marks, 1)
end)

test("data magnet aspect boosts absorb", function()
  local d = Save.new_default()
  d.aspects.owned.data_magnet = true
  assert(Growth.toggle_aspect(d, "data_magnet"))
  local a = Growth.absorb(d, { pulse = 8 })
  eq(a.pulse, 10)
end)

test("upload skill spends bank, not lifetime", function()
  local d = Save.new_default()
  Growth.absorb(d, { pulse = 7 })
  local ok = Growth.learn(d, "pulse_dash")
  assert(ok)
  eq(d.data_core.bank.pulse, 1); eq(d.data_core.lifetime.pulse, 7)
  assert(Growth.is_equipped(d, "pulse_dash"))
  local ok2 = Growth.learn(d, "overdrive")
  eq(ok2, false)
end)

test("loadout keeps 1..4 skills", function()
  local d = Save.new_default()
  local ok = Growth.toggle_equip(d, "flowsort")
  eq(ok, false)
  for _, id in ipairs({ "patch_bolt", "pulse_dash", "recall_beam", "firewall" }) do d.skills.learned[id] = true end
  assert(Growth.toggle_equip(d, "patch_bolt")); assert(Growth.toggle_equip(d, "pulse_dash")); assert(Growth.toggle_equip(d, "recall_beam"))
  eq(Growth.toggle_equip(d, "firewall"), false)
end)

test("care: hunger drains, starving is one mistake, feeding fixes", function()
  local d = Save.new_default()
  d.care.hunger = 1
  eq(Growth.tick_care(d, 24), "starving")
  eq(d.care.mistakes, 1)
  eq(Growth.tick_care(d, 24), nil)
  eq(d.care.mistakes, 1)
  d.settlement.resources.bits = 10
  assert(Growth.feed(d, "snack"))
  eq(d.care.starving, false); eq(d.care.score, 1); eq(d.settlement.resources.bits, 5)
end)

test("treats steer evolution direction", function()
  local d = Save.new_default()
  d.settlement.resources.bits = 100
  d.care.hunger = 10
  Growth.feed(d, "treat_archive")
  local dom = Growth.dominant(d)
  eq(dom, "archive")
end)

test("evolution gates on level, data, leaning, care, mood", function()
  local d = Save.new_default()
  local st = Growth.evolution_status(d)
  eq(st.ready, false)
  d.companion.level = 5
  Growth.absorb(d, { pulse = 30 })
  d.care.score = 8
  d.care.mood = 60
  st = Growth.evolution_status(d)
  eq(st.ready, true); eq(st.form, "pulsebit")
  d.care.mistakes = 1 -- neglect blocks it
  eq(Growth.evolution_status(d).ready, false)
  d.care.mistakes = 0
  assert(Growth.evolve(d))
  eq(d.companion.stage, "pulsebit"); eq(d.companion.name, "Pulsebit")
  assert(Growth.is_learned(d, "tempo_rush"))
  local s = Growth.stats(d)
  eq(s.type, "pulse")
  eq(Growth.evolution_status(d).ready, false)
end)

test("xp levels up and counts mastery", function()
  local d = Save.new_default()
  eq(Growth.add_xp(d, 250), 1)
  eq(d.companion.level, 2); eq(d.companion.xp, 150)
  eq(Growth.add_xp(d, 50), 1)
  eq(d.commander.mastery, 2)
end)

test("damage respects type and is at least 1", function()
  local strong = Growth.damage(10, 10, 10, 1.5, 0.5)
  local plain = Growth.damage(10, 10, 10, 1, 0.5)
  assert(strong > plain)
  eq(Growth.damage(1, 1, 999, 0.67, 0), 1)
end)

test("old v1 saves gain growth fields", function()
  Save.fs = memfs()
  Save.fs.files[Save.FILE] = '{"save_version":1,"companion":{"level":3,"xp":5},"skills":{"flowsort":{"unlocked":true}}}'
  local d = Save.load()
  eq(d.data_core.lifetime.pulse, 0); eq(d.care.hunger, 80); eq(d.skills.equipped[1], "flowsort")
  eq(d.aspects.scarf, "blue")
end)

print(string.format("\n%d passed, %d failed", passed, failed))
os.exit(failed == 0 and 0 or 1)
