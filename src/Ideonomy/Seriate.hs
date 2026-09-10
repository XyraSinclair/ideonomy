-- | Seriation: the order of a list as its own object of study.
--
-- Gunkel seriated lists by hand; gwern seriates by embedding-TSP. Here the
-- algebra is pure and the meaning is bound elsewhere: these operators take
-- a similarity matrix (from any source: embeddings, model judgments,
-- counts) and return orders and scores. A named axis is a /claim/ about
-- what the order means; naming belongs to the caller (a model, a person),
-- measuring belongs here.
--
-- Three operators and one objective:
--
-- * 'spectralOrder' — Fiedler-vector seriation: the second eigenvector of
--   the graph Laplacian, the classic archaeology ordering; global,
--   gap-revealing.
-- * 'greedyChain' — nearest-neighbor chaining from the loneliest endpoint;
--   local, fast, gwern-style.
-- * 'smoothness' — mean adjacent similarity: lets orders compete (a
--   model-named axis order can be scored against the spectral order on
--   equal terms).
-- * 'bestOrder' — the smoother of spectral and greedy.
--
-- Pure by design; n^2 power iteration is ample for list-sized n.
module Ideonomy.Seriate
  ( Sim, cosine, simMatrix, spectralOrder, greedyChain, smoothness, bestOrder
  ) where

import Data.List (sortOn)
import Ideonomy.Rng (mkRng, uniform)

-- | A square similarity matrix, row-major.
type Sim = [[Double]]

cosine :: [Double] -> [Double] -> Double
cosine u v = dot / (nu * nv)
  where
    dot = sum (zipWith (*) u v)
    nu = orOne (sqrt (sum (map (^ (2 :: Int)) u)))
    nv = orOne (sqrt (sum (map (^ (2 :: Int)) v)))

orOne :: Double -> Double
orOne x = if x == 0 then 1 else x

simMatrix :: [[Double]] -> Sim
simMatrix vectors =
  [ [if i == j then 1 else cosine u v | (j, v) <- indexed] | (i, u) <- indexed ]
  where indexed = zip [0 :: Int ..] vectors

-- | Order items by the Fiedler vector of the similarity graph's Laplacian.
--
-- Power-iterates @M = cI - L@ (which reverses L's spectrum), deflating the
-- constant vector (L's trivial kernel), so the dominant remaining direction
-- is the Fiedler vector. Deterministic: the start vector comes from a fixed
-- seed.
spectralOrder :: Sim -> [Int]
spectralOrder sim
  | n <= 2 = [0 .. n - 1]
  | otherwise = map fst (sortOn snd (zip [0 ..] (iterate step v0 !! iters)))
  where
    n = length sim
    iters = 500 :: Int
    deg = [sum row - d | (row, d) <- zip sim (diagonal sim)]
    c = 2 * maximum deg + 1
    v0 = startVector n
    step v =
      let mean = sum v / fromIntegral n
          centered = map (subtract mean) v
          norm = orOne (sqrt (sum (map (^ (2 :: Int)) centered)))
          u = map (/ norm) centered
       in [ c * ui - (di * ui - (sum (zipWith (*) row u) - sii * ui))
          | (row, di, ui, sii) <- zip4 sim deg u (diagonal sim) ]
    zip4 (a : as) (b : bs) (x : xs) (y : ys) = (a, b, x, y) : zip4 as bs xs ys
    zip4 _ _ _ _ = []

diagonal :: Sim -> [Double]
diagonal sim = [row !! i | (i, row) <- zip [0 ..] sim]

-- | Fixed-seed uniform draws in [-1, 1), as the Python's @Random(4)@.
startVector :: Int -> [Double]
startVector n = go n (mkRng 4)
  where
    go 0 _ = []
    go k g = let (x, g') = uniform g in (2 * x - 1) : go (k - 1) g'

-- | Chain from the loneliest item (a natural endpoint) by nearest neighbor.
greedyChain :: Sim -> [Int]
greedyChain sim
  | n == 0 = []
  | otherwise = reverse (go [start] [i | i <- [0 .. n - 1], i /= start])
  where
    n = length sim
    start = firstMinOn (\i -> sum (sim !! i)) [0 .. n - 1]
    go order [] = order
    go order@(lst : _) unused =
      let nxt = firstMaxOn (\i -> sim !! lst !! i) unused
       in go (nxt : order) (filter (/= nxt) unused)
    go [] _ = error "greedyChain: empty order"

-- | Mean similarity of adjacent pairs: the objective all orders compete on.
smoothness :: Sim -> [Int] -> Double
smoothness sim order
  | length order < 2 = 1
  | otherwise = sum [sim !! a !! b | (a, b) <- zip order (drop 1 order)] / fromIntegral (length order - 1)

-- | @(order, method, smoothness)@: the smoother of spectral and greedy chains.
bestOrder :: Sim -> ([Int], String, Double)
bestOrder sim = (order, method, smoothness sim order)
  where
    candidates = [(spectralOrder sim, "spectral"), (greedyChain sim, "greedy")]
    (order, method) = firstMaxOn (smoothness sim . fst) candidates

-- | The first element attaining the extremum, as Python's @min@/@max@.
firstMinOn, firstMaxOn :: Ord b => (a -> b) -> [a] -> a
firstMinOn f = foldl1 (\m x -> if f x < f m then x else m)
firstMaxOn f = foldl1 (\m x -> if f x > f m then x else m)
