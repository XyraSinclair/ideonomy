-- | The respiratory engine: expand <-> compress breaths with an MDL ratchet.
--
-- Substrate-agnostic. A corpus is text items; expand, judge, and compress
-- are pluggable functions in a 'Config'; the two-part
-- minimum-description-length code decides whether each breath is kept.
-- Mechanical defaults run with no model so the rhythm is testable offline;
-- model hooks deepen every phase.
--
-- Everything here is pure: 'breath' maps a 'State' to a 'Record' and the
-- next 'State', and 'run' folds breaths until the budget is spent or the
-- compression plateaus. Design: CYCLES.md.
module Ideonomy.Cycles
  ( Item (..), Compression (..), State (..), Record (..), Expansion (..)
  , Expand, Judge, Compress, Config (..), defaultConfig
  , stopWords, labelBits, tokens
  , add, seed
  , modelBits, dataBits, codeLength, rawBits
  , compressMechanical, compressWith, residueExtract, residueWith
  , expandMechanical, judgeMechanical
  , breath, run, expansionName
  ) where

import Data.List (sort)
import qualified Data.Map.Strict as Map
import Data.Maybe (fromMaybe, isNothing)
import Data.Set (Set)
import qualified Data.Set as Set
import Ideonomy.Util (roundTo, wordsAlnum)

stopWords :: Set String
stopWords = Set.fromList
  [ "a", "an", "and", "are", "as", "at", "be", "by", "for", "from", "in"
  , "is", "it", "of", "on", "or", "the", "to", "with", "that", "this" ]

-- | Cost (in token-equivalents) of a dictionary pointer into the structure:
-- a group label is just an index, not a fresh symbol, so it is cheap. This
-- is the only free parameter in the code length, and the score is
-- sensitive to it: the same cluster can flip between paying and not paying
-- as it moves. That is fine for the RATCHET, which only ever compares
-- structures under the same constant; absolute code lengths are not
-- meaningful across different constants.
labelBits :: Double
labelBits = 1.0

tokens :: String -> Set String
tokens text = Set.fromList (wordsAlnum text) `Set.difference` stopWords

-- ------------------------------------------------------------------ state

data Item = Item
  { ident :: String
  , text :: String
  , born :: Int          -- ^ cycle it entered the corpus
  , source :: String     -- ^ @seed@ | @expand:<op>@ | ...
  } deriving (Eq, Show)

-- | A structure that explains the corpus: groups, each with a distilled
-- rule. Both association lists keep label insertion order.
data Compression = Compression
  { groups :: [(String, [String])]     -- ^ label -> member item ids
  , rule :: [(String, Set String)]     -- ^ label -> shared-token invariant
  } deriving (Eq, Show)

-- | L(structure): cost to write the structure down. Only non-empty rules
-- are structure. A singleton group carries an empty rule and contributes
-- nothing here: it is an unexplained item, encoded raw in the data term,
-- not a compression claim.
modelBits :: Compression -> Double
modelBits comp = sum [labelBits + fromIntegral (Set.size toks) | (_, toks) <- comp.rule, not (Set.null toks)]

data State = State
  { corpus :: [(String, Item)]         -- ^ insertion order, as the Python dict
  , compression :: Maybe Compression
  , residue :: [String]                -- ^ item ids handed forward
  , history :: [Record]
  , cycle :: Int
  , nextId :: Int
  } deriving (Show)

data Expansion = Accepted | Reverted deriving (Eq, Show)

expansionName :: Expansion -> String
expansionName Accepted = "accepted"
expansionName Reverted = "reverted"

-- | One breath's ledger line.
data Record = Record
  { cycle :: Int
  , items :: Int
  , added :: Int
  , groups :: Int
  , codelen :: Double
  , raw :: Double
  , ratio :: Double
  , residue :: Int
  , expansion :: Expansion
  } deriving (Eq, Show)

-- | Append an item; returns its id. Ids are never reused, even after a
-- rolled-back breath.
add :: String -> String -> State -> (String, State)
add txt src s = (iid, s { corpus = s.corpus ++ [(iid, item)], nextId = s.nextId + 1 })
  where
    iid = 'i' : show s.nextId
    item = Item { ident = iid, text = txt, born = s.cycle, source = src }

seed :: [String] -> State
seed = foldl (\s t -> snd (add t "seed" s)) empty
  where empty = State { corpus = [], compression = Nothing, residue = [], history = [], cycle = 0, nextId = 0 }

itemOf :: State -> String -> Item
itemOf s iid = fromMaybe (error ("cycles: no item " ++ iid)) (lookup iid s.corpus)

-- ---------------------------------------------------------- MDL: the ratchet

-- | L(item | rule): tokens of the item not predicted by its group's rule.
--
-- Symmetric difference: tokens the rule promised but the item lacks, plus
-- tokens the item carries that the rule did not capture. Both are residual.
dataBits :: Item -> Set String -> Double
dataBits item r
  | Set.null r = rawCost toks               -- raw-encoded: no structure claimed
  | otherwise = fromIntegral (Set.size (symDiff toks r)) + labelBits
  where toks = tokens item.text

symDiff :: Ord a => Set a -> Set a -> Set a
symDiff a b = (a `Set.difference` b) `Set.union` (b `Set.difference` a)

-- | @len(toks) or 1@.
rawCost :: Set String -> Double
rawCost toks = fromIntegral (max 1 (Set.size toks))

memberOf :: Compression -> Map.Map String String
memberOf comp = Map.fromList [(iid, lbl) | (lbl, ids) <- comp.groups, iid <- ids]

ruleOf :: Compression -> String -> Set String
ruleOf comp lbl = fromMaybe Set.empty (lookup lbl comp.rule)

-- | Two-part code length: L(structure) + sum L(item | structure).
codeLength :: State -> Compression -> Double
codeLength s comp = modelBits comp + sum [dataBits it (ruleFor iid) | (iid, it) <- s.corpus]
  where
    members = memberOf comp
    ruleFor iid = maybe Set.empty (ruleOf comp) (Map.lookup iid members)

-- | Code length with no structure: the corpus encoded item by item.
rawBits :: State -> Double
rawBits s = sum [rawCost (tokens it.text) | (_, it) <- s.corpus]

-- ------------------------------------------------- mechanical phase defaults

-- | COMPRESS (P6/P7/P8/distill) at the default coverage threshold 0.45.
compressMechanical :: State -> Compression
compressMechanical = compressWith 0.45

-- | Greedy agglomeration by token coverage; each group's rule is the
-- majority-shared token set (the distilled invariant).
--
-- Similarity is coverage (the fraction of the new item's tokens the cluster
-- vocabulary already holds), not Jaccard, so large clusters are not
-- penalised by their growing vocabulary's effect on a union denominator.
compressWith :: Double -> State -> Compression
compressWith threshold s = Compression { groups = grouped, rule = map distill grouped }
  where
    grouped = [(lbl, reverse ids) | (lbl, _, ids) <- foldl place [] s.corpus]
    -- clusters: (label, accumulated vocabulary, member ids reversed), in insertion order
    place clusters (iid, it) =
      let toks = tokens it.text
          coverage acc = fromIntegral (Set.size (toks `Set.intersection` acc)) / rawCost toks
          scored = [(lbl, coverage acc) | (lbl, acc, _) <- clusters, coverage acc > 0]
       in case scored of
            _ | Just (best, sim) <- firstMax scored, sim >= threshold ->
                  [ if lbl == best then (lbl, acc `Set.union` toks, iid : ids) else c
                  | c@(lbl, acc, ids) <- clusters ]
            _ -> clusters ++ [('g' : show (length clusters), toks, [iid])]
    firstMax = foldl (\m x -> case m of
      Just (_, best) | snd x <= best -> m
      _ -> Just x) Nothing
    -- distill each group's rule (P-distill): tokens shared by a strict
    -- majority of members, the neutral-or-better threshold
    -- (2*count - n - 1 >= 0): inclusion never raises the group's code length.
    -- Singletons get an empty rule: one item is not yet structure.
    distill (lbl, members)
      | length members < 2 = (lbl, Set.empty)
      | otherwise =
          let toksOf = map (tokens . (.text) . itemOf s) members
              counts = Map.fromListWith (+) [(t, 1 :: Int) | toks <- toksOf, t <- Set.toList toks]
              need = length members `div` 2 + 1
              cand = Map.keysSet (Map.filter (>= need) counts)
              -- The rule is a compression CLAIM; keep it only if it pays. If
              -- encoding the members via the rule costs at least as much as
              -- encoding them raw, drop it: codelen(corpus) <= raw_bits(corpus)
              -- always holds, so a "compression" is never worse than nothing.
              withRule = labelBits + fromIntegral (Set.size cand)
                + sum [fromIntegral (Set.size (symDiff toks cand)) + labelBits | toks <- toksOf]
              rawSum = sum (map rawCost toksOf)
           in (lbl, if withRule < rawSum then cand else Set.empty)

-- | RESIDUE at the default quantile 0.7.
residueExtract :: State -> Compression -> [String]
residueExtract = residueWith 0.7

-- | RESIDUE: items whose per-item data cost is in the top tail, plus
-- singleton groups (structure that failed to generalize).
--
-- A flat cost distribution has no tail: when every item resists equally,
-- nothing resists /more/, so nothing is residue. Items at the global
-- minimum are excluded so ties cannot flood the seed with the whole corpus.
residueWith :: Double -> State -> Compression -> [String]
residueWith quantile s comp
  | null costs = []
  | otherwise = Set.toAscList (Set.fromList (res ++ singletons))
  where
    members = memberOf comp
    costs = [(iid, dataBits it (ruleOf comp (fromMaybe "" (Map.lookup iid members)))) | (iid, it) <- s.corpus]
    ordered = sort (map snd costs)
    n = length ordered
    cut = ordered !! min (n - 1) (floor (quantile * fromIntegral n))
    lowest = minimum ordered
    res = [iid | (iid, c) <- costs, c >= cut, c > lowest]
    singletons = [iid | (_, [iid]) <- comp.groups]

-- | EXPAND (P12 combine), biased toward the residue: cross residue tokens
-- with corpus tokens to phrase frontier probes. Mechanical stand-in for a
-- model probing the unexplained; deterministic (no RNG) by construction.
expandMechanical :: State -> Maybe Compression -> Int -> [String]
expandMechanical s _ k = go [] pairs
  where
    seeds = if null s.residue then map fst s.corpus else s.residue
    resTokens = concat [Set.toAscList (tokens (itemOf s iid).text) | iid <- seeds]
    pool = concat [Set.toAscList (tokens it.text) | (_, it) <- s.corpus]
    seen = Set.fromList [it.text | (_, it) <- s.corpus]
    step = max 1 (length resTokens)
    pairs = [(a, b) | (i, a) <- zip [0 ..] resTokens, b <- everyNth step (drop i pool)]
    everyNth _ [] = []
    everyNth m (x : xs) = x : everyNth m (drop (m - 1) xs)
    go out [] = reverse out
    go out ((a, b) : rest)
      | a == b = go out rest
      | otherwise =
          let txt = a ++ " " ++ b
              out' = if txt `Set.notMember` seen && txt `notElem` out then txt : out else out
           in if length out' >= k then reverse out' else go out' rest

-- | JUDGE/FILTER (P18): drop candidates that duplicate or are near-subsets
-- of existing corpus items.
judgeMechanical :: State -> [String] -> [String]
judgeMechanical s = filter keep
  where
    existing = [tokens it.text | (_, it) <- s.corpus]
    keep txt =
      let toks = tokens txt
          near e = toks `Set.isSubsetOf` e || jaccard toks e >= 0.9
       in not (Set.null toks) && not (any near existing)
    jaccard :: Set String -> Set String -> Double
    jaccard a b = fromIntegral (Set.size (a `Set.intersection` b))
      / fromIntegral (max 1 (Set.size (a `Set.union` b)))

-- ------------------------------------------------------------- the breath

type Expand = State -> Maybe Compression -> Int -> [String]
type Judge = State -> [String] -> [String]
type Compress = State -> Compression

data Config = Config
  { expand :: Expand
  , judge :: Judge
  , compress :: Compress
  , k :: Int
  }

defaultConfig :: Config
defaultConfig = Config { expand = expandMechanical, judge = judgeMechanical, compress = compressMechanical, k = 6 }

-- | One expand->judge->compress->measure->residue breath, with MDL ratchet.
--
-- The expansion is accepted only if it does not worsen the compression
-- ratio; on regression the new items are rolled back and the breath is
-- recorded as a failed expansion (logged, never hidden).
breath :: Config -> State -> (Record, State)
breath cfg s0 = (rec, final)
  where
    cyc = s0.cycle + 1
    s1 = State { corpus = s0.corpus, compression = s0.compression, residue = s0.residue
               , history = s0.history, cycle = cyc, nextId = s0.nextId }
    prevComp = s0.compression
    prevLen = maybe 0 (codeLength s1) prevComp
    prevRatio = if prevLen /= 0 then rawBits s1 / prevLen else 1.0
    -- breathe in
    kept = cfg.judge s1 (cfg.expand s1 prevComp cfg.k)
    s2 = foldl (\s t -> snd (add t ("expand:c" ++ show cyc) s)) s1 kept
    -- breathe out
    grown = cfg.compress s2
    newLen = codeLength s2 grown
    newRatio = if newLen /= 0 then rawBits s2 / newLen else 0.0
    -- Ratchet on the compression RATIO, not absolute codelen: adding items
    -- always raises absolute bits, so the scale-correct test is whether the
    -- corpus still compresses at least as well, i.e. the new items were on
    -- the frontier (joined the structure) rather than noise (inflated residue).
    accepted = isNothing prevComp || newRatio >= prevRatio - 1e-9
    -- on regression roll back the expansion; keep the prior structure (P32)
    (s3, comp, len) =
      if accepted then (s2, grown, newLen)
      else let s' = s2 { corpus = s1.corpus }
               c' = cfg.compress s'
            in (s', c', codeLength s' c')
    res = residueExtract s3 comp
    rec = Record
      { cycle = cyc
      , items = length s3.corpus
      , added = if accepted then length kept else 0
      , groups = length comp.groups
      , codelen = roundTo 2 len
      , raw = roundTo 2 (rawBits s3)
      , ratio = if len /= 0 then roundTo 3 (rawBits s3 / len) else 0.0
      , residue = length res
      , expansion = if accepted then Accepted else Reverted
      }
    final = State { corpus = s3.corpus, compression = Just comp, residue = res
                  , history = s3.history ++ [rec], cycle = cyc, nextId = s3.nextId }

-- | Breathe until the budget is spent or compression plateaus (P30/P32).
run :: Config -> Int -> State -> State
run cfg budget = go budget (0 :: Int)
  where
    go 0 _ s = s
    go n stale s =
      let prev = case s.history of
            [] -> Nothing
            hs -> Just (last hs).codelen
          (rec, s') = breath cfg s
          flat = case prev of
            Just p -> abs (rec.codelen - p) < 0.5 && rec.added == 0
            Nothing -> False
       in if flat
            then (if stale + 1 >= 2 then s' else go (n - 1) (stale + 1) s')
            else go (n - 1) 0 s'
