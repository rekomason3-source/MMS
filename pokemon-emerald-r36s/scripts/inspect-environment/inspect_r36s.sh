#!/usr/bin/env bash
# inspect_r36s.sh - READ-ONLY environment report for R36S / ArkOS / RetroArch / mGBA.
#
# It never writes, moves, or deletes anything on the device. The only file it can
# create is the report itself, and only if you pass --out FILE.
#
# Run ON THE HANDHELD (ArkOS terminal, or over SSH/Wi-Fi):
#     bash inspect_r36s.sh                       # print report to screen
#     bash inspect_r36s.sh --out /roms/r36s-report.txt
#
# Run ON A PC against a mounted SD card (only the ROMS/EASYROMS partition is
# usually visible on Windows/macOS; the Linux partition needs Linux):
#     bash inspect_r36s.sh --roms /media/$USER/EASYROMS --config /media/$USER/<rootfs>/home/ark/.config
#
# Options:
#     --roms DIR      ROM root(s) to scan (repeatable). Default: /roms /roms2
#     --config DIR    Linux user config dir. Default: $HOME/.config (ArkOS: /home/ark/.config)
#     --out FILE      also write the report to FILE
#     --no-hash       skip ROM/save hashing (faster)
set -u

ROM_ROOTS=()
CONFIG_DIR=""
OUT=""
HASH=1
while [ $# -gt 0 ]; do
  case "$1" in
    --roms) ROM_ROOTS+=("$2"); shift 2 ;;
    --config) CONFIG_DIR="$2"; shift 2 ;;
    --out) OUT="$2"; shift 2 ;;
    --no-hash) HASH=0; shift ;;
    -h|--help) sed -n '2,22p' "$0"; exit 0 ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
done
[ ${#ROM_ROOTS[@]} -eq 0 ] && ROM_ROOTS=(/roms /roms2)
if [ -z "$CONFIG_DIR" ]; then
  if [ -d /home/ark/.config ]; then CONFIG_DIR=/home/ark/.config; else CONFIG_DIR="$HOME/.config"; fi
fi

# Known-good Pokemon Emerald dumps (No-Intro, via libretro-database metadat/no-intro).
known_sha1() {
  case "$1" in
    f3ae088181bf583e55daf962a92bb46f4f1d07b7) echo "Pokemon - Emerald Version (USA, Europe) [BPEE] - MATCHES libretro cheat file" ;;
    d7cf8f156ba9c455d164e1ea780a6bf1945465c2) echo "Pocket Monsters - Emerald (Japan) [BPEJ]" ;;
    61c2eb2b380b1a75f0c94b767a2d4c26cd7ce4e3) echo "Pokemon - Smaragd-Edition (Germany) [BPED]" ;;
    ca666651374d89ca439007bed54d839eb7bd14d0) echo "Pokemon - Version Emeraude (France) [BPEF]" ;;
    1692db322400c3141c5de2db38469913ceb1f4d4) echo "Pokemon - Versione Smeraldo (Italy) [BPEI]" ;;
    fe1558a3dcb0360ab558969e09b690888b846dd9) echo "Pokemon - Edicion Esmeralda (Spain) [BPES]" ;;
    *) echo "UNKNOWN - not a clean retail dump (hack, patched, trimmed, or bad dump)" ;;
  esac
}

report() {
  h() { printf '\n==== %s ====\n' "$1"; }
  kv() { printf '%-34s %s\n' "$1" "$2"; }

  h "Report"
  kv "generated" "$(date -u '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null)"
  kv "script" "inspect_r36s.sh (read-only)"
  kv "config dir" "$CONFIG_DIR"
  kv "rom roots" "${ROM_ROOTS[*]}"

  h "System (only meaningful when run on the handheld)"
  kv "uname" "$(uname -a 2>/dev/null)"
  [ -r /etc/os-release ] && kv "os-release" "$(. /etc/os-release; echo "$PRETTY_NAME")"
  for f in /usr/share/plymouth/themes/text.plymouth /home/ark/.config/.VERSION /etc/arkos-release; do
    [ -r "$f" ] && kv "version file $f" "$(grep -m3 -i -E 'title|version|ark' "$f" 2>/dev/null | tr '\n' ' ')"
  done
  [ -r /proc/device-tree/model ] && kv "device-tree model" "$(tr -d '\0' </proc/device-tree/model)"
  [ -r /proc/device-tree/compatible ] && kv "dt compatible" "$(tr '\0' ' ' </proc/device-tree/compatible)"
  kv "cpu" "$(grep -m1 -E 'model name|Hardware' /proc/cpuinfo 2>/dev/null | cut -d: -f2-) cores=$(grep -c ^processor /proc/cpuinfo 2>/dev/null)"
  kv "memory" "$(grep -m1 MemTotal /proc/meminfo 2>/dev/null)"
  kv "boot dtb files" "$(ls /boot/*.dtb 2>/dev/null | xargs -n1 basename 2>/dev/null | tr '\n' ' ')"
  kv "mounts (roms)" "$(grep -E ' /roms2? ' /proc/mounts 2>/dev/null | awk '{print $1" "$2" "$3}' | tr '\n' ';')"
  kv "input devices" "$(grep -E '^N: Name=' /proc/bus/input/devices 2>/dev/null | cut -d'"' -f2 | tr '\n' ';')"
  kv "python3" "$(command -v python3 2>/dev/null || echo 'not found')"

  for RA in retroarch retroarch32; do
    D="$CONFIG_DIR/$RA"
    h "RetroArch config: $D"
    if [ ! -d "$D" ]; then echo "not found"; continue; fi
    for bin in /opt/$RA/bin/$RA /usr/local/bin/$RA /usr/bin/$RA; do
      [ -x "$bin" ] && kv "binary $bin" "$("$bin" --version 2>&1 | head -1)"
    done
    CFG="$D/retroarch.cfg"
    if [ -r "$CFG" ]; then
      kv "retroarch.cfg" "$(ls -l "$CFG" | awk '{print $5" bytes, "$6" "$7" "$8}')"
      echo "-- persistence / cheats / saves --"
      grep -E '^(config_save_on_exit|apply_cheats_after_load|apply_cheats_after_toggle|cheat_database_path|savefile_directory|savefiles_in_content_dir|savestate_directory|savestates_in_content_dir|savestate_auto_load|savestate_auto_save|savestate_auto_index|block_sram_overwrite|sort_save[a-z_]*|libretro_directory|joypad_autoconfig_dir|input_autodetect_enable|input_remapping_directory|rgui_config_directory) ' "$CFG"
      echo "-- hotkeys bound to a gamepad button (nul = unbound) --"
      grep -E '^(input_enable_hotkey_btn|input_menu_toggle_gamepad_combo|input_hotkey_block_delay|input_(load_state|save_state|reset|exit_emulator|close_content|menu_toggle|state_slot_increase|state_slot_decrease|screenshot|pause_toggle|toggle_fast_forward|hold_fast_forward|rewind|cheat_toggle|cheat_index_plus|cheat_index_minus|brightness_up|brightness_down)_btn) ' "$CFG"
    fi
    echo "-- core / game overrides that could change hotkeys for mGBA --"
    find "$D/config" -maxdepth 3 \( -iname '*mgba*' -o -iname '*emerald*' \) 2>/dev/null | while read -r f; do
      echo "$f"; [ -f "$f" ] && grep -E 'input_.*(state|hotkey|reset)' "$f" 2>/dev/null | sed 's/^/    /'
    done
    echo "-- controller autoconfig profiles --"
    ls "$D/autoconfig/udev" 2>/dev/null | head -20
    echo "-- mGBA core files --"
    ls -l "$D/cores" 2>/dev/null | grep -i -E 'mgba|gpsp|vba' | awk '{print $5, $6, $7, $8, $9}'
    [ -r "$D/cores/mgba_libretro.info" ] && grep -E '^(display_version|corename)' "$D/cores/mgba_libretro.info"
    echo "-- Emerald cheat files --"
    find "$D/cheats" -iname '*emerald*.cht' 2>/dev/null | while read -r f; do
      n=$(grep -m1 -E '^cheats *=' "$f" | tr -d ' ')
      mew=$(grep -n -i 'Battle Mew' "$f" | head -1 | cut -c1-60)
      echo "$f  [$n]  ${mew:+mew-entry: $mew}"
      [ "$HASH" = 1 ] && echo "    sha256 $(sha256sum "$f" | cut -d' ' -f1)"
    done
  done

  h "ROMs, saves, save states"
  for R in "${ROM_ROOTS[@]}"; do
    [ -d "$R" ] || { echo "$R: not found"; continue; }
    for G in "$R/gba" "$R/GBA"; do
      [ -d "$G" ] || continue
      echo "-- $G --"
      find "$G" -maxdepth 2 -type f \( -iname '*.gba' -o -iname '*.zip' -o -iname '*.7z' \) 2>/dev/null | grep -i -E 'emer|esmer|smarag|smeral|pokemon|pocket' | while read -r f; do
        echo "ROM  $f"
        kv "  size" "$(wc -c <"$f" | tr -d ' ') bytes"
        case "$f" in
          *.gba|*.GBA)
            kv "  header title (0xA0)" "$(dd if="$f" bs=1 skip=160 count=12 2>/dev/null | tr -c '[:print:]' '.')"
            kv "  game code (0xAC)" "$(dd if="$f" bs=1 skip=172 count=4 2>/dev/null | tr -c '[:print:]' '.')"
            kv "  maker code (0xB0)" "$(dd if="$f" bs=1 skip=176 count=2 2>/dev/null | tr -c '[:print:]' '.')"
            kv "  version byte (0xBC)" "$(dd if="$f" bs=1 skip=188 count=1 2>/dev/null | od -An -tu1 | tr -d ' ')"
            if [ "$HASH" = 1 ]; then
              s=$(sha1sum "$f" | cut -d' ' -f1)
              kv "  sha1" "$s"
              kv "  crc32/md5" "$(command -v crc32 >/dev/null && crc32 "$f") $(md5sum "$f" | cut -d' ' -f1)"
              kv "  identity" "$(known_sha1 "$s")"
            fi ;;
          *) echo "  compressed: identity must be checked on the extracted .gba" ;;
        esac
      done
      echo "-- save files / states in $G (and subfolders) --"
      find "$G" -maxdepth 3 -type f \( -iname '*.srm' -o -iname '*.sav' -o -iname '*.state*' -o -iname '*.ss[0-9]' \) 2>/dev/null | while read -r f; do
        line="$(ls -l --time-style=+%Y-%m-%dT%H:%M "$f" 2>/dev/null | awk '{print $5" "$6}')"
        [ "$HASH" = 1 ] && line="$line sha256=$(sha256sum "$f" | cut -c1-16)…"
        echo "  $f  $line"
      done
    done
  done
  for S in "$CONFIG_DIR/retroarch/saves" "$CONFIG_DIR/retroarch/states" "$CONFIG_DIR/retroarch32/saves" "$CONFIG_DIR/retroarch32/states"; do
    [ -d "$S" ] && { echo "-- $S --"; find "$S" -type f -iname '*emer*' 2>/dev/null | head -50; }
  done

  h "Done"
  echo "Nothing was modified. Send this report back for analysis."
}

if [ -n "$OUT" ]; then report | tee "$OUT"; else report; fi
