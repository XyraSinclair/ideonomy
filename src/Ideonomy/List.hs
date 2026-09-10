-- | The never-ending list-making structure: the list as the first-class
-- object. An 'Ideolist' is named, typed (@of_@ says what one item is),
-- provenanced (every list records the operation and parents that made it),
-- and persistent (a 'Store' survives across chats). The algebra is
-- applicative and closes over itself: the operations ship as an Ideolist.
--
-- Every operation is pure — parents are never mutated — and every result
-- carries lineage. Status is honest: a list is 'Open' until its denominator
-- is proven, then 'Closed'; claiming closure is a coverage assertion (P11).
module Ideonomy.List
  ( Status (..), Ideolist (..), statusName, readStatus
  , fromValue, toValue, decode, encode
  , combine, gate, grow, sampleItems
  , Store (..), storePath, save, load, names
  , operations, seedList, cli
  ) where

import Control.Monad (unless)
import Data.Char (isAlphaNum)
import Data.List (isInfixOf, isSuffixOf, sort)
import qualified Data.Set as Set
import Ideonomy.Json (Value (..), (!?), asString, asStrings, list, obj, str)
import qualified Ideonomy.Json as J
import Ideonomy.Cli (opt, optInt, optSeed, parseArgs, positionals, require, usage)
import Ideonomy.Models (Model, command, mkCommand)
import Ideonomy.Rng (Rng, mkRng, sample)
import Ideonomy.Util (casefold, joinWith, replace, strip)
import System.Directory (createDirectoryIfMissing, doesDirectoryExist, listDirectory, doesFileExist)
import System.FilePath (takeDirectory, (</>))

data Status = Open | Closed deriving (Eq, Show)

statusName :: Status -> String
statusName Open = "open"
statusName Closed = "closed"

readStatus :: String -> Either String Status
readStatus "open" = Right Open
readStatus "closed" = Right Closed
readStatus s = Left ("status " ++ show s ++ "; one of open, closed")

data Ideolist = Ideolist
  { name :: String
  , of_ :: String            -- ^ what ONE item is: the type
  , items :: [String]
  , status :: Status
  , madeBy :: String         -- ^ operation that produced this list
  , parents :: [String]      -- ^ names of source lists
  , source :: Maybe Value    -- ^ provenance: tier, url, seriation, relations...
  } deriving (Eq, Show)

seedList :: String -> String -> [String] -> Ideolist
seedList n o xs = Ideolist { name = n, of_ = o, items = xs, status = Open, madeBy = "seed", parents = [], source = Nothing }

-- ------------------------------------------------------------- persistence

fromValue :: Value -> Either String Ideolist
fromValue v = do
  n <- need "name"
  o <- need "of"
  st <- maybe (Right Open) readStatus (v !? "status" >>= asString)
  pure Ideolist
    { name = n, of_ = o
    , items = maybe [] asStrings (v !? "items")
    , status = st
    , madeBy = maybe "seed" id (v !? "made_by" >>= asString)
    , parents = maybe [] asStrings (v !? "parents")
    , source = case v !? "source" of
        Just Null -> Nothing
        s -> s
    }
  where
    need k = maybe (Left ("list record missing " ++ show k)) Right (v !? k >>= asString)

toValue :: Ideolist -> Value
toValue l = obj $
  [ ("name", str l.name), ("of", str l.of_), ("items", list l.items)
  , ("status", str (statusName l.status)), ("made_by", str l.madeBy)
  , ("parents", list l.parents) ]
  ++ maybe [] (\s -> [("source", s)]) l.source

decode :: String -> Either String Ideolist
decode s = J.parse s >>= fromValue

-- | One line in Python's default @json.dumps@ layout — the form the
-- catalog files on disk carry, so a rewrite touches only the record it changed.
encode :: Ideolist -> String
encode = J.renderSpaced . toValue

-- ----------------------------------------------------------------- algebra

-- | combine : Ideolist a -> Ideolist b -> Ideolist (a x b).  P12.
-- The template names @{a}@ and @{b}@.
combine :: String -> Maybe String -> Ideolist -> Ideolist -> Ideolist
combine template nm a b = Ideolist
  { name = maybe (a.name ++ "x" ++ b.name) id nm
  , of_ = "(" ++ a.of_ ++ ") x (" ++ b.of_ ++ ")"
  , items = [replace "{b}" y (replace "{a}" x template) | x <- a.items, y <- b.items]
  , status = Open
  , madeBy = "combine(" ++ show template ++ ")"
  , parents = [a.name, b.name]
  , source = Nothing
  }

-- | gate : Ideolist a -> (a -> Bool) -> (kept, residue).  P18.
-- The residue is a real list, not a discard — it seeds the next cycle.
gate :: String -> (String -> Bool) -> Ideolist -> (Ideolist, Ideolist)
gate why p l = (mk "kept" (filter p l.items), mk "residue" (filter (not . p) l.items))
  where
    mk tag xs = Ideolist
      { name = l.name ++ "/" ++ tag, of_ = l.of_, items = xs, status = Open
      , madeBy = "gate(" ++ why ++ ")", parents = [l.name], source = Nothing }

-- | grow : Ideolist a -> Model -> k -> Ideolist a.  The cheap-tier move:
-- enumeration is cheap; judgment of what grew is not done here. Growth
-- reopens any closure.
grow :: Model -> Int -> String -> Ideolist -> IO Ideolist
grow model k hint l = do
  reply <- model prompt
  let have = Set.fromList (map casefold l.items)
      new = [x | ln <- lines reply, let x = strip (dropWhile (`elem` " -*\t") ln)
               , not (null x), casefold x `Set.notMember` have]
  pure l { items = l.items ++ take k new, status = Open
         , madeBy = "grow(k=" ++ show k ++ ")", parents = [l.name], source = Nothing }
  where
    shown = unlines ["- " ++ x | x <- lastN 40 l.items]
    prompt =
      "Extend this list. Each item is: " ++ l.of_ ++ ".\n"
      ++ (if null hint then "" else "Guidance: " ++ hint) ++ "\n"
      ++ "Existing items (do not repeat, do not rephrase):\n" ++ shown ++ "\n"
      ++ "Give exactly " ++ show k ++ " NEW items, one per line, no numbering, no "
      ++ "commentary. Vary along dimensions the existing items neglect."
    lastN n xs = drop (length xs - n) xs

-- | sample : forced non-default picks (mode-collapse resistance).
sampleItems :: Int -> [String] -> Rng -> Ideolist -> Either String [String]
sampleItems n avoid g l
  | n > length pool = Left ("asked for " ++ show n ++ ", only " ++ show (length pool) ++ " available")
  | otherwise = Right (fst (sample n pool g))
  where
    pool = [x | x <- l.items, x `notElem` avoid]

-- ------------------------------------------------------------------- store

-- | A directory of Ideolists — the part that never ends. Default @.lists/@
-- beside the residue ledger; both are the cross-chat memory.
newtype Store = Store { root :: FilePath }

storePath :: Store -> String -> Either String FilePath
storePath st n
  | null n || not (all ok n) || ".." `isInfixOf` n = Left ("unusable list name " ++ show n)
  | otherwise = Right (st.root </> (n ++ ".json"))
  where ok c = isAlphaNum c || c `elem` "._/-"

save :: Store -> Ideolist -> IO FilePath
save st l = do
  p <- either (ioError . userError) pure (storePath st l.name)
  createDirectoryIfMissing True (takeDirectory p)
  writeFile p (J.renderIndent 1 (toValue l))
  pure p

load :: Store -> String -> IO Ideolist
load st n = do
  p <- either (ioError . userError) pure (storePath st n)
  exists <- doesFileExist p
  unless exists (ioError (userError ("no list named " ++ show n ++ " in " ++ st.root)))
  s <- readFile p
  either (ioError . userError . ((p ++ ": ") ++)) pure (decode s)

names :: Store -> IO [String]
names st = do
  exists <- doesDirectoryExist st.root
  if not exists then pure [] else sort <$> walk ""
  where
    walk rel = do
      let dir = if null rel then st.root else st.root </> rel
      entries <- listDirectory dir
      concat <$> mapM (entry rel) (sort entries)
    entry rel e = do
      let rel' = if null rel then e else rel </> e
      isDir <- doesDirectoryExist (st.root </> rel')
      if isDir then walk rel'
      else pure [take (length rel' - 5) rel' | ".json" `isSuffixOf` rel']

-- ------------------------------------------------------- self-application

operations :: Ideolist
operations = seedList "list-operations" "an operation in the list algebra, as a type signature"
  [ "combine : Ideolist a -> Ideolist b -> template -> Ideolist (a x b)"
  , "gate : Ideolist a -> (item -> bool) -> (kept, residue)"
  , "grow : Ideolist a -> Model -> k -> Ideolist a"
  , "sample : Ideolist a -> n -> seed -> [item]"
  , "corpus : Ideolist a -> cycles.State"
  , "save/load : Ideolist a <-> Store"
  ]

-- --------------------------------------------------------------------- CLI

-- | @ideonomy lists [--store DIR] <ls|new|add|show|sample|combine|grow> ...@
cli :: [String] -> IO ()
cli argv = do
  let a = parseArgs [] ["store", "n", "seed", "template", "name", "model", "k", "hint"] argv
      st = Store (maybe ".lists" id (opt "store" a))
  case positionals a of
    ["ls"] -> names st >>= mapM_ (\n -> do
      l <- load st n
      putStrLn (n ++ "  [" ++ statusName l.status ++ "]  " ++ show (length l.items) ++ " items  of: " ++ l.of_))
    ["new", n, o] -> save st (seedList n o []) >> putStrLn ("created " ++ n)
    ("add" : n : xs@(_ : _)) -> do
      l <- load st n
      let l' = l { items = l.items ++ [x | x <- xs, x `notElem` l.items] }
      save st l' >> putStrLn (n ++ ": " ++ show (length l'.items) ++ " items")
    ["show", n] -> do
      l <- load st n
      putStrLn (l.name ++ "  [" ++ statusName l.status ++ "]  of: " ++ l.of_ ++ "  made_by: " ++ l.madeBy
                ++ (if null l.parents then "" else "  parents: " ++ joinWith ", " l.parents))
      mapM_ (putStrLn . ("  - " ++)) l.items
    ["sample", n] -> do
      l <- load st n
      seed <- optSeed a
      xs <- either (ioError . userError) pure (sampleItems (optInt "n" 3 a) [] (mkRng seed) l)
      mapM_ (putStrLn . ("- " ++)) xs
    ["combine", x, y] -> do
      lx <- load st x
      ly <- load st y
      let out = combine (maybe "{a} {b}" id (opt "template" a)) (opt "name" a) lx ly
      save st out >> putStrLn (out.name ++ ": " ++ show (length out.items) ++ " items  of: " ++ out.of_)
    ["grow", n] -> do
      l <- load st n
      let model = command (mkCommand (require "model" a) "")
      grown <- grow model (optInt "k" 10 a) (maybe "" id (opt "hint" a)) l
      save st grown
      mapM_ (putStrLn . ("+ " ++)) (drop (length l.items) grown.items)
    _ -> usage "usage: ideonomy lists [--store DIR] ls | new NAME OF | add NAME ITEM... | show NAME | sample NAME [--n 3] [--seed N] | combine A B [--template '{a} {b}'] [--name N] | grow NAME --model CMD [--k 10] [--hint TEXT]"
