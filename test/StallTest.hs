-- | The stall reader, offline: the readers and the map are one catalog, the
-- arithmetic reading is pure, and the similarity readings reach their
-- verdicts through a judge that is a pure function of the request.
module StallTest (tests) where

import Data.List (isInfixOf, isPrefixOf)
import qualified Data.Map.Strict as M
import Harness
import qualified Ideonomy.Canon as Canon
import Ideonomy.Json (Value (..), (!?), asArray, asString, key, obj, parse, str)
import qualified Ideonomy.Json as J
import Ideonomy.List (Ideolist (..), seedList)
import Ideonomy.Stall

-- | A judge that reads the first word: the text against itself is 0.95, the
-- far anchor 0.05, and an item is near when the state's first word occurs
-- in it.
firstWord :: String -> IO String
firstWord input = pure (unlines (map one (lines input)))
  where
    one l = case parse l of
      Left e -> error e
      Right v ->
        let s = maybe "" id (asString (key "state" v))
            w = takeWhile (`notElem` ": ") s
            p i t | i == "self" = 0.95 | i == "far" = 0.05 | w `isInfixOf` t = 0.9 | otherwise = 0.1 :: Double
        in J.render (obj [("answers", Array [ obj [("id", str i), ("p", Double (p i t))]
                                          | q <- asArray (key "questions" v)
                                          , Just i <- [q !? "id" >>= asString], Just t <- [q !? "text" >>= asString] ])])

stalls :: IO Ideolist
stalls = do
  cat <- Canon.lists Canon.Grown
  case [l | l <- cat, l.name == "enumeration-stalls"] of
    (l : _) -> pure l
    [] -> ioError (userError "no enumeration-stalls in data")

synthetic :: Ideolist
synthetic = (seedList "synthetic" "a mechanism" ["Alpha: the first mechanism", "Beta: the second mechanism", "Gamma: the third mechanism"])
  { source = Just (obj [("kind", str "map")]) }

ledgerWith :: [String] -> [Breath]
ledgerWith rejected =
  [ Breath 1 synthetic.items [] Nothing (Just 3)
  , Breath 2 [] [ (c, "Rejected: near") | c <- rejected ] Nothing (Just (length rejected)) ]

reading :: Report -> String -> Reading
reading r h = maybe (Unreadable "no row") id (lookup h r.grid)

tests :: [Test]
tests =
  [ test "readers_and_the_map_are_one_catalog" $ do
      m <- stalls
      let handles = map (takeWhile (/= ':')) m.items
      case moves m of
        Left e -> pure (Just e)
        Right mv -> firstJust <$> sequence
          [ assertEq "handles" handles (map fst readers)
          , assertEq "moves parsed" (length handles) (M.size mv)
          , assert "every move is a sentence" (all ((> 20) . length) (M.elems mv)) ]
  , test "ends_at_the_bound" $ firstJust <$> sequence
      [ assert "pile" (case endsAtBound 18 [18, 18, 18, 17, 16] 18 [18, 9] of Read v True _ -> "pile" `isPrefixOf` v; _ -> False)
      , assert "below the pile" (case endsAtBound 18 [18, 18, 18, 17, 16] 15 [] of Read _ False _ -> True; _ -> False)
      , assert "no pile" (case endsAtBound 18 [18, 17, 16, 15] 18 [] of Read "no pile" False _ -> True; _ -> False)
      , assert "empty catalog" (case endsAtBound 18 [] 18 [] of Unreadable _ -> True; _ -> False) ]
  , test "each_near_a_different_one_offline" $ do
      m <- stalls
      spread <- readMap firstWord [synthetic, m] synthetic (Just (ledgerWith ["Alpha again: x", "Beta again: y", "Gamma again: z"]))
      dry <- readMap firstWord [synthetic, m] synthetic (Just (ledgerWith ["Alpha again: x", "Alpha once more: y", "Alpha still: z"]))
      firstJust <$> sequence
        [ assert "judge's stall" (case reading spread "Each near a different one" of Read v True _ -> "judge's stall" `isPrefixOf` v; _ -> False)
        , assertIn "restart move printed" "restart:" (render spread)
        , assert "dry region" (case reading dry "Each near a different one" of Read v False _ -> "dry region" `isPrefixOf` v; _ -> False)
        , assert "no seed, no plate" (case reading dry "Nearest plate" of Unreadable _ -> True; _ -> False) ]
  , test "nearest_plate_offline" $ do
      m <- stalls
      let ledger = [ Breath 1 ["Alpha: a"] [] (Just "Alpha: the seed") (Just 1)
                   , Breath 2 ["Alpha again: b", "Alpha still: c", "Beta: d"] [] Nothing (Just 3) ]
      r <- readMap firstWord [synthetic, m] synthetic (Just ledger)
      assert "plate" (case reading r "Nearest plate" of Read v True _ -> "plate" `isPrefixOf` v; _ -> False)
  , test "option_expiries_grid_offline" $ do
      r <- report firstWord "option-expiries"
      let readCount = length [ () | (_, Read {}) <- r.grid ]
      firstJust <$> sequence
        [ assertEq "grid rows" (length readers) (length r.grid)
        , assertEq "breaths" (Just 3) r.breaths
        , assert "one role is unreadable" (case reading r "One role throughout" of Unreadable c -> "seat" `isInfixOf` c; _ -> False)
        , assert "bound is read" (case reading r "Ends at the bound" of Read {} -> True; _ -> False)
        , assert "residue is read" (case reading r "Each near a different one" of Read {} -> True; _ -> False)
        , assertEq "read count" 2 readCount
        , assertIn "header" "=== option-expiries" (render r) ]
  ]
