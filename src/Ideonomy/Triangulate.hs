-- | Executable triangulation for questions with no computable oracle — P-9.
--
-- The top-ranked premier skill, made real. For irreducibly normative,
-- aesthetic, or strategic questions, you must not fabricate a scalar oracle
-- and optimize it with false rigor. Instead: dimensionalize the value space,
-- gather >=2 /independent/ judgments per axis, and report the spread. Where
-- independent judges agree, the axis is settled and compresses; where they
-- disagree, the disagreement is the signal — it localizes exactly where the
-- question genuinely underdetermines its answer. Contested axes are named as
-- residue (kind @contested_axis@) and can be fed straight into the
-- cross-session ledger (P-10), so P-9 and P-10 compose.
--
-- Organon: P5 dimensionalize + P21 judge-panel + M4 cross-model triangulation
-- + P37 residue-seed. The gate is honesty about the absence of a gate: you
-- either produce independent reads per axis, or you name the judgment
-- irreducible and its owner — never a single manufactured number.
--
-- Judges are injectable so the logic is testable offline; for real use, back
-- them with 'command' (any model CLI): @ideonomy triangulate@.
module Ideonomy.Triangulate
  ( Judge, Verdict (..), AxisResult (..), Triangulation (..)
  , leans, mean, spread, contested, contestedAt, contestedAxes, settledAxes
  , report, residueItems, triangulate, modelJudge, dimensionalize
  , parseLean, parseWhy, cli
  ) where

import Data.Char (isSpace)
import Data.List (tails)
import Ideonomy.Cli (opts, parseArgs, positionals, usage)
import Ideonomy.Models (Model, clamp, command, lastLabeled, leadingNumber, mkCommand)
import Ideonomy.Util (joinWith, nub', roundTo, showFixed, showSigned, strip, stripCI, truncateTo)

-- | A judge scores one axis of one question: @judge axis question@.
type Judge = String -> String -> IO Verdict

data Verdict = Verdict
  { judge :: String
  , axis :: String
  , lean :: Double     -- ^ -1 (fails the axis) .. +1 (excels); 0 = neutral/uncertain
  , stance :: String   -- ^ one-line reason
  } deriving (Eq, Show)

data AxisResult = AxisResult { axis :: String, verdicts :: [Verdict] }
  deriving (Eq, Show)

data Triangulation = Triangulation { question :: String, axes :: [AxisResult] }
  deriving (Eq, Show)

leans :: AxisResult -> [Double]
leans a = [v.lean | v <- a.verdicts]

mean :: AxisResult -> Double
mean a = case leans a of
  [] -> 0
  xs -> roundTo 3 (sum xs / fromIntegral (length xs))

spread :: AxisResult -> Double
spread a = case leans a of
  [] -> 0
  xs -> roundTo 3 (maximum xs - minimum xs)

-- | Contested if judges disagree in sign, one is uncertain while another is
-- confident, or the spread is wide (threshold 1.0).
contested :: AxisResult -> Bool
contested = contestedAt 1.0

contestedAt :: Double -> AxisResult -> Bool
contestedAt threshold a
  | length xs < 2 = True                                 -- one read is not triangulation
  | 1 `elem` signs && (-1) `elem` signs = True           -- genuine sign disagreement
  | 0 `elem` signs && any ((>= 0.6) . abs) xs = True     -- uncertain vs confident is a split
  | otherwise = spread a >= threshold
  where
    xs = leans a
    signs = [if x > 0.15 then 1 else if x < -0.15 then -1 else 0 :: Int | x <- xs]

contestedAxes :: Triangulation -> [AxisResult]
contestedAxes t = filter contested t.axes

settledAxes :: Triangulation -> [AxisResult]
settledAxes t = filter (not . contested) t.axes

report :: Triangulation -> String
report t = joinWith "\n" $
  [ "question: " ++ t.question
  , "axes: " ++ show (length t.axes) ++ "  settled: " ++ show (length (settledAxes t))
      ++ "  contested: " ++ show (length (contestedAxes t))
  , "" ]
  ++ concat
    [ ("[" ++ tag ++ "] " ++ a.axis ++ "  mean=" ++ showSigned 2 (mean a) ++ " spread=" ++ showFixed 2 (spread a))
      : ["    " ++ v.judge ++ ": " ++ showSigned 2 v.lean ++ "  " ++ v.stance | v <- a.verdicts]
    | a <- t.axes, let tag = if contested a then "CONTESTED" else "settled" ]
  ++ (if null (contestedAxes t) then [] else
        ["", "irreducible judgments (no oracle — owner must decide):"]
        ++ ["  - " ++ a.axis ++ ": judges split; owner=___ grounds=___" | a <- contestedAxes t])

-- | Each contested axis as residue for the ledger (P-10): @(text, kind)@,
-- kind always @contested_axis@.
residueItems :: Triangulation -> [(String, String)]
residueItems t =
  [ ("contested axis: " ++ a.axis ++ " (spread " ++ showFixed 2 (spread a) ++ ")", "contested_axis")
  | a <- contestedAxes t ]

-- | Run every judge on every axis. The gate: >=2 independent judges, else
-- this is not triangulation — refuse and tell the caller to name the owner.
triangulate :: String -> [String] -> [Judge] -> IO (Either String Triangulation)
triangulate question axes judges
  | length judges < 2 = pure (Left
      "triangulation needs >=2 independent judges. With fewer, do not fabricate a verdict — name the judgment irreducible and its owner.")
  | null axes = pure (Left
      "no value axes given; dimensionalize the question first (P5) — a question with no named axes cannot be triangulated.")
  | otherwise = do
      rs <- mapM (\ax -> AxisResult ax <$> mapM (\j -> j ax question) judges) axes
      pure (Right (Triangulation question rs))

-- ----------------------------------------------------- model-backed judges

-- | A judge backed by any model (e.g. 'command').
modelJudge :: Model -> String -> Judge
modelJudge model nm axis question = do
  reply <- model prompt
  pure Verdict { judge = nm, axis = axis, lean = parseLean reply, stance = parseWhy reply }
  where
    prompt =
      "Judge ONE axis of the question below, independently. Do not try to "
      ++ "give an overall verdict.\n\nQuestion: " ++ question ++ "\nAxis: " ++ axis ++ "\n\n"
      ++ "Reply with exactly two lines:\n"
      ++ "LEAN: <a number from -1.0 (fails this axis) to +1.0 (excels), "
      ++ "0 if genuinely uncertain>\n"
      ++ "WHY: <one sentence>"

-- | P5: ask a model for the 2-5 value axes the vague predicate comprises.
-- No axes -> refuse to manufacture the single vague axis this skill exists
-- to prevent; the caller must dimensionalize by hand.
dimensionalize :: String -> Model -> Int -> IO (Either String [String])
dimensionalize question model k = do
  reply <- model prompt
  let axes = [a | ln <- lines reply, not (null (strip ln)), let a = trimSet ln, not (null a)]
  pure $ if null axes
    then Left "dimensionalization returned no axes; name the value axes yourself (P5) — refusing to fall back to a manufactured scalar."
    else Right (take k axes)
  where
    prompt =
      "The question below turns on a vague predicate (good/right/better). "
      ++ "Name the " ++ show k ++ " concrete, independent value-axes it actually comprises — "
      ++ "the dimensions along which one would judge it. One per line, terse, "
      ++ "no numbering.\n\nQuestion: " ++ question
    junk = " -*\t0123456789.)"
    trimSet = dropWhile (`elem` junk) . reverse . dropWhile (`elem` junk) . reverse

-- | The LAST @LEAN: <number>@; when no labeled number exists, the first
-- number anywhere in the text; 0 when there is none. Clamped to [-1, 1].
parseLean :: String -> Double
parseLean text = case labeled "LEAN:" text of
  [] -> maybe 0 clamp (firstNumber text)
  xs -> clamp (last xs)

-- | The LAST @WHY:@ line; else the last line (truncated), else a placeholder.
parseWhy :: String -> String
parseWhy text = case lastLabeled "WHY:" text of
  Just w | not (null w) -> w
  _ -> case lines (strip text) of
    [] -> "(no reason given)"
    ls -> truncateTo 160 (last ls)

labeled :: String -> String -> [Double]
labeled label text =
  [n | tl <- tails text, Just rest <- [stripCI label tl], Just n <- [leadingNumber (dropWhile isSpace rest)]]

firstNumber :: String -> Maybe Double
firstNumber text = case [n | tl <- tails text, Just n <- [leadingNumber tl]] of
  [] -> Nothing
  (n : _) -> Just n

-- --------------------------------------------------------------------- CLI

usageLine :: String
usageLine = "usage: ideonomy triangulate QUESTION --judge CMD --judge CMD [--judge CMD]... [--axis AXIS]..."

-- | @ideonomy triangulate QUESTION --judge CMD --judge CMD ... [--axis AXIS]...@
-- Judges are model commands with @{prompt}@; without @--axis@ the first judge
-- dimensionalizes the question.
cli :: [String] -> IO ()
cli argv = do
  let a = parseArgs [] argv
  case (positionals a, opts "judge" a) of
    ([question], cmds@(c1 : _ : _))
      | length (nub' cmds) < length cmds -> usage (usageLine ++ "\nerror: "
          ++ "duplicate --judge commands: identical judges are one judge, not a panel — "
          ++ "independence is the point (M4). Vary the model or the framing. "
          ++ "(Distinct commands are necessary, not sufficient; true independence is on you.)")
      | otherwise -> do
          let models = [("judge-" ++ show i, command (mkCommand c ("judge-" ++ show i))) | (i, c) <- zip [1 :: Int ..] cmds]
          axes <- case opts "axis" a of
            [] -> dimensionalize question (command (mkCommand c1 "judge-1")) 4 >>= either (ioError . userError) pure
            xs -> pure xs
          tri <- triangulate question axes [modelJudge m nm | (nm, m) <- models] >>= either (ioError . userError) pure
          putStrLn (report tri)
    ([_], [_]) -> usage (usageLine ++ "\nerror: triangulation needs >=2 independent --judge commands; "
                         ++ "with one judge, name the judgment irreducible and its owner instead")
    _ -> usage usageLine
