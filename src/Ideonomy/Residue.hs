-- | The cross-session residue ledger — P-10 made durable.
--
-- The respiratory engine's thesis is that what carries structure forward
-- across breaths is the residue: the unexplained, the failed reframe, the
-- surviving attack, the named-but-unfilled gap, the contested judgment.
-- Within a session that residue lives in context. Across sessions it
-- evaporates unless it is persisted and /cited before the next expansion/.
-- This module is that durable seed store, with the distinction the engine
-- cares about made executable:
--
-- * 'Metabolism' breath — opened on prior residue and seeded, resolved, or
--   adjudicated (dropped/deferred) some of it: the work compounded.
-- * 'Churn' breath — compressed/added without ever engaging prior residue:
--   motion without gain.
--
-- The classifier is an anti-forgetting aid, not an anti-adversarial one: an
-- operator determined to game it (e.g. a last-minute @seed@ after unrelated
-- work) can — the ledger records what was touched, not whether the touching
-- was sincere. Cross-model or human audit (M6) is the backstop where that
-- matters.
--
-- Organon: P31 episodic-memory + P32 variant-archive + P37 residue-seed +
-- P30 ledger. JSON-backed, model-agnostic. CLI: @ideonomy residue@.
--
-- Every operation is pure, @Ledger -> Either String (x, Ledger)@; the CLI is
-- load / mutate / save with no locking, so concurrent invocations against
-- one store are last-writer-wins. Scope ledgers per topic (one writer each).
module Ideonomy.Residue
  ( Kind (..), kinds, kindName, readKind
  , Status (..), statusName, readStatus
  , Breath (..), breathName, readBreath
  , Ruling (..)
  , Residue (..), Session (..), Ledger (..), Score (..)
  , emptyLedger, current
  , openSession, add, seed, resolve, closeSession, score
  , toValue, fromValue, save, load, storePath
  , cli
  ) where

import Data.List (sortOn)
import Ideonomy.Cli (Args, flag, opt, parseArgs, positionals, usage)
import Ideonomy.Json (Value (..), (!?), asInt, asString, asStrings, int, list, obj, str)
import qualified Ideonomy.Json as J
import Ideonomy.Util (joinWith, roundTo, timestamp)
import System.Directory (createDirectoryIfMissing, doesFileExist)
import System.Exit (ExitCode (..), exitWith)
import System.FilePath (takeDirectory, (</>))
import System.IO (hPutStrLn, stderr)

-- ------------------------------------------------------------------ kinds

-- | Residue kinds, each tied to the premier skill that tends to produce it.
data Kind
  = Anomaly | FailedReframe | SurvivingAttack | NamedGap
  | ContestedAxis | UnexplainedCore | OpenQuestion
  deriving (Eq, Ord, Show, Enum, Bounded)

kinds :: [(Kind, String)]
kinds =
  [ (Anomaly, "a sensed misfit that resisted explanation (P2)")
  , (FailedReframe, "a reframe the MDL gate reverted as cosmetic (P-3)")
  , (SurvivingAttack, "an objection that landed or a claim that barely held (P-4)")
  , (NamedGap, "a coverage-denominator cell with no filler yet (P-11)")
  , (ContestedAxis, "a value-axis where independent judges disagreed (P-9)")
  , (UnexplainedCore, "the residual a distillation could not compress (P36)")
  , (OpenQuestion, "a question left open at session close")
  ]

kindName :: Kind -> String
kindName = \case
  Anomaly -> "anomaly"
  FailedReframe -> "failed_reframe"
  SurvivingAttack -> "surviving_attack"
  NamedGap -> "named_gap"
  ContestedAxis -> "contested_axis"
  UnexplainedCore -> "unexplained_core"
  OpenQuestion -> "open_question"

readKind :: String -> Either String Kind
readKind s = case [k | (k, _) <- kinds, kindName k == s] of
  (k : _) -> Right k
  [] -> Left ("unknown residue kind: '" ++ s ++ "' (one of " ++ joinWith ", " (map (kindName . fst) kinds) ++ ")")

data Status = Open | Seeded | Resolved | Dropped | Deferred
  deriving (Eq, Ord, Show, Enum, Bounded)

statusName :: Status -> String
statusName = \case
  Open -> "open"
  Seeded -> "seeded"
  Resolved -> "resolved"
  Dropped -> "dropped"
  Deferred -> "deferred"

readStatus :: String -> Either String Status
readStatus s = case [st | st <- [minBound .. maxBound], statusName st == s] of
  (st : _) -> Right st
  [] -> Left ("status " ++ show s ++ "; one of " ++ joinWith ", " (map statusName [minBound .. maxBound]))

-- | Still carried forward: surfaced at the next open, counted as open residue.
carried :: Status -> Bool
carried st = st `elem` [Open, Seeded, Deferred]

-- | How a closed session breathed. Absent while the session is open.
data Breath = Metabolism | Churn deriving (Eq, Show)

breathName :: Breath -> String
breathName Metabolism = "metabolism"
breathName Churn = "churn"

readBreath :: String -> Either String (Maybe Breath)
readBreath "" = Right Nothing
readBreath "metabolism" = Right (Just Metabolism)
readBreath "churn" = Right (Just Churn)
readBreath s = Left ("breath " ++ show s ++ "; one of metabolism, churn, or empty")

-- | What 'resolve' rules: settled, ruled out, or accepted as visible debt.
data Ruling = Resolve | Drop | Defer deriving (Eq, Show)

-- ---------------------------------------------------------------- records

data Residue = Residue
  { id_ :: String
  , text :: String
  , kind :: Kind
  , status :: Status
  , origin :: String           -- ^ skill/breath that produced it
  , bornSession :: String
  , touchedSession :: String
  , notes :: [String]
  } deriving (Eq, Show)

data Session = Session
  { id_ :: String
  , opened :: String
  , citedPrior :: Int          -- ^ how many prior residue items were surfaced at open
  , added :: [String]
  , seeded :: [String]
  , resolved :: [String]
  , adjudicated :: [String]    -- ^ dropped/deferred here
  , closed :: String
  , breath :: Maybe Breath
  , note :: String             -- ^ free-text close summary
  } deriving (Eq, Show)

data Ledger = Ledger
  { topic :: String
  , residue :: [(String, Residue)]   -- ^ keyed by id, insertion order kept
  , sessions :: [Session]
  , seq_ :: Int
  } deriving (Eq, Show)

emptyLedger :: Ledger
emptyLedger = Ledger { topic = "default", residue = [], sessions = [], seq_ = 0 }

data Score = Score
  { openResidue :: Int
  , strict :: Double
  , lenient :: Double
  , metabolismBreaths :: Int
  , churnBreaths :: Int
  } deriving (Eq, Show)

-- ------------------------------------------------------------ persistence

residueValue :: Residue -> Value
residueValue r = obj
  [ ("id", str r.id_), ("text", str r.text), ("kind", str (kindName r.kind))
  , ("status", str (statusName r.status)), ("origin", str r.origin)
  , ("born_session", str r.bornSession), ("touched_session", str r.touchedSession)
  , ("notes", list r.notes) ]

sessionValue :: Session -> Value
sessionValue s = obj
  [ ("id", str s.id_), ("opened", str s.opened), ("cited_prior", int s.citedPrior)
  , ("added", list s.added), ("seeded", list s.seeded), ("resolved", list s.resolved)
  , ("adjudicated", list s.adjudicated), ("closed", str s.closed)
  , ("breath", str (maybe "" breathName s.breath)), ("note", str s.note) ]

toValue :: Ledger -> Value
toValue l = obj
  [ ("topic", str l.topic)
  , ("residue", obj [(k, residueValue r) | (k, r) <- l.residue])
  , ("sessions", Array (map sessionValue l.sessions))
  , ("_seq", int l.seq_) ]

-- | Unknown keys are ignored: a store written by a future version with
-- extra fields must still load.
fromValue :: Value -> Either String Ledger
fromValue v = do
  rs <- mapM (\(k, rv) -> (,) k <$> residueFrom rv) (maybe [] J.asObject (v !? "residue"))
  ss <- mapM sessionFrom (maybe [] J.asArray (v !? "sessions"))
  pure Ledger
    { topic = strOr "default" "topic" v
    , residue = rs
    , sessions = ss
    , seq_ = maybe 0 id (v !? "_seq" >>= asInt) }

residueFrom :: Value -> Either String Residue
residueFrom v = do
  i <- need "id" v
  t <- need "text" v
  k <- need "kind" v >>= readKind
  st <- maybe (Right Open) readStatus (v !? "status" >>= asString)
  pure Residue
    { id_ = i, text = t, kind = k, status = st
    , origin = strOr "" "origin" v
    , bornSession = strOr "" "born_session" v
    , touchedSession = strOr "" "touched_session" v
    , notes = maybe [] asStrings (v !? "notes") }

sessionFrom :: Value -> Either String Session
sessionFrom v = do
  i <- need "id" v
  o <- need "opened" v
  b <- readBreath (strOr "" "breath" v)
  pure Session
    { id_ = i, opened = o
    , citedPrior = maybe 0 id (v !? "cited_prior" >>= asInt)
    , added = strs "added", seeded = strs "seeded", resolved = strs "resolved"
    , adjudicated = strs "adjudicated"
    , closed = strOr "" "closed" v, breath = b, note = strOr "" "note" v }
  where strs k = maybe [] asStrings (v !? k)

need :: String -> Value -> Either String String
need k v = maybe (Left ("record missing " ++ show k)) Right (v !? k >>= asString)

strOr :: String -> String -> Value -> String
strOr d k v = maybe d id (v !? k >>= asString)

save :: FilePath -> Ledger -> IO ()
save path l = do
  createDirectoryIfMissing True (takeDirectory path)
  writeFile path (J.renderIndent 2 (toValue l))

-- | A missing file is an empty ledger; a corrupt one is the error.
load :: FilePath -> IO (Either String Ledger)
load path = do
  exists <- doesFileExist path
  if not exists then pure (Right emptyLedger)
  else (>>= fromValue) <$> J.parseFile path

-- | @--store@ wins; otherwise @.residue/<topic>.json@ with topic @ledger@.
storePath :: Maybe String -> Maybe String -> FilePath
storePath store topic' = maybe (".residue" </> (maybe "ledger" id topic' ++ ".json")) id store

-- ------------------------------------------------------- session lifecycle

current :: Ledger -> Maybe Session
current l = case reverse l.sessions of
  (s : _) | null s.closed -> Just s
  _ -> Nothing

requireOpen :: Ledger -> Either String Session
requireOpen l = maybe (Left "no open session; run `open` first (it surfaces prior residue — the gate)") Right (current l)

getResidue :: String -> Ledger -> Either String Residue
getResidue rid l = maybe (Left ("unknown residue id: '" ++ rid ++ "'")) Right (lookup rid l.residue)

putResidue :: Residue -> Ledger -> Ledger
putResidue r l = l { residue = [(k, if k == r.id_ then r else x) | (k, x) <- l.residue] }

-- | Replace the open session (the last one).
putSession :: Session -> Ledger -> Ledger
putSession s l = l { sessions = init l.sessions ++ [s] }

-- | Start a session and surface the open residue that must be cited (the
-- gate). Returns the session and the carried residue sorted by id.
openSession :: String -> Ledger -> Either String ((Session, [Residue]), Ledger)
openSession now l = case current l of
  Just _ -> Left "a session is already open; close it first"
  Nothing ->
    let n = l.seq_ + 1
        carriedNow = [r | (_, r) <- l.residue, carried r.status]
        sess = Session
          { id_ = 's' : show n, opened = now, citedPrior = length carriedNow
          , added = [], seeded = [], resolved = [], adjudicated = []
          , closed = "", breath = Nothing, note = "" }
     in Right ((sess, sortOn (.id_) carriedNow), l { seq_ = n, sessions = l.sessions ++ [sess] })

add :: String -> Kind -> String -> Ledger -> Either String (Residue, Ledger)
add text' k origin' l = do
  sess <- requireOpen l
  let n = l.seq_ + 1
      rid = 'r' : show n
      r = Residue
        { id_ = rid, text = text', kind = k, status = Open, origin = origin'
        , bornSession = sess.id_, touchedSession = sess.id_, notes = [] }
  pure (r, putSession sess { added = sess.added ++ [rid] } l { seq_ = n, residue = l.residue ++ [(rid, r)] })

-- | Mark a prior residue item as fuel for the current expansion.
seed :: String -> Ledger -> Either String (Residue, Ledger)
seed rid l = do
  sess <- requireOpen l
  r <- getResidue rid l
  let r' = r { status = Seeded, touchedSession = sess.id_ }
      sess' = if rid `elem` sess.seeded then sess else sess { seeded = sess.seeded ++ [rid] }
  pure (r', putSession sess' (putResidue r' l))

resolve :: String -> String -> Ruling -> Ledger -> Either String (Residue, Ledger)
resolve rid note' ruling l = do
  sess <- requireOpen l
  r <- getResidue rid l
  let st = case ruling of
        Drop -> Dropped
        Defer -> Deferred
        Resolve -> Resolved
      r' = r { status = st, touchedSession = sess.id_
             , notes = r.notes ++ [note' | not (null note')] }
      -- ruling out IS engagement
      sess' = case ruling of
        Resolve | rid `elem` sess.resolved -> sess
                | otherwise -> sess { resolved = sess.resolved ++ [rid] }
        _ | rid `elem` sess.adjudicated -> sess
          | otherwise -> sess { adjudicated = sess.adjudicated ++ [rid] }
  pure (r', putSession sess' (putResidue r' l))

-- | Finalize the session and classify the breath. Metabolism iff prior
-- residue existed, was surfaced, and was engaged — where "engaged" means
-- seeding, resolving, dropping, or deferring an item born in an EARLIER
-- session (ruling a prior gap out is adjudication, not churn). Touching
-- only residue added this same session is motion within the session, not
-- compounding across them.
closeSession :: String -> Ledger -> Either String (Session, Ledger)
closeSession now l = do
  sess <- requireOpen l
  let engaged = or [r.bornSession /= sess.id_
                   | rid <- sess.seeded ++ sess.resolved ++ sess.adjudicated
                   , Just r <- [lookup rid l.residue]]
      sess' = sess { closed = now
                   , breath = Just (if sess.citedPrior > 0 && engaged then Metabolism else Churn) }
  pure (sess', putSession sess' l)

-- ---------------------------------------------------- scoring (P30 dual)

score :: Ledger -> Score
score l = Score
  { openResidue = count carried
  , strict = roundTo 4 (fromIntegral adjudicatedN / total)
  , lenient = roundTo 4 (fromIntegral (adjudicatedN + count (== Deferred)) / total)
  , metabolismBreaths = length [() | Just Metabolism <- breaths]
  , churnBreaths = length [() | Just Churn <- breaths]
  }
  where
    count p = length [() | (_, r) <- l.residue, p r.status]
    total = fromIntegral (max 1 (length l.residue)) :: Double
    adjudicatedN = count (== Resolved) + count (== Dropped)
    breaths = [s.breath | s <- l.sessions, not (null s.closed)]

-- --------------------------------------------------------------------- CLI

data Cmd
  = CmdOpen
  | CmdAdd String Kind String
  | CmdSeed [String]
  | CmdResolve String String Ruling
  | CmdStatus
  | CmdClose String

usageLine :: String
usageLine = "usage: ideonomy residue [--store PATH] [--topic TOPIC] open | add TEXT --kind KIND [--from ORIGIN] | seed ID... | resolve ID [--note TEXT] [--drop | --defer] | status | close [--note TEXT]"

parseCmd :: Args -> Either String Cmd
parseCmd a = case positionals a of
  ["open"] -> Right CmdOpen
  ["add", t] -> do
    k <- maybe (Left "add requires --kind") readKind (opt "kind" a)
    pure (CmdAdd t k (maybe "" id (opt "from" a)))
  ("seed" : ids@(_ : _)) -> Right (CmdSeed ids)
  ["resolve", rid]
    | flag "drop" a && flag "defer" a -> Left "--drop and --defer are mutually exclusive"
    | otherwise -> Right (CmdResolve rid (maybe "" id (opt "note" a))
                          (if flag "drop" a then Drop else if flag "defer" a then Defer else Resolve))
  ["status"] -> Right CmdStatus
  ["close"] -> Right (CmdClose (maybe "" id (opt "note" a)))
  _ -> Left ""

-- | Pure dispatch: the new ledger and the lines to print.
dispatch :: String -> FilePath -> Cmd -> Ledger -> Either String (Ledger, [String])
dispatch now path cmd led = case cmd of
  CmdOpen -> do
    ((sess, carriedNow), led') <- openSession now led
    let header = "session " ++ sess.id_ ++ " open  (topic=" ++ led.topic ++ ", store=" ++ path ++ ")"
        body
          | null carriedNow = ["no prior residue — a clean start."]
          | otherwise =
              ("prior residue to engage before you expand (" ++ show (length carriedNow) ++ "):")
              : ["  " ++ r.id_ ++ " [" ++ kindName r.kind ++ "/" ++ statusName r.status ++ "] " ++ r.text | r <- carriedNow]
              ++ ["→ seed the ones fueling this work, resolve/drop what's done, or this closes as a CHURN breath."]
    pure (led', header : body)
  CmdAdd t k o -> do
    (r, led') <- add t k o led
    pure (led', ["added " ++ r.id_ ++ " [" ++ kindName r.kind ++ "] " ++ r.text])
  CmdSeed ids -> do
    let step (l, out) rid = do
          (r, l') <- seed rid l
          pure (l', out ++ ["seeded " ++ r.id_])
    foldl (\acc rid -> acc >>= (`step` rid)) (Right (led, [])) ids
  CmdResolve rid n ruling -> do
    (r, led') <- resolve rid n ruling led
    pure (led', [statusName r.status ++ " " ++ r.id_])
  CmdStatus -> do
    let sc = score led
        pct x = show (round (x * 100) :: Integer) ++ "%"
        byKind = [ (kindName k, length [() | (_, r) <- led.residue, r.kind == k, carried r.status])
                 | k <- [minBound .. maxBound] ]
    pure (led,
      [ "store=" ++ path
      , "topic=" ++ led.topic ++ "  open_residue=" ++ show sc.openResidue
        ++ "  strict=" ++ pct sc.strict ++ "  lenient=" ++ pct sc.lenient
      , "breaths: metabolism=" ++ show sc.metabolismBreaths ++ "  churn=" ++ show sc.churnBreaths ]
      ++ ["  " ++ k ++ ": " ++ show n | (k, n) <- sortOn fst byKind, n > 0])
  CmdClose n -> do
    (sess, led') <- closeSession now led
    let sess' = if null n then sess else sess { note = n }
    pure (putSession sess' led',
      [ "session " ++ sess'.id_ ++ " closed as a " ++ upper (maybe "" breathName sess'.breath)
        ++ " breath  (cited=" ++ show sess'.citedPrior ++ " seeded=" ++ show (length sess'.seeded)
        ++ " resolved=" ++ show (length sess'.resolved) ++ " added=" ++ show (length sess'.added) ++ ")" ])
  where
    upper = map (\c -> if c >= 'a' && c <= 'z' then toEnum (fromEnum c - 32) else c)

-- | @ideonomy residue [--store PATH] [--topic TOPIC] <open|add|seed|resolve|status|close> ...@
-- Load / mutate / save; an error exits 2 without saving (nothing mutated
-- is saved).
cli :: [String] -> IO ()
cli argv = do
  let a = parseArgs ["drop", "defer"] ["store", "topic", "kind", "from", "note"] argv
      path = storePath (opt "store" a) (opt "topic" a)
  cmd <- either (\e -> usage (if null e then usageLine else "error: " ++ e ++ "\n" ++ usageLine)) pure (parseCmd a)
  loaded <- load path
  led0 <- either (\e -> failWith ("error: cannot read ledger " ++ path ++ ": " ++ e)) pure loaded
  let led = maybe led0 (\t -> led0 { topic = t }) (opt "topic" a)
  now <- timestamp
  case dispatch now path cmd led of
    Left e -> failWith ("error: " ++ e ++ "  [store: " ++ path ++ "]")
    Right (led', out) -> do
      mapM_ putStrLn out
      save path led'
  where
    failWith :: String -> IO a
    failWith msg = hPutStrLn stderr msg >> exitWith (ExitFailure 2)
