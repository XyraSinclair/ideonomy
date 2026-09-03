"""Offline gates for the register catalog: denominator integrity, the
mixing semantics, and forced-variation behavior."""

from __future__ import annotations

import unittest

from ideonomy import registers as G


class CatalogTests(unittest.TestCase):
    def test_every_register_belongs_to_a_declared_family(self) -> None:
        for k, r in G.REGISTERS.items():
            self.assertIn(r.family, G.FAMILIES, k)
        # every declared family is inhabited — no vacuous denominator rows
        used = {r.family for r in G.REGISTERS.values()}
        self.assertEqual(used, set(G.FAMILIES))


class MixTests(unittest.TestCase):
    def test_mix_embodies_both_stances_and_order_matters(self) -> None:
        p = G.mix_prompt("mischief", "numinous", "the launch post")
        self.assertIn(G.REGISTERS["mischief"].stance, p)
        q = G.mix_prompt("numinous", "mischief", "the launch post")
        self.assertNotEqual(p, q)                  # dominant/trace is ordered
        self.assertIn("Dominant", p)

    def test_draw_mix_forces_distinct_pairs_and_honors_avoid(self) -> None:
        first = G.draw_mix(10, seed=3)
        self.assertEqual(len(set(first)), 10)
        again = G.draw_mix(10, seed=3, avoid=first)
        self.assertTrue(set(first).isdisjoint(again))


if __name__ == "__main__":
    unittest.main()
