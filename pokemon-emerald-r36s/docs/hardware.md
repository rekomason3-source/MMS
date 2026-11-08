# Hardware — R36S

| Item | Genuine R36S (documented) | Your unit |
|---|---|---|
| SoC | Rockchip RK3326, 4× Cortex-A35 | ❓ |
| GPU | Mali-G31 | ❓ |
| RAM | 1 GB (clones: 512 MB / 2 GB) | ❓ |
| Screen | 3.5" 640×480; several panel revisions (needs a matching DTB) | ❓ |
| Storage | microSD (one or two slots, depending on model) | ❓ |
| Controls | D-pad, A/B/X/Y, L1/R1/L2/R2, Select/Start, 2 analog sticks (L3/R3) | ✅ (user) |

Clones exist that use different SoCs (RK3128, Allwinner A33) and need different firmware. The `inspect_r36s.sh` System section (`/boot/*.dtb`, device-tree model, `/proc/cpuinfo`, `MemTotal`) answers the ❓ rows.

Bot relevance: 1 GB RAM and A35 cores can easily run a small Python/Lua helper. They can't run a local AI model at useful speed. See `bot-architecture.md`.

Sources: https://handhelds.wiki/R36S_Overview , https://handhelds.wiki/R36S_Clones , https://techtactician.com/r36s-vs-r36xx-r36plus-max-ultra-explained/
