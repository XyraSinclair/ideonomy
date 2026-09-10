-- | Offline tests for the respiratory engine. No models, no network.
module CyclesTest (tests) where

import qualified Data.Set as Set
import Harness
import Ideonomy.Cycles hiding (run)
import qualified Ideonomy.Cycles as Cycles
import Ideonomy.Util (joinWith)

structuredCorpus :: State
structuredCorpus = seed [c ++ " " ++ t | (c, tails) <- cores, t <- tails]
  where
    cores =
      [ ("neural network training", ["convergence", "regularization", "checkpoint", "scheduler"])
      , ("database query index", ["btree", "planner", "vacuum", "lookup"])
      , ("http request caching", ["header", "policy", "routing", "revalidation"]) ]

withCompression :: State -> State
withCompression s = s { compression = Just (compressMechanical s) }

item :: String -> String -> Item
item i t = Item { ident = i, text = t, born = 0, source = "seed" }

tests :: [Test]
tests =
  [ -- MdlTests
    test "structure_beats_raw_on_structured_corpus" $ do
      let s = structuredCorpus
          comp = compressMechanical s
      r1 <- assertEq "finds the 3 clusters" 3 (length comp.groups)
      r2 <- assert "ratio > 1" (codeLength s comp < rawBits s)
      pure (firstJust [r1, r2])
  , test "singletons_are_not_structure" $ do
      let s = seed ["alpha beta", "gamma delta", "epsilon zeta"]
          comp = compressMechanical s
      -- token-disjoint items -> all singletons, empty rules, no model cost.
      r1 <- assert "empty rules" (all (Set.null . snd) comp.rule)
      r2 <- assertEq "model bits" 0.0 (modelBits comp)
      -- codelen equals raw: nothing claimed, nothing saved.
      r3 <- assert "codelen == raw" (abs (codeLength s comp - rawBits s) < 1e-7)
      pure (firstJust [r1, r2, r3])
  , test "data_bits_rewards_match" $ do
      let rule = Set.fromList ["a", "b", "c"]
          close = item "x" "a b c d"
          far = item "y" "a x y z w"
      assert "close costs less" (dataBits close rule < dataBits far rule)

    -- RatchetTests
  , test "frontier_expansion_is_accepted_and_ratio_climbs" $ do
      let s = withCompression structuredCorpus
          extras = ["adam", "dropout", "sharding", "cdn", "etag", "warmup"]
          frontier st comp k = take k
            [ joinWith " " (Set.toAscList r) ++ " " ++ extras !! (i `mod` length extras)
            | (i, r) <- zip [st.cycle ..] [r | (_, r) <- maybe [] (.rule) comp, not (Set.null r)] ]
          cfg = defaultConfig { expand = frontier }
          (r1, s1) = breath cfg s
          (r2, _) = breath cfg s1
      a1 <- assertEq "accepted" Accepted r1.expansion
      a2 <- assert "compression deepens" (r2.ratio >= r1.ratio)
      a3 <- assert "corpus grew" (r2.items > r1.items)
      pure (firstJust [a1, a2, a3])
  , test "noise_expansion_is_reverted" $ do
      let s = withCompression structuredCorpus
          before = length s.corpus
          noise _ _ _ = ["zzz qqq", "wxy vut", "lmn opq"]   -- token-disjoint junk
          (rec, s') = breath defaultConfig { expand = noise } s
      r1 <- assertEq "reverted" Reverted rec.expansion
      r2 <- assertEq "rolled back" before (length s'.corpus)
      pure (firstJust [r1, r2])
  , test "residue_extracted_and_run_terminates" $ do
      let (outlier, s0) = add "qqq www eee rrr ttt yyy" "seed" structuredCorpus
          c = compressMechanical s0
          s = s0 { compression = Just c, residue = residueExtract s0 c }
          out = Cycles.run defaultConfig 8 s                      -- must terminate (plateau)
      r1 <- assert "the misfit resists" (outlier `elem` s.residue)
      r2 <- assert "at most 8 breaths" (length out.history <= 8)
      r3 <- assert "every record has a verdict" (all ((`elem` [Accepted, Reverted]) . (.expansion)) out.history)
      pure (firstJust [r1, r2, r3])

    -- EdgeTests
  , test "breath_on_empty_corpus_does_not_crash" $ do
      let s = seed []
          (_, s1) = breath defaultConfig s
          (rec, _) = breath defaultConfig s1    -- second breath: prev_comp exists, codelen == 0
      assert "has a verdict" (rec.expansion `elem` [Accepted, Reverted])
  , test "flat_cost_corpus_has_no_residue_tail" $ do
      -- every item = shared core + exactly one unique token: costs all tie,
      -- so nothing resists more than anything else; residue must not flood.
      let s = structuredCorpus
      assertEq "no residue" [] (residueExtract s (compressMechanical s))
  , test "residue_flags_outlier_not_everything" $ do
      let (outlier, s) = add "qqq www eee rrr ttt yyy" "seed" structuredCorpus
          res = residueExtract s (compressMechanical s)
      r1 <- assert "outlier flagged" (outlier `elem` res)
      r2 <- assert "not everything" (length res < length s.corpus)
      pure (firstJust [r1, r2])
  , test "compression_never_worse_than_raw" $ do
      -- A rule is a compression claim; it must pay or be dropped. Duplicate
      -- items and tie-promoted tokens were the two known violations.
      let cases = [ ["alpha beta", "alpha beta"]
                  , ["alpha beta x", "alpha beta y", "alpha z"]
                  , ["a", "a b", "a b c", "zzz"] ]
          check texts = let s = seed texts
                            comp = compressMechanical s
                         in assert ("structure worse than raw on " ++ show texts) (codeLength s comp <= rawBits s)
      firstJust <$> mapM check cases
  ]
