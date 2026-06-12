"""Offline tests for the cross-session residue ledger (P-10)."""

from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from ideonomy import residue as R


class LedgerTests(unittest.TestCase):
    def test_session_lifecycle_and_persistence(self) -> None:
        led = R.Ledger(topic="t")
        sess, carried = led.open_session(now="t0")
        self.assertEqual(carried, [])              # clean start
        led.add("why is drain slow", "anomaly", origin="P-5")
        led.add("source X uncovered", "named_gap", origin="P-11")
        led.close_session(now="t1")

        with tempfile.TemporaryDirectory() as d:
            p = Path(d) / "l.json"
            led.save(p)
            led2 = R.Ledger.load(p)
        self.assertEqual(len(led2.residue), 2)
        self.assertEqual(led2.sessions[0].breath, "churn")  # added but engaged no prior

    def test_metabolism_vs_churn(self) -> None:
        led = R.Ledger()
        # session 1: produce residue
        led.open_session(now="t0")
        r = led.add("contested register", "contested_axis")
        led.close_session(now="t1")
        self.assertEqual(led.sessions[-1].breath, "churn")
        # session 2: open (cites prior) and resolve it -> metabolism
        _, carried = led.open_session(now="t2")
        self.assertEqual([c.id for c in carried], [r.id])   # prior surfaced
        led.seed(r.id)
        led.resolve(r.id, note="decided by human")
        led.close_session(now="t3")
        self.assertEqual(led.sessions[-1].breath, "metabolism")

    def test_open_session_gate_requires_close(self) -> None:
        led = R.Ledger()
        led.open_session(now="t0")
        with self.assertRaises(RuntimeError):
            led.open_session(now="t1")              # cannot open twice

    def test_add_requires_open_and_valid_kind(self) -> None:
        led = R.Ledger()
        with self.assertRaises(RuntimeError):
            led.add("x", "anomaly")                 # no open session
        led.open_session(now="t0")
        with self.assertRaises(KeyError):
            led.add("x", "not_a_kind")

    def test_dual_score(self) -> None:
        led = R.Ledger()
        led.open_session(now="t0")
        a = led.add("a", "anomaly")
        b = led.add("b", "named_gap")
        led.add("c", "open_question")
        led.resolve(a.id)
        led.resolve(b.id, drop=True)                # dropped counts as adjudicated
        sc = led.score()
        self.assertAlmostEqual(sc["strict"], 2 / 3, places=3)
        self.assertEqual(sc["open_residue"], 1)

    def test_cli_smoke(self) -> None:
        with tempfile.TemporaryDirectory() as d:
            store = str(Path(d) / "l.json")
            self.assertEqual(R.main(["--store", store, "open"]), 0)
            self.assertEqual(R.main(["--store", store, "add", "q", "--kind", "open_question"]), 0)
            self.assertEqual(R.main(["--store", store, "status"]), 0)
            self.assertEqual(R.main(["--store", store, "close"]), 0)
            led = R.Ledger.load(Path(store))
            self.assertEqual(len(led.residue), 1)
            self.assertEqual(led.sessions[-1].breath, "churn")


if __name__ == "__main__":
    unittest.main()
