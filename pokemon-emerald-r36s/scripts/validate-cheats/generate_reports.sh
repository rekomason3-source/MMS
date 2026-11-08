#!/usr/bin/env bash
# Regenerate docs/generated/* from the upstream cheat files and ArkOS default hotkeys.
# To analyze YOUR device instead, pass your own files:
#   python3 analyze_cht.py my.cht --retroarch-cfg retroarch.cfg --autoconfig "GO-Super Gamepad.cfg"
set -euo pipefail
cd "$(dirname "$0")/../.."
F=tests/fixtures
for v in pre-2021-11 current; do
  python3 scripts/validate-cheats/analyze_cht.py \
    "cheats/upstream/libretro-$v Pokemon - Emerald Version (USA, Europe) (Code Breaker).cht" \
    --retroarch-cfg "$F/arkos-retroarch.cfg.rg351mp.excerpt" --autoconfig "$F/GO-Super Gamepad.cfg" \
    > "docs/generated/analysis-libretro-$v.md"
done
echo "wrote docs/generated/analysis-libretro-{pre-2021-11,current}.md"
