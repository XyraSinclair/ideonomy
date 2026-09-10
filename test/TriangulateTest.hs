-- | Offline tests for executable triangulation (P-9). Judges are injected
-- deterministic mocks — no models, no network.
module TriangulateTest (tests) where

import Data.List (isInfixOf, sort)
import Harness
import Ideonomy.Triangulate

-- | A mock judge returning a preset lean per axis.
fixed :: String -> [(String, Double)] -> Judge
fixed nm ls axis _ = pure Verdict
  { judge = nm, axis = axis, lean = maybe 0 id (lookup axis ls), stance = nm ++ " on " ++ axis }

tests :: [Test]
tests =
  [ test "agreement is settled, disagreement is contested" $ do
      let j1 = fixed "a" [("austerity", 0.8), ("exactness", 0.7)]
          j2 = fixed "b" [("austerity", 0.7), ("exactness", -0.6)]   -- split on exactness
      r <- triangulate "is the copy right?" ["austerity", "exactness"] [j1, j2]
      case r of
        Left e -> pure (Just e)
        Right tri -> do
          r1 <- assertEq "settled" ["austerity"] (sort [a.axis | a <- settledAxes tri])
          r2 <- assertEq "contested" ["exactness"] (sort [a.axis | a <- contestedAxes tri])
          pure (firstJust [r1, r2])
  , test "gate requires two independent judges" $ do
      r <- triangulate "q" ["x"] [fixed "a" [("x", 0.5)]]         -- one judge is not triangulation
      assertLeft "one judge" r
  , test "gate requires axes" $ do
      r <- triangulate "q" [] [fixed "a" [], fixed "b" []]         -- no dimensionalization
      assertLeft "no axes" r
  , test "contested axes become residue (P-9 to P-10)" $ do
      let j1 = fixed "a" [("reversibility", 0.9), ("blast_radius", -0.8)]
          j2 = fixed "b" [("reversibility", 0.85), ("blast_radius", 0.7)]  -- split on blast
      r <- triangulate "ship it?" ["reversibility", "blast_radius"] [j1, j2]
      case r of
        Left e -> pure (Just e)
        Right tri -> do
          let items = residueItems tri
          r1 <- assertEq "only the contested axis" 1 (length items)
          r2 <- assertEq "kind" ["contested_axis"] (map snd items)
          r3 <- assert "names the axis" (all (("blast_radius" `isInfixOf`) . fst) items)
          pure (firstJust [r1, r2, r3])
  , test "report names irreducible and never a single scalar" $ do
      r <- triangulate "good?" ["taste"] [fixed "a" [("taste", 0.2)], fixed "b" [("taste", -0.9)]]
      case r of
        Left e -> pure (Just e)
        Right tri -> do
          let rep = report tri
          r1 <- assertIn "contested" "CONTESTED" rep
          r2 <- assertIn "names who must decide" "owner=" rep
          -- the report is per-axis with spreads, not one collapsed number.
          r3 <- assertIn "spread" "spread=" rep
          pure (firstJust [r1, r2, r3])
  , test "parse lean" $ do
      r1 <- assertClose "labeled" 0.7 (parseLean "LEAN: 0.7\nWHY: x")
      r2 <- assertClose "clamped" 1.0 (parseLean "LEAN: 2.0")
      r3 <- assertClose "absent" 0.0 (parseLean "no number here")
      pure (firstJust [r1, r2, r3])
  , test "model judge parses model reply" $ do
      v <- modelJudge (\_ -> pure "LEAN: -0.4\nWHY: too florid") "m1" "austerity" "q"
      r1 <- assertClose "lean" (-0.4) v.lean
      r2 <- assertEq "stance" "too florid" v.stance
      pure (firstJust [r1, r2])
  , test "dimensionalize strips numbering and refuses empty" $ do
      axes <- dimensionalize "q" (\_ -> pure "1. austerity\n2) exactness") 4
      r1 <- assertEq "axes" (Right ["austerity", "exactness"]) axes
      -- No axes -> refuse to manufacture a scalar (the P-9 discipline).
      none <- dimensionalize "q" (\_ -> pure "") 4
      r2 <- assertLeft "empty" none
      pure (firstJust [r1, r2])
  , test "uncertain vs confident is contested" $ do
      let j1 = fixed "a" [("taste", 0.0)]     -- genuinely uncertain
          j2 = fixed "b" [("taste", 0.9)]     -- confident
      r <- triangulate "good?" ["taste"] [j1, j2]
      case r of
        Left e -> pure (Just e)
        Right tri -> assertEq "contested" ["taste"] [a.axis | a <- contestedAxes tri]
  ]

assertClose :: String -> Double -> Double -> IO (Maybe String)
assertClose msg want got = assert (msg ++ ": expected " ++ show want ++ ", got " ++ show got) (abs (want - got) < 1e-7)
