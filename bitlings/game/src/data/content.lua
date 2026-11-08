-- Game content tables: data types, skills, aspects, cards, enemies, forms,
-- residents. Pure data (no LÖVE calls) so it can be unit-tested.
--
-- Data-type triangle (taught by FlowSort):
--   BUILD beats PULSE, PULSE beats ARCHIVE, ARCHIVE beats BUILD.

local K = {}

K.TYPES = { "build", "pulse", "archive" }
K.BEATS = { build = "pulse", pulse = "archive", archive = "build" }
K.TYPE_NAME = { build = "Build", pulse = "Pulse", archive = "Archive", neutral = "Neutral" }
-- trait that each data type feeds (traits come from the master design)
K.TYPE_TRAIT = { build = "build", pulse = "focus", archive = "knowledge" }

-- Skills ---------------------------------------------------------------------
-- kind: attack | shield | drone | buff_atk | debuff_def | heal
-- learn: data-bank cost to upload at the Upload Station (nil = innate/signature)
K.SKILLS = {
  flowsort = { name = "FlowSort", type = "neutral", en = 2, kind = "attack", power = 10, meter = 20,
    desc = "Sorts the foe's data. Builds Overclock fast." },
  patch_bolt = { name = "Patch Bolt", type = "build", en = 3, kind = "attack", power = 18,
    learn = { build = 6 }, desc = "A bolt of repair code. Strong vs Pulse." },
  firewall = { name = "Firewall", type = "build", en = 4, kind = "shield", turns = 2,
    learn = { build = 10 }, desc = "Halves damage taken for 2 turns." },
  construct_drone = { name = "Construct Drone", type = "build", en = 6, kind = "drone", power = 9, turns = 3,
    learn = { build = 18 }, desc = "Builds a drone that strikes each turn for 3 turns." },
  pulse_dash = { name = "Pulse Dash", type = "pulse", en = 2, kind = "attack", power = 15,
    learn = { pulse = 6 }, desc = "A fast charge. Strong vs Archive." },
  tempo_up = { name = "Tempo Up", type = "pulse", en = 3, kind = "buff_atk", turns = 3,
    learn = { pulse = 10 }, desc = "+50% ATK for 3 turns." },
  overdrive = { name = "Overdrive Burst", type = "pulse", en = 6, kind = "attack", power = 32,
    learn = { pulse = 18 }, desc = "Dump all tempo into one huge hit." },
  recall_beam = { name = "Recall Beam", type = "archive", en = 3, kind = "attack", power = 16,
    learn = { archive = 6 }, desc = "Fires remembered data. Strong vs Build." },
  pattern_echo = { name = "Pattern Echo", type = "archive", en = 3, kind = "debuff_def", turns = 3,
    learn = { archive = 10 }, desc = "Exposes a weakness: foe takes +50% for 3 turns." },
  restore = { name = "Restore", type = "archive", en = 5, kind = "heal", amount = 0.4,
    learn = { archive = 18 }, desc = "Restore 40% HP." },
  -- evolution signatures
  system_siege = { name = "System Siege", type = "build", en = 7, kind = "attack", power = 42,
    desc = "Hackbit signature. Tears a system apart." },
  total_recall = { name = "Total Recall", type = "archive", en = 6, kind = "heal", amount = 0.65,
    desc = "Archivebit signature. Restore 65% HP." },
  tempo_rush = { name = "Tempo Rush", type = "pulse", en = 5, kind = "attack", power = 18, hits = 2,
    desc = "Pulsebit signature. Strikes twice." },
}
K.SKILL_ORDER = {
  "flowsort", "patch_bolt", "firewall", "construct_drone", "pulse_dash", "tempo_up", "overdrive",
  "recall_beam", "pattern_echo", "restore", "system_siege", "total_recall", "tempo_rush",
}
K.MAX_EQUIPPED = 4

-- Aspects: passive modules equipped in the Lounge -------------------------------
K.ASPECTS = {
  warm_core = { name = "Warm Core", cost = 30, desc = "Hunger drains half as fast." },
  sync_lens = { name = "Sync Lens", cost = 30, desc = "Wider Sync Strike and Brace timing." },
  thick_casing = { name = "Thick Casing", cost = 60, desc = "+20% DEF." },
  lucky_byte = { name = "Lucky Byte", cost = 60, desc = "+50% Bits from battles." },
  data_magnet = { name = "Data Magnet", cost = 80, desc = "+25% data absorbed." },
  overclock_coil = { name = "Overclock Coil", cost = nil, desc = "Overclock meter fills 50% faster. (Reward)" },
}
K.ASPECT_ORDER = { "warm_core", "sync_lens", "thick_casing", "lucky_byte", "data_magnet", "overclock_coil" }
K.MAX_ASPECTS = 2

K.SCARVES = {
  { id = "blue", name = "Blue", dark = "2a62e0", light = "4f8cff" },
  { id = "red", name = "Ember", dark = "c2304a", light = "ff5a75" },
  { id = "green", name = "Moss", dark = "1f9e5a", light = "4fe08c" },
  { id = "gold", name = "Gold", dark = "c7911f", light = "ffc857" },
  { id = "violet", name = "Dusk", dark = "6a3fd0", light = "b59bff" },
}

-- Patch Cards: played mid-battle as a free action (one per turn) -------------
K.CARDS = {
  heal = { name = "Heal Patch", cost = 20, desc = "Restore 40% HP." },
  energy = { name = "Charge Patch", cost = 15, desc = "+6 EN." },
  boost = { name = "Boost Patch", cost = 25, desc = "+50% ATK for 2 turns." },
  shield = { name = "Shield Patch", cost = 25, desc = "Block the next hit completely." },
}
K.CARD_ORDER = { "heal", "energy", "boost", "shield" }

-- Food -------------------------------------------------------------------------
K.FOODS = {
  snack = { name = "Byte Snack", cost = 5, hunger = 40, mood = 5 },
  treat_build = { name = "Build Treat", cost = 15, hunger = 15, mood = 8, data = { build = 3 } },
  treat_pulse = { name = "Pulse Treat", cost = 15, hunger = 15, mood = 8, data = { pulse = 3 } },
  treat_archive = { name = "Archive Treat", cost = 15, hunger = 15, mood = 8, data = { archive = 3 } },
}
K.FOOD_ORDER = { "snack", "treat_build", "treat_pulse", "treat_archive" }

-- Evolution forms ------------------------------------------------------------------
K.FORMS = {
  sparkbit = { name = "Sparkbit", type = "neutral", mult = 1.0 },
  hackbit = { name = "Hackbit", type = "build", mult = 1.3, signature = "system_siege",
    desc = "Builder. Engineering, constructs, siege." },
  pulsebit = { name = "Pulsebit", type = "pulse", mult = 1.3, signature = "tempo_rush",
    desc = "Executor. Speed, tempo, pressure." },
  archivebit = { name = "Archivebit", type = "archive", mult = 1.3, signature = "total_recall",
    desc = "Keeper. Memory, analysis, support." },
}
K.FORM_FOR_TYPE = { build = "hackbit", pulse = "pulsebit", archive = "archivebit" }

K.EVOLVE = { level = 3, data_total = 30, share = 0.45, care = 8, mood = 50 }

-- Enemies (Glitches) -----------------------------------------------------------
-- attacks: { name, power, hits?, drain_en?, charge? (telegraphed one turn early) }
K.ENEMIES = {
  loop = {
    name = "Loop Glitch", type = "pulse", hp = 40, atk = 8, def = 6,
    data = { pulse = 6 }, bits = 10, xp = 0, sprite = "e_loop", color = "ff3d7f",
    attacks = { { name = "Rewind", power = 8 }, { name = "Repeat", power = 5, hits = 2 } },
    desc = "A broken pattern that repeats forever. Break the sequence.",
  },
  noise_mote = {
    name = "Noise Mote", type = "pulse", hp = 30, atk = 9, def = 6,
    data = { pulse = 4 }, bits = 6, xp = 12, sprite = "e_noise", color = "aab3d9", chase = true,
    attacks = { { name = "Static Burst", power = 8 }, { name = "Hiss", power = 6 } },
    desc = "Floods the field with static. Hides the real signal.",
  },
  drift_wisp = {
    name = "Drift Wisp", type = "archive", hp = 36, atk = 9, def = 7,
    data = { archive = 4 }, bits = 7, xp = 14, sprite = "e_wisp", color = "9b7bff",
    attacks = { { name = "Drift", power = 9 }, { name = "Fade Touch", power = 7, drain_en = 2 } },
    desc = "Moves goals and markers. Re-anchor and strike.",
  },
  fragment_crab = {
    name = "Fragment Crab", type = "build", hp = 48, atk = 10, def = 12,
    data = { build = 5 }, bits = 9, xp = 18, sprite = "e_crab", color = "ffc857",
    attacks = { { name = "Pinch", power = 10 }, { name = "Splinter", power = 6, hits = 2 } },
    desc = "Carries broken memory shards in its shell. Tough.",
  },
  mimic_node = {
    name = "Mimic Node", type = "archive", hp = 40, atk = 11, def = 8, mimic = true,
    data = { archive = 3, build = 2, pulse = 2 }, bits = 12, xp = 20, sprite = "e_mimic", color = "5fe3ff",
    attacks = { { name = "Copy Bite", power = 11 } },
    desc = "Looks like a data fragment. Changes type every turn: verify before acting.",
  },
  corruptor = {
    name = "Corruptor", type = "build", hp = 110, atk = 12, def = 10, boss = true,
    data = { build = 10, pulse = 4, archive = 4 }, bits = 60, xp = 80, sprite = "e_corruptor", color = "ff3d7f",
    card = "shield", aspect = "overclock_coil",
    attacks = {
      { name = "Corrupt Slam", power = 13 },
      { name = "Bit Rot", power = 8, drain_en = 3 },
      { name = "Overwrite", power = 30, charge = true },
    },
    desc = "Converts neutral systems. Guards the Relay Tower.",
  },
}
K.ENEMY_ORDER = { "loop", "noise_mote", "drift_wisp", "fragment_crab", "mimic_node", "corruptor" }

K.RESIDENTS = {
  barkbit = { name = "Barkbit", sprite = "r_barkbit",
    desc = "Loyal Fetch: brings back Bits and a Patch Card after every expedition." },
  purrbit = { name = "Purrbit", sprite = "r_purrbit",
    desc = "Quiet Pattern Scan: reads which way Sparkbit's evolution is leaning." },
}
K.RESIDENT_ORDER = { "barkbit", "purrbit" }

-- Sprite grids --------------------------------------------------------------------
-- Palette keys per sprite. Colors are hex strings resolved at bake time.
K.SPRITES = {
  e_noise = {
    pal = { o = "1a1c3a", g = "6b74b8", w = "e8ecff", k = "0b0d1f", x = "5fe3ff" },
    rows = {
      "x....x....x.",
      "...oooooo...",
      "..owgwgwgo..",
      ".ogwgggwggo.",
      ".ogkkggkkgo.",
      "xoggggggggox",
      ".ogwgwgwggo.",
      ".oggggggggo.",
      "..ogwgwggo..",
      "...oooooo...",
      "x....x....x.",
      "............",
    },
  },
  e_wisp = {
    pal = { o = "1a1c3a", v = "9b7bff", w = "f2f6ff", k = "1a1c3a", p = "ff8fb8" },
    rows = {
      "....oooo....",
      "..oovvvvoo..",
      ".ovvvvvvvvo.",
      ".ovwkvvwkvo.",
      "ovvwkvvwkvvo",
      "ovvvvvvvvvvo",
      "ovvvvppvvvvo",
      ".ovvvvvvvvo.",
      "..ovv.ovvo..",
      "...ov..ovo..",
      "....o...o...",
      "............",
    },
  },
  e_crab = {
    pal = { o = "1a1c3a", a = "ffc857", y = "d98a2b", k = "1a1c3a" },
    rows = {
      "............",
      ".aa......aa.",
      "a.a......a.a",
      ".aa.oooo.aa.",
      "..aoyyyyoa..",
      ".oyyyyyyyyo.",
      "oyykyyyykyyo",
      "oyyyyyyyyyyo",
      ".oyyyyyyyyo.",
      "..oooooooo..",
      ".o.o....o.o.",
      "o..o....o..o",
    },
  },
  e_mimic = {
    pal = { c = "5fe3ff", w = "f2f6ff", k = "1a1c3a", m = "ff3d7f" },
    rows = {
      ".....cc.....",
      "....cwwc....",
      "...cwwwwc...",
      "..cwkwwkwc..",
      ".cwwwwwwwwc.",
      "cwwkmkmkmwwc",
      ".cwwmmmmwwc.",
      "..cwwwwwwc..",
      "...cwwwwc...",
      "....cwwc....",
      ".....cc.....",
      "............",
    },
  },
  e_loop = {
    pal = { m = "ff3d7f", w = "f2f6ff", k = "1a1c3a" },
    rows = {
      "....mmmm....",
      "..mmwwwwmm..",
      ".mwmmmmmmwm.",
      ".mwm....mwm.",
      "mwm..ww..mwm",
      "mwm.wkkw.mwm",
      "mwm.wkkw.mwm",
      "mwm..ww..mwm",
      ".mwm....mwm.",
      ".mwmmmmmmwm.",
      "..mmwwwwmm..",
      "....mmmm....",
    },
  },
  e_corruptor = {
    pal = { m = "ff3d7f", o = "1a1c3a", d = "3a1640", k = "0b0d1f", w = "ffc857" },
    rows = {
      "......mmmm......",
      "....mmoooomm....",
      "...moddddddom...",
      "..moddddddddom..",
      ".moddkkddkkddom.",
      ".moddkwddkwddom.",
      "moddddddddddddom",
      "modmdddmmdddmdom",
      "moddddmddmddddom",
      ".modddddddddddm.",
      ".mmoddddddddomm.",
      "..mo.oddddo.om..",
      "..m..oo..oo..m..",
      ".mm..........mm.",
      "................",
      "................",
    },
  },
  r_barkbit = {
    pal = { o = "1a1c3a", a = "ffc857", w = "f2f6ff", k = "1a1c3a", n = "1a1c3a", r = "ff5a75" },
    rows = {
      "............",
      ".oo......oo.",
      "oaao....oaao",
      "oaaooooooaao",
      ".owwwwwwwwo.",
      ".owkwwwwkwo.",
      ".owwwnnwwwo.",
      ".owwwwwwwwo.",
      "..orrrrrro..",
      "..owwwwwwo..",
      "...oo..oo...",
      "............",
    },
  },
  r_purrbit = {
    pal = { o = "1a1c3a", v = "9b7bff", w = "f2f6ff", g = "6dff9e", k = "1a1c3a", p = "ff8fb8" },
    rows = {
      ".o........o.",
      ".oo......oo.",
      ".ovo....ovo.",
      ".ovvoooovvo.",
      ".owwwwwwwwo.",
      ".owgkwwgkwo.",
      ".owwwppwwwo.",
      ".owwwwwwwwo.",
      "..ovvvvvvo..",
      "..owwwwwwo..",
      "...oo..oo.oo",
      "..........o.",
    },
  },
}

-- Sparkbit + evolved forms (16x16, facing right). 'c'/'v' crest and 's'/'S'
-- scarf keys are recolored per save (dominant data type, chosen scarf).
K.FORM_SPRITES = {
  sparkbit = {
    ".......vv.......",
    "......vccv......",
    "....oooccooo....",
    "...owwwwwwwwo...",
    "..owwwwwwwwwwo..",
    "..owwwwwwwwwwo..",
    ".owwwwwwwwwwwwo.",
    ".owwwwwwwwwwwwo.",
    ".owwwwwwwwwwwwo.",
    ".owlwwwwwwwwlwo.",
    "..owwwwwwwwwwo..",
    "..osSSSSSSSSso..",
    ".Sossssssssssso.",
    "SS.owwwwwwwwo...",
    "....oowwwwoo....",
    "......oooo......",
  },
  hackbit = {
    "......a..a......",
    "......a..a......",
    "....oooaaooo....",
    "...owwwwwwwwo...",
    "..oaaaaaaaaaao..",
    "..owwwwwwwwwwo..",
    ".owwwwwwwwwwwwo.",
    ".owwwwwwwwwwwwo.",
    ".owwwwwwwwwwwwo.",
    ".owawwwwwwwwawo.",
    "..owwwwwwwwwwo..",
    "..osSSSSSSSSso..",
    ".Sossssssssssso.",
    "SS.owwwwwwwwo...",
    "...ooowwwwooo...",
    "......oooo......",
  },
  archivebit = {
    "......vvvv......",
    ".....vwwwwv.....",
    "....ovwvvwvo....",
    "...owwwwwwwwo...",
    "..owwwwwwwwwwo..",
    "..owwwwwwwwwwo..",
    "vowwwwwwwwwwwwo.",
    "vowwwwwwwwwwwwo.",
    "vowwwwwwwwwwwwo.",
    ".owvwwwwwwwwvwo.",
    "..owwwwwwwwwwo..",
    "..osSSSSSSSSso..",
    ".Sossssssssssso.",
    "SS.owwwwwwwwo...",
    "....oowwwwoo....",
    "......oooo......",
  },
  pulsebit = {
    ".........cc.....",
    "........cc......",
    "....ooocccoo....",
    ".ccowwwwwwwwo...",
    "..owwwwwwwwwwo..",
    "..owwwwwwwwwwo..",
    ".owwwwwwwwwwwwo.",
    ".owwwwwwwwwwwwo.",
    ".owwwwwwwwwwwwo.",
    ".owcwwwwwwwwcwo.",
    "..owwwwwwwwwwo..",
    "..osSSSSSSSSso..",
    ".Sossssssssssso.",
    "SS.owwwwwwwwo...",
    "....oowwwwoo....",
    "......oooo......",
  },
}

K.TYPE_COLOR = { build = "ffc857", pulse = "5fe3ff", archive = "9b7bff", neutral = "e8ecff" }

return K
