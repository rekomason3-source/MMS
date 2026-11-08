# Analysis of `libretro-pre-2021-11 Pokemon - Emerald Version (USA, Europe) (Code Breaker).cht`

- Cheats: 137
- Hotkey config: tests/fixtures/arkos-retroarch.cfg.rg351mp.excerpt; controller: tests/fixtures/GO-Super Gamepad.cfg
- Cheats with hotkey conflicts: 20
- Cheats with parser warnings: 33

| # | Cheat | Format | Activator | Writes | Hotkey conflict | Warnings |
|---|---|---|---|---|---|---|
| 0 | Master Code | CodeBreaker | always on | - | - | - |
| 1 | Skip Intro | CodeBreaker | always on | IO, IWRAM | - | - |
| 2 | Change PLYR Name (View Trainer Card) | CodeBreaker | always on | IO, IWRAM | - | - |
| 3 | No Random Battles | CodeBreaker | always on | IO | - | - |
| 4 | Always Your Turn | CodeBreaker | always on | EWRAM, IO | - | - |
| 5 | Easy Win (Trainer) | CodeBreaker | always on | EWRAM, IO | - | - |
| 6 | Easy Win (Doubles) | CodeBreaker | always on | EWRAM, IO | - | - |
| 7 | Quick Contest | CodeBreaker | always on | EWRAM, IO | - | - |
| 8 | Maximum Score | CodeBreaker | always on | EWRAM, IO | - | - |
| 9 | Maximum Hearts | CodeBreaker | always on | EWRAM, IO | - | - |
| 10 | Max Coins from Pokies | CodeBreaker | always on | EWRAM, IO | - | - |
| 11 | Receive BP [Hold Select] | CodeBreaker | Select; Select | IO, IWRAM | - | a line was swallowed by a FILL code - check that the button gate still protects every write (it may run unconditionally) |
| 12 | Free Daycare | CodeBreaker | always on | IO | - | - |
| 13 | Free MOD Shop Items | CodeBreaker | always on | EWRAM, IO | - | - |
| 14 | Access MOD Shop [L+A+Sel] | CodeBreaker | A+Select+L; A+Select+L | EWRAM, IO, IWRAM | A+Select+L -> Load State [DANGER] | a line was swallowed by a FILL code - check that the button gate still protects every write (it may run unconditionally) |
| 15 | Access Deco Shop [L+A+Sel] | CodeBreaker | A+Select+L; A+Select+L | EWRAM, IO, IWRAM | A+Select+L -> Load State [DANGER] | a line was swallowed by a FILL code - check that the button gate still protects every write (it may run unconditionally) |
| 16 | Maximum Sale Price | CodeBreaker | always on | IO, IWRAM | - | - |
| 17 | Infinite Safari Time | CodeBreaker | always on | IO | - | - |
| 18 | Infinite Safari Balls | CodeBreaker | always on | IO | - | - |
| 19 | Safari PKMN Easily Caught | CodeBreaker | always on | EWRAM, IO | - | - |
| 20 | Wild PKMN Easily Caught | CodeBreaker | always on | EWRAM, IO | - | - |
| 21 | Gain 5000 Exp (Press R+A whilst EXP Gained is displayed) | CodeBreaker | always on | EWRAM, IO | - | - |
| 22 | Infinite PP | CodeBreaker | always on | IO | - | - |
| 23 | Pokemon #1: Max Stats | CodeBreaker | always on | IO | - | - |
| 24 | Pokemon #2: Max Stats | CodeBreaker | always on | IO | - | - |
| 25 | Pokemon #3: Max Stats | CodeBreaker | always on | IO | - | - |
| 26 | Pokemon #4: Max Stats | CodeBreaker | always on | IO | - | - |
| 27 | Pokemon #5: Max Stats | CodeBreaker | always on | IO | - | - |
| 28 | Pokemon #6: Max Stats | CodeBreaker | always on | IO | - | - |
| 29 | Empty 6th Party Slot [Sel+L] | CodeBreaker | always on | EWRAM, IO | - | - |
| 30 | Enable National Dex [Select] | CodeBreaker | Select | IO, IWRAM | - | a line was swallowed by a FILL code - check that the button gate still protects every write (it may run unconditionally) |
| 31 | Access Pyramid Chall[Select] | CodeBreaker | Select | IO, IWRAM | - | a line was swallowed by a FILL code - check that the button gate still protects every write (it may run unconditionally) |
| 32 | Install PokeNAV [Sel+R+Down] | CodeBreaker | Select+Down+R | IO, IWRAM | Select+Down+R -> Save State [DANGER]<br>Select+Down+R -> State Slot + [side-effect] | a line was swallowed by a FILL code - check that the button gate still protects every write (it may run unconditionally) |
| 33 | Install Match Call[Sel+R+Up] | CodeBreaker | Select+Up+R | IO, IWRAM | Select+Up+R -> Save State [DANGER]<br>Select+Up+R -> State Slot - [side-effect] | a line was swallowed by a FILL code - check that the button gate still protects every write (it may run unconditionally) |
| 34 | Have all Match Calls | CodeBreaker | always on | EWRAM, IO, IWRAM | - | - |
| 35 | Access PC [B+Sel] | CodeBreaker | B+Select | IO, IWRAM | B+Select -> Reset Game [DANGER] | a line was swallowed by a FILL code - check that the button gate still protects every write (it may run unconditionally) |
| 36 | Access Birchs Bag [L+R+Up] | CodeBreaker | Up+R+L; Up+R+L; Up+R+L | IO, IWRAM | - | a line was swallowed by a FILL code - check that the button gate still protects every write (it may run unconditionally) |
| 37 | Battle Mew [L+Sel] | CodeBreaker | Select+L | IO, IWRAM | Select+L -> Load State [DANGER] | a line was swallowed by a FILL code - check that the button gate still protects every write (it may run unconditionally) |
| 38 | Battle Deoxys [R+Sel] | CodeBreaker | Select+R | IO, IWRAM | Select+R -> Save State [DANGER] | a line was swallowed by a FILL code - check that the button gate still protects every write (it may run unconditionally) |
| 39 | Battle Ho-oh [R+A+Sel] | CodeBreaker | A+Select+R | IO, IWRAM | A+Select+R -> Save State [DANGER] | a line was swallowed by a FILL code - check that the button gate still protects every write (it may run unconditionally) |
| 40 | Battle Lugia [L+B+Sel] | CodeBreaker | B+Select+L | IO, IWRAM | B+Select+L -> Load State [DANGER]<br>B+Select+L -> Reset Game [DANGER] | a line was swallowed by a FILL code - check that the button gate still protects every write (it may run unconditionally) |
| 41 | Battle Kyogre [R+A+Sel] | CodeBreaker | A+Select+R | IO, IWRAM | A+Select+R -> Save State [DANGER] | a line was swallowed by a FILL code - check that the button gate still protects every write (it may run unconditionally) |
| 42 | Battle Groudon [R+B+Sel] | CodeBreaker | B+Select+R | IO, IWRAM | B+Select+R -> Save State [DANGER]<br>B+Select+R -> Reset Game [DANGER] | a line was swallowed by a FILL code - check that the button gate still protects every write (it may run unconditionally) |
| 43 | Choose Latias/Latios [L+Sel] | CodeBreaker | always on | IO, IWRAM | - | - |
| 44 | Battle Latias/Latios [R+Sel] | CodeBreaker | always on | IO, IWRAM | - | - |
| 45 | Receive Starter | CodeBreaker | Down+R+L; Down+R+L; Down+R+L; Down+R+L; Down+R+L | IO, IWRAM | - | a line was swallowed by a FILL code - check that the button gate still protects every write (it may run unconditionally) |
| 46 | Starter to Receive - Cyndaquil | CodeBreaker | Down+R+L | IO, IWRAM | - | a line was swallowed by a FILL code - check that the button gate still protects every write (it may run unconditionally) |
| 47 | Starter to Receive - Totodile | CodeBreaker | Down+R+L | IO, IWRAM | - | a line was swallowed by a FILL code - check that the button gate still protects every write (it may run unconditionally) |
| 48 | Starter to Receive - Chikorita | CodeBreaker | Down+R+L | IO, IWRAM | - | a line was swallowed by a FILL code - check that the button gate still protects every write (it may run unconditionally) |
| 49 | Have Ability: Cut | CodeBreaker | always on | IO, IWRAM | - | - |
| 50 | Have Ability: Rock Smash | CodeBreaker | always on | IO, IWRAM | - | - |
| 51 | Have Ability: Waterfall | CodeBreaker | always on | IO, IWRAM | - | - |
| 52 | Have Ability: Flash [L+Sel] | CodeBreaker | Select+Up | IO, IWRAM | Select+Up -> State Slot - [side-effect] | a line was swallowed by a FILL code - check that the button gate still protects every write (it may run unconditionally) |
| 53 | Have Ability: Dive [R+Sel] | CodeBreaker | Select+R | IO, IWRAM | Select+R -> Save State [DANGER] | a line was swallowed by a FILL code - check that the button gate still protects every write (it may run unconditionally) |
| 54 | Have Ability: Surf [B+Sel] | CodeBreaker | B+Select | IO, IWRAM | B+Select -> Reset Game [DANGER] | a line was swallowed by a FILL code - check that the button gate still protects every write (it may run unconditionally) |
| 55 | Access Secret Power | CodeBreaker | always on | IO, IWRAM | - | - |
| 56 | Access Fly Map [A+Sel] | CodeBreaker | A+Select | IO, IWRAM | - | a line was swallowed by a FILL code - check that the button gate still protects every write (it may run unconditionally) |
| 57 | Fly Anywhere on Map | CodeBreaker | always on | EWRAM, IO | - | - |
| 58 | Max Direct Hits | CodeBreaker | always on | EWRAM, IO | - | - |
| 59 | No Misses | CodeBreaker | always on | EWRAM, IO | - | - |
| 60 | Quick Blend | CodeBreaker | always on | EWRAM, IO | - | - |
| 61 | Maximum Feel | CodeBreaker | always on | EWRAM, IO | - | - |
| 62 | Max Lvl Gold (Cool) | CodeBreaker | always on | EWRAM, IO | - | - |
| 63 | Max Lvl Gold (Beauty) | CodeBreaker | always on | EWRAM, IO | - | - |
| 64 | Max Lvl Gold (Cute) | CodeBreaker | always on | EWRAM, IO | - | - |
| 65 | Max Lvl Gold (Smart) | CodeBreaker | always on | EWRAM, IO | - | - |
| 66 | Max Lvl Gold (Tough) | CodeBreaker | always on | EWRAM, IO | - | - |
| 67 | Re-Battle Activator [Select+A] | CodeBreaker | Select | IO, IWRAM | - | a line was swallowed by a FILL code - check that the button gate still protects every write (it may run unconditionally) |
| 68 | Battle Tower (Single) | CodeBreaker | always on | IO, IWRAM | - | - |
| 69 | Battle Palace | CodeBreaker | always on | IO, IWRAM | - | - |
| 70 | Battle Pyramid | CodeBreaker | always on | IO, IWRAM | - | - |
| 71 | Battle Dome | CodeBreaker | always on | EWRAM, IO, IWRAM | - | - |
| 72 | Gym Leader Roxanne | CodeBreaker | always on | EWRAM, IO | - | - |
| 73 | Gym Leader Brawly | CodeBreaker | always on | EWRAM, IO | - | - |
| 74 | Gym Leader Watson | CodeBreaker | always on | EWRAM, IO | - | - |
| 75 | Gym Leader Flannery | CodeBreaker | always on | EWRAM, IO | - | - |
| 76 | Gym Leader Norman | CodeBreaker | always on | EWRAM, IO | - | - |
| 77 | Gym Leader Winona | CodeBreaker | always on | EWRAM, IO | - | - |
| 78 | Gym Leader Tate&Liza | CodeBreaker | always on | EWRAM, IO | - | - |
| 79 | Gym Leader Juan | CodeBreaker | always on | EWRAM, IO | - | - |
| 80 | Elite Four Sidney | CodeBreaker | always on | EWRAM, IO | - | - |
| 81 | Elite Four Phoebe | CodeBreaker | always on | EWRAM, IO | - | - |
| 82 | Elite Four Glacia | CodeBreaker | always on | EWRAM, IO | - | - |
| 83 | Elite Four Drake | CodeBreaker | always on | EWRAM, IO | - | - |
| 84 | Champion Wallace | CodeBreaker | always on | EWRAM, IO | - | - |
| 85 | Stone Badge [Sel+Up] | CodeBreaker | Select+Up | IO, IWRAM | Select+Up -> State Slot - [side-effect] | a line was swallowed by a FILL code - check that the button gate still protects every write (it may run unconditionally) |
| 86 | Knuckle Badge [Sel+Rght] | CodeBreaker | Select+Right | IO, IWRAM | - | a line was swallowed by a FILL code - check that the button gate still protects every write (it may run unconditionally) |
| 87 | Dynamo Badge [Sel+Down] | CodeBreaker | Select+Down | IO, IWRAM | Select+Down -> State Slot + [side-effect] | a line was swallowed by a FILL code - check that the button gate still protects every write (it may run unconditionally) |
| 88 | Heat Badge [Sel+Left] | CodeBreaker | Select+Left | IO, IWRAM | - | a line was swallowed by a FILL code - check that the button gate still protects every write (it may run unconditionally) |
| 89 | Balance Badge [Sel+L+Up] | CodeBreaker | Select+Up+L | IO, IWRAM | Select+Up+L -> Load State [DANGER]<br>Select+Up+L -> State Slot - [side-effect] | a line was swallowed by a FILL code - check that the button gate still protects every write (it may run unconditionally) |
| 90 | Feather Badge [Sel+L+Rght] | CodeBreaker | Select+Right+L | IO, IWRAM | Select+Right+L -> Load State [DANGER] | a line was swallowed by a FILL code - check that the button gate still protects every write (it may run unconditionally) |
| 91 | Mind Badge [Sel+L+Down] | CodeBreaker | Select+Down+L | IO, IWRAM | Select+Down+L -> Load State [DANGER]<br>Select+Down+L -> State Slot + [side-effect] | a line was swallowed by a FILL code - check that the button gate still protects every write (it may run unconditionally) |
| 92 | Rain Badge [Sel+L+Left] | CodeBreaker | Select+Left+L | IO, IWRAM | Select+Left+L -> Load State [DANGER] | a line was swallowed by a FILL code - check that the button gate still protects every write (it may run unconditionally) |
| 93 | Battle Pike | CodeBreaker | always on | IO, IWRAM | - | - |
| 94 | Faraway Island | CodeBreaker | always on | EWRAM, IO | - | - |
| 95 | Birth Island | CodeBreaker | always on | EWRAM, IO | - | - |
| 96 | Navel Rock | CodeBreaker | always on | EWRAM, IO | - | - |
| 97 | Southern Island | CodeBreaker | always on | EWRAM, IO | - | - |
| 98 | Battle Frontier | CodeBreaker | always on | EWRAM, IO | - | - |
| 99 | Safari Zone | CodeBreaker | always on | EWRAM, IO | - | - |
| 100 | Petalburg City | CodeBreaker | always on | EWRAM, IO | - | - |
| 101 | Slateport City | CodeBreaker | always on | EWRAM, IO | - | - |
| 102 | Mauville City | CodeBreaker | always on | EWRAM, IO | - | - |
| 103 | Rustboro City | CodeBreaker | always on | EWRAM, IO | - | - |
| 104 | Fortree City | CodeBreaker | always on | EWRAM, IO | - | - |
| 105 | Lilycove City | CodeBreaker | always on | EWRAM, IO | - | - |
| 106 | Mossdeep City | CodeBreaker | always on | EWRAM, IO | - | - |
| 107 | Sootopolis City | CodeBreaker | always on | EWRAM, IO | - | - |
| 108 | Ever Grande City | CodeBreaker | always on | EWRAM, IO | - | - |
| 109 | Littleroot Town | CodeBreaker | always on | EWRAM, IO | - | - |
| 110 | Oldale Town | CodeBreaker | always on | EWRAM, IO | - | - |
| 111 | Dewford Town | CodeBreaker | always on | EWRAM, IO | - | - |
| 112 | Lavaridge Town | CodeBreaker | always on | EWRAM, IO | - | - |
| 113 | Fallarbor Town | CodeBreaker | always on | EWRAM, IO | - | - |
| 114 | Verdanturf Town | CodeBreaker | always on | EWRAM, IO | - | - |
| 115 | Pacifidlog Town | CodeBreaker | always on | EWRAM, IO | - | - |
| 116 | Battle Arena | CodeBreaker | always on | IO, IWRAM | - | - |
| 117 | Purchase All Mail | CodeBreaker | always on | EWRAM, IO | - | - |
| 118 | Purchase All Pokeballs | CodeBreaker | always on | EWRAM, IO | - | - |
| 119 | Purchase All Misc Items (Part 1) | CodeBreaker | always on | EWRAM, IO, IWRAM | - | - |
| 120 | Purchase All Misc Items (Part 2) | CodeBreaker | always on | EWRAM, IO | - | - |
| 121 | Purchase All TM's/HM's (Part 1) | CodeBreaker | always on | EWRAM, IO, IWRAM | - | - |
| 122 | Purchase All TM's/HM's (Part 2) | CodeBreaker | always on | EWRAM, IO | - | - |
| 123 | Purchase All Berries (Part 1) | CodeBreaker | always on | EWRAM, IO, IWRAM | - | - |
| 124 | Purchase All Berries (Part 2) | CodeBreaker | always on | EWRAM, IO | - | - |
| 125 | Purchase All Hold Items (Part 1) | CodeBreaker | always on | EWRAM, IO, IWRAM | - | - |
| 126 | Purchase All Hold Items (Part 2) | CodeBreaker | always on | EWRAM, IO | - | - |
| 127 | Purchase All Decorations (Part 1) | CodeBreaker | always on | EWRAM, IO, IWRAM | - | - |
| 128 | Purchase All Decorations (Part 2) | CodeBreaker | always on | EWRAM, IO | - | - |
| 129 | Quick Egg Hatch | CodeBreaker | always on | IO, IWRAM | - | - |
| 130 | Infinite Cash | CodeBreaker | always on | EWRAM, IO, IWRAM | - | - |
| 131 | All Items on Sale: Part 1/2 | CodeBreaker | always on | EWRAM, IO | - | - |
| 132 | All Items on Sale: Part 2/2 | CodeBreaker | always on | EWRAM, IO | - | - |
| 133 | Copy Battle PKMN Part 1/2 | CodeBreaker | always on | EWRAM, IO, IWRAM | - | - |
| 134 | Copy Battle PKMN Part 2/2 | CodeBreaker | always on | EWRAM, IO, IWRAM, OTHER | - | cheat ends inside a FILL: mGBA keeps this state in the SHARED set, so the FIRST line of the next enabled cheat will be swallowed |
| 135 | Clone Box PKMN Part 1/2 | CodeBreaker | always on | EWRAM, IO, IWRAM | - | - |
| 136 | Clone Box PKMN Part 2/2 | CodeBreaker | always on | IO, OTHER, SRAM/Flash | - | - |
