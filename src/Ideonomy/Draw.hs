-- | Seeded draws from the full Gunkel catalog — variation with teeth.
--
-- LLMs default to the same few ideation moves; an external chooser forces
-- non-default ones (mode-collapse resistance, an idea due to latentwill's
-- ideonomy-skill picker). This drawer composes from a much larger space:
-- 236 divisions x 12 variation operators (2,832 lens-operator pairs), each
-- rendered as one prompt over your subject.
--
-- The draw supplies /variation/; relevance is not the drawer's job. Judge
-- the outputs (P18 filter, P22 adversarial-refute), keep the live cells,
-- and route what resists to the residue ledger. A draw is an expansion
-- half-breath — worthless without the compression that follows (CYCLES.md).
--
-- > ideonomy draw "your subject"                # 3 draws, random
-- > ideonomy draw "your subject" --n 5 --seed 7 # deterministic
--
-- Deterministic under @--seed@ for testing and replay.
module Ideonomy.Draw (Draw (..), prompt, draw, cli) where

import qualified Data.Set as Set
import Ideonomy.Cli (opt, optInt, parseArgs, positionals, usage)
import Ideonomy.Divisions (divisions, lensPrompt)
import Ideonomy.Operators (variationOperators)
import Ideonomy.Rng (Rng, mkRng, sample, seedFromClock)
import Ideonomy.Util (lower, replace)
import Text.Read (readMaybe)

data Draw = Draw
  { division :: String   -- ^ Gunkel theme, e.g. "ANOMALIES"
  , binomen :: String    -- ^ its coined field, e.g. "Xenology"
  , operator :: String   -- ^ variation operator, e.g. "invert"
  } deriving (Eq, Show)

-- | The lens over the subject, then one forced variation on what it found.
prompt :: Draw -> String -> Either String String
prompt d subject = do
  lens <- lensPrompt d.division subject
  tpl <- maybe (Left ("unknown variation operator: " ++ show d.operator)) Right
           (lookup d.operator variationOperators)
  pure (lens ++ "\n\nThen apply one forced variation — "
        ++ "[" ++ d.operator ++ "] " ++ replace "{x}" "what you found" tpl ++ "\n"
        ++ "Keep only what survives judgment; name what resists as residue.")

-- | Draw @n@ distinct (division, operator) pairs, uniformly, under the
-- given generator. @avoid@ excludes already-used pairs (bring your own
-- memory — e.g. pairs recorded in a residue ledger); the drawer itself is
-- deliberately stateless.
draw :: Int -> Rng -> [(String, String)] -> Either String [Draw]
draw n g avoid
  | n > length pool = Left ("asked for " ++ show n ++ " draws; only " ++ show (length pool) ++ " pairs available")
  | otherwise = Right [Draw { division = d, binomen = b, operator = op } | (d, b, op) <- fst (sample n pool g)]
  where
    avoided = Set.fromList avoid
    pool = [(d, b, op) | (d, b) <- divisions, (op, _) <- variationOperators, (d, op) `Set.notMember` avoided]

-- | @ideonomy draw SUBJECT [--n 3] [--seed N]@
cli :: [String] -> IO ()
cli argv = do
  let a = parseArgs [] ["n", "seed"] argv
  subject <- case positionals a of
    [s] -> pure s
    _ -> usage "usage: ideonomy draw SUBJECT [--n 3] [--seed N]"
  seed <- case opt "seed" a of
    Nothing -> seedFromClock
    Just s -> maybe (usage ("--seed expects an integer, got " ++ show s)) pure (readMaybe s)
  ds <- either (ioError . userError) pure (draw (optInt "n" 3 a) (mkRng seed) [])
  mapM_ (\(i, d) -> do
    putStrLn ("--- draw " ++ show i ++ ": " ++ d.binomen ++ " (" ++ lower d.division ++ ") x " ++ d.operator)
    either (ioError . userError) putStrLn (prompt d subject)
    putStrLn "") (zip [1 :: Int ..] ds)
