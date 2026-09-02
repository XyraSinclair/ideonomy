"""Offline tests for the metabolic loop skeleton."""

from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from ideonomy import loop as L


def sense(state: L.State) -> L.State:
    state.tensions.setdefault("t1", L.Tension(key="t1", description="drift"))
    return state


def act(state: L.State) -> L.State:
    state.tensions["t1"].status = "resolved"
    state.tensions["t1"].resolution = "pinned"
    return state


class LoopTests(unittest.TestCase):
    def test_score_dual_reading_keeps_debt_visible(self) -> None:
        s = L.State(subject="x")
        s.tensions = {
            "a": L.Tension("a", "", status="resolved"),
            "b": L.Tension("b", "", status="deferred"),
            "c": L.Tension("c", "", status="open"),
        }
        sc = s.score()
        self.assertAlmostEqual(sc["strict"], 1 / 3, places=3)
        self.assertAlmostEqual(sc["lenient"], 2 / 3, places=3)
        self.assertEqual(sc["accepted_debt"], 1)
        self.assertEqual(sc["open"], 1)

    def test_save_load_roundtrip(self) -> None:
        s = L.State(subject="x", lessons=["l1"])
        s.tensions["t"] = L.Tension("t", "d", status="refuted", evidence=["e"])
        s.record("SENSE", "note")
        with tempfile.TemporaryDirectory() as d:
            p = Path(d) / "state.json"
            s.save(p)
            s2 = L.State.load(p)
        self.assertEqual(s2.tensions["t"].status, "refuted")
        self.assertEqual(s2.lessons, ["l1"])
        self.assertEqual(len(s2.history), 1)


if __name__ == "__main__":
    unittest.main()
