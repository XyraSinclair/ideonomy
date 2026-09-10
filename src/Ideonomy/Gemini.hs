-- | The Gemini rail the corpus drivers share: text generation on a cheap
-- and a strong tier, JSON-mode replies, and batch embeddings. The boot
-- libraries have no HTTP client, so every call shells out to @curl@ (8.3
-- or later): the request body travels on stdin and the key travels from
-- @$GEMINI_API_KEY@ into a header through curl's own variable expansion,
-- so it never appears on a command line or on disk.
--
-- Failures retry with a linear back-off and then surface; nothing here
-- swallows an error. Also home to the few Python-shaped helpers the
-- drivers need (default @json.dumps@ layout, @repr@, truthiness) until the
-- spine grows them.
module Ideonomy.Gemini
  ( cheap, strong, embedModel, embedDim
  , apiKey, ask, askJson, embedBatch
  , pyRepr, pyReprList, pyStr, truthy, setKey
  ) where

import Control.Concurrent (threadDelay)
import Control.Exception (SomeException, fromException, throwIO, try)
import Data.Char (ord)
import Data.List (intercalate)
import Ideonomy.Json (Value (..), (!?), asArray, asString, int, obj, parse, render, renderSpaced, showDouble, str)
import Ideonomy.Util (strip)
import Numeric (showHex)
import System.Environment (lookupEnv)
import System.Exit (ExitCode (..), exitWith)
import System.IO (hPutStrLn, stderr)
import System.Process (proc, readCreateProcessWithExitCode)

cheap, strong, embedModel :: String
cheap = "gemini-3-flash-preview"
strong = "gemini-3.1-pro-preview"
embedModel = "gemini-embedding-001"

embedDim :: Int
embedDim = 256

-- | The key must be in the environment; the check runs when a request is
-- built (before any retry), as the Python's @_key()@ did, so a dry read of
-- the store needs no key and a missing key never retries.
apiKey :: IO String
apiKey = lookupEnv "GEMINI_API_KEY" >>= \case
  Just k | not (null k) -> pure k
  _ -> do
    hPutStrLn stderr "Set GEMINI_API_KEY in the environment before running this driver"
    exitWith (ExitFailure 1)

endpoint :: String -> String -> String
endpoint model verb = "https://generativelanguage.googleapis.com/v1beta/models/" ++ model ++ ":" ++ verb

-- | One POST; the parsed JSON reply, or an exception for any transport,
-- HTTP, or parse failure.
post :: Int -> String -> Value -> IO Value
post maxTime url body = do
  (code, out, err) <- readCreateProcessWithExitCode (proc "curl" args) (render body)
  case code of
    ExitSuccess -> either (\e -> ioError (userError ("gemini: reply is not JSON: " ++ e))) pure (parse out)
    ExitFailure n -> ioError (userError ("gemini: curl exit " ++ show n ++ ": " ++ take 500 (strip (err ++ out))))
  where
    args =
      [ "--silent", "--show-error", "--fail-with-body", "--max-time", show maxTime
      , "--header", "Content-Type: application/json"
      , "--variable", "%GEMINI_API_KEY", "--expand-header", "x-goog-api-key: {{GEMINI_API_KEY}}"
      , "--data-binary", "@-", url ]

-- | @retries@ attempts; attempt @i@ (from 0) that fails sleeps
-- @delaySecs i@ before the next, and the last failure is re-raised. An
-- exit is not a failure to retry.
retrying :: Int -> (Int -> Int) -> IO a -> IO a
retrying retries delaySecs act = apiKey >> go 0
  where
    go attempt = do
      r <- try act
      case r of
        Right v -> pure v
        Left (e :: SomeException)
          | Just (code :: ExitCode) <- fromException e -> exitWith code
          | attempt >= retries - 1 -> throwIO e
          | otherwise -> threadDelay (delaySecs attempt * 1000000) >> go (attempt + 1)

-- | One attempt: the model's text reply, or an exception.
generateOnce :: Bool -> String -> String -> IO String
generateOnce wantJson model prompt = do
  out <- post 180 (endpoint model "generateContent") body
  maybe (ioError (userError ("gemini: no text in reply: " ++ take 300 (render out)))) pure (replyText out)
  where
    body = obj $
      [("contents", Array [obj [("parts", Array [obj [("text", str prompt)]])]])]
      ++ [("generationConfig", obj [("responseMimeType", str "application/json")]) | wantJson]
    replyText out = do
      c <- headMay (asArray (maybe Null id (out !? "candidates")))
      p <- headMay (asArray (maybe Null id (c !? "content" >>= (!? "parts"))))
      p !? "text" >>= asString
    headMay (x : _) = Just x
    headMay [] = Nothing

-- | The model's text reply; three attempts, 10 s then 20 s apart.
ask :: String -> String -> IO String
ask model prompt = retrying 3 (\a -> 10 * (a + 1)) (generateOnce False model prompt)

-- | JSON mode: the reply parsed. A reply that is not JSON counts as a
-- failed attempt, as it did upstream.
askJson :: String -> String -> IO Value
askJson model prompt = retrying 3 (\a -> 10 * (a + 1)) $ do
  t <- generateOnce True model prompt
  either (\e -> ioError (userError ("gemini: reply is not JSON: " ++ e))) pure (parse t)

-- | One @batchEmbedContents@ call (the caller batches by 100): the raw
-- @values@ arrays, kept as parsed so a cache file re-renders byte for
-- byte.
embedBatch :: [String] -> IO [Value]
embedBatch texts = retrying 4 (\a -> 5 * (a + 1)) $ do
  out <- post 120 (endpoint embedModel "batchEmbedContents") body
  embs <- maybe (ioError (userError ("gemini: no embeddings in reply: " ++ take 300 (render out)))) pure (out !? "embeddings")
  mapM values (asArray embs)
  where
    body = obj [("requests", Array [request t | t <- texts])]
    request t = obj
      [ ("model", str ("models/" ++ embedModel))
      , ("content", obj [("parts", Array [obj [("text", str t)]])])
      , ("outputDimensionality", int embedDim) ]
    values e = maybe (ioError (userError "gemini: embedding without values")) pure (e !? "values")

-- ------------------------------------------------ Python-shaped helpers

-- | Python's @repr@ of a str, for the few stdout lines that printed lists.
pyRepr :: String -> String
pyRepr s
  | '\'' `elem` s && '"' `notElem` s = '"' : concatMap (esc '"') s ++ "\""
  | otherwise = '\'' : concatMap (esc '\'') s ++ "'"
  where
    esc q c
      | c == q = ['\\', c]
      | c == '\\' = "\\\\"
      | c == '\n' = "\\n"
      | c == '\r' = "\\r"
      | c == '\t' = "\\t"
      | ord c < 0x20 || ord c == 0x7f = "\\x" ++ pad2 (showHex (ord c) "")
      | otherwise = [c]
    pad2 h = replicate (2 - length h) '0' ++ h

pyReprList :: [String] -> String
pyReprList xs = "[" ++ intercalate ", " (map pyRepr xs) ++ "]"

-- | Python's @str@ of a decoded JSON value inside an f-string.
pyStr :: Value -> String
pyStr = \case
  String s -> s
  Null -> "None"
  Bool b -> if b then "True" else "False"
  Int n -> show n
  Double d -> showDouble d
  v -> renderSpaced v

-- | Python truthiness of a decoded JSON value (@if v.get("keep")@).
truthy :: Value -> Bool
truthy = \case
  Null -> False
  Bool b -> b
  Int n -> n /= 0
  Double d -> d /= 0
  String s -> not (null s)
  Array xs -> not (null xs)
  Object kvs -> not (null kvs)

-- | @d[k] = v@ on an ordered object: an existing key keeps its place, a new
-- one goes last.
setKey :: String -> Value -> [(String, Value)] -> [(String, Value)]
setKey k v kvs
  | any ((== k) . fst) kvs = [(k', if k' == k then v else v') | (k', v') <- kvs]
  | otherwise = kvs ++ [(k, v)]
