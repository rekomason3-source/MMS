#!/usr/bin/env bash
# backup_saves.sh - Copy Pokemon Emerald save data to a NEW timestamped folder,
# write a SHA-256 manifest, and verify the copy. It never deletes or overwrites.
#
# What it copies (anything in SRC_DIR whose name starts with the ROM base name):
#   <rom>.srm          RetroArch in-game save (the important one - your real progress)
#   <rom>.sav          (if present; some setups use .sav)
#   <rom>.state*       RetroArch save states (.state, .state1..N, .state.auto)
#   <rom>.cht / *.png  (if present)
#
# Usage:
#   bash backup_saves.sh --src /roms/gba --name "Pokemon - Emerald Version (USA, Europe)" --dest /roms/backups/emerald
#
# Recommended: --dest on a DIFFERENT card (/roms2) or copy the result to a PC afterwards.
# Close the game (Select+Start) before running so the .srm on disk is current.
set -euo pipefail

SRC="" NAME="" DEST=""
while [ $# -gt 0 ]; do
  case "$1" in
    --src) SRC="$2"; shift 2 ;;
    --name) NAME="$2"; shift 2 ;;
    --dest) DEST="$2"; shift 2 ;;
    -h|--help) sed -n '2,16p' "$0"; exit 0 ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
done
[ -n "$SRC" ] && [ -n "$NAME" ] && [ -n "$DEST" ] || { echo "need --src, --name and --dest (see --help)" >&2; exit 2; }
[ -d "$SRC" ] || { echo "source dir not found: $SRC" >&2; exit 1; }

if pgrep -x retroarch >/dev/null 2>&1 || pgrep -x retroarch32 >/dev/null 2>&1; then
  echo "WARNING: RetroArch is running. The .srm on disk may be stale until the game is closed." >&2
  echo "         Close the game first (Select+Start), then re-run. Aborting." >&2
  exit 3
fi

shopt -s nullglob
files=()
for f in "$SRC/$NAME".srm "$SRC/$NAME".sav "$SRC/$NAME".state* "$SRC/$NAME".cht "$SRC/$NAME".png; do
  [ -f "$f" ] && files+=("$f")
done
[ ${#files[@]} -gt 0 ] || { echo "no save files matching '$NAME.*' in $SRC" >&2; exit 1; }

STAMP="$(date '+%Y%m%d-%H%M%S')"
OUTDIR="$DEST/$STAMP"
[ -e "$OUTDIR" ] && { echo "refusing: $OUTDIR already exists" >&2; exit 1; }
mkdir -p "$OUTDIR"

for f in "${files[@]}"; do
  cp -p -- "$f" "$OUTDIR/"            # -p keeps timestamps; cp never touches the source
done

( cd "$SRC" && for f in "${files[@]}"; do sha256sum -- "$(basename "$f")"; done ) > "$OUTDIR/SHA256SUMS.source"
( cd "$OUTDIR" && sha256sum -c SHA256SUMS.source ) > "$OUTDIR/VERIFY.log" 2>&1 || {
  echo "VERIFY FAILED - backup in $OUTDIR does not match the source. See VERIFY.log" >&2; exit 4; }

{
  echo "created: $STAMP"
  echo "source:  $SRC"
  echo "rom:     $NAME"
  for f in "${files[@]}"; do ls -l --time-style=+%Y-%m-%dT%H:%M:%S "$f"; done
} > "$OUTDIR/MANIFEST.txt"

sync
echo "OK: ${#files[@]} file(s) backed up and verified -> $OUTDIR"
cat "$OUTDIR/VERIFY.log"
