-- | Consult the atlas — the lists and maps a situation belongs to, handed
-- back as instruments.
--
-- The catalog stores its information in denominators, partitions, orders,
-- and gates (README). A plan or brainstorm that never opens the atlas
-- samples the mode of the model's training distribution; this module is
-- the door in. Give it a situation and it returns the lists whose item type
-- the situation belongs to, each rendered as something to /use/: an axis to
-- stand on, members to check off, edges to walk, probes already written as
-- small experiments.
--
-- Retrieval is lexical and offline, so a map whose vocabulary differs from
-- yours can be missed — every hit prints its @of@ sentence so the miss is
-- visible. The judgment is the caller's: which members the plan contains,
-- which are ruled out, which stay unlabeled. @--frame audit@ prints the
-- coverage frame that turns that judgment into a labeled denominator
-- instead of a feeling (the gate of @prove-the-coverage-denominator@).
--
-- > ideonomy consult "raising a seed round with four months of cash"
-- > ideonomy consult --file plan.md --frame audit --k 2
-- > ideonomy consult --from-residue mywork      # what last session left open
-- > ideonomy consult --file plan.md --frame audit --model 'claude -p {prompt}'
--
-- Deterministic: same catalog, same query, same order.
module Ideonomy.Consult
  ( stop, fieldWeights, stem, tokens, handle
  , Instrument (..), instrument
  , Atlas, atlas, atlasSize, consult
  , render, renderAudit
  , cli
  ) where

import Data.Char (isAsciiLower, isDigit, isSpace, toLower)
import Data.List (isPrefixOf, sortOn)
import qualified Data.Map.Strict as M
import Data.Ord (Down (..))
import qualified Data.Set as Set
import qualified Ideonomy.Canon as Canon
import Ideonomy.Cli (flag, opt, optInt, parseArgs, positionals, usage)
import Ideonomy.Json ((!?), asArray, asString)
import qualified Ideonomy.Json as J
import Ideonomy.List (Ideolist (..))
import Ideonomy.Models (command, mkCommand)
import qualified Ideonomy.Residue as R
import Ideonomy.Util (joinWith, replace, roundTo, strip)
import Numeric (log1p)
import System.Exit (ExitCode (..), exitWith)

stop :: Set.Set String
stop = Set.fromList $ words
  "a an the and or but if then than that this these those of for to in on at by \
  \with from as is are was were be been being it its into over under about \
  \between through after before during without within against not no nor so \
  \such can could may might must shall should will would do does did done have \
  \has had having we our you your they their them he she his her who whom which \
  \what when where why how any all each every some more most much many one two \
  \first next also just only very own same other another there here out up down \
  \per via etc make keep get use way thing three four five six seven eight nine ten"

fieldWeights :: [(String, Double)]
fieldWeights =
  [ ("name", 3.0), ("of", 3.0), ("questions", 2.0), ("axis", 2.0)
  , ("register", 1.5), ("items", 1.0), ("labels", 1.0), ("limits", 0.5) ]

stem :: String -> String
stem t
  | n > 4 && "ies" `endsWith` t = take (n - 3) t ++ "y"
  | n > 4 && "ing" `endsWith` t = take (n - 3) t
  | n > 3 && "s" `endsWith` t && not ("ss" `endsWith` t) = take (n - 1) t
  | otherwise = t
  where
    n = length t
    endsWith suf s = suf == drop (length s - length suf) s

-- | Lower-case ASCII @[a-z0-9]+@ runs longer than two characters, minus
-- stop words, stemmed.
tokens :: String -> [String]
tokens text = [stem t | t <- runs (map toLower text), length t > 2, t `Set.notMember` stop]
  where
    ok c = isAsciiLower c || isDigit c
    runs s = case dropWhile (not . ok) s of
      [] -> []
      s' -> let (w, rest) = span ok s' in w : runs rest

-- | The memorable name in front of an item's mechanism sentence; canon
-- items carry no colon and are returned whole (clipped to 60).
handle :: String -> String
handle item = case break (== ':') item of
  (h, ':' : _) | length h <= width -> strip h
  _ | length item <= width -> item
    | otherwise -> stripEnd (take (width - 1) item) ++ "…"
  where
    width = 60
    stripEnd = reverse . dropWhile isSpace . reverse

data Instrument = Instrument
  { name :: String
  , tier :: String
  , kind :: String
  , of_ :: String
  , score :: Double
  , hits :: [String]                         -- ^ query tokens that matched
  , axis :: String
  , axisNote :: String
  , members :: [(String, String)]            -- ^ (handle, full item text)
  , edges :: [(String, String, String)]      -- ^ (from handle, to handle, label)
  , probes :: [(String, String, String)]     -- ^ (horizon, handle, next question)
  , questions :: [String]                    -- ^ first question, changed question
  , limits :: [String]
  } deriving (Eq, Show)

instrument :: Ideolist -> Instrument
instrument l = Instrument
  { name = l.name
  , tier = field "tier" "session" src
  , kind = field "kind" "list" src
  , of_ = l.of_
  , score = 0
  , hits = []
  , axis = field "axis" "" ser
  , axisNote = field "note" "" ser
  , members = [(handle it, it) | it <- l.items]
  , edges = [ (handle (field "from" "" e), handle (field "to" "" e), field "label" "" e)
            | e <- map Just (arr "relations" src) ]
  , probes = [ (field "horizon" "" p, handle (field "item" "" p), field "next_question" "" p)
             | p <- map Just (arr "priorities" src) ]
  , questions = [q | k <- ["first_question", "changed_question"], Just q <- [nonEmpty (field k "" ex)]]
  , limits = boundary (src >>= (!? "boundary_claim"))
  }
  where
    src = l.source
    ser = src >>= (!? "seriation")
    ex = src >>= (!? "exploration")
    field k d v = maybe d id (v >>= (!? k) >>= asString)
    arr k v = maybe [] asArray (v >>= (!? k))
    nonEmpty s = if null s then Nothing else Just s
    -- Python's list(x or []): a list of strings, a dict's keys, or a
    -- string's characters. Kept as the Python does it.
    boundary = \case
      Just (J.Array xs) -> [s | J.String s <- xs]
      -- a claim written as one sentence, or as {universe, excluded, ...}
      Just (J.Object kvs) -> [v | (_, J.String v) <- kvs]
      Just (J.String s) -> [s]
      _ -> []

-- | The searchable text of each field.
fields :: Instrument -> String -> [(String, String)]
fields inst register =
  [ ("name", replace "." " " (replace "-" " " inst.name))
  , ("of", inst.of_)
  , ("questions", unwords' inst.questions)
  , ("axis", inst.axis)
  , ("register", register)
  , ("items", unwords' [t | (_, t) <- inst.members])
  , ("labels", unwords' [lb | (_, _, lb) <- inst.edges])
  , ("limits", unwords' inst.limits) ]
  where unwords' = joinWith " "

-- | The whole catalog, both provenance tiers, indexed once per process.
data Atlas = Atlas
  { entries :: [(Instrument, M.Map String Double)]   -- ^ per instrument: token -> weighted tf
  , idf :: M.Map String Double
  }

atlas :: IO Atlas
atlas = do
  canon <- Canon.lists Canon.Canon
  grown <- Canon.lists Canon.Grown
  let entries = [(instrument l, tfOf l) | l <- canon ++ grown]
      df = M.fromListWith (+) [(t, 1 :: Int) | (_, tf) <- entries, t <- M.keys tf]
      n = fromIntegral (max (length entries) 1) :: Double
  pure Atlas { entries = entries, idf = M.map (\d -> log (1 + n / fromIntegral d)) df }
  where
    tfOf l =
      let inst = instrument l
          register = maybe "" id (l.source >>= (!? "register") >>= asString)
          fs = fields inst register
       in M.fromListWith (+)
            [ (t, w) | (fname, w) <- fieldWeights, Just txt <- [lookup fname fs], t <- tokens txt ]

atlasSize :: Atlas -> Int
atlasSize a = length a.entries

-- | The top @k@ instruments for a situation; @Nothing@ filters mean "all".
-- Score is @Σ idf·log1p(tf)@ over the matched query tokens.
consult :: Atlas -> String -> Int -> Maybe String -> Maybe String -> [Instrument]
consult a query k tier' kind' =
  [ inst { score = roundTo 3 s, hits = hs }
  | (s, inst, hs) <- take k (sortOn (\(s, inst, _) -> (Down s, inst.name)) scored) ]
  where
    q = Set.toAscList (Set.fromList (tokens query))
    scored =
      [ (sum [a.idf M.! t * log1p (tf M.! t) | t <- hs], inst, hs)
      | (inst, tf) <- a.entries
      , maybe True (== inst.tier) tier'
      , maybe True (== inst.kind) kind'
      , let hs = [t | t <- q, t `M.member` tf]
      , not (null hs) ]

-- ---------------------------------------------------------------- rendering

render :: Bool -> Instrument -> String
render full inst = joinWith "\n" $
  [ "=== " ++ inst.name ++ "  [" ++ inst.tier ++ " " ++ inst.kind ++ "; score "
    ++ J.render (J.dbl inst.score) ++ "; matched: " ++ joinWith ", " inst.hits ++ "]"
  , "of: " ++ inst.of_ ]
  ++ (if null inst.axis then [] else
      [ "axis: " ++ inst.axis
      , "  Place the situation on this axis before reading the members: the neighbors of that stop are what to expect next." ])
  ++ ["members (" ++ show (length inst.members) ++ "):"]
  ++ ["  - " ++ (if full then t else h) | (h, t) <- inst.members]
  ++ (if null inst.edges then [] else
      "edges (what a move recruits or forecloses):"
      : ["  " ++ x ++ " -> " ++ y ++ ": " ++ lb | (x, y, lb) <- inst.edges])
  ++ (if null inst.probes then [] else
      "probes (the cheapest discriminating experiment already written):"
      : ["  [" ++ horizon ++ "] " ++ h ++ ": " ++ q | (horizon, h, q) <- inst.probes])
  ++ (case inst.limits of
        (lim : _) -> ["limit: " ++ lim]
        [] -> [])

-- | The coverage frame: every member of every chosen map gets a label, or
-- the audit is declared partial. Zero unlabeled elements is the gate.
renderAudit :: [Instrument] -> String -> String
renderAudit insts situation = joinWith "\n" $
  [ "COVERAGE AUDIT"
  , "Situation:", strip situation, ""
  , "For each map below, label EVERY member exactly once:"
  , "  present   — the plan contains or assumes this mechanism (say where)"
  , "  ruled-out — it cannot apply here (say why)"
  , "  unlabeled — you could not decide (say what would decide it)"
  , "Then walk each edge whose `from` member is present and state the \
    \consequence the plan did not. Finish with: zero unlabeled, or the \
    \word PARTIAL and the count.", "" ]
  ++ concat
    [ ("--- " ++ inst.name ++ ": " ++ inst.of_)
      : ["[ ] " ++ h ++ " — " ++ rest h t | (h, t) <- inst.members]
      ++ ["edge " ++ x ++ " -> " ++ y ++ ": " ++ lb | (x, y, lb) <- inst.edges]
      ++ [""]
    | inst <- insts ]
  where
    rest h t
      | h `isPrefixOf` t = dropWhile (`elem` ": ") (drop (length h) t)
      | otherwise = t

-- ---------------------------------------------------------------------- CLI

usageLine :: String
usageLine = "usage: ideonomy consult [SITUATION] [--file PATH] [--k 3] [--tier all|canon|grown] [--kind all|list|map] [--full] [--frame instrument|audit] [--from-residue TOPIC] [--store PATH] [--model CMD]"

-- | @ideonomy consult [SITUATION] [--file PATH] [--k 3] [--tier all|canon|grown]
-- [--kind all|list|map] [--full] [--frame instrument|audit]
-- [--from-residue TOPIC] [--store PATH] [--model CMD]@
cli :: [String] -> IO ()
cli argv = do
  let a = parseArgs ["full"] argv
      choice n allowed = case opt n a of
        Nothing -> pure Nothing
        Just v | v `elem` allowed -> pure (Just v)
               | otherwise -> usage ("error: --" ++ n ++ " must be one of " ++ joinWith ", " allowed ++ "\n" ++ usageLine)
      asFilter = (>>= \v -> if v == "all" then Nothing else Just v)
  tier' <- asFilter <$> choice "tier" ["all", "canon", "grown"]
  kind' <- asFilter <$> choice "kind" ["all", "list", "map"]
  frame <- maybe "instrument" id <$> choice "frame" ["instrument", "audit"]
  positional <- case positionals a of
    [] -> pure ""
    [s] -> pure s
    _ -> usage usageLine
  atl <- atlas
  case opt "from-residue" a of
    Just topic -> do
      let path = R.storePath (opt "store" a) (Just topic)
      led <- R.load path >>= either (ioError . userError . ((path ++ ": ") ++)) pure
      let open = [r | (_, r) <- led.residue, r.status == R.Open]
      if null open
        then putStrLn ("no open residue in " ++ path) >> exitWith (ExitFailure 1)
        else mapM_ (\r -> do
          let found = consult atl r.text 2 tier' kind'
          putStrLn ("residue " ++ r.id_ ++ " [" ++ R.kindName r.kind ++ "]: " ++ r.text)
          mapM_ (\inst -> putStrLn ("  -> " ++ inst.name ++ ": " ++ inst.of_)) found
          if null found then putStrLn "  -> nothing in the atlas matches; a territory to grow" else pure ()
          putStrLn "") open
    Nothing -> do
      situation <- maybe (pure positional) readFile (opt "file" a)
      if null (strip situation) then usage ("error: give a situation, --file, or --from-residue\n" ++ usageLine) else pure ()
      let insts = consult atl situation (optInt "k" 3 a) tier' kind'
      if null insts
        then putStrLn "nothing in the atlas matches; say it in other words, or this is a territory to grow"
             >> exitWith (ExitFailure 1)
        else do
          let text = if frame == "audit" then renderAudit insts situation
                     else joinWith "\n\n" (map (render (flag "full" a)) insts)
          case opt "model" a of
            Just cmd -> command (mkCommand cmd "") text >>= putStrLn
            Nothing -> putStrLn text
