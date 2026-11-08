# Bitlings — Growth, Care & Battle Design (v0.2 addendum)

**Status:** Approved direction, November 2026. This **supersedes the RTS layer** of `BITLINGS_GAME_MASTER.md` §4.2/§9/§28 for the native R36S game. Everything else in the master doc still stands.

## 1. Direction in one line

> **Raise Sparkbit. It becomes what you feed it: the data it absorbs, the care you give, and the skills you upload in the Lounge.**

## 2. Influences: mechanics borrowed, nothing copied

Per master §35, only broad design patterns are used. No names, characters, art, maps, UI or audio from any of these.

| Influence | Pattern borrowed | Bitlings system |
|---|---|---|
| Digimon Tamers | Partner grows by absorbing the data of beaten foes; tamers boost partners mid-fight | **Data Absorb** after every win; **Patch Cards** played mid-battle |
| Digimon World 1 | Raising sim (feed, rest, train); evolution depends on how you raised it; rescued creatures move into your town and it grows | **Care** + **Lounge** + **Residents**; evolution gated on care quality |
| Pokémon | Type triangle, collection log, small party | **Build ▸ Pulse ▸ Archive ▸ Build**; **Bitdex** |
| Legend of Dragoon | Timed button-press attack chains; temporary super form; defending restores | **Sync Strike** chains; **Overclock**; **Guard** (+EN) |

## 3. Core loop

1. **Lounge:** feed, pet, rest; upload skills; install aspects; talk to residents.
2. **Gateway:** pick a region.
3. **Explore:** every Glitch is visible on the map (no random encounters). Some patrol, some chase.
4. **Battle:** turn-based with timed inputs.
5. **Win → Absorb:** the Glitch's data flows into Sparkbit (stats, looks, evolution pressure, upload currency).
6. **Return home:** HP heals, residents reward you, spend data on new skills.
7. **Evolve** when data, care, level and leaning line up.

## 4. Data: the central resource

| Pool | Gained from | Used for | Ever spent? |
|---|---|---|---|
| **Lifetime data** (per type) | Battles, FlowSort, data treats | Stats, appearance, evolution direction | Never |
| **Data bank** (per type) | Same events (same amount) | Uploading skills | Yes |

Spending to learn skills never sets evolution back. That's a deliberate anti-grind rule.

**Stats from data** (`src/systems/growth.lua`):

| Type | Every 5 lifetime points |
|---|---|
| Build | +1 DEF, +3 HP |
| Pulse | +1 ATK, +1 SPD |
| Archive | +1 EN (+1 ATK per 10) |

**Appearance from data** (the user's "Sparkbit changes with input" requirement):

| Trigger | Visible change |
|---|---|
| Any data | Crest recolors to the dominant type (amber / cyan / violet) |
| 15+ data | Data marks appear on the body |
| 40+ data | More marks |
| Level | More aura particles |
| Hungry (< 30) | Droops, shows a hunger bubble |
| Scarf aspect | Scarf color (5 options) |
| Evolution | New form sprite |

## 5. Care

| Stat | Behavior |
|---|---|
| Hunger 0–100 | Drains ~1 point / 12 s of play (full → empty in ~20 min). Starts once the Upload Station exists |
| Mood 0–100 | + feed, pet, rest, wins; − hunger, losses |
| Care score | +1 per *good* act: feeding while hungry (< 70), petting (rate-limited), resting |
| Care mistakes | +1 the moment hunger hits 0 (once per episode) |
| **Care quality** | `score − 3 × mistakes` |

Nothing dies and nothing is lost permanently. Neglect only delays evolution and weakens Sparkbit while starving (−10% ATK/DEF).

## 6. The Lounge: modify skills and aspects

The repaired terminal becomes the **Upload Station** (L1/R1 switch tabs):

| Tab | What you do |
|---|---|
| STATUS | Stats, lifetime data, care, evolution checklist + forecast, **Evolve** |
| SKILLS | Upload skills with banked data; equip up to **4** |
| ASPECTS | Buy/install passive modules (**2** slots); change scarf |
| CARE | Byte Snack; **Data Treats** (+3 data of a chosen type, which steers evolution); buy Patch Cards |
| BITDEX | Every Glitch/Bitling met; weaknesses and drops once absorbed |

**Skills** (9 uploadable + FlowSort + 3 evolution signatures):

| Build | Pulse | Archive |
|---|---|---|
| Patch Bolt (6) attack | Pulse Dash (6) attack | Recall Beam (6) attack |
| Firewall (10) −50% dmg 2 turns | Tempo Up (10) +50% ATK 3 turns | Pattern Echo (10) foe takes +50% |
| Construct Drone (18) 3-turn drone | Overdrive Burst (18) big hit | Restore (18) heal 40% |

**Aspects:** Warm Core (hunger ×0.5), Sync Lens (wider timing), Thick Casing (+20% DEF), Lucky Byte (+50% Bits), Data Magnet (+25% data), Overclock Coil (boss reward).

**Residents:**

| Resident | How you get them | Service |
|---|---|---|
| **Barkbit** | Rescued from the Corruptor | *Loyal Fetch*: +10 Bits and a Patch Card after each expedition |
| **Purrbit** | Befriended with a snack (found via Curiosity) | *Quiet Pattern Scan*: tells you which form you're heading toward and why |

## 7. Battle

| Action | Rule |
|---|---|
| **Strike** | First hit lands; then up to 3 rings close on the foe. Press A on each to chain (8 → 6 → 8 → 12 power). A miss ends the chain. All four = *Perfect Sync* |
| **Skills** | Cost EN. Typed attacks use the triangle (×1.5 strong / ×0.67 weak) |
| **Patch** | Free action, once per turn: Heal 40% / +6 EN / +50% ATK / block next hit |
| **Guard** | −50% next hit, +3 EN, +meter |
| **Brace** | On enemy turns, press A on the "!" flash: −50%. Pressing early locks you out |
| **Overclock** | Meter fills from hits dealt/taken and braces. When full: ×1.5 ATK/DEF for 3 turns (free action) |
| Bosses | Telegraph a charge attack one turn ahead (Guard!) |
| Mimic | Changes type every turn (*verify before acting*, master §8) |
| Win | Absorb data, XP, Bits, possible card. Level-up heals |
| Lose | Return to Lounge at full HP, −mood. Nothing lost |

## 8. Evolution

**Gates (all required):** Level 3 · 30 lifetime data · one type ≥ 45% of evolution pressure · care quality ≥ 8 · mood ≥ 50.

**Pressure per type** = lifetime data + 2 × mapped trait (Build→build, Pulse→focus, Archive→knowledge). So play style matters as well as what you absorb.

| Dominant | Form | Signature |
|---|---|---|
| Build | **Hackbit** | System Siege (huge Build hit) |
| Pulse | **Pulsebit** | Tempo Rush (double Pulse hit) |
| Archive | **Archivebit** | Total Recall (heal 65%) |

Forms get ×1.3 stats and take on that type. Identity, memories, bond and residents carry over. Players may delay evolving (master §4.3).

## 9. Content shipped in v0.2

| Region | Screens | Glitches | Other |
|---|---|---|---|
| Lounge (Ch. 0) | 1 | Loop Glitch: seal 3 nodes, then the **battle tutorial** | Upload Station, residents |
| **Signals (Ch. 1)** | Signal Fields → Static Marsh → Relay Tower | Noise Mote ×3, Drift Wisp, Fragment Crab, Mimic Node, **Corruptor (boss)** | 2 caches (1 hidden), Purrbit (hidden), Barkbit (caged), end card |

## 10. Next design questions (for the user)

1. Second-stage evolutions: 2 branches per form (e.g. Hackbit → tank vs. engineer), gated on care?
2. Should residents ever fight (a call-in assist), or stay home-only?
3. Chapter 2 (Archive) theme and its signature mechanic.
4. Real art direction for Sparkbit and the three forms.
