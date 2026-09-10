-- | Balanced multi-party constraint solving over idea-space (P21 + M2 + P37).
--
-- A 'panel' is parallel opinions; a /parley/ is a negotiation. Each party
-- holds a model and a charter of declared constraints, and the solver
-- searches for a proposal inside the joint feasible region — every party's
-- every constraint satisfied, by that party's own reading.
--
-- Balance is structural:
--
--   * proposal rights rotate round-robin, so no party frames more often;
--   * each party is sovereign over exactly its own constraints — it scores
--     those and nothing else, so no party grades another's charter;
--   * at impasse the surviving proposal is chosen by maximin (the best worst
--     satisfaction across all constraints), the balanced criterion — never
--     the proposal one loud party liked most.
--
-- An accord is a proposal plus every party's on-the-record satisfaction. An
-- impasse names the binding constraints — the genuine conflict — and feeds
-- them to the residue ledger (P-10). Models are injectable for offline
-- testing; back them with 'command' for real heterogeneous parleys:
-- @ideonomy parley@.
module Ideonomy.Parley
  ( Party (..), Reading (..), Round (..), Parley (..)
  , worst, accord, best, binding, report, residueItems, parley, cli
  ) where

import Data.List (find)
import Ideonomy.Cli (optDouble, optInt, opts, parseArgs, positionals, usage)
import Ideonomy.Models (Model, command, lastLabeled, lastLean, mkCommand)
import Ideonomy.Util (fill, joinWith, showSigned, strip)

data Party = Party { name :: String, model :: Model, constraints :: [String] }

data Reading = Reading { party :: String, constraint :: String, sat :: Double, why :: String }
  deriving (Eq, Show)

data Round = Round { proposer :: String, proposal :: String, readings :: [Reading] }
  deriving (Eq, Show)

data Parley = Parley { task :: String, accept :: Double, rounds :: [Round] }
  deriving (Eq, Show)

proposeTemplate :: String
proposeTemplate =
  "You are {name}, one party in a multi-party negotiation over the task "
  ++ "below. Draft ONE concrete proposal that could satisfy every party's "
  ++ "declared constraints — including the other parties'. Be specific; a "
  ++ "vague proposal satisfies nothing.\n\nTask: {task}\n\n"
  ++ "All declared constraints:\n{charters}\n{feedback}"
  ++ "Reply with the proposal text only."

scoreTemplate :: String
scoreTemplate =
  "You are {name}. Score the proposal below against ONE of your declared "
  ++ "constraints — only this one, only yours.\n\nConstraint: {constraint}\n\n"
  ++ "Proposal:\n{proposal}\n\nReply with exactly two lines:\n"
  ++ "SAT: <-1.0 (violates it) .. +1.0 (fully satisfies it), 0 if unclear>\n"
  ++ "WHY: <one sentence>"

worst :: Round -> Double
worst r = case r.readings of
  [] -> -1
  rs -> minimum [x.sat | x <- rs]

-- | First round whose worst reading clears the acceptance bar.
accord :: Parley -> Maybe Round
accord p = find (\r -> not (null r.readings) && worst r >= p.accept) p.rounds

-- | Maximin: the proposal with the least-bad worst reading (first on ties).
best :: Parley -> Maybe Round
best p = case [r | r <- p.rounds, not (null r.readings)] of
  [] -> Nothing
  (r : rs) -> Just (foldl (\b x -> if worst x > worst b then x else b) r rs)

-- | The constraints that block the best proposal — the real conflict.
binding :: Parley -> [Reading]
binding p = case best p of
  Nothing -> []
  Just b -> [r | r <- b.readings, r.sat < p.accept]

report :: Parley -> String
report p = joinWith "\n" $ ("task: " ++ p.task) : case accord p of
  Just a ->
    [ "ACCORD after " ++ show (length p.rounds) ++ " round(s) (proposer " ++ a.proposer
        ++ ", worst sat " ++ showSigned 2 (worst a) ++ "):"
    , "  " ++ a.proposal ]
    ++ ["    " ++ line r | r <- a.readings]
  Nothing ->
    ["IMPASSE after " ++ show (length p.rounds) ++ " round(s)."]
    ++ (case best p of
          Just b -> [ "best (maximin) proposal, proposer " ++ b.proposer ++ ", worst sat " ++ showSigned 2 (worst b) ++ ":"
                    , "  " ++ b.proposal ]
          Nothing -> [])
    ++ ["binding constraints (the genuine conflict):"]
    ++ ["  - " ++ line r | r <- binding p]
  where
    line r = r.party ++ " | " ++ r.constraint ++ ": " ++ showSigned 2 r.sat ++ "  " ++ r.why

-- | At impasse, each binding constraint is residue (@(text, kind)@, kind
-- always @contested_axis@); an accord closed.
residueItems :: Parley -> [(String, String)]
residueItems p = case accord p of
  Just _ -> []
  Nothing ->
    [ ("parley impasse: " ++ r.party ++ "'s constraint unmet — " ++ r.constraint
        ++ " (sat " ++ showSigned 2 r.sat ++ "): " ++ r.why, "contested_axis")
    | r <- binding p ]

-- | Negotiate to joint feasibility or a named impasse.
--
-- Gate: >=2 parties, each with a non-empty charter — one party is a
-- monologue, and a party with no constraints has nothing at stake.
parley :: String -> [Party] -> Int -> Double -> IO (Either String Parley)
parley task parties maxRounds accept
  | length parties < 2 = pure (Left "a parley needs >=2 parties; one party is a monologue.")
  | otherwise = case gate [] parties of
      Left e -> pure (Left e)
      Right () -> Right <$> go 0 "" []
  where
    gate _ [] = Right ()
    gate seen (p : ps)
      | null p.constraints = Left ("party " ++ show p.name ++ " declares no constraints: nothing at stake, nothing to negotiate.")
      | p.name `elem` seen = Left ("duplicate party name " ++ show p.name)
      | otherwise = gate (p.name : seen) ps
    charters = joinWith "\n" ["  " ++ p.name ++ ": " ++ c | p <- parties, c <- p.constraints]
    done acc = Parley { task = task, accept = accept, rounds = reverse acc }
    go i feedback acc
      | i >= maxRounds = pure (done acc)
      | otherwise = do
          let proposer = parties !! (i `mod` length parties)          -- equal proposal rights
          proposal <- proposer.model (fill
            [("{name}", proposer.name), ("{task}", task), ("{charters}", charters), ("{feedback}", feedback)]
            proposeTemplate)
          readings <- sequence
            [ do reply <- p.model (fill [("{name}", p.name), ("{constraint}", c), ("{proposal}", proposal)] scoreTemplate)
                 pure Reading { party = p.name, constraint = c, sat = lastLean "SAT:" reply, why = lastWhy reply }
            | p <- parties, c <- p.constraints ]                     -- sovereignty: own charter only
          let rnd = Round { proposer = proposer.name, proposal = proposal, readings = readings }
              unmet = [r | r <- readings, r.sat < accept]
              feedback' = "Previous proposal failed these constraints — address them directly:\n"
                ++ joinWith "\n" ["  " ++ r.party ++ " | " ++ r.constraint ++ ": " ++ r.why | r <- unmet] ++ "\n"
          if worst rnd >= accept then pure (done (rnd : acc)) else go (i + 1) feedback' (rnd : acc)

lastWhy :: String -> String
lastWhy reply = case lastLabeled "WHY:" reply of
  Just w | not (null w) -> w
  _ -> "(no reason given)"

-- --------------------------------------------------------------------- CLI

usageLine :: String
usageLine = "usage: ideonomy parley TASK --party NAME=CMD --party NAME=CMD [--party NAME=CMD]... --constraint NAME:TEXT [--constraint NAME:TEXT]... [--rounds 4] [--accept 0.15]"

-- | @ideonomy parley TASK --party NAME=CMD ... --constraint NAME:TEXT ... [--rounds 4] [--accept 0.15]@
cli :: [String] -> IO ()
cli argv = do
  let a = parseArgs [] argv
  case (positionals a, opts "party" a, opts "constraint" a) of
    ([task], partySpecs@(_ : _), constraintSpecs@(_ : _)) -> do
      named <- foldl (\acc spec -> acc >>= \ps -> case break (== '=') spec of
          (n, '=' : c) | not (null c) -> pure (if any ((== n) . fst) ps then [(k, if k == n then c else v) | (k, v) <- ps] else ps ++ [(n, c)])
          _ -> usage (usageLine ++ "\nerror: --party " ++ show spec ++ ": expected NAME=CMD")) (pure []) partySpecs
      cons <- mapM (\spec -> case break (== ':') spec of
          (n, ':' : t) | not (null t), any ((== n) . fst) named -> pure (n, strip t)
          _ -> usage (usageLine ++ "\nerror: --constraint " ++ show spec ++ ": expected NAME:TEXT with a declared --party NAME")) constraintSpecs
      let parties = [Party { name = n, model = command (mkCommand c n), constraints = [t | (m, t) <- cons, m == n] } | (n, c) <- named]
      st <- parley task parties (optInt "rounds" 4 a) (optDouble "accept" 0.15 a) >>= either (ioError . userError) pure
      putStrLn (report st)
    _ -> usage usageLine
