-- | The offline catalog atlas: one static page joining every list of both
-- tiers to its display-only seriation order and its stored map point,
-- without changing a list or a coordinate.
--
-- Three data files meet here. The catalog itself ('Canon.lists', both
-- tiers). @seriations.jsonl@: per-canon-list display orders — a sidecar,
-- so canon text stays verbatim while the page shows items along a named
-- axis. @catalog-map.jsonl@: a @_meta@ row and one 2-D point per list,
-- each point carrying the SHA-256 fingerprint of the sorted items it was
-- projected from; a point is shown only when the fingerprint still matches
-- the items, so a regrown list loses its position rather than keeping a
-- stale one. Every join failure is loud: a sidecar order that is not a
-- permutation, a relation whose endpoint is not an item, a priority naming
-- a non-item, all abort the build.
--
-- The page embeds the payload as inert JSON (keys sorted, @&<>@ and the
-- U+2028/2029 line separators escaped) inside a template read from
-- @data/atlas.html@; markup never interpolates a data string.
--
-- @ideonomy atlas [--output docs/catalog-map.html]@
module Ideonomy.Atlas (catalog, render, itemsHash, sha256Hex, cli) where

import Data.Bits (complement, rotateR, shiftL, shiftR, xor, (.&.), (.|.))
import Data.Char (ord)
import Data.List (intercalate, sort, zipWith4)
import qualified Data.Map.Strict as Map
import Data.Word (Word32, Word8)
import Ideonomy.Canon (Tier (..), tierName)
import qualified Ideonomy.Canon as Canon
import Ideonomy.Cli (opt, parseArgs, positionals, usage)
import Ideonomy.Data (dataFile, readCatalogJsonl)
import Ideonomy.Json (Value (..), (!?), asString, int, list, obj, renderSorted, str)
import qualified Ideonomy.Json as J
import Ideonomy.List (Ideolist (..), toValue)
import Ideonomy.Util (replace, strip)
import Numeric (showHex)
import System.Directory (createDirectoryIfMissing)
import System.FilePath (takeDirectory)
import System.IO (IOMode (..), hGetContents', hPutStr, hSetEncoding, openFile, utf8, withFile)

-- | Join catalog records to display-only orders and existing map points:
-- @{"lists": [...], "map": _meta, "stored_points": n}@.
catalog :: IO Value
catalog = do
  sidecar <- readCatalogJsonl "seriations.jsonl"
  mapRows <- readCatalogJsonl "catalog-map.jsonl"
  let orders = Map.fromList [(n, row) | row <- sidecar, Just n <- [row !? "name" >>= asString]]
      metadata = last (Object [] : [m | row <- mapRows, Just m <- [row !? "_meta"]])
  points <- Map.fromList <$> mapM pointKey [row | row <- mapRows, row !? "_meta" == Nothing]
  records <- concat <$> mapM (tierRecords orders points) [Canon, Grown]
  pure (obj [("lists", Array records), ("map", metadata), ("stored_points", int (Map.size points))])
  where
    pointKey row = case (row !? "tier" >>= asString, row !? "name" >>= asString) of
      (Just t, Just n) -> pure ((t, n), row)
      _ -> ioError (userError ("catalog-map row without tier and name: " ++ J.render row))
    tierRecords orders points tier = do
      ls <- Canon.lists tier
      let byName = Map.fromList [(l.name, l) | l <- ls]   -- last wins, as a Python dict
      mapM (either (ioError . userError) pure . record orders points tier) (Map.elems byName)

-- | One atlas record: the list as stored plus tier, position, seriation,
-- and display order; canon items reordered by the sidecar when present.
record :: Map.Map String Value -> Map.Map (String, String) Value -> Tier -> Ideolist -> Either String Value
record orders points tier l = do
  (position, note) <- case Map.lookup (tierName tier, l.name) points of
    Nothing -> Right (Null, "no stored projection")
    Just p
      | (p !? "items_hash" >>= asString) == Just (itemsHash l.items) ->
          case (p !? "x", p !? "y") of
            (Just x, Just y) -> Right (Array [x, y], "current item fingerprint")
            _ -> Left ("catalog-map point without x and y: " ++ l.name)
      | otherwise -> Right (Null, "stored projection predates or cannot verify these items")
  let stored = maybe (Object []) (\s -> if truthy s then s else Object []) (src "seriation")
  (items, seriation, display) <- case (tier, Map.lookup l.name orders) of
    (Canon, Just sidecar) -> do
      order <- maybe (Left invalidOrder) Right (sidecar !? "order")
      idx <- case order of
        Array xs | Just is <- mapM asInteger xs, sort is == [0 .. toInteger (length l.items) - 1] -> Right is
        _ -> Left invalidOrder
      Right ( [l.items !! fromInteger i | i <- idx]
            , Object [(k, v) | (k, v) <- J.asObject sidecar, k `notElem` ["name", "tier", "order"]]
            , "Sidecar order; canon text is unchanged" )
    _ -> Right (l.items, stored, "Stored item order")
  relations <- elements "relations"
  mapM_ (\e -> if validEdge e then Right () else Left ("invalid relation endpoint or label: " ++ l.name)) relations
  priorities <- elements "priorities"
  mapM_ (\p -> if member (p !? "item") then Right () else Left ("invalid priority item: " ++ l.name)) priorities
  pure $ Object $
    [(k, v) | (k, v) <- J.asObject (toValue l), k /= "items"]
    ++ [ ("items", list items), ("tier", str (tierName tier)), ("position", position)
       , ("position_note", str note), ("seriation", seriation), ("display_order", str display) ]
  where
    src k = l.source >>= (!? k)
    invalidOrder = "invalid canon display order: " ++ l.name
    asInteger (Int n) = Just n   -- bools and floats are not ints, as in Python
    asInteger _ = Nothing
    elements k = case src k of
      Nothing -> Right []
      Just (Array xs) -> Right xs
      Just _ -> Left (k ++ " is not a list: " ++ l.name)
    member v = maybe False (`elem` l.items) (v >>= asString)
    validEdge e = member (e !? "from") && member (e !? "to")
      && maybe False (not . null . strip) (e !? "label" >>= asString)

-- | Python truthiness, for @source.get("seriation") or {}@.
truthy :: Value -> Bool
truthy = \case
  Null -> False
  Bool b -> b
  Int n -> n /= 0
  Double d -> d /= 0
  String s -> not (null s)
  Array xs -> not (null xs)
  Object kvs -> not (null kvs)

-- | The map point fingerprint: hex SHA-256 of Python's default
-- @json.dumps(sorted(items), ensure_ascii=False)@ — @", "@ separators,
-- UTF-8 bytes.
itemsHash :: [String] -> String
itemsHash items = sha256Hex (utf8Bytes ("[" ++ intercalate ", " (map (J.render . String) (sort items)) ++ "]"))

-- | Embed the payload as inert JSON and substitute it into the template.
render :: String -> Value -> String
render template payload = replace "__CATALOG_JSON__" (concatMap esc (renderSorted payload)) template
  where
    esc '&' = "\\u0026"
    esc '<' = "\\u003c"
    esc '>' = "\\u003e"
    esc '\x2028' = "\\u2028"
    esc '\x2029' = "\\u2029"
    esc c = [c]

-- ------------------------------------------------------------------ sha256

utf8Bytes :: String -> [Word8]
utf8Bytes = concatMap enc
  where
    enc c
      | n < 0x80 = [w n]
      | n < 0x800 = [w (0xC0 .|. shiftR n 6), cont n]
      | n < 0x10000 = [w (0xE0 .|. shiftR n 12), cont (shiftR n 6), cont n]
      | otherwise = [w (0xF0 .|. shiftR n 18), cont (shiftR n 12), cont (shiftR n 6), cont n]
      where n = ord c
    cont x = w (0x80 .|. (x .&. 0x3F))
    w :: Int -> Word8
    w = fromIntegral

-- | Lower-case hex digest of the bytes.
sha256Hex :: [Word8] -> String
sha256Hex = concatMap hex2 . sha256
  where hex2 b = let h = showHex b "" in if length h < 2 then '0' : h else h

sha256 :: [Word8] -> [Word8]
sha256 msg = concatMap bytes (unpack (foldl' block h0 (chunks (pad msg))))
  where
    pad m = let n = length m
                zeros = (55 - n) `mod` 64
             in m ++ [0x80] ++ replicate zeros 0 ++ bytes64 (fromIntegral n * 8)
    bytes64 :: Integer -> [Word8]
    bytes64 x = [fromIntegral (x `shiftR` (8 * i)) | i <- [7, 6 .. 0]]
    chunks [] = []
    chunks xs = let (a, b) = splitAt 64 xs in a : chunks b
    bytes :: Word32 -> [Word8]
    bytes x = [fromIntegral (x `shiftR` (8 * i)) | i <- [3, 2, 1, 0]]
    unpack (a, b, c, d, e, f, g, h) = [a, b, c, d, e, f, g, h]
    h0 = (0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a, 0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19)
    block st@(a0, b0, c0, d0, e0, f0, g0, h0') chunk =
      let (a, b, c, d, e, f, g, h) = foldl' step st (zip ks (schedule chunk))
       in (a0 + a, b0 + b, c0 + c, d0 + d, e0 + e, f0 + f, g0 + g, h0' + h)
    step (!a, !b, !c, !d, !e, !f, !g, !h) (k, w) =
      let s1 = rotateR e 6 `xor` rotateR e 11 `xor` rotateR e 25
          ch = (e .&. f) `xor` (complement e .&. g)
          t1 = h + s1 + ch + k + w
          s0 = rotateR a 2 `xor` rotateR a 13 `xor` rotateR a 22
          maj = (a .&. b) `xor` (a .&. c) `xor` (b .&. c)
          t2 = s0 + maj
       in (t1 + t2, a, b, c, d + t1, e, f, g)
    schedule chunk =
      let w16 = [foldl' (\acc x -> acc `shiftL` 8 .|. fromIntegral x) 0 (take 4 (drop (4 * i) chunk)) | i <- [0 .. 15]]
          ws = w16 ++ zipWith4 ext (drop 14 ws) (drop 9 ws) (drop 1 ws) ws
          ext w2 w7 w15 w16' =
            let s0 = rotateR w15 7 `xor` rotateR w15 18 `xor` shiftR w15 3
                s1 = rotateR w2 17 `xor` rotateR w2 19 `xor` shiftR w2 10
             in w16' + s0 + w7 + s1
       in take 64 ws
    ks :: [Word32]
    ks =
      [ 0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5
      , 0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174
      , 0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da
      , 0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967
      , 0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85
      , 0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070
      , 0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3
      , 0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2 ]

-- --------------------------------------------------------------------- CLI

-- | @ideonomy atlas [--output PATH]@
cli :: [String] -> IO ()
cli argv = do
  let a = parseArgs [] ["output"] argv
  case positionals a of
    [] -> do
      let out = maybe "docs/catalog-map.html" id (opt "output" a)
      payload <- catalog
      template <- dataFile "atlas.html" >>= readUtf8
      createDirectoryIfMissing True (takeDirectory out)
      withFile out WriteMode (\h -> hSetEncoding h utf8 >> hPutStr h (render template payload))
      putStrLn ("Wrote " ++ out)
    _ -> usage "usage: ideonomy atlas [--output PATH]"
  where
    readUtf8 p = do
      h <- openFile p ReadMode
      hSetEncoding h utf8
      hGetContents' h
