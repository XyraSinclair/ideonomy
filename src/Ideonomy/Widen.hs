-- | The widen axis: grow the meta-list of lists worth making.
--
-- Deepening ("Ideonomy.Climb") grows a list along its own gap gradient.
-- Widening grows the /set of lists/ — Gunkel's "reapplication" move. It
-- proposes new list specs, each a @{name, of}@ an agent could hand
-- straight to the climb, seeded from three streams that a single model
-- would never span alone:
--
-- * Xyra's stated domains (strategy, somatics, math, tactics, ops, first-
--   strike, cooperation, convincing, deal flow, psyop) crossed with the
--   generative angle each domain under-serves;
-- * Gunkel's 236 divisions as lenses (each division names a kind of list);
-- * the existing lists themselves, as parents for cross-products.
--
-- Output: candidate specs -> gate (is this a genuine, enumerable,
-- non-duplicate list of real categories?) -> the catalog's
-- @list-specs.jsonl@. Nothing is grown here; this only decides WHICH lists
-- deserve a climb. Cheap by construction.
--
-- > ideonomy widen --k 40
module Ideonomy.Widen (Spec (..), domains, existingNames, propose, gate, cli) where

import Data.Char (isLetter, toLower, toUpper)
import qualified Data.Set as Set
import Ideonomy.Cli (optInt, parseArgs, positionals, usage)
import Ideonomy.Climb (loadGrown)
import Ideonomy.Data (dataFile)
import Ideonomy.Divisions (divisions)
import Ideonomy.Gemini (askJson, cheap, strong, truthy)
import Ideonomy.Json (Value (..), (!?), asArray, asInt, asString, key, obj, readJsonl, render, str)
import Ideonomy.Rng (mkRng, sample)
import Ideonomy.Util (joinWith)
import System.Directory (createDirectoryIfMissing, doesFileExist)
import System.FilePath (takeDirectory)

data Spec = Spec { name :: String, of_ :: String, why :: String, gateWhy :: String }
  deriving (Eq, Show)

domains :: [String]
domains =
  [ "strategy", "somatics", "mathematics", "tactics", "operations"
  , "first-strike / preemption", "cooperation", "persuasion"
  , "deal flow", "influence operations", "negotiation", "epistemics"
  , "logistics", "timing", "leverage", "risk" ]

-- | Names already spoken for: prior specs plus the grown store.
existingNames :: IO (Set.Set String)
existingNames = do
  out <- dataFile "list-specs.jsonl"
  exists <- doesFileExist out
  prior <- if exists then readJsonl out >>= mapM nameOf else pure []
  grown <- loadGrown
  pure (Set.fromList (prior ++ map fst grown))
  where
    nameOf s = maybe (ioError (userError "list-specs.jsonl: record missing \"name\"")) pure (s !? "name" >>= asString)

-- | Python's @str.title@: a letter is upper-cased after a non-letter,
-- lower-cased after a letter.
title :: String -> String
title = go False
  where
    go _ [] = []
    go prevLetter (c : cs)
      | isLetter c = (if prevLetter then toLower c else toUpper c) : go True cs
      | otherwise = c : go False cs

-- | @k@ proposed specs from the cheap tier, seeded with 24 divisions drawn
-- by @seed@ (the raw records, in reply order).
propose :: Int -> Int -> IO [Value]
propose k seed = do
  reply <- askJson cheap prompt
  pure (asArray (key "specs" reply))
  where
    lenses = fst (sample 24 divisions (mkRng seed))
    lensStr = joinWith "\n" ["- " ++ title theme ++ " (" ++ greek ++ ")" | (theme, greek) <- lenses]
    domStr = joinWith ", " domains
    prompt =
      "You are enumerating LISTS WORTH MAKING for an ideonomy database — "
      ++ "Patrick Gunkel's science of systematic lists. A good list spec is a "
      ++ "family of real, mutually-distinct categories that an analyst would "
      ++ "find load-bearing, phrased so its items combine with other lists.\n\n"
      ++ "Seed domains (bias toward these): " ++ domStr ++ ".\n\n"
      ++ "Gunkel divisions to use as lenses (each names a KIND of list):\n"
      ++ lensStr ++ "\n\n"
      ++ "Propose exactly " ++ show k ++ " list specs. Each must be a list that does NOT yet "
      ++ "obviously exist as a standard reference, is enumerable (10-200 real "
      ++ "items), and is genuinely useful for thinking about the seed domains. "
      ++ "Cross a domain with a lens where it yields something sharp (e.g. "
      ++ "'failure modes of coalitions', 'invariants preserved under "
      ++ "renegotiation', 'somatic tells of deception'). Reply as JSON: "
      ++ "{\"specs\": [{\"name\": \"kebab-case-id\", \"of\": \"what ONE item is, a "
      ++ "precise noun/verb phrase\", \"why\": \"one clause on what it is for\"}]}"

-- | The strong tier keeps the specs that are genuine, enumerable, distinct
-- families with a precise @of@; proposals already named are not offered.
gate :: [Value] -> Set.Set String -> IO [Spec]
gate specs have
  | null fresh = pure []
  | otherwise = do
      judged <- askJson strong $
        "Gate these proposed list specs for an ideonomy database. KEEP "
        ++ "a spec only if it is (a) a genuine family of distinct, real "
        ++ "categories — not a vague theme or a single question; (b) "
        ++ "actually enumerable to 10+ concrete items; (c) not a trivial "
        ++ "restatement of another kept spec; (d) its 'of' precisely says "
        ++ "what one item is. Be strict; most proposals are vague.\n\n"
        ++ listing ++ "\n\n"
        ++ "Reply JSON: {\"verdicts\":[{\"i\":int,\"keep\":bool,\"why\":str}]}"
      mapM toSpec
        [ (fst (fresh !! i), field "why" v)
        | v <- asArray (key "verdicts" judged), Just i <- [v !? "i" >>= asInt]
        , i >= 0, i < length fresh, truthy (key "keep" v) ]
  where
    fresh = [(s, n) | s <- specs, Just n <- [s !? "name" >>= asString], not (null n), n `Set.notMember` have]
    listing = joinWith "\n"
      [ show i ++ ". " ++ n ++ ": " ++ field "of" s ++ "  [" ++ field "why" s ++ "]"
      | (i, (s, n)) <- zip [0 :: Int ..] fresh ]
    field k v = maybe "" id (v !? k >>= asString)
    toSpec (s, gw) = do
      n <- maybe (ioError (userError "spec without name")) pure (s !? "name" >>= asString)
      o <- maybe (ioError (userError ("spec " ++ show n ++ " without \"of\""))) pure (s !? "of" >>= asString)
      pure Spec { name = n, of_ = o, why = field "why" s, gateWhy = gw }

-- | @ideonomy widen [--k 40] [--seed 0]@
cli :: [String] -> IO ()
cli argv = do
  let a = parseArgs [] ["k", "seed"] argv
  case positionals a of
    [] -> pure ()
    _ -> usage "usage: ideonomy widen [--k 40] [--seed 0]"
  have <- existingNames
  specs <- propose (optInt "k" 40 a) (optInt "seed" 0 a)
  kept0 <- gate specs have
  -- de-dupe against prior specs by name
  let kept = reverse (snd (foldl (\(seen, acc) s -> if s.name `Set.member` seen then (seen, acc) else (Set.insert s.name seen, s : acc)) (have, []) kept0))
  out <- dataFile "list-specs.jsonl"
  createDirectoryIfMissing True (takeDirectory out)
  appendFile out (concat [render (record s) ++ "\n" | s <- kept])
  total <- do
    exists <- doesFileExist out
    if exists then length . lines <$> readFile out else pure 0
  putStrLn ("proposed " ++ show (length specs) ++ ", kept " ++ show (length kept) ++ " new specs -> " ++ out
            ++ " (" ++ show total ++ " total)")
  mapM_ (\s -> putStrLn ("  + " ++ s.name ++ ": " ++ s.of_)) kept
  where
    record s = obj
      [ ("name", str s.name), ("of", str s.of_), ("why", str s.why), ("gate_why", str s.gateWhy)
      , ("status", str "spec"), ("source", obj [("tier", str "spec"), ("via", str "widen.py")]) ]
