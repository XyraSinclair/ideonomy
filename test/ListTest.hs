module ListTest (tests) where

import Harness
import Ideonomy.List
import Ideonomy.Rng (mkRng)
import System.Directory (getTemporaryDirectory, removeDirectoryRecursive)
import System.FilePath ((</>))

tests :: [Test]
tests =
  [ test "combine carries the product type and lineage" $ do
      let regs = seedList "regs" "a register" ["grief"]
          lens = seedList "lens" "a division" ["ANOMALIES"]
          c = combine "Read {b} in the register of {a}." Nothing regs lens
      r1 <- assertEq "items" ["Read ANOMALIES in the register of grief."] c.items
      r2 <- assertEq "parents" ["regs", "lens"] c.parents
      r3 <- assertIn "of carries a" "a register" c.of_
      r4 <- assertIn "of carries b" "a division" c.of_
      pure (firstJust [r1, r2, r3, r4])
  , test "gate returns a real residue list with lineage" $ do
      let (kept, residue) = gate "double" ((== 2) . length) (seedList "x" "t" ["aa", "b", "cc"])
      r1 <- assertEq "kept" ["aa", "cc"] kept.items
      r2 <- assertEq "residue" ["b"] residue.items
      r3 <- assertEq "residue parents" ["x"] residue.parents
      pure (firstJust [r1, r2, r3])
  , test "grow appends new items, dedupes, and reopens" $ do
      let l = (seedList "n" "a number word" ["one", "two"]) { status = Closed }
      g <- grow (\_ -> pure "- three\n* Two\nfour\n\n") 10 "" l
      r1 <- assertEq "items" ["one", "two", "three", "four"] g.items
      r2 <- assertEq "status" Open g.status
      pure (firstJust [r1, r2])
  , test "sample is deterministic under a seed and refuses overdraw" $ do
      let l = seedList "s" "t" (map show [1 .. 20 :: Int])
          a = sampleItems 5 [] (mkRng 7) l
          b = sampleItems 5 [] (mkRng 7) l
      r1 <- assertEq "same seed" a b
      r2 <- assertLeft "overdraw" (sampleItems 21 [] (mkRng 1) l)
      pure (firstJust [r1, r2])
  , test "store round trips nested names and rejects escapes" $ do
      tmp <- getTemporaryDirectory
      let st = Store (tmp </> "ideonomy-listtest")
      _ <- save st (seedList "a/b" "t" ["x"])
      back <- load st "a/b"
      ns <- names st
      removeDirectoryRecursive st.root
      r1 <- assertEq "items" ["x"] back.items
      r2 <- assertEq "names" ["a/b"] ns
      r3 <- assertLeft "escape" (storePath st "../evil")
      pure (firstJust [r1, r2, r3])
  , test "the algebra applies to itself" $ do
      let sq = combine "{a} after {b}" Nothing operations operations
          n = length operations.items
      r1 <- assertEq "n^2" (n * n) (length sq.items)
      r2 <- assertEq "parents" ["list-operations", "list-operations"] sq.parents
      pure (firstJust [r1, r2])
  ]
