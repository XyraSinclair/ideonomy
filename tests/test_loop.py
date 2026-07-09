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
    def test_cycle_runs_stages_in_order_and_records_history(self) -> None:
        s = L.cycle(L.State(subject="x"), [("SENSE", sense), ("ACT", act)])
        self.assertEqual([h["phase"] for h in s.history], ["SENSE", "ACT"])
        self.assertEqual(s.score()["strict"], 1.0)

    def test_run_until_stops_on_done_within_budget(self) -> None:
        calls: list[int] = []

        def stage(state: L.State) -> L.State:
            calls.append(1)
            return act(sense(state))

        L.run_until(L.State(subject="x"), [("SENSE", stage)],
                    done=lambda st: st.score()["strict"] >= 1.0, max_cycles=10)
        self.assertEqual(len(calls), 1)          # done after one cycle, not ten

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

    def test_cycle_persists_ledger_into_fresh_directory(self) -> None:
        with tempfile.TemporaryDirectory() as d:
            p = Path(d) / "runs" / "state.json"
            L.cycle(L.State(subject="x"), [("SENSE", sense)], ledger_path=p)
            self.assertTrue(p.exists())


if __name__ == "__main__":
    unittest.main()
