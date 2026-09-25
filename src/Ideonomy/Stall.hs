-- | The stall reader: one grown map read against the atlas's own
-- @enumeration-stalls@, seventeen mechanisms by which an enumeration stops
-- yielding before its universe is exhausted while feeling complete.
--
-- Three carriers, the record, its climb ledger, and the catalog, and one
-- instrument, a closed judge for content similarity (@judge --jsonl@:
-- typed probabilities from a single prefill pass; any command speaking its
-- protocol serves, and offline tests inject a pure one). Every stall is
-- reported in one of two states: read, with its evidence and, when the
-- reading is the stall, the restart move the map itself prescribes; or
-- unreadable, with the carrier that would read it. The grid is the report,
-- not the hits: the denominator discipline turned on the instrument.
--
-- What is read. /Ends at the bound/ is arithmetic: map lengths across the
-- catalog and candidate counts across the ledger, against the gate's
-- ceiling. /Nearest plate/ and /Each near a different one/ are one
-- asymmetric question, "the text above is a case of this rule", which the
-- judge ranks well (top-1 4 of 6, MRR 0.76 against the ledger's own merge
-- targets; the symmetric "same mechanism" ranked at chance). Every call
-- carries its own two anchors, the text as a case of itself and an item
-- from another map, so "near" is decided inside the call and never by a
-- fixed threshold. What the judge cannot read is declared, not faked: the
-- seat of an item's subject is grammar, on which it measured at chance,
-- and the quality of an item is a rating it grades at chance
-- (docs/fieldnotes.md, 2026-09-25).
--
-- > ideonomy stall NAME                          # the grid for one grown map
-- > ideonomy stall NAME --judge 'judge --jsonl'   # the judge command (the default)
module Ideonomy.Stall
  ( Reading (..), Report (..), Breath (..)
  , readers, moves, endsAtBound, readMap, report, render, cli
  ) where

import Control.Monad (unless)
import Data.Char (isSpace, toUpper)
import Data.List (isPrefixOf, maximumBy)
import qualified Data.Map.Strict as M
import Data.Ord (comparing)
import qualified Ideonomy.Canon as Canon
import Ideonomy.Check (itemCeiling)
import Ideonomy.Cli (opt, parseArgs, positionals, usage)
import Ideonomy.Fences (isMap)
import Ideonomy.Json (Value (..), (!?), asArray, asInt, asNumber, asString, asStrings, key, obj, readJsonl, str)
import qualified Ideonomy.Json as J
import Ideonomy.List (Ideolist (..))
import Ideonomy.Models (Model, command, mkCommand)
import Ideonomy.Util (joinWith, nub', showFixed, splitOn, strip, truncateTo)
import System.Directory (doesFileExist)
import System.FilePath ((</>))

-- | One stall's reading: read, with a verdict, whether the verdict is the
-- stall, and evidence lines; or unreadable, with the carrier that would
-- read it.
data Reading
  = Read { verdict :: String, stalled :: Bool, evidence :: [String] }
  | Unreadable String
  deriving (Eq, Show)

data Report = Report
  { mapName :: String
  , items :: Int
  , breaths :: Maybe Int            -- ^ ledger lines, when a ledger exists
  , maps :: Int                     -- ^ grown maps in the catalog
  , grid :: [(String, Reading)]     -- ^ every stall, in the map's order
  , restart :: M.Map String String  -- ^ handle -> the move that restarts it
  } deriving (Show)

-- | One climb-ledger line.
data Breath = Breath
  { number :: Int
  , accepted :: [String]
  , residue :: [(String, String)]   -- ^ (rejected candidate, why)
  , seed :: Maybe String            -- ^ the seed this breath left for the next
  , candidates :: Maybe Int
  } deriving (Eq, Show)

-- | Every stall the map names and, for each this module cannot read, the
-- carrier it lacks. 'Nothing' marks a stall this module reads.
readers :: [(String, Maybe String)]
readers =
  [ ("One role throughout", Just "the seat of each item's subject, extracted per item by a generating model and counted; a closed judge reads content, not grammar, and measured at chance on this tell")
  , ("Both ends named", Just "the seriation axis and its endpoints; the record carries none")
  , ("Stops on its best", Just "a blind rating of each item set against admission order; this judge grades quality at chance")
  , ("Phantom tail", Just "a cut-one breath: one member removed, the rest re-counted")
  , ("No box for it", Just "the brief's frame; the record does not carry its brief")
  , ("Each near a different one", Nothing)
  , ("Published as finished", Just "the inflow after publication; the ledger ends at admission")
  , ("Nearest plate", Nothing)
  , ("Harder, not fewer", Just "a blind rating of each item set against admission order; this judge grades quality at chance")
  , ("Box without a hole", Just "a typology with one axis from outside the list; the record carries none")
  , ("Restatable once found", Just "a breath in a rotated register, then restatement in the first")
  , ("Never met one", Just "an outsider's case brought before a breath, and whether it is recognised without having been produced")
  , ("Singletons gone", Just "a second net of a different make, and both nets' rediscovery rates")
  , ("Every address visited", Just "one pass whose unit is the member and not the container")
  , ("Ends at the bound", Nothing)
  , ("Two nets, one boat", Just "two enumerators' unique fractions, and a third source of a different make")
  , ("Missing column", Just "the axes; the record carries none")
  ]

-- | The restart move each item of the stalls map prescribes, by handle.
-- The map's grammar is data: an item reads "Handle: ...; the move that
-- restarts it is ...;", and an item without a move is a defect in the map.
moves :: Ideolist -> Either String (M.Map String String)
moves m = M.fromList <$> mapM one m.items
  where
    one it = case break (== ':') it of
      (h, ':' : rest)
        | (mv : _) <- [strip (drop (length pfx) seg) | seg <- map strip (splitOn ';' rest), pfx `isPrefixOf` seg] -> Right (h, mv)
        | otherwise -> Left ("enumeration-stalls: no restart move in " ++ show h)
      _ -> Left ("enumeration-stalls: item without a handle: " ++ take 60 it)
    pfx = "the move that restarts it is"

-- ------------------------------------------------------------------ ledger

ledgerPath :: String -> FilePath
ledgerPath n = "corpus" </> "climb-ledger" </> (n ++ ".jsonl")

readLedger :: String -> IO (Maybe [Breath])
readLedger n = do
  ok <- doesFileExist (ledgerPath n)
  if ok then Just . map breath <$> readJsonl (ledgerPath n) else pure Nothing

breath :: Value -> Breath
breath v = Breath
  { number = maybe 0 id (asInt (key "breath" v))
  , accepted = asStrings (key "accepted" v)
  , residue = [ (c, maybe "" id (o !? "why" >>= asString)) | o <- asArray (key "residue" v), Just c <- [o !? "item" >>= asString] ]
  , seed = asString (key "seed" v)
  , candidates = asInt (key "candidates" v)
  }

-- ------------------------------------------------------------------- reads

-- | Map lengths across the catalog and candidate counts across the ledger,
-- against the ceiling. The pile is more than half the maps at the ceiling;
-- the reading is the stall when this map is one of them.
endsAtBound :: Int -> [Int] -> Int -> [Int] -> Reading
endsAtBound ceiling lengths mine cands
  | null lengths = Unreadable "map lengths across the catalog; the catalog holds no maps"
  | otherwise = Read verdict (pile && mine == ceiling) $
      ( "catalog: " ++ show atMax ++ " of " ++ show total ++ " maps sit at the ceiling of " ++ show ceiling
        ++ " (" ++ unwords [show k ++ ":" ++ show c | (k, c) <- hist] ++ "); this map: " ++ show mine )
      : [ "ledger: " ++ show (length (filter (== ceiling) cands)) ++ " of " ++ show (length cands)
          ++ " breaths proposed exactly " ++ show ceiling ++ " candidates" | not (null cands) ]
  where
    total = length lengths
    atMax = length (filter (== ceiling) lengths)
    pile = 2 * atMax > total
    hist = [ (k, c) | k <- [minimum lengths .. maximum lengths], let c = length (filter (== k) lengths), c > 0 ]
    verdict
      | pile && mine == ceiling = "pile: more than half the catalog sits at the ceiling, this map among them"
      | pile = "the catalog piles at the ceiling; this map sits below it"
      | otherwise = "no pile"

-- | One judge call over several states: one request line per state, one
-- response line per request; per state, the probability by question id.
-- Every asked id must come back; a short answer is an error, not a default.
ask :: Model -> [(String, [(String, String)])] -> IO [M.Map String Double]
ask _ [] = pure []
ask judge groups = do
  out <- judge (unlines [J.render (request s qs) | (s, qs) <- groups])
  let ls = filter (not . all isSpace) (lines out)
  unless (length ls == length groups) $
    ioError (userError ("judge returned " ++ show (length ls) ++ " lines for " ++ show (length groups) ++ " requests"))
  rs <- mapM answers ls
  let missing = [ i | ((_, qs), ps) <- zip groups rs, (i, _) <- qs, not (M.member i ps) ]
  unless (null missing) $ ioError (userError ("judge answered without ids " ++ show (take 5 missing)))
  pure rs
  where
    request s qs = obj [ ("state", str s)
                       , ("questions", Array [obj [("id", str i), ("type", str "noul"), ("text", str t)] | (i, t) <- qs]) ]
    answers l = case J.parse l of
      Left e -> ioError (userError ("judge: " ++ e))
      Right v
        | Just e <- v !? "error" -> ioError (userError ("judge: " ++ J.render e))
        | otherwise -> pure (M.fromList [ (i, p) | a <- asArray (key "answers" v)
                                                 , Just i <- [a !? "id" >>= asString], Just p <- [a !? "p" >>= asNumber] ])

logit :: Double -> Double
logit p = let q = min (1 - 1e-6) (max 1e-6 p) in log (q / (1 - q))

-- | Near, decided inside the call: closer in log-odds to the text against
-- itself than to an item from another map.
near :: M.Map String Double -> Double -> Bool
near ps p = logit p > (logit (ps M.! "self") + logit (ps M.! "far")) / 2

handle :: String -> String
handle = takeWhile (/= ':')

clause :: String -> String
clause = truncateTo 220

-- | The one question both similarity readings ask; the state is the case.
caseOf :: String -> String
caseOf rule = "The text above is a case of this rule: " ++ clause rule

-- | The near decision as evidence: the best member's probability against
-- the midpoint the anchors set.
against :: M.Map String Double -> Double -> String
against ps p = showFixed 2 p ++ (if near ps p then " > " else " < ") ++ showFixed 2 mid
  where mid = 1 / (1 + exp (negate ((logit (ps M.! "self") + logit (ps M.! "far")) / 2)))

-- | An item from the map after this one in the catalog, wrapping: the far
-- anchor every similarity call carries.
farItem :: [Ideolist] -> String -> Maybe String
farItem cat n = case [ it | l <- after ++ before, l.name /= n, isMap l, (it : _) <- [l.items] ] of
  (it : _) -> Just it
  [] -> Nothing
  where (before, after) = break ((== n) . (.name)) cat

-- | The members each breath admitted, each as a case of the seed the
-- previous breath left: a plate is two thirds or more of them near it.
nearestPlate :: Model -> String -> [Breath] -> IO Reading
nearestPlate judge far ledger =
  case [ (b.number, s, b.accepted) | (prev, b) <- zip ledger (drop 1 ledger), Just s <- [prev.seed], not (null b.accepted) ] of
    [] -> pure (Unreadable "a breath that began from the seed the previous breath left; this ledger has none")
    seeded -> do
      rs <- ask judge [ (it, [("self", caseOf it), ("far", caseOf far), ("seed", caseOf s)]) | (_, s, acc) <- seeded, it <- acc ]
      let rows = go seeded rs
          plates = [ n | (n, k, tot) <- rows, tot >= 3, 3 * k >= 2 * tot ]
          verdict | null plates = "spread: the admitted members do not cluster on the seed"
                  | otherwise = "plate: breath " ++ joinWith ", " (map show plates) ++ " clustered on the seed it was given"
      pure (Read verdict (not (null plates))
             [ "breath " ++ show n ++ ": " ++ show k ++ " of " ++ show tot ++ " admitted members are cases of the seed breath " ++ show (n - 1) ++ " left" | (n, k, tot) <- rows ])
  where
    go [] _ = []
    go ((n, _, acc) : more) rs = let (mine, rest) = splitAt (length acc) rs
                                 in (n, length [ () | ps <- mine, near ps (ps M.! "seed") ], length acc) : go more rest

-- | Every rejected candidate as a case of each admitted member: the
-- judge's stall is each candidate nearest a different member.
eachNear :: Model -> String -> [String] -> [Breath] -> IO Reading
eachNear judge far admitted ledger
  | null admitted = pure (Unreadable "admitted members to set the residue against; the record has none")
  | otherwise = case concatMap (.residue) ledger of
      [] -> pure (Unreadable "the residue, rejected candidates with their reasons; this ledger records none")
      res -> do
        rs <- ask judge [ (c, [("self", caseOf c), ("far", caseOf far)] ++ [ ("i" ++ show k, caseOf it) | (k, it) <- zip [0 :: Int ..] admitted ]) | (c, _) <- res ]
        let rows = [ (c, why, best, p, ps)
                   | ((c, why), ps) <- zip res rs
                   , let (best, p) = maximumBy (comparing snd) [ (it, ps M.! ("i" ++ show k)) | (k, it) <- zip [0 :: Int ..] admitted ] ]
            neighbours = nub' [ handle b | (_, _, b, p, ps) <- rows, near ps p ]
            n = length [ () | (_, _, _, p, ps) <- rows, near ps p ]
            d = length neighbours
            stall = n >= 3 && d == n
            verdict
              | stall = "judge's stall: each rejected candidate sits nearest a different admitted member"
              | n >= 2 && 2 * d <= n = "dry region: the residue clusters on " ++ joinWith ", " neighbours
              | n == 0 = "far from all: no rejected candidate is a case of an admitted member"
              | otherwise = "mixed: " ++ show n ++ " near, " ++ show d ++ " distinct neighbours"
        pure (Read verdict stall $
          ("residue " ++ show (length res) ++ "; " ++ show n ++ " near an admitted member, " ++ show d ++ " distinct neighbours; near is above the midpoint of the item as a case of itself and of a far rule")
          : [ "  " ++ handle c ++ (if near ps p then " -> " else " -/-> ") ++ handle best ++ " (" ++ against ps p ++ ")"
              ++ (if null why then "" else "  ledger: " ++ truncateTo 90 why)
            | (c, why, best, p, ps) <- rows ])

-- | The grid for one record, given the catalog it sits in and its ledger.
readMap :: Model -> [Ideolist] -> Ideolist -> Maybe [Breath] -> IO Report
readMap judge cat rec ledger = do
  stalls <- case [m | m <- cat, m.name == "enumeration-stalls"] of
    (m : _) -> pure m
    [] -> ioError (userError "the catalog holds no enumeration-stalls map")
  mv <- either (ioError . userError) pure (moves stalls)
  let lengths = [length m.items | m <- cat, isMap m]
      cands = [c | Just bs <- [ledger], b <- bs, Just c <- [b.candidates]]
      far = farItem cat rec.name
      noLedger = Unreadable ("the climb ledger at " ++ ledgerPath rec.name ++ "; none")
      noFar = Unreadable "an item from another map as the far anchor; the catalog holds no other map"
      one h = case lookup h readers of
        Nothing -> ioError (userError ("enumeration-stalls names a stall this reader has no row for: " ++ show h))
        Just (Just carrier) -> pure (Unreadable carrier)
        Just Nothing -> case (h, ledger, far) of
          ("Ends at the bound", _, _) -> pure (endsAtBound itemCeiling lengths (length rec.items) cands)
          (_, Nothing, _) -> pure noLedger
          (_, _, Nothing) -> pure noFar
          ("Nearest plate", Just bs, Just f) -> nearestPlate judge f bs
          ("Each near a different one", Just bs, Just f) -> eachNear judge f rec.items bs
          _ -> ioError (userError ("no reader for " ++ show h))
  g <- mapM (\it -> (,) (handle it) <$> one (handle it)) stalls.items
  pure Report { mapName = rec.name, items = length rec.items, breaths = length <$> ledger
              , maps = length lengths, grid = g, restart = mv }

report :: Model -> String -> IO Report
report judge n = do
  cat <- Canon.lists Canon.Grown
  rec <- case [l | l <- cat, l.name == n] of
    (l : _) -> pure l
    [] -> ioError (userError ("no grown list named " ++ show n))
  ledger <- readLedger n
  readMap judge cat rec ledger

-- --------------------------------------------------------------- rendering

render :: Report -> String
render r = joinWith "\n" $
  [ "=== " ++ r.mapName ++ "  [" ++ show r.items ++ " items; ledger: " ++ maybe "none" (\k -> show k ++ " breaths") r.breaths
    ++ "; catalog: " ++ show r.maps ++ " maps]"
  , "read " ++ show (length done) ++ " of " ++ show (length r.grid) ++ " stalls; " ++ show (length open) ++ " need a carrier this reader lacks"
  , "" ]
  ++ concat [ (map toUpper h ++ ": " ++ v) : map ("  " ++) ev ++ [ "  restart: " ++ M.findWithDefault "" h r.restart | st ]
            | (h, Read v st ev) <- r.grid ]
  ++ [ "", "unreadable:" ]
  ++ [ "  " ++ h ++ " -- " ++ c | (h, c) <- open ]
  where
    done = [ h | (h, Read {}) <- r.grid ]
    open = [ (h, c) | (h, Unreadable c) <- r.grid ]

-- --------------------------------------------------------------------- CLI

usageLine :: String
usageLine = "usage: ideonomy stall NAME [--judge CMD]   (CMD reads judge requests as JSON lines on stdin; default: judge --jsonl)"

cli :: [String] -> IO ()
cli argv = do
  let a = parseArgs [] ["judge"] argv
  case positionals a of
    [n] -> report (command (mkCommand (maybe "judge --jsonl" id (opt "judge" a)) "judge")) n >>= putStrLn . render
    _ -> usage usageLine
