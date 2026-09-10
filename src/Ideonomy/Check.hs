-- | The gate for grown map records (P18 gate, P11 coverage). An ideonomic
-- map is an 'Ideolist' whose @source.kind == "map"@ carrying an authored
-- seriation, 4–7 conditional relations between exact items, one near and
-- one wild opening, and the exploration that changed its question. A map
-- that fails the gate is copy, not a map.
--
-- 'mapView' is the typed reading of the record — every field the fleet
-- brief names, with its shape enforced — and 'checkRecord' is the gate on
-- top of it: it returns every violation, not the first, so an author can
-- repair a record in one pass. The check is exact-string: an item text
-- changed in @items@ but not in a relation endpoint is a violation, which
-- is the failure the fleet's REPAIR notes warn about.
--
-- @ideonomy check PATH...@ — each PATH holds one record as a JSON object;
-- prints @ok NAME N items M edges@ per file or every violation, exit 1 on
-- any failure.
module Ideonomy.Check
  ( MapRecord (..), Seriation (..), Relation (..), Priority (..), Exploration (..), Horizon (..)
  , horizonName, readHorizon, mapView, checkRecord, cli
  ) where

import Control.Exception (IOException, try)
import Control.Monad (unless)
import Ideonomy.Cli (parseArgs, positionals, usage)
import Ideonomy.Json (Value (..), (!?), asString, parseFile)
import Ideonomy.List (Ideolist (..), fromValue)
import Ideonomy.Util (joinWith, nub', strip)
import System.Exit (exitWith, ExitCode (..))

data Horizon = Near | Wild deriving (Eq, Show)

horizonName :: Horizon -> String
horizonName Near = "near"
horizonName Wild = "wild"

readHorizon :: String -> Either String Horizon
readHorizon "near" = Right Near
readHorizon "wild" = Right Wild
readHorizon s = Left ("horizon " ++ show s ++ "; one of near, wild")

-- | An authored itinerary along a named axis, not a scalar ranking.
data Seriation = Seriation
  { axis :: String
  , method :: Maybe String
  , note :: Maybe String
  , namedBy :: Maybe String
  } deriving (Eq, Show)

-- | A conditional claim between two exact items.
data Relation = Relation { from_ :: String, to :: String, label :: String }
  deriving (Eq, Show)

-- | An opening: the next expedition from one item.
data Priority = Priority { item :: String, horizon :: Horizon, why :: String, nextQuestion :: String }
  deriving (Eq, Show)

-- | What the second breath changed, and the member the first framing hid.
data Exploration = Exploration { firstQuestion :: String, changedQuestion :: String, newMember :: String }
  deriving (Eq, Show)

data MapRecord = MapRecord
  { ideolist :: Ideolist
  , seriation :: Seriation
  , relations :: [Relation]
  , exploration :: Exploration
  , priorities :: [Priority]
  } deriving (Eq, Show)

-- ------------------------------------------------------------------- view

-- | Shape errors accumulate: every missing or mistyped field is reported.
newtype V a = V (Either [String] a)

instance Functor V where
  fmap f (V e) = V (fmap f e)

instance Applicative V where
  pure = V . Right
  V (Left a) <*> V (Left b) = V (Left (a ++ b))
  V (Left a) <*> _ = V (Left a)
  V (Right f) <*> V x = V (fmap f x)

failV :: String -> V a
failV = V . Left . pure

-- | The typed reading of a map record. Left names every field that is
-- missing or of the wrong shape, joined by @"; "@.
mapView :: Ideolist -> Either String MapRecord
mapView l = case view l of
  V (Left errs) -> Left (joinWith "; " errs)
  V (Right r) -> Right r

view :: Ideolist -> V MapRecord
view l = case l.source of
  Nothing -> failV "source: missing"
  Just src -> case src !? "kind" >>= asString of
    Just "map" ->
      MapRecord l
        <$> object "source.seriation" src "seriation" seriationV
        <*> array "source.relations" src "relations" relationV
        <*> object "source.exploration" src "exploration" explorationV
        <*> array "source.priorities" src "priorities" priorityV
    Just k -> failV ("source.kind: expected \"map\", got " ++ show k)
    Nothing -> failV "source.kind: missing"
  where
    seriationV path v = Seriation <$> string path v "axis" <*> optional path v "method"
      <*> optional path v "note" <*> optional path v "named_by"
    relationV path v = Relation <$> string path v "from" <*> string path v "to" <*> string path v "label"
    priorityV path v = Priority <$> string path v "item" <*> horizonV path v
      <*> string path v "why" <*> string path v "next_question"
    explorationV path v = Exploration <$> string path v "first_question"
      <*> string path v "changed_question" <*> string path v "new_member"
    horizonV path v = case string path v "horizon" of
      V (Right h) -> either (\e -> failV (path ++ ".horizon: " ++ e)) pure (readHorizon h)
      V (Left e) -> V (Left e)
    string path v k = case v !? k of
      Just (String s) -> pure s
      Just _ -> failV (path ++ "." ++ k ++ ": expected a string")
      Nothing -> failV (path ++ "." ++ k ++ ": missing")
    optional path v k = case v !? k of
      Nothing -> pure Nothing
      Just Null -> pure Nothing
      Just (String s) -> pure (Just s)
      Just _ -> failV (path ++ "." ++ k ++ ": expected a string")
    object path v k f = case v !? k of
      Just o@(Object _) -> f path o
      Just _ -> failV (path ++ ": expected an object")
      Nothing -> failV (path ++ ": missing")
    array path v k f = case v !? k of
      Just (Array xs) -> traverse (\(i, x) -> case x of
        Object _ -> f (path ++ "[" ++ show i ++ "]") x
        _ -> failV (path ++ "[" ++ show i ++ "]: expected an object")) (zip [0 :: Int ..] xs)
      Just _ -> failV (path ++ ": expected a list")
      Nothing -> failV (path ++ ": missing")

-- ------------------------------------------------------------------- gate

-- | Every violation of the map gate; empty means the record passes. The
-- item checks need only the list, so they are reported even when the
-- source is misshapen; the rest need the typed view.
checkRecord :: Ideolist -> [String]
checkRecord l = itemViolations l.items ++ case view l of
  V (Left errs) -> errs
  V (Right r) -> violations r

itemViolations :: [String] -> [String]
itemViolations items =
  [ "duplicate item: " ++ shorten x | x <- nub' [x | (i, x) <- zip [0 :: Int ..] items, x `elem` take i items] ]
  ++ [ "13 <= unique items <= 18: have " ++ show n | n < 13 || n > 18 ]
  where n = length (nub' items)

violations :: MapRecord -> [String]
violations r =
  [ "4 <= relations <= 7: have " ++ show m | m < 4 || m > 7 ]
  ++ concat
       [ [ at ++ ".from is not an item: " ++ shorten e.from_ | not (isItem e.from_) ]
         ++ [ at ++ ".to is not an item: " ++ shorten e.to | not (isItem e.to) ]
         ++ [ at ++ ".label is blank" | null (strip e.label) ]
       | (i, e) <- zip [0 :: Int ..] r.relations, let at = "relations[" ++ show i ++ "]" ]
  ++ [ "priorities[" ++ show i ++ "].item is not an item: " ++ shorten p.item
     | (i, p) <- zip [0 :: Int ..] r.priorities, not (isItem p.item) ]
  ++ [ "exploration.new_member is not an item: " ++ shorten r.exploration.newMember
     | not (isItem r.exploration.newMember) ]
  ++ [ "seriation.axis is blank" | null (strip r.seriation.axis) ]
  where
    m = length r.relations
    isItem x = x `elem` r.ideolist.items

shorten :: String -> String
shorten s = if length s <= 72 then s else take 71 s ++ "\x2026"

-- --------------------------------------------------------------------- CLI

-- | @ideonomy check PATH...@
cli :: [String] -> IO ()
cli argv = case positionals (parseArgs [] argv) of
  [] -> usage "usage: ideonomy check PATH..."
  paths -> do
    oks <- mapM checkFile paths
    unless (and oks) (exitWith (ExitFailure 1))
  where
    checkFile p = do
      parsed <- try (parseFile p) :: IO (Either IOException (Either String Value))
      case either (Left . show) id parsed >>= fromValue of
        Left e -> report [e] >> pure False
        Right l -> case (checkRecord l, mapView l) of
          ([], Right r) -> do
            putStrLn ("ok " ++ l.name ++ " " ++ show (length (nub' l.items)) ++ " items " ++ show (length r.relations) ++ " edges")
            pure True
          (vs, _) -> report vs >> pure False
      where report = mapM_ (\v -> putStrLn (p ++ ": " ++ v))
