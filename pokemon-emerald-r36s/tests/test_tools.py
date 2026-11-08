"""Unit tests for the offline tools. Run: python3 -m unittest discover -s tests -v"""
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts" / "validate-cheats"))
sys.path.insert(0, str(ROOT / "scripts" / "inspect-environment"))

import analyze_cht as A  # noqa: E402
import identify_rom as I  # noqa: E402

FIX = ROOT / "tests" / "fixtures"
RA = A.parse_cfg(FIX / "arkos-retroarch.cfg.rg351mp.excerpt")
PAD = A.parse_cfg(FIX / "GO-Super Gamepad.cfg")
BATTLE_MEW = "449E9E7D+3CD9+74000130+01FB+83000E48+7DFE+74000130+01FB+83000E4A+0826"


class Splitter(unittest.TestCase):
    def test_codebreaker_lines(self):
        self.assertEqual(A.mgba_libretro_split("83000E48+7DFE+74000130+01FB"),
                         ["83000E48 7DFE", "74000130 01FB"])

    def test_gameshark_lines(self):
        self.assertEqual(A.mgba_libretro_split("D8BAE4D9+4864DCE5"), ["D8BAE4D9 4864DCE5"])

    def test_double_plus_misaligns(self):
        # Upstream "Have Surf Ability" contains '++'; mGBA shifts every following line.
        out = A.mgba_libretro_split("D0000020+0004++83000E48+1ED2")
        self.assertEqual(out[0], "D0000020 0004")
        self.assertNotIn("83000E48 1ED2", out)  # the real write line is never produced


class CodeBreaker(unittest.TestCase):
    def test_battle_mew_decode(self):
        r = A.analyze_cheat(A.Cheat(37, "Battle Mew [L+Sel]", BATTLE_MEW))
        self.assertEqual(r.fmt, "CodeBreaker")
        self.assertIn(["Select", "L"], r.activators)
        self.assertEqual(r.swallowed_lines, ["74000130 01FB"])  # first gate eaten by FILL

    def test_battle_mew_conflicts_with_load_state(self):
        hits = A.hotkey_conflicts(["Select", "L"], RA, PAD)
        self.assertTrue(any(h.startswith("Load State") for h in hits))

    def test_select_r_is_save_state(self):
        hits = A.hotkey_conflicts(["Select", "R"], RA, PAD)
        self.assertTrue(any(h.startswith("Save State") for h in hits))

    def test_no_select_no_hotkey(self):
        self.assertEqual(A.hotkey_conflicts(["L", "R", "Down"], RA, PAD), [])

    def test_unbound_load_state_removes_conflict(self):
        ra = dict(RA, input_load_state_btn="nul")
        hits = A.hotkey_conflicts(["Select", "L"], ra, PAD)
        self.assertFalse(any(h.startswith("Load State") for h in hits))

    def test_keyinput_mask(self):
        # 0x03BB = Select + Up held (upstream mislabels this Flash cheat as L+Sel)
        self.assertEqual(A.keys_from_mask(~0x03BB & 0x3FF), ["Select", "Up"])


class RomId(unittest.TestCase):
    def test_header_parse_and_unknown_hash(self):
        rom = bytearray(0x200)
        rom[0xA0:0xAC] = b"POKEMON EMER"
        rom[0xAC:0xB0] = b"BPEE"
        rom[0xB0:0xB2] = b"01"
        rom[0xB2] = 0x96
        rom[0xBD] = (-sum(rom[0xA0:0xBD]) - 0x19) & 0xFF
        r = I.identify(bytes(rom))
        self.assertEqual(r["header"]["game_code"], "BPEE")
        self.assertTrue(r["header"]["header_checksum_ok"])
        self.assertIsNone(r["match"])
        self.assertIn("UNVERIFIED", r["verdict"])


if __name__ == "__main__":
    unittest.main()
