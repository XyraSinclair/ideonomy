module DrawTest (tests) where

import qualified Data.Set as Set
import Harness
import Ideonomy.Draw
import Ideonomy.Rng (mkRng)

tests :: [Test]
tests =
  [ test "draws_are_distinct_pairs" $ do
      ds <- unwrap (draw 50 (mkRng 0) [])
      assertEq "distinct pairs" 50 (Set.size (Set.fromList (pairs ds)))
  , test "avoid_excludes_pairs" $ do
      first <- unwrap (draw 10 (mkRng 3) [])
      let avoid = pairs first
      again <- unwrap (draw 10 (mkRng 3) avoid)
      assert "avoid is disjoint from the redraw"
        (Set.null (Set.fromList avoid `Set.intersection` Set.fromList (pairs again)))
  ]
  where
    pairs ds = [(d.division, d.operator) | d <- ds]
    unwrap = either (ioError . userError) pure
