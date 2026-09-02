"""Offline gates for ideonomic trials. Every test defends a thesis-level
claim: a fooling mode, a balance guarantee, or a burden semantic."""

from __future__ import annotations

import unittest

from ideonomy import residue as R
from ideonomy import trial as T


def says(reply: str):
    return lambda prompt: reply


class RoleGateTests(unittest.TestCase):
    def test_same_callable_cannot_prosecute_and_defend(self) -> None:
        m = says("case")
        with self.assertRaises(ValueError):
            T.trial("c", m, m, [says("LEAN: 0.5\nGROUNDS: x")])

    def test_bench_must_be_independent_of_the_parties(self) -> None:
        a, b = says("for"), says("against")
        with self.assertRaises(ValueError):
            T.trial("c", a, b, [a])           # advocate on the bench


class BalanceTests(unittest.TestCase):
    def test_sides_get_equal_turns(self) -> None:
        t = T.trial("c", says("for"), says("against"),
                    [says("LEAN: 0.5\nGROUNDS: g")], rounds=2)
        roles = [x.role for x in t.turns]
        self.assertEqual(roles.count("advocate"), roles.count("adversary"))

    def test_swap_instability_is_contested_not_a_coin_flip(self) -> None:
        # A judge that always sides with whoever spoke of "sunlight": with the
        # sun-model as advocate the claim is upheld; swapped, rejected. The
        # balanced verdict must be CONTESTED, naming model bias as the ground.
        def biased_judge(prompt: str) -> str:
            first = prompt.index("[advocate]")
            lean = 0.8 if "sunlight" in prompt[first:prompt.index("[adversary]")] else -0.8
            return f"LEAN: {lean}\nGROUNDS: whoever said sunlight"
        sun, moon = says("sunlight sunlight"), says("moonlight")
        t = T.balanced_trial("c", sun, moon, [biased_judge])
        self.assertEqual(t.verdict, "CONTESTED")
        self.assertIn("role swap", t.forced_contested)

    def test_swap_stable_verdict_stands(self) -> None:
        j = says("LEAN: 0.9\nGROUNDS: the case held both ways")
        t = T.balanced_trial("c", says("x"), says("y"), [j])
        self.assertEqual(t.verdict, "UPHELD")


class BurdenTests(unittest.TestCase):
    def test_unproven_claim_is_rejected_not_averaged(self) -> None:
        j = says("LEAN: 0.4\nGROUNDS: plausible but thin")
        low = T.trial("c", says("x"), says("y"), [j], burden="preponderance")
        high = T.trial("c", says("x"), says("y"), [j], burden="high")
        self.assertEqual(low.verdict, "UPHELD")
        self.assertEqual(high.verdict, "REJECTED")   # burden unmet -> fails

    def test_bench_sign_split_is_contested(self) -> None:
        t = T.trial("c", says("x"), says("y"),
                    [says("LEAN: 0.8\nGROUNDS: a"), says("LEAN: -0.8\nGROUNDS: b")])
        self.assertEqual(t.verdict, "CONTESTED")


class FoolingModeTests(unittest.TestCase):
    def test_instruction_echoing_judge_is_read_by_its_ruling(self) -> None:
        # The judge prompt itself contains "LEAN:"; an echoing judge's echo
        # must not be read as the ruling — the LAST lean line wins.
        def echoer(prompt: str) -> str:
            return prompt + "\nLEAN: -0.9\nGROUNDS: the adversary's counterexample"
        t = T.trial("c", says("x"), says("y"), [echoer])
        self.assertEqual(t.verdict, "REJECTED")
        self.assertAlmostEqual(t.leans[0], -0.9)

    def test_contested_trial_becomes_ledger_residue(self) -> None:
        t = T.trial("c", says("x"), says("y"),
                    [says("LEAN: 0.8\nGROUNDS: a"), says("LEAN: -0.8\nGROUNDS: b")])
        led = R.Ledger()
        led.open_session(now="t0")
        ids = t.to_residue(led)
        self.assertEqual(len(ids), 1)
        self.assertEqual(led.residue[ids[0]].kind, "contested_axis")


if __name__ == "__main__":
    unittest.main()
