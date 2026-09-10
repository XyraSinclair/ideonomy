-- | JSON with boot libraries only: a parsec parser, a printer that matches
-- Python's @json.dumps@ conventions (compact separators, Python-style
-- indentation, integers kept integral, non-ASCII left raw), and small
-- accessors. Objects keep key order, because the ledgers on disk are read
-- by people and diffed by git.
module Ideonomy.Json
  ( Value (..)
  , parse, parseFile, readJsonl
  , render, renderSpaced, renderIndent, renderSorted, showDouble
  , (!?), key, asString, asStrings, asArray, asObject, asNumber, asInt, asBool
  , str, int, dbl, list, obj, sortKeys
  ) where

import Data.Char (chr, isControl, isDigit, isHexDigit, ord)
import Data.List (intercalate, sortOn)
import Numeric (showEFloat, showFFloat, showHex)
import qualified Text.Parsec as P
import Text.Parsec.String (Parser)
import Text.Read (readMaybe)

data Value
  = Null
  | Bool Bool
  | Int Integer
  | Double Double
  | String String
  | Array [Value]
  | Object [(String, Value)]
  deriving (Eq, Show)

-- ---------------------------------------------------------------- parsing

parse :: String -> Either String Value
parse s = either (Left . show) Right (P.parse (ws *> value <* ws <* P.eof) "" s)

parseFile :: FilePath -> IO (Either String Value)
parseFile p = parse <$> readFile p

-- | One value per non-blank line.
readJsonl :: FilePath -> IO [Value]
readJsonl p = do
  ls <- lines <$> readFile p
  mapM one [l | l <- ls, any (not . (`elem` " \t\r")) l]
  where
    one l = either (\e -> ioError (userError (p ++ ": " ++ e))) pure (parse l)

ws :: Parser ()
ws = P.skipMany (P.oneOf " \t\r\n")

value :: Parser Value
value = P.choice
  [ Null <$ P.string "null"
  , Bool True <$ P.string "true"
  , Bool False <$ P.string "false"
  , String <$> stringLit
  , number
  , Array <$> P.between (P.char '[' *> ws) (P.char ']') (P.sepBy (value <* ws) (P.char ',' *> ws))
  , Object <$> P.between (P.char '{' *> ws) (P.char '}') (P.sepBy pair (P.char ',' *> ws))
  ] P.<?> "JSON value"
  where
    pair = do
      k <- stringLit
      ws *> P.char ':' *> ws
      v <- value
      ws
      pure (k, v)

stringLit :: Parser String
stringLit = P.char '"' *> P.many ch <* P.char '"'
  where
    ch = (P.char '\\' *> esc) P.<|> P.satisfy (\c -> c /= '"' && c /= '\\')
    esc = P.choice
      [ '"' <$ P.char '"', '\\' <$ P.char '\\', '/' <$ P.char '/'
      , '\b' <$ P.char 'b', '\f' <$ P.char 'f', '\n' <$ P.char 'n'
      , '\r' <$ P.char 'r', '\t' <$ P.char 't', P.char 'u' *> unicode ]
    hex4 = do
      h <- P.count 4 (P.satisfy isHexDigit)
      pure (read ("0x" ++ h) :: Int)
    unicode = do
      hi <- hex4
      if hi >= 0xD800 && hi <= 0xDBFF
        then do
          lo <- P.string "\\u" *> hex4
          pure (chr (0x10000 + (hi - 0xD800) * 0x400 + (lo - 0xDC00)))
        else pure (chr hi)

number :: Parser Value
number = do
  s <- P.many1 (P.satisfy (\c -> isDigit c || c `elem` "-+.eE"))
  let isFloat = any (`elem` ".eE") s
  case (if isFloat then Double <$> readMaybe s else Int <$> readMaybe s) of
    Just v -> pure v
    Nothing -> fail ("bad number " ++ s)

-- --------------------------------------------------------------- printing

-- | Compact, Python @separators=(",", ":")@.
render :: Value -> String
render = \case
  Null -> "null"
  Bool b -> if b then "true" else "false"
  Int n -> show n
  Double d -> showDouble d
  String s -> quote s
  Array xs -> "[" ++ intercalate "," (map render xs) ++ "]"
  Object kvs -> "{" ++ intercalate "," [quote k ++ ":" ++ render v | (k, v) <- kvs] ++ "}"

-- | Python's default @json.dumps@ layout (@", "@ and @": "@ separators,
-- non-ASCII raw): the bytes the embedding cache keys and the map
-- fingerprints are hashed over.
renderSpaced :: Value -> String
renderSpaced = \case
  Array xs -> "[" ++ intercalate ", " (map renderSpaced xs) ++ "]"
  Object kvs -> "{" ++ intercalate ", " [quote k ++ ": " ++ renderSpaced v | (k, v) <- kvs] ++ "}"
  v -> render v

-- | Python @json.dumps(indent=n)@ layout.
renderIndent :: Int -> Value -> String
renderIndent n = go 0
  where
    pad d = replicate (d * n) ' '
    go d = \case
      Array [] -> "[]"
      Object [] -> "{}"
      Array xs -> "[\n" ++ intercalate ",\n" [pad (d + 1) ++ go (d + 1) x | x <- xs] ++ "\n" ++ pad d ++ "]"
      Object kvs -> "{\n" ++ intercalate ",\n" [pad (d + 1) ++ quote k ++ ": " ++ go (d + 1) v | (k, v) <- kvs] ++ "\n" ++ pad d ++ "}"
      v -> render v

-- | Compact with keys sorted recursively (@sort_keys=True@).
renderSorted :: Value -> String
renderSorted = render . sortKeys

sortKeys :: Value -> Value
sortKeys = \case
  Array xs -> Array (map sortKeys xs)
  Object kvs -> Object (sortOn fst [(k, sortKeys v) | (k, v) <- kvs])
  v -> v

quote :: String -> String
quote s = '"' : concatMap esc s ++ "\""
  where
    esc '"' = "\\\""
    esc '\\' = "\\\\"
    esc '\n' = "\\n"
    esc '\r' = "\\r"
    esc '\t' = "\\t"
    esc '\b' = "\\b"
    esc '\f' = "\\f"
    esc c | isControl c && ord c < 0x20 = "\\u" ++ pad4 (showHex (ord c) "")
          | otherwise = [c]
    pad4 h = replicate (4 - length h) '0' ++ h

-- | Python's @repr(float)@: shortest round-trip digits, fixed notation for
-- 1e-4 <= |x| < 1e16, otherwise @1e-05@ style.
showDouble :: Double -> String
showDouble d
  | isNaN d || isInfinite d = error "showDouble: non-finite"
  | d == 0 = if isNegativeZero d then "-0.0" else "0.0"
  | a >= 1e-4 && a < 1e16 = showFFloat Nothing d ""
  | otherwise = sci (showEFloat Nothing d "")
  where
    a = abs d
    sci s =
      let (m, e) = break (== 'e') s
          m' = if ".0" `isSuffixOf'` m then take (length m - 2) m else m
          ex = read (drop 1 e) :: Int
          sign = if ex < 0 then "-" else "+"
          digits = show (abs ex)
       in m' ++ "e" ++ sign ++ (if length digits < 2 then '0' : digits else digits)
    isSuffixOf' suf xs = suf == drop (length xs - length suf) xs

-- -------------------------------------------------------------- accessors

infixl 9 !?
(!?) :: Value -> String -> Maybe Value
Object kvs !? k = lookup k kvs
_ !? _ = Nothing

-- | Lookup with a default.
key :: String -> Value -> Value
key k v = maybe Null id (v !? k)

asString :: Value -> Maybe String
asString (String s) = Just s
asString _ = Nothing

asStrings :: Value -> [String]
asStrings (Array xs) = [s | String s <- xs]
asStrings _ = []

asArray :: Value -> [Value]
asArray (Array xs) = xs
asArray _ = []

asObject :: Value -> [(String, Value)]
asObject (Object kvs) = kvs
asObject _ = []

asNumber :: Value -> Maybe Double
asNumber (Int n) = Just (fromInteger n)
asNumber (Double d) = Just d
asNumber _ = Nothing

asInt :: Value -> Maybe Int
asInt (Int n) = Just (fromInteger n)
asInt _ = Nothing

asBool :: Value -> Maybe Bool
asBool (Bool b) = Just b
asBool _ = Nothing

-- ----------------------------------------------------------- constructors

str :: String -> Value
str = String

int :: Int -> Value
int = Int . toInteger

dbl :: Double -> Value
dbl = Double

list :: [String] -> Value
list = Array . map String

obj :: [(String, Value)] -> Value
obj = Object
