#!/usr/bin/env python3
"""Unit tests for the byte-stream decoder used by the macOS native TTY probe."""
from __future__ import annotations

import sys
import unittest
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO_ROOT))

from scripts.run_macos_terminal_focus_probe import FocusSequenceDecoder


class FocusSequenceDecoderTests(unittest.TestCase):
    def test_decodes_sequences_split_across_reads(self) -> None:
        decoder = FocusSequenceDecoder()
        self.assertEqual([], decoder.feed(b"prefix\x1b["))
        self.assertEqual(["focus_lost"], decoder.feed(b"Omiddle\x1b"))
        self.assertEqual(["focus_gained"], decoder.feed(b"[I"))

    def test_decodes_multiple_events_in_wire_order(self) -> None:
        decoder = FocusSequenceDecoder()
        self.assertEqual(
            ["focus_gained", "focus_lost", "focus_lost", "focus_gained"],
            decoder.feed(b"a\x1b[I\x1b[O\x1b[O\x1b[I"),
        )

    def test_ignores_near_matches_and_bounds_pending_bytes(self) -> None:
        decoder = FocusSequenceDecoder()
        self.assertEqual([], decoder.feed(b"x" * 1000 + b"\x1b[X"))
        self.assertLessEqual(len(decoder.pending), 2)
        self.assertEqual(["focus_lost"], decoder.feed(b"\x1b[O"))


if __name__ == "__main__":
    unittest.main()
