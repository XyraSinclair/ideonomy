"""Offline gates for the multi-party constraint solver. Every test defends a
balance guarantee or a sovereignty/impasse semantic."""

from __future__ import annotations

import unittest

from ideonomy import parley as P
from ideonomy import residue as R


def keyword_party(name: str, want: str) -> P.Party:
    """Accepts a proposal iff it contains `want`; proposes its own keyword."""
    def model(prompt: str) -> str:
        if prompt.startswith("You are") and "SAT:" in prompt:
            prop = prompt.split("Proposal:\n", 1)[1]
            sat = 1.0 if want in prop else -1.0
            return f"SAT: {sat}\nWHY: {'has' if sat > 0 else 'lacks'} {want}"
        return f"plan with {want}"
    return P.Party(name=name, model=model, constraints=[f"must include {want}"])


class GateTests(unittest.TestCase):
    def test_one_party_is_a_monologue(self) -> None:
        with self.assertRaises(ValueError):
            P.parley("t", [keyword_party("a", "x")])

    def test_party_without_stakes_is_refused(self) -> None:
        idle = P.Party(name="b", model=lambda p: "", constraints=[])
        with self.assertRaises(ValueError):
            P.parley("t", [keyword_party("a", "x"), idle])


class SovereigntyTests(unittest.TestCase):
    def test_each_constraint_scored_only_by_its_owner(self) -> None:
        asked: dict[str, list[str]] = {"a": [], "b": []}

        def recorder(name: str) -> P.Party:
            def model(prompt: str) -> str:
                if "SAT:" in prompt:
                    c = prompt.split("Constraint: ", 1)[1].splitlines()[0]
                    asked[name].append(c)
                    return "SAT: -1.0\nWHY: no"
                return "proposal"
            return P.Party(name=name, model=model, constraints=[f"{name}-charter"])

        P.parley("t", [recorder("a"), recorder("b")], max_rounds=1)
        self.assertEqual(asked["a"], ["a-charter"])   # never b's charter
        self.assertEqual(asked["b"], ["b-charter"])   # never a's charter


class BalanceTests(unittest.TestCase):
    def test_proposal_rights_rotate(self) -> None:
        parties = [keyword_party("a", "impossible-x"),
                   keyword_party("b", "impossible-y")]
        st = P.parley("t", parties, max_rounds=4)
        proposers = [r.proposer for r in st.rounds]
        self.assertEqual(proposers, ["a", "b", "a", "b"])   # equal rights

    def test_impasse_selects_maximin_not_loudest(self) -> None:
        st = P.Parley(task="t", accept=0.15)
        st.rounds = [
            P.Round(proposer="a", proposal="p1", readings=[
                P.Reading("a", "c1", 0.9, ""), P.Reading("b", "c2", -0.9, "")]),
            P.Round(proposer="b", proposal="p2", readings=[
                P.Reading("a", "c1", 0.1, ""), P.Reading("b", "c2", 0.0, "")]),
        ]
        self.assertEqual(st.best.proposal, "p2")   # worst -0.9 loses to worst 0.0
        self.assertIsNone(st.accord)


class OutcomeTests(unittest.TestCase):
    def test_joint_feasibility_reaches_accord(self) -> None:
        # The proposer sees the charters; a proposer that echoes every declared
        # keyword satisfies both parties.
        def synthesist(prompt: str) -> str:
            if "SAT:" in prompt:
                return "SAT: 1.0\nWHY: fine"
            return "plan with alpha and beta"
        a = P.Party("a", synthesist, ["must include alpha"])
        b = keyword_party("b", "beta")
        st = P.parley("t", [a, b], max_rounds=2)
        self.assertIsNotNone(st.accord)
        self.assertGreaterEqual(st.accord.worst, 0.15)

    def test_impasse_names_binding_constraints_as_residue(self) -> None:
        parties = [keyword_party("a", "impossible-x"),
                   keyword_party("b", "impossible-y")]
        st = P.parley("t", parties, max_rounds=2)
        self.assertIsNone(st.accord)
        led = R.Ledger()
        led.open_session(now="t0")
        ids = st.to_residue(led)
        self.assertTrue(ids)
        texts = [led.residue[i].text for i in ids]
        self.assertTrue(any("impossible" in t for t in texts))


if __name__ == "__main__":
    unittest.main()
