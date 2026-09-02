import unittest

from ideonomy import draw as drw


class TestDraw(unittest.TestCase):
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


if __name__ == "__main__":
    unittest.main()
