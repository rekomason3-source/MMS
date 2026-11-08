#!/usr/bin/env bash
# Builds:
#   dist/bitlings.love   — runs on any LÖVE 11.5 (desktop: `love dist/bitlings.love`)
#   dist/bitlings.zip    — PortMaster package (Bitlings.sh + bitlings/)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DIST="$ROOT/dist"
rm -rf "$DIST"
mkdir -p "$DIST"

# 1) .love archive (game root must be the archive root)
( cd "$ROOT/game" && zip -9 -q -r -X "$DIST/bitlings.love" main.lua conf.lua src assets )

# 2) PortMaster layout
PM="$DIST/portmaster"
mkdir -p "$PM/bitlings/saves"
cp "$ROOT/portmaster/Bitlings.sh" "$PM/Bitlings.sh"
chmod +x "$PM/Bitlings.sh"
cp "$ROOT/portmaster/bitlings/port.json" "$ROOT/portmaster/bitlings/gameinfo.xml" "$PM/bitlings/"
cp "$DIST/bitlings.love" "$PM/bitlings/bitlings.love"
cp "$ROOT/docs/CONTROLS.md" "$PM/bitlings/CONTROLS.md"
touch "$PM/bitlings/saves/.keep"
( cd "$PM" && zip -9 -q -r -X "$DIST/bitlings.zip" Bitlings.sh bitlings )

echo "Built:"
ls -lh "$DIST/bitlings.love" "$DIST/bitlings.zip"
