#!/usr/bin/env python3
"""
analyze_cht.py - Static analyzer for RetroArch .cht files used with the
mGBA libretro core (Game Boy Advance).

What it does (no emulator, no ROM needed):
  1. Parses a RetroArch .cht file (cheatN_desc / cheatN_code / cheatN_enable).
  2. Splits each code exactly the way mGBA's libretro core does
     (port of retro_cheat_set() in src/platform/libretro/libretro.c).
  3. Classifies each line the way mGBA's autodetect does
     (8+4 hex digits -> CodeBreaker, 8+8 -> GameShark / Action Replay).
  4. For *unencrypted* CodeBreaker codes, walks mGBA's CodeBreaker state
     machine (port of GBACheatAddCodeBreaker() in src/gba/cheats/codebreaker.c)
     to find:
       - button activators (reads of KEYINPUT 0x04000130, and D0000020 codes)
       - lines that get *swallowed* as parameters of a preceding fill code
       - writes by memory region (EWRAM / IWRAM / IO / ROM)
  5. Cross-checks button activators against RetroArch hotkeys
     (retroarch.cfg + controller autoconfig) to find combos that will ALSO
     fire a RetroArch hotkey (e.g. Select+L = Load State on ArkOS defaults).

Limitations (be honest about them):
  - Encrypted CodeBreaker (after a 9xxxxxxx line) and GameShark/AR codes are
    NOT decrypted; they are reported as "not decoded".
  - This proves how mGBA *parses* a code. It does NOT prove the code does the
    right thing in-game. That needs an in-emulator test on a verified ROM.

Usage:
  python3 analyze_cht.py CHEATFILE.cht [--retroarch-cfg retroarch.cfg]
                         [--autoconfig "GO-Super Gamepad.cfg"] [--json]
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from dataclasses import dataclass, field, asdict
from pathlib import Path

KEYINPUT = 0x04000130

# GBA KEYINPUT bit order (active-low register).
GBA_BUTTONS = ["A", "B", "Select", "Start", "Right", "Left", "Up", "Down", "R", "L"]

# GBA button -> RetroArch retropad bind name (mGBA core default mapping).
GBA_TO_RETROPAD = {
    "A": "a", "B": "b", "Select": "select", "Start": "start",
    "Right": "right", "Left": "left", "Up": "up", "Down": "down",
    "R": "r", "L": "l",
}

# RetroArch hotkey bind keys we care about (cfg key prefix -> human name).
HOTKEYS = {
    "input_load_state": "Load State",
    "input_save_state": "Save State",
    "input_reset": "Reset Game",
    "input_exit_emulator": "Exit Emulator",
    "input_menu_toggle": "Menu Toggle",
    "input_state_slot_increase": "State Slot +",
    "input_state_slot_decrease": "State Slot -",
    "input_screenshot": "Screenshot",
    "input_pause_toggle": "Pause",
    "input_toggle_fast_forward": "Fast-Forward Toggle",
    "input_hold_fast_forward": "Fast-Forward Hold",
    "input_rewind": "Rewind",
    "input_brightness_up": "Brightness + (ArkOS)",
    "input_brightness_down": "Brightness - (ArkOS)",
    "input_cheat_toggle": "Cheat Toggle",
    "input_cheat_index_plus": "Cheat Index +",
    "input_cheat_index_minus": "Cheat Index -",
    "input_close_content": "Close Content",
    "input_disk_eject_toggle": "Disk Eject",
}

# Hotkeys whose accidental trigger can lose or overwrite progress.
DANGEROUS_HOTKEYS = {"Load State", "Save State", "Reset Game", "Exit Emulator", "Close Content"}

CB_TYPE_NAMES = {
    0x0: "GAME_ID/master", 0x1: "HOOK/master", 0x2: "OR16", 0x3: "WRITE8",
    0x4: "FILL(slide)", 0x5: "FILL_LIST", 0x6: "AND16", 0x7: "IF_EQ16",
    0x8: "WRITE16", 0x9: "ENCRYPT_SEED", 0xA: "IF_NE16", 0xB: "IF_GT16",
    0xC: "IF_LT16", 0xD: "IF_SPECIAL", 0xE: "ADD16", 0xF: "IF_AND16",
}
CB_CONDITIONS = {0x7, 0xA, 0xB, 0xC, 0xF}
CB_WRITES = {0x2, 0x3, 0x4, 0x5, 0x6, 0x8, 0xE}


def region(addr: int) -> str:
    a = addr & 0x0FFFFFFF
    if 0x02000000 <= a < 0x03000000:
        return "EWRAM"   # Emerald SaveBlock1/2 + PC storage live here (shifted, see docs)
    if 0x03000000 <= a < 0x04000000:
        return "IWRAM"
    if 0x04000000 <= a < 0x05000000:
        return "IO"
    if 0x08000000 <= a < 0x0E000000:
        return "ROM"
    if 0x0E000000 <= a < 0x10000000:
        return "SRAM/Flash"
    return "OTHER"


# --------------------------------------------------------------------------
# .cht parsing
# --------------------------------------------------------------------------
@dataclass
class Cheat:
    index: int
    desc: str = ""
    code: str = ""
    enable: bool = False


def parse_cht(text: str) -> list[Cheat]:
    cheats: dict[int, Cheat] = {}
    pat = re.compile(r'^\s*cheat(\d+)_(desc|code|enable)\s*=\s*"?(.*?)"?\s*$')
    for line in text.splitlines():
        m = pat.match(line)
        if not m:
            continue
        idx, key, val = int(m.group(1)), m.group(2), m.group(3)
        c = cheats.setdefault(idx, Cheat(idx))
        if key == "desc":
            c.desc = val
        elif key == "code":
            c.code = val
        else:
            c.enable = val.strip().lower() == "true"
    return [cheats[k] for k in sorted(cheats)]


def mgba_libretro_split(code: str) -> list[str]:
    """Faithful port of the GBA branch of retro_cheat_set() in mGBA libretro.c."""
    out = []
    buf = list("XXXXXXXX XXXXXXXX") + ["\0"]
    data = code + "\0"
    pos = 0
    for ch in data:
        buf[pos] = " " if (ch.isspace() or ch == "+") else ch
        if (pos == 13 and buf[pos] in (" ", "\0")) or pos == 17:
            out.append("".join(buf[:pos]))
            pos = 0
            continue
        pos += 1
    return out


# --------------------------------------------------------------------------
# CodeBreaker walk (unencrypted only)
# --------------------------------------------------------------------------
def keys_from_mask(mask: int) -> list[str]:
    return [GBA_BUTTONS[i] for i in range(10) if mask & (1 << i)]


@dataclass
class LineInfo:
    text: str
    fmt: str
    note: str = ""


@dataclass
class CheatReport:
    index: int
    desc: str
    fmt: str = "unknown"
    lines: list[LineInfo] = field(default_factory=list)
    activators: list[list[str]] = field(default_factory=list)
    write_regions: list[str] = field(default_factory=list)
    swallowed_lines: list[str] = field(default_factory=list)
    hotkey_conflicts: list[str] = field(default_factory=list)
    warnings: list[str] = field(default_factory=list)


def analyze_cheat(c: Cheat) -> CheatReport:
    r = CheatReport(c.index, c.desc)
    lines = mgba_libretro_split(c.code)
    fmts = set()
    encrypted = False
    incomplete = None          # None | "fill" | "fill_list"
    remaining = 0
    regions = set()
    for ln in lines:
        parts = ln.split()
        if len(parts) == 2 and len(parts[0]) == 8 and len(parts[1]) == 4:
            fmts.add("CodeBreaker")
            op1, op2 = int(parts[0], 16), int(parts[1], 16)
            if encrypted:
                r.lines.append(LineInfo(ln, "CB", "encrypted - not decoded"))
                continue
            if incomplete == "fill":
                r.lines.append(LineInfo(ln, "CB", "consumed as FILL parameters (count/step), NOT executed"))
                r.swallowed_lines.append(ln)
                incomplete = None
                continue
            if incomplete == "fill_list":
                take = min(3, remaining)
                remaining -= take
                r.lines.append(LineInfo(ln, "CB", f"consumed as FILL_LIST data ({take} halfwords), NOT executed"))
                r.swallowed_lines.append(ln)
                if remaining == 0:
                    incomplete = None
                continue
            t = op1 >> 28
            addr = op1 & 0x0FFFFFFF
            name = CB_TYPE_NAMES[t]
            note = name
            if t == 0x9:
                encrypted = True
                note += " -> following CodeBreaker lines in this SET are decrypted"
            elif t == 0xD:
                if addr == 0x20:
                    keys = keys_from_mask(op2)
                    r.activators.append(keys)
                    note += f" buttons-held {'+'.join(keys)}"
                else:
                    note += " (unsupported by mGBA: code rejected)"
                    r.warnings.append(f"{ln}: IF_SPECIAL subtype not supported by mGBA")
            elif t in CB_CONDITIONS:
                if addr == KEYINPUT & 0x0FFFFFFF:
                    if t == 0x7:
                        keys = keys_from_mask((~op2) & 0x3FF)
                        r.activators.append(keys)
                        note += f" KEYINPUT=={op2:04X} -> exactly {'+'.join(keys) or 'none'} held"
                    else:
                        note += f" KEYINPUT compare {op2:04X}"
                        r.activators.append(["(non-exact KEYINPUT test)"])
                else:
                    note += f" @ {addr:07X} [{region(addr)}]"
            elif t in CB_WRITES:
                regions.add(region(addr))
                note += f" @ {addr:07X} [{region(addr)}] = {op2:04X}"
                if t == 0x4:
                    incomplete = "fill"
                    note += " (next line will be consumed as parameters)"
                elif t == 0x5:
                    incomplete = "fill_list"
                    remaining = op2
                    note += f" (next {op2} halfwords consumed as data)"
            r.lines.append(LineInfo(ln, "CB", note))
        elif len(parts) == 2 and len(parts[0]) == 8 and len(parts[1]) == 8:
            fmts.add("GameShark/ActionReplay")
            r.lines.append(LineInfo(ln, "GSA/AR", "autodetected by mGBA (v1/v3, encrypted or raw) - not decoded"))
        elif ln.strip():
            fmts.add("unknown")
            r.lines.append(LineInfo(ln, "?", "unrecognised line format"))
            r.warnings.append(f"unrecognised line: {ln!r}")
    if incomplete:
        r.warnings.append("cheat ends inside a FILL: mGBA keeps this state in the SHARED set, "
                          "so the FIRST line of the next enabled cheat will be swallowed")
    if encrypted:
        r.warnings.append("contains ENCRYPT_SEED: later CodeBreaker lines from OTHER enabled cheats "
                          "are decrypted too (mGBA libretro uses one shared cheat set)")
    if r.swallowed_lines and r.activators:
        r.warnings.append("a line was swallowed by a FILL code - check that the button gate still "
                          "protects every write (it may run unconditionally)")
    r.fmt = "+".join(sorted(fmts)) or "empty"
    r.write_regions = sorted(regions)
    return r


# --------------------------------------------------------------------------
# Hotkey conflict detection
# --------------------------------------------------------------------------
def parse_cfg(path: Path | None) -> dict[str, str]:
    d: dict[str, str] = {}
    if not path:
        return d
    for line in path.read_text(errors="replace").splitlines():
        m = re.match(r'^\s*([A-Za-z0-9_]+)\s*=\s*"?(.*?)"?\s*$', line)
        if m:
            d[m.group(1)] = m.group(2)
    return d


def hotkey_conflicts(activator: list[str], ra: dict[str, str], pad: dict[str, str]) -> list[str]:
    """Return hotkeys fired by physically holding `activator` (GBA button names)."""
    if not ra or not pad:
        return []
    phys = set()
    for b in activator:
        rp = GBA_TO_RETROPAD.get(b)
        if rp and pad.get(f"input_{rp}_btn", "nul") != "nul":
            phys.add(pad[f"input_{rp}_btn"])
    enable = ra.get("input_enable_hotkey_btn", "nul")
    enable_held = enable == "nul" or enable in phys
    hits = []
    if not enable_held:
        return hits
    for key, name in HOTKEYS.items():
        btn = ra.get(f"{key}_btn", "nul")
        if btn != "nul" and btn in phys and btn != enable:
            tag = "DANGER" if name in DANGEROUS_HOTKEYS else "side-effect"
            hits.append(f"{name} [{tag}]")
    return hits


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("cht", type=Path)
    ap.add_argument("--retroarch-cfg", type=Path)
    ap.add_argument("--autoconfig", type=Path, help="RetroArch controller autoconfig .cfg")
    ap.add_argument("--json", action="store_true")
    ap.add_argument("--only-flagged", action="store_true", help="only show cheats with conflicts or warnings")
    a = ap.parse_args(argv)

    cheats = parse_cht(a.cht.read_text(errors="replace"))
    ra, pad = parse_cfg(a.retroarch_cfg), parse_cfg(a.autoconfig)
    reports = []
    for c in cheats:
        r = analyze_cheat(c)
        for act in r.activators:
            for h in hotkey_conflicts(act, ra, pad):
                msg = f"{'+'.join(act)} -> {h}"
                if msg not in r.hotkey_conflicts:
                    r.hotkey_conflicts.append(msg)
        reports.append(r)

    if a.json:
        print(json.dumps([asdict(r) for r in reports], indent=2))
        return 0

    print(f"# Analysis of `{a.cht.name}`\n")
    print(f"- Cheats: {len(reports)}")
    print(f"- Hotkey config: {a.retroarch_cfg or 'not provided'}; controller: {a.autoconfig or 'not provided'}")
    flagged = [r for r in reports if r.hotkey_conflicts or r.warnings]
    print(f"- Cheats with hotkey conflicts: {sum(1 for r in reports if r.hotkey_conflicts)}")
    print(f"- Cheats with parser warnings: {sum(1 for r in reports if r.warnings)}\n")
    print("| # | Cheat | Format | Activator | Writes | Hotkey conflict | Warnings |")
    print("|---|---|---|---|---|---|---|")
    for r in (flagged if a.only_flagged else reports):
        act = "; ".join("+".join(x) for x in r.activators) or "always on"
        print(f"| {r.index} | {r.desc} | {r.fmt} | {act} | {', '.join(r.write_regions) or '-'} | "
              f"{'<br>'.join(r.hotkey_conflicts) or '-'} | {'<br>'.join(r.warnings) or '-'} |")
    return 0


if __name__ == "__main__":
    sys.exit(main())
