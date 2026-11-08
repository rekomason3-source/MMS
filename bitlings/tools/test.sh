#!/usr/bin/env bash
# 1) pure-Lua unit tests (needs luajit)
# 2) full scripted playthrough in real LÖVE 11.5 (needs love; uses xvfb-run
#    when there is no display). Screenshots land in the LÖVE save dir.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "== unit tests"
luajit tests/test_core.lua

echo "== autotest playthrough"
SAVE_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/love/bitlings_first_spark"
RUN=(love game)
if [ -z "${DISPLAY:-}" ] && command -v xvfb-run >/dev/null; then
  RUN=(xvfb-run -a -s "-screen 0 640x480x24" love game)
fi
BITLINGS_AUTOTEST=1 BITLINGS_NOAUDIO=1 BITLINGS_SPEED=3 "${RUN[@]}" 2>&1 | grep -vE "^ALSA|Could not open device"
status=${PIPESTATUS[0]}
echo "screenshots: $SAVE_DIR/shot_*.png"
exit "$status"
