# R36S TECHNICAL TARGET — BITLINGS

## Verified baseline
- RK3326 quad-core ARM Cortex-A35 up to about 1.5 GHz
- Mali-G31 MP2
- 1 GB DDR3L
- 3.5-inch 640×480 4:3 IPS
- Linux/ArkOS-compatible firmware
- dual analog sticks + D-pad + ABXY + shoulder buttons
- microSD storage
- normally no built-in Wi-Fi

## Consequences
- 640×480 canonical canvas
- offline-first
- lightweight 2D
- small armies/maps
- controller-first UI
- no required cloud AI

## Recommended native runtime
**LÖVE 11.5 via PortMaster**. PortMaster documents LÖVE as a lightweight 2D framework, one of the easiest/common engines to port, with a shared aarch64 runtime.

## Secondary
Godot 3.x through PortMaster FRT if editor/scene tooling materially speeds development.

## Split-stack rule
The R36S game may use LÖVE while the broader Bitlings desktop/web Lounge uses Phaser/TypeScript. Share data/IP concepts rather than forcing one engine everywhere.
