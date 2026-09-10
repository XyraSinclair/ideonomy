-- | A small deterministic generator (SplitMix64) so seeded draws replay
-- exactly, with no package beyond base. Same seed, same sequence, forever.
module Ideonomy.Rng
  ( Rng, mkRng, seedFromClock, next, uniform, below, sample
  ) where

import Data.Bits (shiftR, xor)
import Data.Time.Clock.POSIX (getPOSIXTime)
import Data.Word (Word64)

newtype Rng = Rng Word64

mkRng :: Int -> Rng
mkRng = Rng . fromIntegral

-- | A non-reproducible seed, for callers that did not ask for replay.
seedFromClock :: IO Int
seedFromClock = (\t -> floor (t * 1e6)) <$> getPOSIXTime

next :: Rng -> (Word64, Rng)
next (Rng s) = (z3, Rng s')
  where
    s' = s + 0x9E3779B97F4A7C15
    z1 = (s' `xor` (s' `shiftR` 30)) * 0xBF58476D1CE4E5B9
    z2 = (z1 `xor` (z1 `shiftR` 27)) * 0x94D049BB133111EB
    z3 = z2 `xor` (z2 `shiftR` 31)

-- | Uniform in [0, 1).
uniform :: Rng -> (Double, Rng)
uniform g = let (w, g') = next g in (fromIntegral (w `shiftR` 11) / 9007199254740992, g')

-- | Uniform integer in [0, n).
below :: Int -> Rng -> (Int, Rng)
below n g = let (w, g') = next g in (fromIntegral (w `mod` fromIntegral n), g')

-- | @n@ distinct picks without replacement, in draw order.
sample :: Int -> [a] -> Rng -> ([a], Rng)
sample n xs g0
  | n <= 0 = ([], g0)
  | otherwise = go n xs g0
  where
    go 0 _ g = ([], g)
    go _ [] g = ([], g)
    go k pool g =
      let (i, g') = below (length pool) g
       in case splitAt i pool of
            (before, x : after) -> let (rest, g'') = go (k - 1) (before ++ after) g' in (x : rest, g'')
            (_, []) -> ([], g')
