#!/bin/bash
# PORTMASTER: bitlings.zip, Bitlings.sh
# Bitlings: First Spark — PortMaster launcher (LÖVE 11.5 shared runtime, aarch64)

XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}

if [ -d "/opt/system/Tools/PortMaster/" ]; then
  controlfolder="/opt/system/Tools/PortMaster"
elif [ -d "/opt/tools/PortMaster/" ]; then
  controlfolder="/opt/tools/PortMaster"
elif [ -d "$XDG_DATA_HOME/PortMaster/" ]; then
  controlfolder="$XDG_DATA_HOME/PortMaster"
else
  controlfolder="/roms/ports/PortMaster"
fi

source "$controlfolder/control.txt"
[ -f "${controlfolder}/mod_${CFW_NAME}.txt" ] && source "${controlfolder}/mod_${CFW_NAME}.txt"
get_controls

GAMEDIR="/$directory/ports/bitlings"
cd "$GAMEDIR" || exit 1
> "$GAMEDIR/log.txt" && exec > >(tee "$GAMEDIR/log.txt") 2>&1

# Saves live inside the port folder: stable identity, easy to back up from SD.
# LÖVE writes to $XDG_DATA_HOME/love/bitlings_first_spark/bitcore.json
export XDG_DATA_HOME="$GAMEDIR/saves"
mkdir -p "$XDG_DATA_HOME"

export SDL_GAMECONTROLLERCONFIG="$sdl_controllerconfig"
export BITLINGS_FULLSCREEN=1

# Shared LÖVE 11.5 runtime (PortMaster downloads it on install via port.json).
source "$controlfolder/runtimes/love_11.5/love.txt"

# gptokeyb only supplies the hotkey exit; the game reads the gamepad via SDL.
$GPTOKEYB "$LOVE_GPTK" &
pm_platform_helper "$LOVE_BINARY"
$LOVE_RUN "$GAMEDIR/bitlings.love"

pm_finish
