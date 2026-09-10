-- | Ideonomic trials — adversarial adjudication of one idea (P22 + P21 + M4).
--
-- The evaluation bottleneck, solved as a courtroom instead of a scalar: an
-- /advocate/ builds the strongest case for the claim, an /adversary/ the
-- strongest case against, they cross-examine for a fixed number of rounds,
-- and a separate /judge/ issues a verdict with grounds. The burden of proof
-- is set by claim class: an unproven claim is rejected, never
-- split-the-difference.
--
-- Balance is structural, not hoped for:
--
--   * both sides get the identical prompt scaffold and the same number of
--     turns;
--   * no role may hold two seats (an idea must not adjudicate itself) —
--     roles are named, and the gate compares names;
--   * 'balancedTrial' re-runs the trial with advocate/adversary models
--     swapped — a verdict that flips under the swap is model bias, not idea
--     quality, and comes back 'Contested'.
--
-- Contested and rejected outcomes feed the residue ledger (P-10), so trials
-- compound instead of evaporating. Roles are injectable for offline
-- testing; back them with 'command' for real heterogeneous panels:
-- @ideonomy trial@.
module Ideonomy.Trial
  ( Burden (..), burdenName, readBurden, burdenThreshold
  , Verdict (..), verdictName, Seat (..), seatName
  , Role (..), Turn (..), Trial (..)
  , lean, verdict, report, residueItems, trial, balancedTrial, cli
  ) where


import Ideonomy.Cli (flag, opt, optInt, opts, parseArgs, positionals, require, usage)
import Ideonomy.Models (Model, command, lastLabeled, lastLean, mkCommand)
import Ideonomy.Util (fill, joinWith, roundTo, showSigned)

data Burden = Preponderance | High deriving (Eq, Show)

burdenName :: Burden -> String
burdenName Preponderance = "preponderance"
burdenName High = "high"

readBurden :: String -> Either String Burden
readBurden "preponderance" = Right Preponderance
readBurden "high" = Right High
readBurden s = Left ("unknown burden " ++ show s ++ "; one of high, preponderance")

burdenThreshold :: Burden -> Double
burdenThreshold Preponderance = 0.15
burdenThreshold High = 0.6

data Verdict = Upheld | Rejected | Contested deriving (Eq, Show)

verdictName :: Verdict -> String
verdictName Upheld = "UPHELD"
verdictName Rejected = "REJECTED"
verdictName Contested = "CONTESTED"

data Seat = Advocate | Adversary | Judge deriving (Eq, Show)

seatName :: Seat -> String
seatName Advocate = "advocate"
seatName Adversary = "adversary"
seatName Judge = "judge"

-- | A named model. Names are what the role gate compares: the same name in
-- two seats is self-adjudication.
data Role = Role { name :: String, model :: Model }

data Turn = Turn { role :: Seat, speaker :: String, text :: String }
  deriving (Eq, Show)

data Trial = Trial
  { claim :: String
  , burden :: Burden
  , turns :: [Turn]
  , leans :: [Double]                 -- ^ one per judge
  , grounds :: [String]
  , forcedContested :: Maybe String   -- ^ set by 'balancedTrial'
  } deriving (Eq, Show)

caseTemplate :: String
caseTemplate =
  "You are the {side} in a structured trial of an idea. Build the single "
  ++ "strongest case {direction} the claim — concrete, specific, no hedging. "
  ++ "You will be cross-examined on it.\n\nClaim: {claim}\n{context}"

crossTemplate :: String
crossTemplate =
  "You are the {side} in a structured trial of an idea. Below is the "
  ++ "opposing side's latest argument. Answer its strongest point directly — "
  ++ "concede what is true, destroy what is not. Do not repeat your case.\n\n"
  ++ "Claim: {claim}\n\nOpposing argument:\n{opposing}"

judgeTemplate :: String
judgeTemplate =
  "You are the judge in a structured trial of an idea. Both sides argued "
  ++ "under equal terms; the full transcript is below. Weigh only the "
  ++ "arguments, not the eloquence. Reply with exactly two lines:\n"
  ++ "LEAN: <-1.0 (claim destroyed) .. +1.0 (claim proven), 0 if the "
  ++ "arguments genuinely balance>\n"
  ++ "GROUNDS: <one sentence naming the argument that decided it>\n\n"
  ++ "Claim: {claim}\n\nTranscript:\n{transcript}"

lean :: Trial -> Double
lean t = case t.leans of
  [] -> 0
  xs -> roundTo 3 (sum xs / fromIntegral (length xs))

-- | UPHELD only past the burden; unproven is REJECTED; judge sign-split or
-- swap instability is CONTESTED — never averaged away.
verdict :: Trial -> Verdict
verdict t
  | Just _ <- t.forcedContested = Contested
  | 1 `elem` signs && (-1) `elem` signs = Contested
  | lean t >= burdenThreshold t.burden = Upheld
  | otherwise = Rejected
  where
    signs = [if x > 0.15 then 1 else if x < -0.15 then -1 else 0 :: Int | x <- t.leans]

report :: Trial -> String
report t = joinWith "\n" $
  [ "claim: " ++ t.claim
  , "verdict: " ++ verdictName (verdict t) ++ "  (lean " ++ showSigned 2 (lean t) ++ ", burden "
      ++ burdenName t.burden ++ "=" ++ showSigned 2 (burdenThreshold t.burden) ++ ")" ]
  ++ maybe [] (\why -> ["contested because: " ++ why]) t.forcedContested
  ++ ["grounds: " ++ g | g <- t.grounds]
  ++ [""]
  ++ ["[" ++ seatName x.role ++ ":" ++ x.speaker ++ "] " ++ x.text | x <- t.turns]

-- | CONTESTED verdicts are residue (@(text, kind)@, kind always
-- @contested_axis@); a clean verdict already closed.
residueItems :: Trial -> [(String, String)]
residueItems t
  | verdict t /= Contested = []
  | otherwise = [("trial contested: " ++ t.claim ++ " (" ++ why ++ ")", "contested_axis")]
  where why = maybe "judges split on sign" id t.forcedContested

-- | Run one trial. Gate: three distinct roles, or this is self-adjudication.
trial :: String -> Role -> Role -> [Role] -> Int -> Burden -> String -> IO (Either String Trial)
trial claim advocate adversary judges rounds burden context
  | advocate.name == adversary.name = pure (Left
      "advocate and adversary are the same role: an idea must not prosecute and defend itself.")
  | any (\j -> j.name == advocate.name || j.name == adversary.name) judges = pure (Left
      "a judge is also a party: the bench must be independent of both sides.")
  | null judges = pure (Left "no judges: without a bench this is a debate, not a trial.")
  | otherwise = do
      aCase <- advocate.model (fill [("{side}", "advocate"), ("{direction}", "FOR"), ("{claim}", claim), ("{context}", ctx)] caseTemplate)
      bCase <- adversary.model (fill [("{side}", "adversary"), ("{direction}", "AGAINST"), ("{claim}", claim), ("{context}", ctx)] caseTemplate)
      crossTurns <- cross rounds bCase []
      let argued = [Turn Advocate advocate.name aCase, Turn Adversary adversary.name bCase] ++ crossTurns
          transcript = joinWith "\n\n" ["[" ++ seatName x.role ++ "] " ++ x.text | x <- argued]
      rulings <- mapM (\j -> j.model (fill [("{claim}", claim), ("{transcript}", transcript)] judgeTemplate)) judges
      pure $ Right Trial
        { claim = claim, burden = burden
        , turns = argued ++ [Turn Judge j.name reply | (j, reply) <- zip judges rulings]
        , leans = map (lastLean "LEAN:") rulings
        , grounds = map lastGrounds rulings
        , forcedContested = Nothing }
  where
    ctx = if null context then "" else "Context: " ++ context ++ "\n"
    cross :: Int -> String -> [Turn] -> IO [Turn]
    cross n opposing acc
      | n <= 0 = pure (reverse acc)
      | otherwise = do
          a <- advocate.model (fill [("{side}", "advocate"), ("{claim}", claim), ("{opposing}", opposing)] crossTemplate)
          b <- adversary.model (fill [("{side}", "adversary"), ("{claim}", claim), ("{opposing}", a)] crossTemplate)
          cross (n - 1) b (Turn Adversary adversary.name b : Turn Advocate advocate.name a : acc)

-- | The balance guarantee: run twice with the side-models swapped. A verdict
-- that survives the swap is about the idea; one that flips is about the
-- models, and comes back CONTESTED with that named as the ground.
balancedTrial :: String -> Role -> Role -> [Role] -> Int -> Burden -> String -> IO (Either String Trial)
balancedTrial claim a b judges rounds burden context = do
  r1 <- trial claim a b judges rounds burden context
  case r1 of
    Left e -> pure (Left e)
    Right t1 -> fmap (settle t1) <$> trial claim b a judges rounds burden context
  where
    settle t1 t2
      | verdict t1 == verdict t2 = t1
      | otherwise = keep { forcedContested = Just ("verdict unstable under role swap ("
          ++ verdictName (verdict t1) ++ " vs " ++ verdictName (verdict t2) ++ ") — model bias, not idea quality") }
      where keep = if abs (lean t1) >= abs (lean t2) then t1 else t2

-- | The LAST grounds line: the judge prompt itself contains @GROUNDS:@.
lastGrounds :: String -> String
lastGrounds reply = case lastLabeled "GROUNDS:" reply of
  Just g | not (null g) -> g
  _ -> "(no grounds given)"

-- --------------------------------------------------------------------- CLI

usageLine :: String
usageLine = "usage: ideonomy trial CLAIM --advocate CMD --adversary CMD --judge CMD [--judge CMD]... [--rounds 1] [--burden preponderance|high] [--context TEXT] [--no-swap]"

-- | @ideonomy trial CLAIM --advocate CMD --adversary CMD --judge CMD... [--rounds 1] [--burden B] [--context TEXT] [--no-swap]@
cli :: [String] -> IO ()
cli argv = do
  let a = parseArgs ["no-swap"] argv
  case (positionals a, opts "judge" a) of
    ([claim], judgeCmds@(_ : _)) -> do
      let advCmd = require "advocate" a
          advsCmd = require "adversary" a
      burden <- either (\e -> usage (usageLine ++ "\nerror: " ++ e)) pure (readBurden (maybe "preponderance" id (opt "burden" a)))
      if advCmd == advsCmd
        then usage (usageLine ++ "\nerror: advocate and adversary must be distinct commands — an idea must not prosecute and defend itself.")
        else pure ()
      let advocate = Role { name = "advocate", model = command (mkCommand advCmd "A") }
          adversary = Role { name = "adversary", model = command (mkCommand advsCmd "B") }
          judges = [Role { name = nm, model = command (mkCommand c nm) } | (i, c) <- zip [1 :: Int ..] judgeCmds, let nm = "judge-" ++ show i]
          run = if flag "no-swap" a then trial else balancedTrial
      t <- run claim advocate adversary judges (optInt "rounds" 1 a) burden (maybe "" id (opt "context" a))
             >>= either (ioError . userError) pure
      putStrLn (report t)
    _ -> usage usageLine
