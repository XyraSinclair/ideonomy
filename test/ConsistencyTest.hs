-- | Doc <-> code consistency, machine-enforced. The catalog applies to
-- itself (P20 self-verify, P30 ledger): every count and cross-reference the
-- prose asserts is checked against the machine-readable source, so
-- "docs describe an earlier repo" fails the suite instead of waiting for a
-- careful reader. Runs from the repo root.
module ConsistencyTest (tests) where

import Control.Monad (filterM, forM)
import Data.Char (isDigit, isSpace)
import Data.List (isInfixOf, isPrefixOf, isSuffixOf, sort, tails)
import Harness
import Ideonomy.Divisions (divisions)
import Ideonomy.Json (Value, asArray, asString, parseFile)
import qualified Ideonomy.Json as J
import Ideonomy.Primitives (Primitive (..), multiModelPatterns, phaseName, phases, primitives)
import Ideonomy.Util (strip, stripCI, within)
import Ideonomy.Version (version)
import System.Directory (doesDirectoryExist, doesFileExist, listDirectory)
import System.FilePath (takeDirectory, (</>))

tests :: [Test]
tests =
  -- ORGANON.md and Primitives.hs must agree exactly.
  [ test "every_primitive_appears_in_organon_with_its_name" $ do
      organon <- readFile "ORGANON.md"
      let missing = [p.key ++ " (" ++ p.name ++ ")" | p <- primitives
                    , not (("**" ++ p.key ++ ". " ++ p.name ++ "**") `within` organon)]
      assertEq "missing or renamed in ORGANON.md" [] missing
  , test "organon_has_no_primitive_missing_from_code" $ do
      organon <- readFile "ORGANON.md"
      assertEq "P keys" (sort (map (.key) primitives)) (sort (boldKeys 'P' organon))
  , test "multi_model_patterns_match" $ do
      organon <- readFile "ORGANON.md"
      assertEq "M keys" (sort [takeWhile (not . isSpace) k | (k, _) <- multiModelPatterns]) (sort (boldKeys 'M' organon))
  , test "phases_match" $ do
      organon <- readFile "ORGANON.md"
      assertEq "phases" [] [ph | ph <- map phaseName phases, not (("— " ++ ph) `within` organon)]
  -- Numbers asserted in prose match the machine-readable source.
  , test "readme_primitive_count" $ readFile "README.md" >>= assertIn "README" (show n ++ " inference-time")
  , test "organon_primitive_count" $ readFile "ORGANON.md" >>= assertIn "ORGANON" ("same " ++ show n ++ " primitives")
  , test "cycles_primitive_count" $ readFile "CYCLES.md" >>= assertIn "CYCLES" (show n ++ " primitives")
  , test "skill_count_claims" $ do
      ds <- skillDirs
      readme <- readFile "README.md"
      let claims = skillClaims readme
      assertEq ("README skill counts vs " ++ show (length ds) ++ " dirs") [] [c | c <- claims, c /= length ds]
  , test "division_count" $ do
      readme <- readFile "README.md"
      r1 <- assertEq "divisions" 236 (length divisions)
      r2 <- assertIn "README" ("(" ++ show (length divisions) ++ " recovered)") readme
      pure (firstJust [r1, r2])
  -- Version.hs, plugin.json, and marketplace.json carry one version.
  , test "versions_agree" $ do
      plugin <- json ".claude-plugin/plugin.json"
      market <- json ".claude-plugin/marketplace.json"
      let pv = asString (J.key "version" plugin)
          mv = case asArray (J.key "plugins" market) of
            (p : _) -> asString (J.key "version" p)
            [] -> Nothing
      r1 <- assertEq "plugin.json" (Just version) pv
      r2 <- assertEq "marketplace.json" (Just version) mv
      pure (firstJust [r1, r2])
  -- Every relative markdown link in every tracked .md file resolves.
  , test "intra_repo_links_resolve" $ do
      mds <- markdownFiles "."
      broken <- fmap concat . forM mds $ \md -> do
        txt <- readFile md
        let targets = [t | t <- links txt, not (any (`isPrefixOf` t) ["http://", "https://", "mailto:", "#"])
                         , let p = takeWhile (/= '#') t, not (null p)]
        fmap concat . forM targets $ \t -> do
          let p = takeDirectory md </> takeWhile (/= '#') t
          f <- doesFileExist p
          d <- doesDirectoryExist p
          pure [md ++ " -> " ++ t | not (f || d)]
      assertEq "broken links" [] broken
  -- skills/ satisfies the agent-skill contract.
  , test "every_skill_dir_has_skill_md" $ do
      ds <- skillDirs
      missing <- filterM (fmap not . doesFileExist . (</> "SKILL.md") . ("skills" </>)) ds
      assertEq "dirs without SKILL.md" [] missing
  , test "frontmatter_name_matches_dir_and_spec" $ do
      ds <- skillDirs
      bad <- fmap concat . forM ds $ \d -> do
        fm <- frontmatter <$> readFile ("skills" </> d </> "SKILL.md")
        let nm = maybe "" id (lookup "name" fm)
        pure [d ++ ": name " ++ show nm | nm /= d || not (validName nm) || length nm > 64]
      assertEq "skill names" [] bad
  , test "frontmatter_description_present_and_bounded" $ do
      ds <- skillDirs
      bad <- fmap concat . forM ds $ \d -> do
        fm <- frontmatter <$> readFile ("skills" </> d </> "SKILL.md")
        let desc = maybe "" id (lookup "description" fm)
        pure [d ++ ": description " ++ show (length desc) ++ " chars" | null desc || length desc > 1024]
      assertEq "descriptions" [] bad
  , test "skills_readme_lists_every_skill" $ do
      ds <- skillDirs
      txt <- readFile "skills/README.md"
      assertEq "skills/README.md missing" [] [d | d <- ds, not (("(" ++ d ++ "/SKILL.md)") `within` txt)]
  , test "router_routes_only_to_real_skills" $ do
      ds <- skillDirs
      txt <- readFile "skills/route-to-the-right-move/SKILL.md"
      let refs = [r | r <- backticked txt, length r >= 8, '-' `elem` r, all (\c -> c `elem` ("abcdefghijklmnopqrstuvwxyz0123456789-" :: String)) r
                    , not ("ideonomy" `isPrefixOf` r)]
      assertEq "router references unknown skill" [] [r | r <- refs, r `notElem` ds]
  ]
  where
    n = length primitives

-- ---------------------------------------------------------------- helpers

json :: FilePath -> IO Value
json p = parseFile p >>= either (ioError . userError . ((p ++ ": ") ++)) pure

-- | @**P12.@ style keys with the given letter.
boldKeys :: Char -> String -> [String]
boldKeys letter txt = uniq [k | t <- tails txt, Just rest <- [stripPrefix' "**" t], (k, '.' : _) <- [span (\c -> c == letter || isDigit c) rest]
                            , [letter] `isPrefixOf` k, any isDigit k]
  where
    stripPrefix' pre s = if pre `isPrefixOf` s then Just (drop (length pre) s) else Nothing
    uniq = foldr (\x acc -> if x `elem` acc then acc else x : acc) []

-- | Numbers followed by optional "premier " / "agent " then "skills".
skillClaims :: String -> [Int]
skillClaims txt =
  [ read num
  | (prev, t) <- zip (' ' : txt) (tails txt), not (isDigit prev)
  , let (num, rest) = span isDigit t, not (null num)
  , let r1 = dropWhile isSpace rest
  , let r2 = dropOptional "premier" r1
  , let r3 = dropOptional "agent" r2
  , "skills" `isPrefixOf` r3 ]
  where
    dropOptional w s = case stripCI w s of
      Just rest | (c : _) <- rest, isSpace c -> dropWhile isSpace rest
      _ -> s

skillDirs :: IO [String]
skillDirs = do
  es <- sort <$> listDirectory "skills"
  filterM (doesDirectoryExist . ("skills" </>)) es

validName :: String -> Bool
validName s = not (null s) && all (`elem` ("abcdefghijklmnopqrstuvwxyz0123456789-" :: String)) s
  && not ("-" `isPrefixOf` s) && not ("-" `isSuffixOf` s) && not ("--" `isInfixOf` s)

-- | Every @*.md@ under the root, skipping dot-directories and build output.
markdownFiles :: FilePath -> IO [FilePath]
markdownFiles root = do
  es <- listDirectory root
  fmap concat . forM (sort es) $ \e -> do
    let p = if root == "." then e else root </> e
    d <- doesDirectoryExist p
    if d
      then if "." `isPrefixOf` e || e `elem` ["build", "bin", "node_modules"] then pure [] else markdownFiles p
      else pure [p | ".md" `isSuffixOf` e]

-- | Targets of @](target)@ links.
links :: String -> [String]
links txt = [takeWhile (/= ')') rest | t <- tails txt, Just rest <- [if "](" `isPrefixOf` t then Just (drop 2 t) else Nothing]]

backticked :: String -> [String]
backticked = go
  where
    go [] = []
    go ('`' : rest) = let (w, r) = break (== '`') rest in w : go (drop 1 r)
    go (_ : rest) = go rest

-- | The YAML-ish frontmatter as key/value pairs, folded scalars joined.
frontmatter :: String -> [(String, String)]
frontmatter txt = case lines txt of
  ("---" : rest) -> fold (takeWhile (/= "---") rest)
  _ -> []
  where
    fold ls = finish (foldl step (Nothing, [], []) ls)
    step (cur, buf, out) l = case keyLine l of
      Just (k, first) -> (Just k, if first `elem` [">-", ">", "|", "|-"] then [] else [first], flush cur buf out)
      Nothing -> case cur of
        Just _ -> (cur, buf ++ [strip l], out)
        Nothing -> (cur, buf, out)
    flush (Just k) buf out = out ++ [(k, strip (unwords (filter (not . null) buf)))]
    flush Nothing _ out = out
    finish (cur, buf, out) = flush cur buf out
    keyLine l = let (k, rest) = span (\c -> c `elem` ("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ-" :: String)) l
                 in case rest of
                      (':' : v) | not (null k) -> Just (k, strip v)
                      _ -> Nothing
