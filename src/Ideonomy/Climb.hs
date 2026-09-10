-- | The list hill-climb: Gunkel's progressive loop, machine-run.
--
-- One breath per list per invocation:
--
-- 1. GROW      (cheap tier)   propose k items along neglected dimensions
-- 2. TYPOLOGY  (strong tier)  induce types over the list; name missing and
--                             underpopulated types — the climb's gradient
-- 3. GAP-FILL  (cheap tier)   targeted growth per named gap
-- 4. GATE      (strong tier)  judge every candidate: genuine category,
--                             distinct, combinatorially phrased; drops are
--                             recorded residue, not silence
-- 5. RATCHET                  keep-rate below threshold => plateau flagged;
--                             the list stops claiming easy growth
--
-- Grown lists carry @source.tier == "grown"@ and never masquerade as canon.
-- State compounds in the catalog's @grown.jsonl@ (the database's growing
-- edge) plus a per-list ledger in @corpus/climb-ledger/@, which is relative
-- to the working directory: run the driver from the repo root. Set
-- @GEMINI_API_KEY@ in the environment before running; model calls use the
-- configured account's quota.
--
-- > ideonomy climb                  # one breath over every seeded domain
-- > ideonomy climb --only strategy-generic-moves --breaths 2
-- > ideonomy climb --forever        # continuous: leaky-bucket-paced gradient ascent
--
-- Continuous mode is the calendar-free shape: spend level is a decayed sum
-- over the climb ledger's own timestamps (level = sum exp(-age/tau); the log
-- is the ledger, no second store, restart-safe). A breath is admitted when
-- level <= burst - 1; each admitted breath goes to the argmax-gradient
-- target (last keep_rate, cold starts optimistic at 1.0, ties to the
-- stalest list). Plateaued lists aren't banned — they compete with their
-- real low gradient and only win when nothing better exists. Saturated =>
-- sleep exactly the drain horizon tau*ln(level/(burst-1)). Sustained rate
-- = burst/tau breaths per hour. Run exactly one grower at a time; crashes
-- are the supervisor's job (the level survives restarts by construction).
module Ideonomy.Climb
  ( Pool, plateauKeepRate, ledgerDir
  , seedLists, loadGrown, saveGrown, loadPool, readGrownLines
  , breath, lastBreath, ledgerLevel, pickTarget, forever, epochOf, cli
  ) where

import Control.Concurrent (threadDelay)
import Control.Exception (evaluate)
import Control.Monad (foldM, forM, when)
import Data.Char (isDigit)
import Data.List (isSuffixOf, sortOn)
import qualified Data.Set as Set
import Data.Time (LocalTime, defaultTimeLocale, getCurrentTimeZone, getTimeZone, localTimeToUTC, minutesToTimeZone, parseTimeM, utc)
import Data.Time.Clock.POSIX (getPOSIXTime, utcTimeToPOSIXSeconds)
import Ideonomy.Cli (die, flag, opt, optDouble, optInt, parseArgs, positionals, usage)
import Ideonomy.Data (dataFile)
import Ideonomy.Gemini (ask, askJson, cheap, pyReprList, setKey, strong, truthy)
import Ideonomy.Json (Value (..), (!?), asArray, asInt, asNumber, asObject, asString, asStrings, dbl, int, key, list, obj, readJsonl, render, showDouble, renderSpaced, str)
import Ideonomy.List (Ideolist (..), Status (..), decode, encode)
import Ideonomy.Util (casefold, joinWith, roundTo, showFixed, strip, timestamp)
import System.Directory (createDirectoryIfMissing, doesDirectoryExist, doesFileExist, listDirectory)
import System.FilePath (takeDirectory, (</>))

-- | The grown store in memory: name-keyed, insertion-ordered, as the
-- Python dict was.
type Pool = [(String, Ideolist)]

plateauKeepRate :: Double
plateauKeepRate = 0.25

ledgerDir :: FilePath
ledgerDir = "corpus/climb-ledger"

-- ---------------------------------------------------------------- seeds

seedLists :: [Ideolist]
seedLists =
  [ mk "strategy-generic-moves"
       "a generic strategic move available to any agent in a contested field, phrased as a verb phrase"
       ["Concentrate force at the decisive point", "Trade space for time",
        "Threaten two objectives with one motion", "Deny the opponent tempo by forcing responses",
        "Change the game's boundaries rather than the position", "Commit last, after the opponent reveals",
        "Build optionality before committing force", "Escalate to de-escalate",
        "Encircle the objective to cut reinforcement", "Force a bifurcation where every branch costs the opponent"]
  , mk "somatic-signals"
       "a bodily state or signal that carries decision-relevant information, phrased as a noun phrase"
       ["The tightening chest before an overcommitment", "The exhale that precedes genuine agreement",
        "Grounded weight in the feet under pressure", "The forward lean of premature closure",
        "The gut drop of a wrong decision recognized late", "The jaw set of an unvoiced objection",
        "The softened gaze of real listening", "Breath held while hearing a half-truth",
        "The energizing clarity after a true decision", "Restlessness signaling an unnamed tension"]
  , mk "mathematical-moves"
       "a generic mathematical move that transforms a problem into a more tractable one, phrased as a verb phrase"
       ["Pass to the dual", "Quotient out the symmetry", "Linearize around a fixed point",
        "Compactify the space", "Introduce a generating function", "Exchange the order of summation",
        "Find the conserved quantity", "Relax to a continuous problem, then round",
        "Lift to a covering space", "Diagonalize", "Take the adjoint",
        "Add a dimension to separate the crossings"]
  , mk "invariant-kinds"
       "a kind of invariant — a quantity or structure preserved under a class of transformations, phrased as a noun phrase"
       ["Energy under time translation", "Parity under exchange", "Topological genus under deformation",
        "Rank under row operations", "Trace under conjugation", "The loop invariant under iteration",
        "Type under program refactoring", "Measure under measure-preserving maps",
        "Euler characteristic under triangulation", "Information under lossless encoding"]
  , mk "tactical-maneuvers"
       "a generic tactical maneuver executable within a single engagement, phrased as a verb phrase"
       ["Feint on one axis, strike on another", "Refuse the flank", "Draw the commitment, then counter",
        "Attack the seam between two responsibilities", "Commit the second wave while the first absorbs",
        "Cut the communication line before the assault", "Present a false weakness",
        "Overload one axis to unmask another", "Withdraw under cover to a prepared position",
        "Time the strike to the opponent's rotation"]
  , mk "operational-patterns"
       "a generic operational pattern for sustaining a campaign over time, phrased as a noun phrase"
       ["Rotation of fresh units through the front", "Forward staging of supplies before a tempo increase",
        "Parallel lines of advance with mutual support", "The operational pause to consolidate gains",
        "Awareness of the culminating point before overextension", "Interior lines exploited for faster reinforcement",
        "Logistics throughput as the true rate limiter", "The reserve committed only at the breakthrough",
        "Sequenced objectives, each enabling the next", "A sustainment rhythm matched to burn rate"]
  , mk "first-mover-forecloses"
       "a first-mover action that forecloses the responder's best options, phrased as a verb phrase"
       ["Seize the standard before rivals coordinate", "Lock the scarce input with long-term contracts",
        "Define the category in the audience's mind first", "Occupy the high ground that cannot be contested twice",
        "Set the default that inertia will protect", "Recruit the key talent before the market prices them",
        "File the patent that blocks the design space", "Establish the marketplace whose liquidity self-reinforces",
        "Ship the interface others build upon", "Choose the battlefield before the opponent knows there is one"]
  , mk "cooperation-mechanisms"
       "a mechanism that makes cooperation stable among self-interested parties, phrased as a noun phrase"
       ["Repeated interaction with a long shadow of the future", "Mutual vulnerability deliberately exchanged",
        "Reputation legible to future partners", "Escrow held by a neutral third party",
        "Tit-for-tat with forgiveness", "Costly signaling of commitment",
        "Shared fate through cross-shareholding", "Verification protocols in place of trust",
        "Focal points that coordinate without communication", "Graduated sanctions within a monitored commons"]
  , mk "persuasion-moves"
       "a move that legitimately shifts a person's belief or decision, phrased as a verb phrase"
       ["Steelman their position before answering it", "Let them derive the conclusion themselves",
        "Convert the abstract claim into a concrete case", "Name the shared value the proposal serves",
        "Show the cost of the status quo, not only the gain of change", "Offer a reversible first step",
        "Cite the evidence they already trust", "Make the desired path the easy path",
        "Acknowledge uncertainty to earn credibility on the certain part",
        "Ask the question whose honest answer is the argument"]
  , mk "deal-flow-sources"
       "a source or mechanism that generates a stream of potential deals, phrased as a noun phrase"
       ["Referral loops from past counterparties", "Content that makes buyers self-identify",
        "The broker network paid on completion", "Auctions watched for mispriced lots",
        "Cold outreach sequenced by trigger events", "The community whose members trade with each other first",
        "Distressed-asset lists from lenders", "Conference corridors after the panels",
        "Inbound generated by published expertise", "Partnerships with those upstream of the need"]
  , mk "psyop-patterns"
       "a generic pattern by which an influence operation shapes an audience's perception (catalogued for recognition and defense), phrased as a noun phrase"
       ["The repeated claim mistaken for the verified one", "Flooding the channel to drown the signal",
        "The manufactured consensus of coordinated voices", "Framing the question so every answer concedes it",
        "The leak timed to eclipse the inconvenient story", "The trusted-messenger relay of untrusted content",
        "Ambiguity preserved to enable deniability", "The divided audience turned against itself",
        "Prestige transferred from the credible host", "The false middle positioned between two engineered extremes"]
  ]
  where
    mk n o xs = Ideolist
      { name = n, of_ = o, items = xs, status = Open
      , madeBy = "seed(xyra-domains-2026-09-04)", parents = []
      , source = Just (obj [("tier", str "grown"), ("via", str "human seed")]) }

-- ---------------------------------------------------------------- store

-- | The non-blank lines of a JSONL file, fully read (so the file may be
-- rewritten afterwards).
readGrownLines :: FilePath -> IO [String]
readGrownLines p = do
  ls <- lines <$> readFile p
  _ <- evaluate (length ls)
  pure [l | l <- ls, not (null (strip l))]

readLists :: FilePath -> IO [Ideolist]
readLists p = readGrownLines p >>= mapM one
  where one l = either (\e -> ioError (userError (p ++ ": " ++ e))) pure (decode l)

loadGrown :: IO Pool
loadGrown = do
  p <- dataFile "grown.jsonl"
  exists <- doesFileExist p
  if not exists then pure [] else do
    ls <- readLists p
    pure (foldl (\pool l -> setPool l.name l pool) [] ls)

-- | Sorted by name, one compact record per line; untouched cold-started
-- specs (no items) don't persist.
saveGrown :: Pool -> IO ()
saveGrown pool = do
  p <- dataFile "grown.jsonl"
  createDirectoryIfMissing True (takeDirectory p)
  writeFile p (unlines [encode l | (_, l) <- sortOn fst pool, not (null l.items)])

setPool :: String -> Ideolist -> Pool -> Pool
setPool n l pool
  | any ((== n) . fst) pool = [(k, if k == n then l else v) | (k, v) <- pool]
  | otherwise = pool ++ [(n, l)]

-- | Grown store + human seeds + widen specs (cold-started, of-only).
loadPool :: IO Pool
loadPool = do
  grown <- loadGrown
  let seeded = foldl (\pool l -> if has l.name pool then pool else pool ++ [(l.name, l)]) grown seedLists
  specsPath <- dataFile "list-specs.jsonl"
  exists <- doesFileExist specsPath
  specs <- if exists then readJsonl specsPath else pure []
  foldM addSpec seeded specs
  where
    has n = any ((== n) . fst)
    addSpec pool s = do
      n <- need s "name"
      o <- need s "of"
      pure $ if has n pool then pool else pool ++ [(n, Ideolist
        { name = n, of_ = o, items = [], status = Open, madeBy = "spec(widen.py)", parents = []
        , source = Just (obj [("tier", str "grown"), ("via", str "widen.py spec, cold-started")]) })]
    need s k = maybe (ioError (userError ("list-specs.jsonl: record missing " ++ show k))) pure (s !? k >>= asString)

-- --------------------------------------------------------------- breath

breath :: Ideolist -> IO Ideolist
breath lst = do
  -- 1. GROW (cheap)
  g <- ask cheap $
    "Extend this list. " ++ frame
    ++ "Existing items:\n" ++ shown ++ "\n\n"
    ++ "Offer up to 15 distinct additions, one per line, no numbering or commentary. "
    ++ "Try a changed scale, reversal, remote analogy, or overlooked intermediate; "
    ++ "follow the move that reveals something. Match the register and conceptual "
    ++ "grain. A memorable name must carry a definite distinction, not just rename "
    ++ "an existing member."
  let cand0 = additions g

  -- 2. TYPOLOGY (strong) — the gradient
  t <- askJson strong $
    frame ++ "Existing items:\n" ++ shown ++ "\n\n"
    ++ "Induce the most revealing typology these items support. Then name "
    ++ "neglected or underpopulated types within the same item kind. Prefer "
    ++ "gaps that would change how the field is understood, not simply add "
    ++ "easy examples. Put the most fertile gaps first. Reply as JSON: "
    ++ "{\"types\": [{\"name\": str, \"members\": int}], \"missing_types\": [str], "
    ++ "\"underpopulated_types\": [str]}"
  t' <- expectObject "typology" t
  let gaps = take 3 (asStrings (key "missing_types" t') ++ asStrings (key "underpopulated_types" t'))

  -- 3. GAP-FILL (cheap, targeted)
  filled <- forM gaps $ \gap -> additions <$> ask cheap
    (frame ++ "Existing items:\n" ++ shown ++ "\n\n"
     ++ "The list neglects this type: " ++ gap ++ "\n"
     ++ "Offer up to 6 distinct additions of that type. Let an unusual "
     ++ "case refine the distinction. One per line, no numbering or "
     ++ "commentary, matching the register and conceptual grain.")
  let lowerSet = Set.fromList (map casefold have)
      cand = [c | c <- cand0 ++ concat filled, not (null c), casefold c `Set.notMember` lowerSet]

  -- 4. GATE (strong)
  judged <- askJson strong $
    "You are sharpening a curated list. " ++ frame
    ++ "Existing list:\n" ++ shown ++ "\n\nCandidates:\n"
    ++ joinWith "\n" [show i ++ ". " ++ c | (i, c) <- zip [0 :: Int ..] cand]
    ++ "\n\nFor each candidate judge: KEEP only if it is (a) a recognizable "
    ++ "member with a definite distinction, including speculative or humorous "
    ++ "members when the declared register permits; (b) distinct from every "
    ++ "existing and other kept item, not a rephrasing; (c) phrased in the "
    ++ "list's register and grain. Judge the offered mechanism, not a safer "
    ++ "substitute. A declared possibility is not a claim of established fact. "
    ++ "Reply as JSON: {\"verdicts\": [{\"i\": int, \"keep\": bool, \"why\": str}]}"
  judged' <- expectObject "gate" judged
  let verdicts = [ (cand !! i, truthy (key "keep" v), maybe (str "") id (v !? "why"))
                 | v <- asArray (key "verdicts" judged'), Just i <- [v !? "i" >>= asInt], i >= 0, i < length cand ]
      keep = [c | (c, True, _) <- verdicts]
      residue = [(c, w) | (c, False, w) <- verdicts]

  -- 5. RATCHET + PERSIST
  let rate = fromIntegral (length keep) / fromIntegral (max 1 (length cand)) :: Double
      plateau = rate < plateauKeepRate
      kept0 = [kv | kv@(k, _) <- srcKvs, k `notElem` ["seriation", "coverage", "gate", "exploration", "priorities", "primitives_exercised"]]
      src = foldl (\kvs (k, v) -> setKey k v kvs) kept0
        [ ("tier", str "grown"), ("via", str ("climb.py grow=" ++ cheap ++ " judge=" ++ strong))
        , ("typology", maybe (Array []) id (t' !? "types")), ("gaps_targeted", list gaps)
        , ("plateau", Bool plateau) ]
      out = Ideolist
        { name = lst.name, of_ = lst.of_, items = have ++ keep, status = Open
        , madeBy = "climb(breath keep_rate=" ++ showFixed 2 rate ++ ")"
        , parents = [lst.name], source = Just (Object src) }
  createDirectoryIfMissing True ledgerDir
  now <- timestamp
  appendFile (ledgerDir </> (lst.name ++ ".jsonl")) $ render (obj
    [ ("t", str now), ("before", int (length have)), ("candidates", int (length cand))
    , ("kept", int (length keep)), ("keep_rate", dbl (roundTo 3 rate)), ("gaps", list gaps)
    , ("residue", Array [obj [("item", str r), ("why", w)] | (r, w) <- residue]) ]) ++ "\n"
  putStrLn ("  " ++ lst.name ++ ": " ++ show (length have) ++ " -> " ++ show (length out.items)
            ++ " (cand " ++ show (length cand) ++ ", keep_rate " ++ showFixed 2 rate
            ++ (if plateau then ", PLATEAU" else "") ++ ") gaps: " ++ pyReprList gaps)
  pure out
  where
    have = lst.items
    shown = joinWith "\n" ["- " ++ x | x <- have]
    srcKvs = maybe [] asObject lst.source
    frame = "Each item is: " ++ lst.of_ ++ ".\n"
      ++ concat [f ++ ": " ++ renderSpaced v ++ "\n" | f <- ["register", "mode", "boundary_claim"], Just v <- [lookup f srcKvs]]
    -- one item per line, bullets and numbering-free
    additions reply = [stripChars " -*\t" x | x <- lines reply, not (null (strip x))]
    stripChars cs = dropWhile (`elem` cs) . reverse . dropWhile (`elem` cs) . reverse
    expectObject what v = case v of
      Object _ -> pure v
      _ -> ioError (userError ("climb: " ++ what ++ " reply is not a JSON object: " ++ take 200 (render v)))

-- ----------------------------------------------------------- continuous

-- | Seconds since the epoch of an ISO-8601 stamp, as Python's
-- @datetime.fromisoformat(s).timestamp()@: naive stamps are local time;
-- @Z@ and @±HH:MM@ suffixes are honoured.
epochOf :: String -> IO Double
epochOf s = do
  let (core, rest) = splitAt 19 s
      (frac, zone) = span (\c -> c == '.' || isDigit c) rest
  lt <- maybe (ioError (userError ("bad timestamp " ++ show s))) pure
          (parseTimeM False defaultTimeLocale "%Y-%m-%dT%H:%M:%S" core :: Maybe LocalTime)
  utcTime <- case zone of
    "" -> do
      z0 <- getCurrentTimeZone
      z1 <- getTimeZone (localTimeToUTC z0 lt)
      pure (localTimeToUTC z1 lt)
    "Z" -> pure (localTimeToUTC utc lt)
    (sign : hhmm) | sign `elem` "+-", Just mins <- offsetMinutes hhmm ->
      pure (localTimeToUTC (minutesToTimeZone (if sign == '-' then negate mins else mins)) lt)
    _ -> ioError (userError ("bad timestamp zone " ++ show s))
  let fraction = if null frac then 0 else read ('0' : frac) :: Double
  pure (realToFrac (utcTimeToPOSIXSeconds utcTime) + fraction)
  where
    offsetMinutes x = case filter (/= ':') x of
      [a, b, c, d] | all isDigit [a, b, c, d] -> Just (read [a, b] * 60 + read [c, d])
      _ -> Nothing

-- | @(keep_rate, epoch)@ of the list's most recent breath; optimistic cold
-- start. Regate entries are skipped: survival rate is not growth yield.
lastBreath :: String -> IO (Double, Double)
lastBreath n = do
  let path = ledgerDir </> (n ++ ".jsonl")
  exists <- doesFileExist path
  if not exists then pure (1.0, 0.0) else do
    entries <- readJsonl path
    go (reverse entries)
  where
    go [] = pure (1.0, 0.0)
    go (e : rest)
      | (e !? "by" >>= asString) == Just "fable-regate" = go rest
      | otherwise = do
          rate <- maybe (ioError (userError ("ledger entry without keep_rate: " ++ n))) pure (e !? "keep_rate" >>= asNumber)
          t <- maybe (ioError (userError ("ledger entry without t: " ++ n))) pure (e !? "t" >>= asString)
          (,) rate <$> epochOf t

-- | Decayed breath count over the whole ledger — the spend level.
ledgerLevel :: Double -> IO Double
ledgerLevel tauS = do
  now <- realToFrac <$> getPOSIXTime
  exists <- doesDirectoryExist ledgerDir
  files <- if exists then filter (".jsonl" `isSuffixOf`) <$> listDirectory ledgerDir else pure []
  stamps <- concat <$> forM files (\f -> readJsonl (ledgerDir </> f) >>= mapM stamp)
  pure (sum [exp (negate (now - t) / tauS) | t <- stamps])
  where
    stamp e = maybe (ioError (userError "ledger entry without t")) epochOf (e !? "t" >>= asString)

-- | Argmax gradient: highest last keep_rate, ties to the stalest list.
pickTarget :: Pool -> IO String
pickTarget [] = ioError (userError "climb: no lists to climb")
pickTarget pool = do
  scored <- forM pool (\(n, _) -> (\(r, t) -> (n, (r, negate t))) <$> lastBreath n)
  pure (fst (foldl1 (\m x -> if snd x > snd m then x else m) scored))

forever :: Double -> Double -> IO ()
forever burst tauHours = do
  when (burst <= 1) (die "--burst must exceed 1")
  putStrLn ("continuous climb: burst " ++ showDouble burst ++ ", tau " ++ showDouble tauHours ++ "h "
            ++ "(sustained " ++ showFixed 2 (burst / tauHours) ++ " breaths/h)")
  loop
  where
    tauS = tauHours * 3600
    loop = do
      level <- ledgerLevel tauS
      if level > burst - 1
        then do
          let horizon = tauS * log (level / (burst - 1))
          putStrLn ("  level " ++ showFixed 2 level ++ "/" ++ showDouble burst ++ " — draining " ++ showFixed 0 (horizon / 60) ++ "m")
          threadDelay (ceiling (horizon * 1e6))
        else do
          pool <- loadPool            -- re-read each breath: widen feeds climb live
          n <- pickTarget pool
          l <- maybe (ioError (userError ("no list named " ++ show n))) pure (lookup n pool)
          l' <- breath l
          saveGrown (setPool n l' pool)
      loop

-- ------------------------------------------------------------------ CLI

-- | @ideonomy climb [--only NAME] [--breaths 1] [--forever] [--burst 6.0] [--tau-hours 6.0]@
cli :: [String] -> IO ()
cli argv = do
  let a = parseArgs ["forever"] argv
  case positionals a of
    [] -> pure ()
    _ -> usage "usage: ideonomy climb [--only NAME] [--breaths 1] [--forever] [--burst 6.0] [--tau-hours 6.0]"
  if flag "forever" a then forever (optDouble "burst" 6 a) (optDouble "tau-hours" 6 a) else do
    pool <- loadPool
    let only = maybe "" id (opt "only" a)
        breaths = optInt "breaths" 1 a
        targets = [n | (n, _) <- pool, null only || n == only]
    pool' <- foldM (\p b -> putStrLn ("breath " ++ show b ++ "/" ++ show breaths) >> foldM step p targets) pool [1 .. breaths]
    grownPath <- dataFile "grown.jsonl"
    putStrLn ("grown store: " ++ show (length pool') ++ " lists / " ++ show (sum [length l.items | (_, l) <- pool'])
              ++ " items -> " ++ grownPath)
  where
    step pool n = do
      l <- maybe (ioError (userError ("no list named " ++ show n))) pure (lookup n pool)
      if maybe False truthy (l.source >>= (!? "plateau"))
        then putStrLn ("  " ++ n ++ ": plateaued, skipping") >> pure pool
        else do
          l' <- breath l
          let pool' = setPool n l' pool
          saveGrown pool'
          pure pool'
