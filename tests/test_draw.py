import unittest

from ideonomy import draw as drw
from ideonomy.divisions import DIVISIONS
from ideonomy.operators import VARIATION_OPERATORS


class TestDraw(unittest.TestCase):
    def test_seeded_draw_is_deterministic(self):
        a = drw.draw(5, seed=42)
        b = drw.draw(5, seed=42)
        self.assertEqual(a, b)

    def test_different_seeds_differ(self):
        self.assertNotEqual(drw.draw(5, seed=1), drw.draw(5, seed=2))

    def test_draws_are_distinct_pairs(self):
        ds = drw.draw(50, seed=0)
        pairs = {(d.division, d.operator) for d in ds}
        self.assertEqual(len(pairs), 50)

    def test_avoid_excludes_pairs(self):
        first = drw.draw(10, seed=3)
        avoid = {(d.division, d.operator) for d in first}
        again = drw.draw(10, seed=3, avoid=avoid)
        self.assertTrue(avoid.isdisjoint(
            {(d.division, d.operator) for d in again}))

    def test_pool_size_and_overdraw(self):
        pool = len(DIVISIONS) * len(VARIATION_OPERATORS)
        self.assertEqual(pool, 236 * 12)
        with self.assertRaises(ValueError):
            drw.draw(pool + 1)

    def test_prompt_renders_subject_and_operator(self):
        d = drw.draw(1, seed=9)[0]
        p = d.prompt("the git commit graph")
        self.assertIn("the git commit graph", p)
        self.assertIn(d.operator, p)


if __name__ == "__main__":
    unittest.main()
