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

print(string.format("\n%d passed, %d failed", passed, failed))
os.exit(failed == 0 and 0 or 1)
