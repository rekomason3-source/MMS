#!/usr/bin/env python3
"""
identify_rom.py - Identify a Pokemon Emerald ROM (read-only).

Prints the cartridge header (title, game code, version), checks the header
complement checksum, hashes the file, and compares it against the No-Intro
reference hashes for every retail Emerald release.

Works on a PC or on the handheld (if python3 is available). Accepts .gba or
.zip (first .gba inside the zip is read in memory, nothing is extracted).

Usage:  python3 identify_rom.py "Pokemon - Emerald Version (USA, Europe).gba" [--json]
"""
from __future__ import annotations

import argparse
import hashlib
import json
import sys
import zipfile
import zlib
from pathlib import Path

# Source: libretro-database metadat/no-intro/Nintendo - Game Boy Advance.dat
# (commit c4e17d41ec1bb744fb064f7cefeb61b878fc5d64, fetched 2026-11-08).
KNOWN = {
    "f3ae088181bf583e55daf962a92bb46f4f1d07b7": ("Pokemon - Emerald Version (USA, Europe)", "BPEE", "1f1c08fb"),
    "d7cf8f156ba9c455d164e1ea780a6bf1945465c2": ("Pocket Monsters - Emerald (Japan)", "BPEJ", "4881f3f8"),
    "61c2eb2b380b1a75f0c94b767a2d4c26cd7ce4e3": ("Pokemon - Smaragd-Edition (Germany)", "BPED", "34c9df89"),
    "ca666651374d89ca439007bed54d839eb7bd14d0": ("Pokemon - Version Emeraude (France)", "BPEF", "a3fdccb1"),
    "1692db322400c3141c5de2db38469913ceb1f4d4": ("Pokemon - Versione Smeraldo (Italy)", "BPEI", "a0aec80a"),
    "fe1558a3dcb0360ab558969e09b690888b846dd9": ("Pokemon - Edicion Esmeralda (Spain)", "BPES", "8c4d3108"),
}
CHEAT_FILE_TARGET = "BPEE"  # libretro "Pokemon - Emerald Version (USA, Europe) (Code Breaker).cht"


def load(path: Path) -> tuple[bytes, str]:
    if path.suffix.lower() == ".zip":
        with zipfile.ZipFile(path) as z:
            names = [n for n in z.namelist() if n.lower().endswith(".gba")]
            if not names:
                raise SystemExit("zip contains no .gba file")
            return z.read(names[0]), f"{path.name}:{names[0]}"
    return path.read_bytes(), path.name


def header(data: bytes) -> dict:
    h = data[0xA0:0xC0]
    if len(h) < 0x20:
        return {"error": "file too small to contain a GBA header"}
    chk = (-sum(h[0x00:0x1D]) - 0x19) & 0xFF   # bytes 0xA0..0xBC
    return {
        "title": h[0x00:0x0C].decode("ascii", "replace").rstrip("\0"),
        "game_code": h[0x0C:0x10].decode("ascii", "replace"),
        "maker_code": h[0x10:0x12].decode("ascii", "replace"),
        "version": h[0x1C],
        "header_checksum": f"{h[0x1D]:02x}",
        "header_checksum_ok": chk == h[0x1D],
    }


def identify(data: bytes) -> dict:
    sha1 = hashlib.sha1(data).hexdigest()
    out = {
        "size": len(data),
        "crc32": f"{zlib.crc32(data) & 0xFFFFFFFF:08x}",
        "md5": hashlib.md5(data).hexdigest(),
        "sha1": sha1,
        "header": header(data),
    }
    if sha1 in KNOWN:
        name, code, _ = KNOWN[sha1]
        out["match"] = name
        out["verdict"] = ("VERIFIED clean retail dump; libretro Emerald cheat file targets this ROM"
                          if code == CHEAT_FILE_TARGET else
                          f"VERIFIED clean retail dump ({code}); libretro cheat file targets BPEE - addresses may differ")
    else:
        gc = out["header"].get("game_code", "")
        out["match"] = None
        out["verdict"] = ("UNVERIFIED: header says Emerald (%s) but hash is not a clean retail dump "
                          "(ROM hack, patched, trimmed, or bad dump) - cheats may not work" % gc
                          if gc.startswith("BPE") else
                          "NOT Pokemon Emerald (game code %r)" % gc)
    return out


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("rom", type=Path)
    ap.add_argument("--json", action="store_true")
    a = ap.parse_args(argv)
    data, label = load(a.rom)
    r = identify(data)
    r["file"] = label
    if a.json:
        print(json.dumps(r, indent=2))
    else:
        for k in ("file", "size", "crc32", "md5", "sha1"):
            print(f"{k:>16}: {r[k]}")
        for k, v in r["header"].items():
            print(f"{k:>16}: {v}")
        print(f"{'match':>16}: {r['match']}")
        print(f"{'verdict':>16}: {r['verdict']}")
    return 0 if r["match"] else 1


if __name__ == "__main__":
    sys.exit(main())
