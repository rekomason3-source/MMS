-- Bitcore save: versioned, migrated, backed up. See docs/SAVE_SCHEMA.md.
--
-- Rules
--  * save_version is an integer; bump Save.VERSION when the shape changes
--    and add Save.migrations[old] = function(data) ... return data(old+1) end
--  * loading fills any missing fields from new_default() (forward-compatible)
--  * a save from a NEWER build is never overwritten (read-only session)
--  * every write first copies the current file to the backup slot

local json = require("src.core.json")
local U = require("src.core.util")

local Save = {}

Save.VERSION = 1
Save.FILE = "bitcore.json"
Save.BACKUP = "bitcore.bak.json"
Save.read_only = false

-- Filesystem adapter (swappable in tests). Mirrors love.filesystem.
Save.fs = love and love.filesystem or nil

local TRAITS = {
  "build", "knowledge", "focus", "curiosity", "creativity", "social",
  "recovery", "defense", "aggression", "support", "exploration", "efficiency",
}
Save.TRAITS = TRAITS

function Save.new_default()
  local traits = {}
  for _, t in ipairs(TRAITS) do traits[t] = 0 end
  local now = os.time()
  return {
    save_version = Save.VERSION,
    created_at = now,
    updated_at = now,
    player = { name = "Commander", playtime = 0 },
    commander = { recall = 0, clarity = 0, focus = 0, execution = 0, mastery = 0 },
    companion = {
      species = "Sparkbit", name = "Sparkbit", stage = "Sparkbit",
      level = 1, xp = 0, energy = 5, max_energy = 5, hp = 60,
    },
    -- absorbed data: lifetime shapes Sparkbit (never spent); bank is spent on uploads
    data_core = {
      lifetime = { build = 0, pulse = 0, archive = 0 },
      bank = { build = 0, pulse = 0, archive = 0 },
    },
    care = { hunger = 80, mood = 70, score = 0, mistakes = 0, starving = false, fed = 0 },
    aspects = { owned = {}, equipped = {}, scarf = "blue" },
    cards = { heal = 2, energy = 0, boost = 0, shield = 0 },
    bitdex = { seen = {}, defeated = {} },
    residents = {},
    expedition = { fetch_ready = false, runs = 0 },
    traits = traits,
    skills = {
      flowsort = { unlocked = true, level = 1, uses = 0 },
      curiosity = { unlocked = true, passive = true },
      learned = { flowsort = true },
      equipped = { "flowsort" },
    },
    memories = {},
    evolution = { offered = {}, chosen = "", flags = {} },
    relationship = { affinity = 0, pets = 0 },
    settlement = {
      buildings = {
        core_nest = { level = 1 },
        archive_hall = { level = 0 },
        forge_node = { level = 0 },
        gateway = { level = 0 },
      },
      resources = { bits = 0, core_shards = 0, data_fragments = 0, energy = 0, memory_fragments = 0 },
      improvement = "",
    },
    missions = { completed = {} },
    regions = { unlocked = { "lounge" } },
    discoveries = {},
    progress = {
      awake = false,
      fragments = {},
      terminal_repaired = false,
      flowsort_done = false,
      loop_broken = false,
      gateway_active = false,
      improvement = "",
      memory_stored = false,
      gateway_open = false,
      prologue_complete = false,
    },
    settings = { perf_overlay = false, swap_ab = false, sfx = true },
  }
end

-- Migrations ------------------------------------------------------------
-- [from_version] = function(data) -> data at from_version + 1
Save.migrations = {
  -- v0: pre-versioned prototype saves were flat {level, xp, affinity}.
  [0] = function(d)
    local n = Save.new_default()
    n.save_version = 1
    n.companion.level = math.max(1, math.floor(tonumber(d.level) or 1))
    n.companion.xp = math.max(0, math.floor(tonumber(d.xp) or 0))
    n.relationship.affinity = math.max(0, math.floor(tonumber(d.affinity) or 0))
    if d.awake then n.progress.awake = true end
    return n
  end,
}

function Save.migrate(d)
  if type(d) ~= "table" then return nil, "save is not an object", "corrupt" end
  local v = tonumber(d.save_version) or 0
  if v > Save.VERSION then
    return nil, "save is from a newer build (v" .. v .. ")", "newer"
  end
  while v < Save.VERSION do
    local m = Save.migrations[v]
    if not m then return nil, "no migration from v" .. v, "corrupt" end
    d = m(d)
    local nv = tonumber(d.save_version) or v
    if nv <= v then return nil, "migration from v" .. v .. " did not advance", "corrupt" end
    v = nv
  end
  U.fill_defaults(d, Save.new_default())
  return d
end

function Save.decode(str)
  local ok, d = pcall(json.decode, str)
  if not ok then return nil, tostring(d), "corrupt" end
  return Save.migrate(d)
end

function Save.encode(data)
  return json.encode(data, true)
end

local function exists(path)
  return Save.fs.getInfo(path) ~= nil
end

-- Returns data or nil, err, kind ("missing" | "corrupt" | "newer").
-- On a corrupt main file it falls back to the backup slot.
function Save.load()
  if not Save.fs then return nil, "no filesystem", "missing" end
  if not exists(Save.FILE) then
    if exists(Save.BACKUP) then
      local raw = Save.fs.read(Save.BACKUP)
      local d, err, kind = Save.decode(raw or "")
      if d then return d, "main save missing; restored backup", "backup" end
      return nil, err, kind
    end
    return nil, "no save", "missing"
  end
  local raw = Save.fs.read(Save.FILE)
  local d, err, kind = Save.decode(raw or "")
  if d then return d end
  if kind == "newer" then return nil, err, kind end
  if exists(Save.BACKUP) then
    local braw = Save.fs.read(Save.BACKUP)
    local bd = Save.decode(braw or "")
    if bd then return bd, "save was damaged; restored backup", "backup" end
  end
  return nil, err, kind
end

function Save.write(data)
  if Save.read_only then return false, "read-only (newer save present)" end
  if not Save.fs then return false, "no filesystem" end
  data.save_version = Save.VERSION
  data.updated_at = os.time()
  local ok, str = pcall(Save.encode, data)
  if not ok then return false, "encode failed: " .. tostring(str) end
  if exists(Save.FILE) then
    local cur = Save.fs.read(Save.FILE)
    if cur and #cur > 0 then Save.fs.write(Save.BACKUP, cur) end
  end
  local wok, werr = Save.fs.write(Save.FILE, str)
  if not wok then return false, tostring(werr) end
  return true
end

function Save.delete()
  if not Save.fs then return end
  if exists(Save.FILE) then Save.fs.remove(Save.FILE) end
  if exists(Save.BACKUP) then Save.fs.remove(Save.BACKUP) end
end

return Save
