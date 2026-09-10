-- | Demonstration of the respiratory engine, in two honest parts.
--
-- > ideonomy demo
--
-- Part 1: a corpus with genuine latent structure. The breath compresses it,
-- the MDL ratchet accepts improving breaths and reverts worsening ones, and
-- the residue is extracted as the next frontier. This proves the rhythm and
-- that the ratchet has teeth.
--
-- Part 2: the reflexive run. The engine breathes over the organon's own
-- primitive glosses. These are lexically token-disjoint one-liners, so
-- mechanical (no model) compression correctly bottoms out: the ratchet
-- refuses to pretend a pile of singletons is structure, and the run reports
-- that this corpus needs the model hook to be compressed by meaning rather
-- than by shared tokens. That refusal is the conscientious result, not a
-- failure.
module Ideonomy.Demo (frontierExpand, part1, part2, cli) where

import Ideonomy.Cli (usage)
import Ideonomy.Cycles
import qualified Ideonomy.Json as J
import Ideonomy.Primitives (Primitive (..), primitives)
import Ideonomy.Util (joinWith, showFixed)
import qualified Data.Set as Set

bar :: String -> [Record] -> IO ()
bar label hist = do
  putStrLn ("\n" ++ label)
  putStrLn ("  " ++ padL 3 "cyc" ++ " " ++ padL 5 "items" ++ " " ++ padL 3 "add" ++ " " ++ padL 3 "grp" ++ " "
            ++ padL 8 "codelen" ++ " " ++ padL 6 "raw" ++ " " ++ padL 6 "ratio" ++ " " ++ padL 5 "resid" ++ "  expansion")
  mapM_ row hist
  where
    row r = putStrLn ("  " ++ padL 3 (show r.cycle) ++ " " ++ padL 5 (show r.items) ++ " " ++ padL 3 (show r.added)
                      ++ " " ++ padL 3 (show r.groups) ++ " " ++ padL 8 (pyFloat r.codelen) ++ " " ++ padL 6 (pyFloat r.raw)
                      ++ " " ++ padL 6 (pyFloat r.ratio) ++ " " ++ padL 5 (show r.residue) ++ "  " ++ expansionName r.expansion)

padL :: Int -> String -> String
padL n s = replicate (n - length s) ' ' ++ s

-- | Python's @str(float)@.
pyFloat :: Double -> String
pyFloat = J.render . J.dbl

frontier :: [String]
frontier = [ "adam", "dropout", "quantize", "sharding", "replica", "cdn"
           , "prefetch", "mmap", "etag", "backoff", "warmup", "pruning" ]

-- | A stand-in for a /good/ (model) expansion: probe each cluster's frontier
-- by extending its distilled rule with a fresh token, coherent items that
-- join the structure. (The generic default crosses residue tokens instead
-- and mostly produces noise the ratchet reverts; both behaviours are real.)
frontierExpand :: Expand
frontierExpand _ Nothing _ = []
frontierExpand s (Just comp) k =
  take k [ joinWith " " (Set.toAscList r) ++ " " ++ frontier !! (i `mod` length frontier)
         | (i, r) <- zip [s.cycle ..] [r | (_, r) <- comp.rule, not (Set.null r)] ]

-- | Seed a corpus and settle its initial compression and residue.
settled :: [String] -> (State, Compression)
settled texts = (s { compression = Just c0, residue = residueExtract s c0 }, c0)
  where
    s = seed texts
    c0 = compressMechanical s

part1 :: IO ()
part1 = do
  -- three clusters, each item = shared core + one unique token (the kind of
  -- latent structure real corpora carry).
  let cores =
        [ ("neural network training", ["convergence", "regularization", "checkpoint", "scheduler"])
        , ("database query index", ["btree", "planner", "vacuum", "lookup"])
        , ("http request caching", ["header", "policy", "routing", "revalidation"]) ]
      (state, c0) = settled [core ++ " " ++ tl | (core, tails) <- cores, tl <- tails]
  putStrLn "PART 1 — corpus with latent structure"
  putStrLn ("  seed: " ++ show (length state.corpus) ++ " items, initial compression " ++ show (length c0.groups)
            ++ " groups, ratio=" ++ showFixed 3 (rawBits state / codeLength state c0))
  let out = run defaultConfig { expand = frontierExpand } 4 state
  bar ("breath log (frontier expansion: items that join the structure are "
       ++ "accepted; the ratchet holds the compression ratio):") out.history

part2 :: IO ()
part2 = do
  let (state, c0) = settled [p.name ++ ": " ++ p.gloss | p <- primitives]
      ratio = rawBits state / codeLength state c0
      singletons = length [() | (_, [_]) <- c0.groups]
  putStrLn ("\n\nPART 2 — reflexive run over the organon's own " ++ show (length primitives) ++ " primitives")
  putStrLn ("  groups=" ++ show (length c0.groups) ++ " (" ++ show singletons ++ " singletons), ratio="
            ++ showFixed 3 ratio ++ ", residue=" ++ show (length state.residue))
  let out = run defaultConfig 3 state
  bar "breath log:" out.history
  let verdict =
        if (last out.history).ratio <= 1.0
          then "lexical compression bottoms out (ratio <= 1): the glosses share "
               ++ "almost no surface tokens, so the ratchet correctly refuses to "
               ++ "claim structure. Wire a model expand/compress to compress these "
               ++ "by meaning."
          else "lexical compression found surface structure."
  putStrLn ("\n  verdict: " ++ verdict)

-- | @ideonomy demo@
cli :: [String] -> IO ()
cli [] = part1 >> part2
cli _ = usage "usage: ideonomy demo"
