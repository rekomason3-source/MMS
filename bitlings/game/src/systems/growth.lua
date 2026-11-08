-- Growth model: how absorbed data, care, uploads and aspects shape Sparkbit.
-- Pure functions over the save table (no LÖVE), fully unit-tested.
--
--   lifetime data  -> stats, appearance, evolution direction (never spent)
--   bank data      -> currency for uploading skills at the Upload Station
--   care           -> hunger, mood, care quality (gates evolution)
--   traits         -> behaviour pressure, also nudges evolution direction

local K = require("src.data.content")

local G = {}

local function clamp(v, a, b) return v < a and a or (v > b and b or v) end

-- Typing ------------------------------------------------------------------------
function G.type_mult(atk_type, def_type)
  if not atk_type or not def_type or atk_type == "neutral" or def_type == "neutral" then return 1 end
  if K.BEATS[atk_type] == def_type then return 1.5 end
  if K.BEATS[def_type] == atk_type then return 0.67 end
  return 1
end

-- power * (atk/def)^0.6 * type * variance, min 1. r in [0,1].
function G.damage(power, atk, def, mult, r)
  local v = power * (atk / math.max(1, def)) ^ 0.6 * (mult or 1) * (0.9 + 0.2 * (r or 0.5))
  return math.max(1, math.floor(v + 0.5))
end

-- Aspects --------------------------------------------------------------------------
function G.has_aspect(save, id)
  for _, a in ipairs(save.aspects.equipped) do if a == id then return true end end
  return false
end

-- Form ------------------------------------------------------------------------------
function G.form(save) return K.FORMS[save.companion.stage] and save.companion.stage or "sparkbit" end
function G.form_def(save) return K.FORMS[G.form(save)] end

-- Stats -----------------------------------------------------------------------------
function G.stats(save)
  local lvl = save.companion.level
  local L = save.data_core.lifetime
  local s = {
    hp_max = 60 + 10 * (lvl - 1) + 3 * math.floor(L.build / 5),
    atk = 10 + 2 * (lvl - 1) + math.floor(L.pulse / 5) + math.floor(L.archive / 10),
    def = 8 + 2 * (lvl - 1) + math.floor(L.build / 5),
    spd = 10 + (lvl - 1) + math.floor(L.pulse / 5),
    en_max = 10 + (lvl - 1) + math.floor(L.archive / 5),
  }
  local f = G.form_def(save)
  s.type = f.type
  if f.mult ~= 1 then
    s.hp_max = math.floor(s.hp_max * f.mult)
    s.atk = math.floor(s.atk * f.mult)
    s.def = math.floor(s.def * f.mult)
    s.spd = math.floor(s.spd * f.mult)
  end
  if G.has_aspect(save, "thick_casing") then s.def = math.floor(s.def * 1.2) end
  if save.care.starving then
    s.atk = math.floor(s.atk * 0.9)
    s.def = math.floor(s.def * 0.9)
  end
  return s
end

-- XP --------------------------------------------------------------------------------
function G.xp_to_next(level) return 100 * level end

-- Returns number of levels gained.
function G.add_xp(save, n)
  local c = save.companion
  c.xp = c.xp + n
  local gained = 0
  while c.xp >= G.xp_to_next(c.level) do
    c.xp = c.xp - G.xp_to_next(c.level)
    c.level = c.level + 1
    gained = gained + 1
  end
  if gained > 0 then save.commander.mastery = save.commander.mastery + gained end
  return gained
end

-- Data --------------------------------------------------------------------------------
function G.data_total(save)
  local L, t = save.data_core.lifetime, 0
  for _, k in ipairs(K.TYPES) do t = t + L[k] end
  return t
end

-- Absorb data into lifetime + bank. Returns the table actually added.
function G.absorb(save, data)
  local mult = G.has_aspect(save, "data_magnet") and 1.25 or 1
  local added = {}
  for _, k in ipairs(K.TYPES) do
    local v = data[k]
    if v and v > 0 then
      local n = math.floor(v * mult + 0.5)
      save.data_core.lifetime[k] = save.data_core.lifetime[k] + n
      save.data_core.bank[k] = save.data_core.bank[k] + n
      added[k] = n
    end
  end
  return added
end

-- Evolution pressure per type: lifetime data + 2x mapped trait.
function G.pressure(save)
  local out, total = {}, 0
  for _, k in ipairs(K.TYPES) do
    out[k] = save.data_core.lifetime[k] + 2 * (save.traits[K.TYPE_TRAIT[k]] or 0)
    total = total + out[k]
  end
  return out, total
end

-- Dominant type (or nil if no pressure yet) and its share 0..1.
function G.dominant(save)
  local p, total = G.pressure(save)
  if total <= 0 then return nil, 0, p end
  local best, bv = nil, -1
  for _, k in ipairs(K.TYPES) do
    if p[k] > bv then best, bv = k, p[k] end
  end
  return best, bv / total, p
end

-- Care ---------------------------------------------------------------------------------
function G.care_quality(save) return save.care.score - 3 * save.care.mistakes end

function G.add_mood(save, n) save.care.mood = clamp(save.care.mood + n, 0, 100) end

-- Advance care by dt seconds of gameplay. Returns an event string or nil.
function G.tick_care(save, dt)
  local c = save.care
  local before = c.hunger
  local rate = G.has_aspect(save, "warm_core") and 0.5 or 1
  c.hunger = math.max(0, c.hunger - dt / 12 * rate) -- ~20 min from full to empty
  if c.hunger < 30 then G.add_mood(save, -dt / 30) end
  if c.hunger <= 0 and not c.starving then
    c.starving = true
    c.mistakes = c.mistakes + 1
    G.add_mood(save, -10)
    return "starving"
  end
  if before >= 30 and c.hunger < 30 then return "hungry" end
  return nil
end

-- Feed a food from K.FOODS. Returns ok, message.
function G.feed(save, id)
  local f = K.FOODS[id]
  if not f then return false, "Unknown food" end
  local c = save.care
  local res = save.settlement.resources
  if res.bits < f.cost then return false, "Not enough Bits" end
  if c.hunger >= 95 then return false, "Sparkbit is full" end
  res.bits = res.bits - f.cost
  if c.hunger < 70 then c.score = c.score + 1 end -- feeding when it's needed is good care
  c.hunger = math.min(100, c.hunger + f.hunger)
  c.starving = false
  c.fed = (c.fed or 0) + 1
  G.add_mood(save, f.mood)
  if f.data then G.absorb(save, f.data) end
  return true, "Fed " .. f.name
end

-- Good-care action (pet with bond gain, rest). Raises score + mood.
function G.care_action(save, mood)
  save.care.score = save.care.score + 1
  G.add_mood(save, mood or 5)
end

-- Skills ---------------------------------------------------------------------------------
function G.is_learned(save, id) return save.skills.learned[id] == true end

function G.is_equipped(save, id)
  for _, s in ipairs(save.skills.equipped) do if s == id then return true end end
  return false
end

function G.can_learn(save, id)
  local sk = K.SKILLS[id]
  if not sk or not sk.learn then return false, "Cannot be uploaded" end
  if G.is_learned(save, id) then return false, "Already uploaded" end
  for k, v in pairs(sk.learn) do
    if (save.data_core.bank[k] or 0) < v then return false, "Need " .. v .. " " .. K.TYPE_NAME[k] .. " data" end
  end
  return true
end

function G.learn(save, id)
  local ok, err = G.can_learn(save, id)
  if not ok then return false, err end
  for k, v in pairs(K.SKILLS[id].learn) do save.data_core.bank[k] = save.data_core.bank[k] - v end
  save.skills.learned[id] = true
  if #save.skills.equipped < K.MAX_EQUIPPED then table.insert(save.skills.equipped, id) end
  return true, "Uploaded " .. K.SKILLS[id].name
end

-- Toggle equip. Always keeps at least one skill equipped.
function G.toggle_equip(save, id)
  if not G.is_learned(save, id) then return false, "Not uploaded yet" end
  local eq = save.skills.equipped
  for i, s in ipairs(eq) do
    if s == id then
      if #eq <= 1 then return false, "Keep at least one skill" end
      table.remove(eq, i)
      return true, "Unequipped " .. K.SKILLS[id].name
    end
  end
  if #eq >= K.MAX_EQUIPPED then return false, "Loadout full (" .. K.MAX_EQUIPPED .. ")" end
  table.insert(eq, id)
  return true, "Equipped " .. K.SKILLS[id].name
end

-- Aspects --------------------------------------------------------------------------------
function G.buy_aspect(save, id)
  local a = K.ASPECTS[id]
  if not a then return false, "Unknown aspect" end
  if save.aspects.owned[id] then return false, "Already owned" end
  if not a.cost then return false, "Earned, not sold" end
  local res = save.settlement.resources
  if res.bits < a.cost then return false, "Need " .. a.cost .. " Bits" end
  res.bits = res.bits - a.cost
  save.aspects.owned[id] = true
  return true, "Got " .. a.name
end

function G.toggle_aspect(save, id)
  if not save.aspects.owned[id] then return false, "Not owned" end
  local eq = save.aspects.equipped
  for i, a in ipairs(eq) do
    if a == id then table.remove(eq, i); return true, "Removed " .. K.ASPECTS[id].name end
  end
  if #eq >= K.MAX_ASPECTS then return false, "Aspect slots full (" .. K.MAX_ASPECTS .. ")" end
  table.insert(eq, id)
  return true, "Installed " .. K.ASPECTS[id].name
end

function G.cycle_scarf(save)
  local cur = save.aspects.scarf
  for i, s in ipairs(K.SCARVES) do
    if s.id == cur then
      save.aspects.scarf = K.SCARVES[i % #K.SCARVES + 1].id
      return true
    end
  end
  save.aspects.scarf = K.SCARVES[1].id
  return true
end

function G.buy_card(save, id)
  local c = K.CARDS[id]
  if not c then return false, "Unknown card" end
  local res = save.settlement.resources
  if res.bits < c.cost then return false, "Need " .. c.cost .. " Bits" end
  res.bits = res.bits - c.cost
  save.cards[id] = (save.cards[id] or 0) + 1
  return true, "Bought " .. c.name
end

-- Evolution --------------------------------------------------------------------------------
function G.evolution_status(save)
  local E = K.EVOLVE
  local dom, share = G.dominant(save)
  local q = G.care_quality(save)
  local total = G.data_total(save)
  local form = dom and K.FORM_FOR_TYPE[dom] or nil
  local checks = {
    { label = "Level " .. E.level, ok = save.companion.level >= E.level,
      detail = "Lv " .. save.companion.level },
    { label = E.data_total .. " data absorbed", ok = total >= E.data_total, detail = tostring(total) },
    { label = "Clear leaning (" .. math.floor(E.share * 100) .. "%)", ok = share >= E.share,
      detail = math.floor(share * 100) .. "%" },
    { label = "Care quality " .. E.care, ok = q >= E.care, detail = tostring(q) },
    { label = "Mood " .. E.mood, ok = save.care.mood >= E.mood, detail = tostring(math.floor(save.care.mood)) },
  }
  local ready = G.form(save) == "sparkbit" and form ~= nil
  for _, c in ipairs(checks) do ready = ready and c.ok end
  return { ready = ready, form = form, type = dom, share = share, checks = checks,
    evolved = G.form(save) ~= "sparkbit" }
end

function G.evolve(save)
  local st = G.evolution_status(save)
  if not st.ready then return false, "Not ready" end
  local f = K.FORMS[st.form]
  save.companion.stage = st.form
  save.companion.name = f.name
  save.skills.learned[f.signature] = true
  if #save.skills.equipped < K.MAX_EQUIPPED then
    table.insert(save.skills.equipped, f.signature)
  else
    save.skills.equipped[K.MAX_EQUIPPED] = f.signature
  end
  save.evolution.chosen = st.form
  return true, st.form
end

-- Appearance: everything the renderer needs to show growth --------------------------------
function G.appearance(save)
  local dom = G.dominant(save)
  local total = G.data_total(save)
  return {
    form = G.form(save),
    scarf = save.aspects.scarf,
    crest = dom or "neutral",
    marks = total >= 40 and 2 or (total >= 15 and 1 or 0),
    level = save.companion.level,
    hungry = save.care.hunger < 30,
    mood = save.care.mood,
  }
end

return G
