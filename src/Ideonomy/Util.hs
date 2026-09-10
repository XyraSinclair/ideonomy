-- | String helpers the modules share, so no module grows its own.
module Ideonomy.Util
  ( strip, lower, casefold, replace, within, splitOn, stripCI, stripPrefixCI
  , wordsAlnum, joinWith, indent, truncateTo, roundTo, showFixed, showSigned
  , nub', uniq, byKey, timestamp, fill
  ) where

import Data.Char (isAlphaNum, isSpace, toLower, toUpper)
import Data.List (isPrefixOf, tails)
import qualified Data.Set as Set
import Data.Time (defaultTimeLocale, formatTime, getZonedTime)
import Text.Printf (printf)

strip :: String -> String
strip = dropWhile isSpace . reverse . dropWhile isSpace . reverse

lower :: String -> String
lower = map toLower

-- | Python's @casefold@ for the purposes here: lower-case, whitespace stripped.
casefold :: String -> String
casefold = lower . strip

replace :: String -> String -> String -> String
replace needle rep = go
  where
    go [] = []
    go s@(c : cs)
      | needle `isPrefixOf` s = rep ++ go (drop (length needle) s)
      | otherwise = c : go cs

within :: String -> String -> Bool
within needle hay = any (needle `isPrefixOf`) (tails hay)

splitOn :: Char -> String -> [String]
splitOn c s = case break (== c) s of
  (a, []) -> [a]
  (a, _ : rest) -> a : splitOn c rest

-- | Case-insensitive prefix strip.
stripCI :: String -> String -> Maybe String
stripCI pre s
  | length s >= n && map toUpper pre == map toUpper (take n s) = Just (drop n s)
  | otherwise = Nothing
  where n = length pre

stripPrefixCI :: String -> String -> Maybe String
stripPrefixCI = stripCI

-- | Lower-case alphanumeric runs: the token model every engine shares.
wordsAlnum :: String -> [String]
wordsAlnum = go . lower
  where
    go s = case dropWhile (not . isAlphaNum) s of
      [] -> []
      s' -> let (w, rest) = span isAlphaNum s' in w : go rest

joinWith :: String -> [String] -> String
joinWith _ [] = ""
joinWith sep (x : xs) = x ++ concatMap (sep ++) xs

indent :: Int -> String -> String
indent n = unlines . map (replicate n ' ' ++) . lines

truncateTo :: Int -> String -> String
truncateTo n s = if length s <= n then s else take n s

-- | Python @round(x, n)@ (half-even on the scaled value is close enough here).
roundTo :: Int -> Double -> Double
roundTo n x = fromIntegral (round (x * 10 ^ n) :: Integer) / 10 ^ n

-- | @%.nf@.
showFixed :: Int -> Double -> String
showFixed n = printf ("%." ++ show n ++ "f")

-- | @%+.nf@.
showSigned :: Int -> Double -> String
showSigned n = printf ("%+." ++ show n ++ "f")

-- | Order-preserving dedupe.
nub' :: Ord a => [a] -> [a]
nub' = go Set.empty
  where
    go _ [] = []
    go seen (x : xs)
      | x `Set.member` seen = go seen xs
      | otherwise = x : go (Set.insert x seen) xs

uniq :: Ord a => [a] -> [a]
uniq = nub'

byKey :: Ord k => (a -> k) -> [a] -> [(k, a)]
byKey f xs = [(f x, x) | x <- xs]

-- | Local time as @%Y-%m-%dT%H:%M:%S@.
timestamp :: IO String
timestamp = formatTime defaultTimeLocale "%Y-%m-%dT%H:%M:%S" <$> getZonedTime

-- | Single-pass named substitution, as @str.format@ does it: a substituted
-- value is never rescanned for placeholders.
fill :: [(String, String)] -> String -> String
fill kv = go
  where
    go [] = []
    go s@(c : cs) = case [(v, drop (length k) s) | (k, v) <- kv, k `isPrefixOf` s] of
      ((v, rest) : _) -> v ++ go rest
      [] -> c : go cs
