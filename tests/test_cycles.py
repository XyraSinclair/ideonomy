"""Offline tests for the respiratory engine. No models, no network."""

from __future__ import annotations

import unittest

from ideonomy import cycles


def structured_corpus() -> cycles.State:
    cores = {
        "neural network training": ["convergence", "regularization", "checkpoint", "scheduler"],
        "database query index": ["btree", "planner", "vacuum", "lookup"],
        "http request caching": ["header", "policy", "routing", "revalidation"],
    }
    return cycles.seed([f"{c} {t}" for c, tails in cores.items() for t in tails])


class MdlTests(unittest.TestCase):
    def test_structure_beats_raw_on_structured_corpus(self) -> None:
        s = structured_corpus()
        comp = cycles.compress_mechanical(s)
        self.assertEqual(len(comp.groups), 3)            # finds the 3 clusters
        self.assertLess(cycles.codelen(s, comp), cycles.raw_bits(s))  # ratio > 1

    def test_singletons_are_not_structure(self) -> None:
        s = cycles.seed(["alpha beta", "gamma delta", "epsilon zeta"])
        comp = cycles.compress_mechanical(s)
        # token-disjoint items -> all singletons, empty rules, no model cost.
        self.assertTrue(all(not r for r in comp.rule.values()))
        self.assertEqual(comp.model_bits(), 0.0)
        # codelen equals raw: nothing claimed, nothing saved.
        self.assertAlmostEqual(cycles.codelen(s, comp), cycles.raw_bits(s))

    def test_data_bits_rewards_match(self) -> None:
        rule = {"a", "b", "c"}
        close = cycles.Item("x", "a b c d")
        far = cycles.Item("y", "a x y z w")
        self.assertLess(cycles.data_bits(close, rule), cycles.data_bits(far, rule))


class RatchetTests(unittest.TestCase):
    def test_frontier_expansion_is_accepted_and_ratio_climbs(self) -> None:
        s = structured_corpus()
        s.compression = cycles.compress_mechanical(s)

        def frontier(state: cycles.State, comp, k: int) -> list:
            out = []
            extras = ["adam", "dropout", "sharding", "cdn", "etag", "warmup"]
            i = state.cycle
            for rule in (comp.rule.values() if comp else []):
                if rule:
                    out.append(f"{' '.join(sorted(rule))} {extras[i % len(extras)]}")
                    i += 1
            return out[:k]

        r1 = cycles.breath(s, expand=frontier)
        r2 = cycles.breath(s, expand=frontier)
        self.assertEqual(r1["expansion"], "accepted")
        self.assertGreaterEqual(r2["ratio"], r1["ratio"])   # compression deepens
        self.assertGreater(r2["items"], r1["items"])         # corpus grew

    def test_noise_expansion_is_reverted(self) -> None:
        s = structured_corpus()
        s.compression = cycles.compress_mechanical(s)
        before = len(s.corpus)

        def noise(state: cycles.State, comp, k: int) -> list:
            return ["zzz qqq", "wxy vut", "lmn opq"]   # token-disjoint junk

        rec = cycles.breath(s, expand=noise)
        self.assertEqual(rec["expansion"], "reverted")
        self.assertEqual(len(s.corpus), before)        # rolled back

    def test_residue_extracted_and_run_terminates(self) -> None:
        s = structured_corpus()
        s.compression = cycles.compress_mechanical(s)
        s.residue = cycles.residue_extract(s, s.compression)
        self.assertTrue(s.residue)                      # something resists
        out = cycles.run(s, cycles=8)                   # must terminate (plateau)
        self.assertLessEqual(len(out.history), 8)
        for rec in out.history:
            self.assertIn(rec["expansion"], ("accepted", "reverted"))


if __name__ == "__main__":
    unittest.main()
