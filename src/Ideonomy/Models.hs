-- | Any command is a model: a 'Model' is @String -> IO String@. 'command'
-- shells out to a CLI (claude, codex, ollama, llm, ...), which is how
-- heterogeneous panels are assembled without SDK lock-in. Offline tests
-- inject pure models with @pure . f@.
--
-- Hermeticity: agent CLIs inject the invoking user's global instructions
-- and may read the working directory. For a clean panel seat, isolate the
-- call, e.g. @cd /tmp && claude -p --setting-sources project {prompt}@.
module Ideonomy.Models
  ( Model, Command (..), mkCommand, command, shellQuote
  , panel, refute, survives
  , lastLabeled, lastLean, leadingNumber, clamp
  ) where

import Control.Concurrent (forkIO)
import Control.Concurrent.MVar (newEmptyMVar, putMVar, takeMVar)
import Control.Exception (SomeException, evaluate, try)
import Data.Char (isAlpha, isDigit, isSpace, toUpper)
import Data.List (tails)
import Ideonomy.Util (replace, strip, stripCI, within)
import System.Exit (ExitCode (..))
import System.Process (readCreateProcessWithExitCode, shell)
import System.Timeout (timeout)
import Text.Read (readMaybe)

type Model = String -> IO String

data Command = Command
  { template :: String   -- ^ contains @{prompt}@, or the prompt goes to stdin
  , viaStdin :: Bool
  , timeoutSecs :: Double
  , name :: String
  }

mkCommand :: String -> String -> Command
mkCommand tpl nm = Command { template = tpl, viaStdin = False, timeoutSecs = 600, name = nm }

command :: Command -> Model
command c prompt = do
  let useStdin = viaStdin c || not ("{prompt}" `within` template c)
      -- replace, not a format: templates may carry literal braces (jq filters)
      cmd = if useStdin then template c else replace "{prompt}" (shellQuote prompt) (template c)
      input = if useStdin then prompt else ""
  r <- timeout (round (timeoutSecs c * 1e6)) (readCreateProcessWithExitCode (shell cmd) input)
  case r of
    Nothing -> ioError (userError ("model command timed out (" ++ label ++ ")"))
    Just (ExitSuccess, out, _) -> pure (strip out)
    Just (ExitFailure _, _, err) ->
      ioError (userError ("model command failed (" ++ label ++ "): " ++ take 500 (strip err)))
  where
    label = if null (name c) then show (template c) else name c

-- | POSIX single-quote quoting, like Python's @shlex.quote@.
shellQuote :: String -> String
shellQuote s
  | null s = "''"
  | all safe s = s
  | otherwise = "'" ++ concatMap (\c -> if c == '\'' then "'\"'\"'" else [c]) s ++ "'"
  where
    safe c = c `elem` (['a' .. 'z'] ++ ['A' .. 'Z'] ++ ['0' .. '9'] ++ "@%+=:,./-_")

-- | Run every (model, prompt) pair concurrently (P21). A failed model
-- yields its exception rather than sinking the panel.
panel :: [(Model, String)] -> IO [Either SomeException String]
panel jobs = do
  vars <- mapM run jobs
  mapM takeMVar vars
  where
    run (m, p) = do
      v <- newEmptyMVar
      _ <- forkIO (try (m p >>= evaluate) >>= putMVar v)
      pure v

-- | P22 adversarial-refute: the claim survives iff a majority of refuters
-- fail to refute it. Refuters default to REFUTED when uncertain.
refute :: [Model] -> String -> String -> IO Bool
refute models claim context = do
  votes <- panel [(m, prompt) | m <- models]
  let n = length [() | Right v <- votes, survives v]
  pure (fromIntegral n > (fromIntegral (length models) :: Double) / 2)
  where
    prompt =
      "You are a motivated skeptic. Try to REFUTE the claim below: find a \
      \concrete counterexample, a hidden false assumption, or a reason it \
      \is vacuous. If you cannot decisively refute it but remain uncertain, \
      \default to REFUTED. End your reply with exactly one line: \
      \VERDICT: REFUTED or VERDICT: SURVIVES.\n\nClaim: " ++ claim ++ "\n"
      ++ (if null context then "" else "\nContext:\n" ++ context ++ "\n")

-- | Parse the LAST verdict line; refuted by default when unparseable. A
-- substring test would count a model that echoes its instructions (which
-- contain both verdict strings) as a survival vote.
survives :: String -> Bool
survives reply = go (reverse [strip l | l <- lines reply, not (all isSpace l)])
  where
    go [] = False
    go (l : rest) = case verdict l of
      Just v -> v
      Nothing -> go rest
    verdict l
      | Just r <- stripCI "VERDICT:" l =
          let w = map toUpper (takeWhile isAlpha (dropWhile isSpace r))
           in if w == "SURVIVES" then Just True else if w == "REFUTED" then Just False else Nothing
      | otherwise = Nothing

-- | The text after the LAST occurrence of a label (case-insensitive,
-- anywhere in the text), to end of line. The prompts themselves contain
-- the labels, so an instruction-echoing model must not have its echo read.
lastLabeled :: String -> String -> Maybe String
lastLabeled label text =
  case [strip (takeWhile (/= '\n') (dropWhile isSpace rest)) | t <- tails text, Just rest <- [stripCI label t]] of
    [] -> Nothing
    xs -> Just (last xs)

-- | The LAST @LABEL: <number>@ in the text, clamped to [-1, 1]; 0 when absent.
lastLean :: String -> String -> Double
lastLean label text = maybe 0 (clamp . fst) (lastNumber label text)
  where
    lastNumber lb t = case [n | tl <- tails t, Just rest <- [stripCI lb tl], Just n <- [leadingNumber (dropWhile isSpace rest)]] of
      [] -> Nothing
      xs -> Just (last xs, ())

-- | @[+-]?\\d*\\.?\\d+@ at the head of the text, read as the regex read it.
leadingNumber :: String -> Maybe Double
leadingNumber s
  | not (null frac) = readMaybe (sign ++ (if null whole then "0" else whole) ++ "." ++ frac)
  | not (null whole) = readMaybe (sign ++ whole)
  | otherwise = Nothing
  where
    (sign, r) = case s of
      ('+' : t) -> ("", t)
      ('-' : t) -> ("-", t)
      t -> ("", t)
    (whole, r') = span isDigit r
    frac = case r' of
      ('.' : t) -> takeWhile isDigit t
      _ -> ""

clamp :: Double -> Double
clamp = max (-1) . min 1
