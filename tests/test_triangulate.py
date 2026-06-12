"""Offline tests for executable triangulation (P-9). Judges are injected
deterministic mocks — no models, no network."""

from __future__ import annotations

import unittest

from ideonomy import triangulate as T
from ideonomy import residue as R


def fixed(name: str, leans: dict) -> T.Judge:
    """A mock judge returning a preset lean per axis."""
    def j(axis: str, question: str) -> T.Verdict:
        return T.Verdict(judge=name, axis=axis, lean=leans.get(axis, 0.0),
                         stance=f"{name} on {axis}")
    return j


class TriangulateTests(unittest.TestCase):
    def test_agreement_is_settled_disagreement_is_contested(self) -> None:
        j1 = fixed("a", {"austerity": 0.8, "exactness": 0.7})
        j2 = fixed("b", {"austerity": 0.7, "exactness": -0.6})   # split on exactness
        tri = T.triangulate("is the copy right?", ["austerity", "exactness"], [j1, j2])
        settled = {a.axis for a in tri.settled()}
        contested = {a.axis for a in tri.contested()}
        self.assertEqual(settled, {"austerity"})
        self.assertEqual(contested, {"exactness"})

    def test_gate_requires_two_independent_judges(self) -> None:
        j1 = fixed("a", {"x": 0.5})
        with self.assertRaises(ValueError):
            T.triangulate("q", ["x"], [j1])             # one judge is not triangulation

    def test_gate_requires_axes(self) -> None:
        j1, j2 = fixed("a", {}), fixed("b", {})
        with self.assertRaises(ValueError):
            T.triangulate("q", [], [j1, j2])            # no dimensionalization

    def test_contested_axes_become_residue_p9_to_p10(self) -> None:
        j1 = fixed("a", {"reversibility": 0.9, "blast_radius": -0.8})
        j2 = fixed("b", {"reversibility": 0.85, "blast_radius": 0.7})  # split on blast
        tri = T.triangulate("ship it?", ["reversibility", "blast_radius"], [j1, j2])
        led = R.Ledger()
        led.open_session(now="t0")
        ids = tri.to_residue(led)
        self.assertEqual(len(ids), 1)                   # only the contested axis
        item = led.residue[ids[0]]
        self.assertEqual(item.kind, "contested_axis")
        self.assertIn("blast_radius", item.text)

    def test_report_names_irreducible_and_never_a_single_scalar(self) -> None:
        j1 = fixed("a", {"taste": 0.2})
        j2 = fixed("b", {"taste": -0.9})
        rep = T.triangulate("good?", ["taste"], [j1, j2]).report()
        self.assertIn("CONTESTED", rep)
        self.assertIn("owner=", rep)                    # names who must decide
        # the report is per-axis with spreads, not one collapsed number.
        self.assertIn("spread=", rep)

    def test_parse_lean(self) -> None:
        self.assertAlmostEqual(T._parse_lean("LEAN: 0.7\nWHY: x"), 0.7)
        self.assertAlmostEqual(T._parse_lean("LEAN: 2.0"), 1.0)      # clamped
        self.assertAlmostEqual(T._parse_lean("no number here"), 0.0)


if __name__ == "__main__":
    unittest.main()
