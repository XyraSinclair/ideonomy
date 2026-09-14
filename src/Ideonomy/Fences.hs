-- | The inter-map graph: fences as data.
--
-- A map's @source.boundary_claim@ says in prose which neighbours own the
-- cases it refuses; @source.fences@ says it as typed edges ('Fence'): a
-- neighbour, a kind, the rule that decides the side, and one case at the
-- fence. This module reads every grown map and reports the graph the
-- fences draw, so tiling becomes checkable: a fence whose target is not
-- in the catalog, a fence the neighbour never answers, a map that fences
-- nothing.
--
-- > ideonomy fences            # the graph: coverage, kinds, unknown targets, unreciprocated
-- > ideonomy fences NAME       # one map: every fence out, with rule and case, and every fence in
--
-- Deterministic and offline; exit 1 when a fence names a list the
-- catalog does not hold.
module Ideonomy.Fences (Graph (..), graph, unreciprocated, unknownTargets, cli) where

import Control.Monad (unless)
import qualified Data.Map.Strict as M
import Data.List (sortOn)
import Ideonomy.Check (Fence (..), FenceKind (..), fenceKindName, fencesOf, sideName)
import Ideonomy.Cli (parseArgs, positionals, usage)
import qualified Ideonomy.Canon as Canon
import Ideonomy.Json ((!?), asString)
import Ideonomy.List (Ideolist (..))
import Ideonomy.Util (joinWith)
import System.Exit (exitWith, ExitCode (..))

-- | Every map with its fences, and the names the catalog holds.
data Graph = Graph
  { maps :: [(String, [Fence])]      -- ^ map name, its fences out (catalog order)
  , known :: M.Map String String     -- ^ every list name in the catalog -> its @of@
  }

graph :: IO Graph
graph = do
  canon <- Canon.lists Canon.Canon
  grown <- Canon.lists Canon.Grown
  recs <- mapM (\l -> either (ioError . userError . ((l.name ++ ": ") ++)) (pure . (,) l.name) (fencesOf l))
            [l | l <- grown, isMap l]
  pure Graph { maps = recs, known = M.fromList [(l.name, l.of_) | l <- canon ++ grown] }

isMap :: Ideolist -> Bool
isMap l = (l.source >>= (!? "kind") >>= asString) == Just "map"

-- | Fences whose target is not a list in the catalog: (map, fence).
unknownTargets :: Graph -> [(String, Fence)]
unknownTargets g = [(n, f) | (n, fs) <- g.maps, f <- fs, not (M.member f.to g.known)]

-- | Fences to a map that has fences of its own but none back: (map, target).
-- A fence to a canon list or to a map without fences is not counted; the
-- neighbour had no seat to answer from.
unreciprocated :: Graph -> [(String, String)]
unreciprocated g =
  [ (n, f.to) | (n, fs) <- g.maps, f <- fs
  , Just back <- [M.lookup f.to fenced], not (null back), n `notElem` back ]
  where fenced = M.fromList [(n, map (.to) fs) | (n, fs) <- g.maps]

-- | Fences into one map: (from, fence).
incoming :: Graph -> String -> [(String, Fence)]
incoming g n = [(m, f) | (m, fs) <- g.maps, f <- fs, f.to == n]

-- ---------------------------------------------------------------- rendering

renderSummary :: Graph -> String
renderSummary g = joinWith "\n" $
  [ "maps: " ++ show (length g.maps) ++ "; with fences: " ++ show (length fencedMaps)
    ++ "; fences: " ++ show (length allFences) ]
  ++ [ "  " ++ fenceKindName k ++ ": " ++ show c | (k, c) <- kindCounts ]
  ++ [ "targets: " ++ show (M.size targets) ++ " distinct; grown " ++ show grownT ++ ", canon " ++ show canonT ]
  ++ [ "unknown targets: " ++ show (length unk) ]
  ++ [ "  " ++ n ++ " -> " ++ f.to | (n, f) <- unk ]
  ++ [ "unreciprocated: " ++ show (length unrec) ++ " (a map fenced, the neighbour has fences but none back)" ]
  ++ [ "  " ++ a ++ " -> " ++ b | (a, b) <- take 12 unrec ]
  ++ [ "  ... and " ++ show (length unrec - 12) ++ " more; ideonomy fences NAME shows a map's in and out" | length unrec > 12 ]
  ++ [ "without fences: " ++ joinWith ", " [n | (n, []) <- g.maps] | any (null . snd) g.maps ]
  ++ [ "most fenced (in): " ++ joinWith ", " [n ++ " " ++ show c | (n, c) <- take 8 (sortOn (\(n, c) -> (negate c, n)) (M.toList inDeg))] ]
  where
    fencedMaps = [n | (n, fs) <- g.maps, not (null fs)]
    allFences = [f | (_, fs) <- g.maps, f <- fs]
    kindCounts = [ (k, length [() | f <- allFences, f.kind == k]) | k <- [FenceK, Passage, Dependency, Loop] ]
    targets = M.fromListWith (+) [(f.to, 1 :: Int) | f <- allFences]
    grownNames = M.fromList [(n, ()) | (n, _) <- g.maps]
    grownT = length [() | t <- M.keys targets, M.member t grownNames]
    canonT = length [() | t <- M.keys targets, not (M.member t grownNames), M.member t g.known]
    unk = unknownTargets g
    unrec = unreciprocated g
    inDeg = targets

renderOne :: Graph -> String -> String
renderOne g n = joinWith "\n" $
  [ "=== " ++ n ++ "  [" ++ show (length out) ++ " out, " ++ show (length inc) ++ " in]" ]
  ++ concat [ [ "-> " ++ f.to ++ " (" ++ fenceKindName f.kind ++ "; case " ++ sideName f.caseIs ++ ")"
              , "   rule: " ++ f.rule
              , "   case: " ++ f.case_ ]
            | f <- out ]
  ++ (if null inc then [] else "in:" : [ "<- " ++ m ++ " (" ++ fenceKindName f.kind ++ "): " ++ f.rule | (m, f) <- inc ])
  where
    out = maybe [] id (lookup n g.maps)
    inc = incoming g n

-- --------------------------------------------------------------------- CLI

cli :: [String] -> IO ()
cli argv = do
  g <- graph
  case positionals (parseArgs [] [] argv) of
    [] -> do
      putStrLn (renderSummary g)
      unless (null (unknownTargets g)) (exitWith (ExitFailure 1))
    [n] | n `elem` map fst g.maps -> putStrLn (renderOne g n)
        | otherwise -> usage ("error: no grown map named " ++ show n)
    _ -> usage "usage: ideonomy fences [NAME]"
