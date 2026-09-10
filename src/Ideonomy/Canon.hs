-- | Gunkel's recovered corpus as data — the canon layer of the catalog.
--
-- A canon list is an 'Ideolist' whose @source.tier == "canon"@: recovered
-- verbatim from Patrick Gunkel's own publications, never machine-generated,
-- with per-record provenance (original URL, archive route, page title).
-- Machine-grown extensions live in the @grown@ tier and never masquerade as
-- canon. Both ship as JSONL under @data/@: @canon-*.jsonl@ and @grown.jsonl@.
module Ideonomy.Canon (Tier (..), tierName, readTier, lists, get, cli) where

import Data.List (isPrefixOf, sort, sortOn)
import Ideonomy.Cli (opt, optInt, optSeed, parseArgs, positionals, usage)
import Ideonomy.Data (dataDir)
import Ideonomy.Json ((!?), asString, readJsonl)
import Ideonomy.List (Ideolist (..), fromValue, sampleItems)
import Ideonomy.Rng (mkRng)
import System.Directory (listDirectory)
import System.FilePath ((</>))

data Tier = Canon | Grown deriving (Eq, Show)

tierName :: Tier -> String
tierName Canon = "canon"
tierName Grown = "grown"

readTier :: String -> Either String Tier
readTier "canon" = Right Canon
readTier "grown" = Right Grown
readTier s = Left ("tier " ++ show s ++ "; one of canon, grown")

-- | Every list of one provenance tier, in catalog file order.
lists :: Tier -> IO [Ideolist]
lists tier = do
  dir <- dataDir
  files <- sort . filter isListFile <$> listDirectory dir
  rows <- concat <$> mapM (readJsonl . (dir </>)) files
  ls <- mapM (either (ioError . userError) pure . fromValue) rows
  pure [l | l <- ls, tierOf l == Just (tierName tier)]
  where
    isListFile f = ("canon-" `isPrefixOf` f && ".jsonl" `isSuffix` f) || f == "grown.jsonl"
    isSuffix suf s = suf == drop (length s - length suf) s

tierOf :: Ideolist -> Maybe String
tierOf l = l.source >>= (!? "tier") >>= asString

get :: Tier -> String -> IO Ideolist
get tier n = do
  ls <- lists tier
  case [l | l <- ls, l.name == n] of
    (l : _) -> pure l
    [] -> ioError (userError ("no " ++ tierName tier ++ " list named " ++ show n))

sourceUrl :: Ideolist -> String
sourceUrl l = field "url" ++ " (via " ++ field "via" ++ ")"
  where field k = maybe "?" id (l.source >>= (!? k) >>= asString)

-- | @ideonomy canon [--tier canon|grown] ls | show NAME | sample NAME [--n 3] [--seed N]@
cli :: [String] -> IO ()
cli argv = do
  let a = parseArgs [] argv
  tier <- either (ioError . userError) pure (readTier (maybe "canon" id (opt "tier" a)))
  case positionals a of
    ["ls"] -> do
      ls <- lists tier
      mapM_ (\l -> putStrLn (pad5 (length l.items) ++ "  " ++ l.name ++ "  |  " ++ l.of_)) (sortOnName ls)
      putStrLn ("total: " ++ show (length ls) ++ " lists, " ++ show (sum (map (length . (.items)) ls)) ++ " items")
    ["show", n] -> do
      l <- get tier n
      putStrLn (l.name ++ "  of: " ++ l.of_)
      putStrLn ("source: " ++ sourceUrl l)
      mapM_ (putStrLn . ("  - " ++)) l.items
    ["sample", n] -> do
      l <- get tier n
      seed <- optSeed a
      xs <- either (ioError . userError) pure (sampleItems (optInt "n" 3 a) [] (mkRng seed) l)
      mapM_ (putStrLn . ("- " ++)) xs
    _ -> usage "usage: ideonomy canon [--tier canon|grown] ls | show NAME | sample NAME [--n 3] [--seed N]"
  where
    pad5 n = let s = show n in replicate (5 - length s) ' ' ++ s
    sortOnName = sortOn (.name)
