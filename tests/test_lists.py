"""Offline gates for the applicative list structure. Each test defends a
claim of the algebra: provenance, residue-as-fuel, cheap-tier honesty,
persistence, self-application."""

from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from ideonomy import lists as L


def il(name: str, items: list, of: str = "a thing") -> L.Ideolist:
    return L.Ideolist(name=name, of=of, items=items)


class AlgebraTests(unittest.TestCase):
    def test_combine_propagates_type_and_lineage(self) -> None:
        c = il("regs", ["grief"], of="a register").combine(
            il("lens", ["ANOMALIES"], of="a division"),
            template="Read {b} in the register of {a}.")
        self.assertEqual(c.items, ["Read ANOMALIES in the register of grief."])
        self.assertEqual(c.parents, ["regs", "lens"])
        self.assertIn("a register", c.of)          # the product type is carried
        self.assertIn("a division", c.of)

    def test_gate_residue_is_fuel_not_discard(self) -> None:
        kept, residue = il("x", ["aa", "b", "cc"]).gate(lambda s: len(s) == 2)
        self.assertEqual(kept.items, ["aa", "cc"])
        self.assertEqual(residue.items, ["b"])     # a real list with lineage,
        self.assertEqual(residue.parents, ["x"])   # ready to seed the next cycle

    def test_grow_dedupes_caps_and_reopens_closure(self) -> None:
        # A cheap model that repeats existing items and over-delivers must not
        # pad the list; and growth reopens any claimed denominator.
        closed = L.Ideolist(name="x", of="t", items=["one", "two"], status="closed")
        model = lambda p: "one\nTWO\nthree\nfour\nfive"  # noqa: E731
        g = closed.grow(model, k=2)
        self.assertEqual(g.items, ["one", "two", "three", "four"])
        self.assertEqual(g.status, "open")         # closure is a coverage claim

    def test_store_roundtrip_and_name_safety(self) -> None:
        with tempfile.TemporaryDirectory() as d:
            st = L.Store(Path(d) / "l")
            st.save(il("a/b", ["x"]))
            back = st.load("a/b")
            self.assertEqual(back.items, ["x"])
            self.assertEqual(st.names(), ["a/b"])
            with self.assertRaises(ValueError):
                st.save(il("../escape", ["x"]))

    def test_operations_list_applies_to_itself(self) -> None:
        # The structure is self-applying: the algebra's own operations are an
        # Ideolist and participate in the algebra.
        squared = L.OPERATIONS.combine(L.OPERATIONS,
                                       template="Can {a} be composed with {b}?")
        n = len(L.OPERATIONS.items)
        self.assertEqual(len(squared.items), n * n)
        self.assertEqual(squared.parents, ["list-operations", "list-operations"])


if __name__ == "__main__":
    unittest.main()
