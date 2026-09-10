module Main (main) where

import Harness (run)
import qualified ConsistencyTest
import qualified CyclesTest
import qualified DrawTest
import qualified JsonTest
import qualified ListTest
import qualified RegistersTest
import qualified ModelsTest
import qualified ParleyTest
import qualified ResidueTest
import qualified TrialTest
import qualified TriangulateTest

main :: IO ()
main = run
  [ ("json", JsonTest.tests)
  , ("list", ListTest.tests)
  , ("cycles", CyclesTest.tests)
  , ("draw", DrawTest.tests)
  , ("registers", RegistersTest.tests)
  , ("residue", ResidueTest.tests)
  , ("models", ModelsTest.tests)
  , ("triangulate", TriangulateTest.tests)
  , ("parley", ParleyTest.tests)
  , ("trial", TrialTest.tests)
  , ("consistency", ConsistencyTest.tests)
  ]
