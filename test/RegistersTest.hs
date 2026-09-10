-- | Offline gates for the register catalog: denominator integrity, the
-- mixing semantics, and forced-variation behavior.
module RegistersTest (tests) where

import qualified Data.Set as Set
import Harness
import Ideonomy.Registers
import Ideonomy.Rng (mkRng)

tests :: [Test]
tests =
  [ test "every_register_belongs_to_a_declared_family" $ do
      r1 <- assert "every register's family is declared"
              (all (\(_, r) -> r.family `elem` families) registers)
      -- every declared family is inhabited — no vacuous denominator rows
      r2 <- assertEq "families inhabited" (Set.fromList families)
              (Set.fromList [r.family | (_, r) <- registers])
      pure (firstJust [r1, r2])
  , test "mix_embodies_both_stances_and_order_matters" $ do
      p <- unwrap (mixPrompt "mischief" "numinous" "the launch post")
      mischief <- unwrap (lookupRegister "mischief")
      r1 <- assertIn "dominant stance present" mischief.stance p
      q <- unwrap (mixPrompt "numinous" "mischief" "the launch post")
      r2 <- assert "dominant/trace is ordered" (p /= q)
      r3 <- assertIn "names the dominant" "Dominant" p
      pure (firstJust [r1, r2, r3])
  , test "draw_mix_forces_distinct_pairs_and_honors_avoid" $ do
      first <- unwrap (drawMix 10 (mkRng 3) [])
      r1 <- assertEq "distinct pairs" 10 (Set.size (Set.fromList first))
      again <- unwrap (drawMix 10 (mkRng 3) first)
      r2 <- assert "avoid is disjoint from the redraw"
              (Set.null (Set.fromList first `Set.intersection` Set.fromList again))
      pure (firstJust [r1, r2])
  ]
  where
    unwrap = either (ioError . userError) pure
