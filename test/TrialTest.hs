-- | Offline gates for ideonomic trials. Every test defends a thesis-level
-- claim: a fooling mode, a balance guarantee, or a burden semantic.
module TrialTest (tests) where

import Data.List (findIndex, isInfixOf, isPrefixOf, tails)
import Harness
import Ideonomy.Trial

says :: String -> String -> Role
says nm reply = Role { name = nm, model = \_ -> pure reply }

judge :: String -> Role
judge = says "j"

tests :: [Test]
tests =
  [ -- role gates
    test "same role cannot prosecute and defend" $ do
      let m = says "m" "case"
      r <- trial "c" m m [judge "LEAN: 0.5\nGROUNDS: x"] 1 Preponderance ""
      assertLeft "same role both sides" r
  , test "bench must be independent of the parties" $ do
      let a = says "a" "for"
          b = says "b" "against"
      r <- trial "c" a b [a] 1 Preponderance ""           -- advocate on the bench
      assertLeft "advocate on the bench" r
    -- balance
  , test "sides get equal turns" $ do
      r <- trial "c" (says "a" "for") (says "b" "against") [judge "LEAN: 0.5\nGROUNDS: g"] 2 Preponderance ""
      case r of
        Left e -> pure (Just e)
        Right t -> assertEq "equal turns" (count Advocate t.turns) (count Adversary t.turns)
  , test "swap instability is contested, not a coin flip" $ do
      -- A judge that always sides with whoever spoke of "sunlight": with the
      -- sun-model as advocate the claim is upheld; swapped, rejected. The
      -- balanced verdict must be CONTESTED, naming model bias as the ground.
      let biased = Role { name = "biased", model = \prompt ->
            let opening = between "[advocate]" "[adversary]" prompt
             in pure $ if "sunlight" `isInfixOf` opening
                  then "LEAN: 0.8\nGROUNDS: whoever said sunlight"
                  else "LEAN: -0.8\nGROUNDS: whoever said sunlight" }
          sun = says "sun" "sunlight sunlight"
          moon = says "moon" "moonlight"
      r <- balancedTrial "c" sun moon [biased] 1 Preponderance ""
      case r of
        Left e -> pure (Just e)
        Right t -> do
          r1 <- assertEq "verdict" Contested (verdict t)
          r2 <- assertIn "ground" "role swap" (maybe "" id t.forcedContested)
          pure (firstJust [r1, r2])
  , test "swap-stable verdict stands" $ do
      r <- balancedTrial "c" (says "x" "x") (says "y" "y") [judge "LEAN: 0.9\nGROUNDS: the case held both ways"] 1 Preponderance ""
      either (pure . Just) (assertEq "verdict" Upheld . verdict) r
    -- burden
  , test "unproven claim is rejected, not averaged" $ do
      let j = judge "LEAN: 0.4\nGROUNDS: plausible but thin"
      low <- trial "c" (says "x" "x") (says "y" "y") [j] 1 Preponderance ""
      high <- trial "c" (says "x" "x") (says "y" "y") [j] 1 High ""
      r1 <- assertEq "preponderance" (Right Upheld) (verdict <$> low)
      r2 <- assertEq "high burden unmet -> fails" (Right Rejected) (verdict <$> high)
      pure (firstJust [r1, r2])
  , test "bench sign split is contested" $ do
      r <- trial "c" (says "x" "x") (says "y" "y")
             [says "j1" "LEAN: 0.8\nGROUNDS: a", says "j2" "LEAN: -0.8\nGROUNDS: b"] 1 Preponderance ""
      either (pure . Just) (assertEq "verdict" Contested . verdict) r
    -- fooling modes
  , test "instruction-echoing judge is read by its ruling" $ do
      -- The judge prompt itself contains "LEAN:"; an echoing judge's echo
      -- must not be read as the ruling — the LAST lean line wins.
      let echoer = Role { name = "echo", model = \prompt -> pure (prompt ++ "\nLEAN: -0.9\nGROUNDS: the adversary's counterexample") }
      r <- trial "c" (says "x" "x") (says "y" "y") [echoer] 1 Preponderance ""
      case r of
        Left e -> pure (Just e)
        Right t -> do
          r1 <- assertEq "verdict" Rejected (verdict t)
          r2 <- assert "lean read from the ruling" (case t.leans of [l] -> abs (l + 0.9) < 1e-7; _ -> False)
          pure (firstJust [r1, r2])
  , test "contested trial becomes ledger residue" $ do
      r <- trial "c" (says "x" "x") (says "y" "y")
             [says "j1" "LEAN: 0.8\nGROUNDS: a", says "j2" "LEAN: -0.8\nGROUNDS: b"] 1 Preponderance ""
      case r of
        Left e -> pure (Just e)
        Right t -> do
          let items = residueItems t
          r1 <- assertEq "one item" 1 (length items)
          r2 <- assertEq "kind" ["contested_axis"] (map snd items)
          pure (firstJust [r1, r2])
  ]

count :: Seat -> [Turn] -> Int
count s ts = length [() | t <- ts, t.role == s]

-- | Python's @s[s.index(a):s.index(b)]@.
between :: String -> String -> String -> String
between a b s = case (idx a, idx b) of
  (Just i, Just j) -> take (j - i) (drop i s)
  _ -> ""
  where idx needle = findIndex (needle `isPrefixOf`) (tails s)
