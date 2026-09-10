-- | The seriation drive: relentless, idempotent concept-space mapping.
--
-- Runs the pure seriation algebra ("Ideonomy.Seriate") over the whole
-- database with LM meaning-binding on top:
--
-- 1. embed every list's items (Gemini embedding, cached in
--    @corpus/embcache/@, relative to the working directory: run from the
--    repo root)
-- 2. order each list (spectral vs greedy, smoothest wins)
-- 3. measure SERIABILITY: smoothness gain over random order — how strongly
--    a hidden 1-D dimension runs through the list (low gain = genuine set)
-- 4. name the axis with a strong model (the order is a claim; the name
--    binds it), which may also reverse the direction
-- 5. store: grown lists carry the order in-object (@source.seriation@);
--    canon stays verbatim — orders live in @seriations.jsonl@ as indices
-- 6. self-apply: seriate the catalog itself (list centroids -> the master
--    axis of the whole database + 2D map coords -> @catalog-map.jsonl@)
--
-- > ideonomy seriate --grown            # seriate + name all grown
-- > ideonomy seriate --canon            # order all canon (axes for --canon-names largest)
-- > ideonomy seriate --catalog          # the catalog's own map
-- > ideonomy seriate --all
--
-- Idempotent: cached embeddings, already-seriated lists skipped (@--force@
-- to redo). The cache is keyed and laid out exactly as before the port
-- (@name.md5(items)[:12].json@, Python's default @json.dumps@ layout), so
-- nothing already embedded is paid for twice.
module Ideonomy.SeriateDrive
  ( Scored (..), cacheKey, embedItems, orderAndScore, nameAxis
  , runGrown, runCanon, runCatalog, catalogLaplacian, laplacianPair, md5Hex, cli
  ) where

import Control.Concurrent (forkIO)
import Control.Concurrent.MVar (newEmptyMVar, putMVar, takeMVar)
import Control.Concurrent.QSem (newQSem, signalQSem, waitQSem)
import Control.Exception (SomeException, bracket_, throwIO, try)
import Control.Monad (forM, forM_, when)
import Data.Bits (complement, rotateL, shiftL, shiftR, xor, (.&.), (.|.))
import Data.Char (ord)
import Data.List (intercalate, sortOn, transpose)
import qualified Data.Set as Set
import Data.Word (Word32, Word8)
import Ideonomy.Atlas (itemsHash)
import Ideonomy.Canon (Tier (..))
import qualified Ideonomy.Canon as Canon
import Ideonomy.Cli (flag, optInt, parseArgs, positionals, usage)
import Ideonomy.Climb (readGrownLines)
import Ideonomy.Data (dataFile)
import Ideonomy.Gemini (askJson, embedBatch, pyRepr, pyStr, setKey, strong, truthy)
import Ideonomy.Json (Value (..), (!?), asArray, asNumber, asObject, asString, dbl, int, key, list, obj, parse, readJsonl, render, showDouble, renderSpaced, str)
import Ideonomy.List (Ideolist (..), decode, encode)
import Ideonomy.Rng (mkRng, sample, uniform)
import qualified Ideonomy.Seriate as S
import Ideonomy.Util (roundTo, showSigned, timestamp)
import Numeric (showHex)
import System.Directory (createDirectoryIfMissing, doesFileExist)
import System.FilePath ((</>))

cacheDir :: FilePath
cacheDir = "corpus/embcache"

-- ------------------------------------------------------------ embeddings

-- | The cache key: the first 12 hex digits of the MD5 of Python's default
-- @json.dumps(items, ensure_ascii=False)@, UTF-8 encoded.
cacheKey :: [String] -> String
cacheKey items = take 12 (md5Hex (utf8Bytes (renderSpaced (list items))))

-- | Vectors for the items, from @corpus/embcache/<name>.<key>.json@ when
-- present, else embedded in batches of 100 and written there.
embedItems :: String -> [String] -> IO [[Double]]
embedItems name items = do
  createDirectoryIfMissing True cacheDir
  let path = cacheDir </> (name ++ "." ++ cacheKey items ++ ".json")
  exists <- doesFileExist path
  raw <- if exists
    then readFile path >>= either (\e -> ioError (userError (path ++ ": " ++ e))) pure . parse
    else do
      vecs <- concat <$> mapM embedBatch (chunksOf 100 items)
      writeFile path (renderSpaced (Array vecs))
      pure (Array vecs)
  mapM (vector path) (asArray raw)
  where
    vector path v = case mapM asNumber (asArray v) of
      Just xs | not (null xs) -> pure xs
      _ -> ioError (userError (path ++ ": malformed embedding"))
    chunksOf _ [] = []
    chunksOf n xs = let (h, t) = splitAt n xs in h : chunksOf n t

-- ----------------------------------------------------------- measurement

data Scored = Scored
  { order :: [Int]
  , method :: String
  , smooth :: Double
  , randomSmooth :: Double
  , seriability :: Double
  , sim :: S.Sim
  }

orderAndScore :: String -> [String] -> IO Scored
orderAndScore name items = do
  vecs <- embedItems name items
  let sim = S.simMatrix vecs
      (order, method, s) = S.bestOrder sim
      n = length items
      rand = go (20 :: Int) (mkRng 7)
        where
          go 0 _ = []
          go k g = let (p, g') = sample n [0 .. n - 1] g in S.smoothness sim p : go (k - 1) g'
      baseline = sum rand / fromIntegral (length rand)
  pure Scored
    { order = order, method = method, smooth = roundTo 4 s
    , randomSmooth = roundTo 4 baseline, seriability = roundTo 4 (s - baseline), sim = sim }

nameAxis :: String -> [String] -> IO Value
nameAxis of_ orderedItems = askJson strong $
  "A list has been seriated — ordered so adjacent items are most "
  ++ "similar. Each item is: " ++ of_ ++ ".\nThe seriated order, first to last:\n"
  ++ intercalate "\n" orderedItems ++ "\n\n"
  ++ "Name the latent axis this order runs along, as a one-line claim "
  ++ "(the order's meaning, e.g. 'autonomic depth: from performable to "
  ++ "unfakeable'). If the order reads more naturally reversed, say so. "
  ++ "Judge honestly whether the axis is REVELATORY (reading the order "
  ++ "start-to-finish teaches something the unordered list could not) "
  ++ "or merely local clustering. Reply as JSON: "
  ++ "{\"axis\": str, \"reverse\": bool, \"revelatory\": bool, \"note\": str}"

-- | Up to @n@ actions at a time (the naming calls ran on a six-thread
-- pool upstream, purely for API throughput); results in order, the first
-- failure re-raised.
parallel :: Int -> [IO a] -> IO [a]
parallel n acts = do
  sem <- newQSem n
  vars <- forM acts $ \act -> do
    v <- newEmptyMVar
    _ <- forkIO (bracket_ (waitQSem sem) (signalQSem sem) (try act) >>= putMVar v)
    pure v
  mapM (\v -> takeMVar v >>= either (\e -> throwIO (e :: SomeException)) pure) vars

applyOrder :: [a] -> [Int] -> [a]
applyOrder xs order = map (xs !!) order

-- ----------------------------------------------------------------- tiers

runGrown :: Bool -> IO ()
runGrown force = do
  path <- dataFile "grown.jsonl"
  grown <- readGrownLines path >>= mapM (either (\e -> ioError (userError (path ++ ": " ++ e))) pure . decode)
  let todo = [l | l <- grown, force || not (hasSeriation l)]
  putStrLn ("grown: " ++ show (length todo) ++ " lists to seriate")
  results <- forM todo (\l -> orderAndScore l.name l.items)
  named <- parallel 6 [nameAxis l.of_ (applyOrder l.items r.order) | (l, r) <- zip todo results]
  let updated = [(l.name, reseriate l r ax) | (l, r, ax) <- zip3 todo results named]
  forM_ (zip3 todo results named) $ \(l, r, ax) ->
    putStrLn ("  " ++ l.name ++ ": seriability " ++ showSigned 3 r.seriability ++ " "
              ++ (if truthy (key "revelatory" ax) then "REVELATORY" else "clustering")
              ++ " — " ++ take 70 (maybe "" id (ax !? "axis" >>= asString)))
  let final = [maybe l id (lookup l.name updated) | l <- grown]
  writeFile path (unlines [encode l | l <- sortOn (.name) final])
  where
    hasSeriation l = maybe False (any ((== "seriation") . fst) . asObject) l.source
    reseriate l r ax =
      let order = if truthy (key "reverse" ax) then reverse r.order else r.order
          seriation = obj
            [ ("axis", key "axis" ax), ("revelatory", Bool (truthy (key "revelatory" ax)))
            , ("method", str r.method), ("smoothness", dbl r.smooth)
            , ("random_smoothness", dbl r.randomSmooth), ("seriability", dbl r.seriability)
            , ("named_by", str strong) ]
       in l { items = applyOrder l.items order
            , source = Just (Object (setKey "seriation" seriation (maybe [] asObject l.source))) }

runCanon :: Int -> Bool -> IO ()
runCanon canonNames force = do
  seriations <- dataFile "seriations.jsonl"
  exists <- doesFileExist seriations
  done <- if exists && not force
    then Set.fromList <$> (readJsonl seriations >>= mapM nameOf)
    else pure Set.empty
  lists <- Canon.lists Canon
  let todo = [l | l <- lists, l.name `Set.notMember` done, length l.items >= 8]
  putStrLn ("canon: " ++ show (length todo) ++ " lists to order (axes for the " ++ show canonNames ++ " largest)")
  scored <- forM (zip [1 :: Int ..] todo) $ \(i, l) -> do
    r <- orderAndScore l.name l.items
    when (i `mod` 50 == 0) (putStrLn ("  ..." ++ show i ++ "/" ++ show (length todo) ++ " ordered"))
    pure (l, r)
  let toName = Set.fromList [l.name | (l, _) <- take canonNames (sortOn (negate . length . (.items) . fst) scored)]
      naming = [(l.name, l, r) | (l, r) <- scored, l.name `Set.member` toName]
  axes <- zip (map (\(n, _, _) -> n) naming) <$> parallel 6
    [nameAxis (if null l.of_ then l.name else l.of_) (applyOrder l.items r.order) | (_, l, r) <- naming]
  now <- timestamp
  appendFile seriations $ concat
    [ render (obj
        [ ("name", str l.name), ("tier", str "canon"), ("t", str now)
        , ("order", Array (map int (if truthy (key "reverse" ax) then reverse r.order else r.order)))
        , ("method", str r.method), ("smoothness", dbl r.smooth)
        , ("random_smoothness", dbl r.randomSmooth), ("seriability", dbl r.seriability)
        , ("axis", key "axis" ax), ("revelatory", key "revelatory" ax) ]) ++ "\n"
    | (l, r) <- scored, let ax = maybe (Object []) id (lookup l.name axes) ]
  let top = take 5 (sortOn (negate . (.seriability) . snd) scored)
      flat = take 3 (sortOn ((.seriability) . snd) scored)
  putStrLn ("most seriable: " ++ pairs top)
  putStrLn ("least (true sets): " ++ pairs flat)
  where
    nameOf v = maybe (ioError (userError "seriations.jsonl: record missing \"name\"")) pure (v !? "name" >>= asString)
    pairs xs = "[" ++ intercalate ", " ["(" ++ pyRepr l.name ++ ", " ++ showDouble r.seriability ++ ")" | (l, r) <- xs] ++ "]"

runCatalog :: IO ()
runCatalog = do
  canon <- Canon.lists Canon
  grown <- Canon.lists Grown
  let allLists = foldl' (\acc l -> if any ((== l.name) . (.name)) acc then [if x.name == l.name then l else x | x <- acc] else acc ++ [l]) [] (canon ++ grown)
      big = [l | l <- allLists, length l.items >= 8]
  cents <- forM big $ \l -> centroid <$> embedItems l.name l.items
  let names = map (.name) big
      tiers = [maybe (str "canon") id (l.source >>= (!? "tier")) | l <- big]
      n = length names
  when (n <= 10) (ioError (userError ("catalog map needs more than 10 lists, have " ++ show n)))
  let lap = catalogLaplacian cents
      (fiedler0, third) = laplacianPair lap
      order0 = map fst (sortOn snd (zip [0 ..] fiedler0))
  ax <- nameAxis "an ideonomic list (shown by name) in Gunkel's catalog of the dimensions of ideas" (applyOrder names order0)
  let rev = truthy (key "reverse" ax)
      order = if rev then reverse order0 else order0
      fiedler = if rev then map negate fiedler0 else fiedler0
  now <- timestamp
  out <- dataFile "catalog-map.jsonl"
  writeFile out $ concat $
    (render (obj [("_meta", obj [("t", str now), ("n", int n), ("axis", key "axis" ax), ("revelatory", key "revelatory" ax), ("note", key "note" ax)])]) ++ "\n")
    : [ render (obj
          [ ("name", str (names !! i)), ("tier", tiers !! i)
          , ("items_hash", str (itemsHash ((big !! i).items)))
          , ("x", dbl (roundTo 6 (fiedler !! i))), ("y", dbl (roundTo 6 (third !! i))) ]) ++ "\n"
      | i <- order ]
  putStrLn ("catalog map: " ++ show n ++ " lists; master axis: " ++ pyStr (key "axis" ax))
  where
    centroid vecs = map (/ fromIntegral (length vecs)) (foldl1 (zipWith (+)) vecs)

-- | The catalog's similarity graph as a Laplacian: cosine between unit
-- centroids, kNN-sparsified (k = 10, an edge survives if it is among
-- either endpoint's ten strongest). A near-complete graph localizes the
-- Fiedler vector on one outlier; the sparse mutual-neighbourhood graph
-- spreads the spectrum into a real map.
catalogLaplacian :: [[Double]] -> [[Double]]
catalogLaplacian cents =
  [[(if i == j then sum row else 0) - v | (j, v) <- zip [0 :: Int ..] row] | (i, row) <- zip [0 :: Int ..] w]
  where
    k = 10
    x = map unit cents
    unit v = let nrm = sqrt (dot v v) in map (/ (if nrm == 0 then 1 else nrm)) v   -- a zero centroid poisons everything
    w0 = [[if i == j then 0 else dot u v | (j, v) <- zip [0 :: Int ..] x] | (i, u) <- zip [0 :: Int ..] x]
    thresh = [sortOn negate row !! (k - 1) | row <- w0]
    w = [[if v >= ti || v >= tj then v else 0 | (v, tj) <- zip row thresh] | (row, ti) <- zip w0 thresh]

dot :: [Double] -> [Double] -> Double
dot u v = sum (zipWith (*) u v)

-- ------------------------------------------------------------ eigenpair

-- | The Fiedler vector and the third eigenvector of a graph Laplacian
-- (numpy's @eigh(L)@ columns 1 and 2). The constant kernel is lifted to
-- @c@ above the whole spectrum (@A = L + c·11ᵀ/n + εI@), so the two
-- smallest eigenpairs of @A@ are exactly the pair wanted; block inverse
-- iteration with a 2x2 Rayleigh–Ritz step finds them, each step a
-- Cholesky solve. Deterministic start, converged to vector tolerance.
laplacianPair :: [[Double]] -> ([Double], [Double])
laplacianPair lap
  | n < 3 = (replicate n 0, replicate n 0)
  | otherwise = go (0 :: Int) (unit u0) (unit v0)
  where
    n = length lap
    c = 2 * maximum [row !! i | (i, row) <- zip [0 ..] lap] + 1
    eps = 1e-8 * c
    a = [[v + c / fromIntegral n + (if i == j then eps else 0) | (j, v) <- zip [0 :: Int ..] row] | (i, row) <- zip [0 :: Int ..] lap]
    chol = cholesky a
    (u0, v0) = splitAt n (draws (2 * n) (mkRng 4))
    draws 0 _ = []
    draws k g = let (r, g') = uniform g in (2 * r - 1) : draws (k - 1 :: Int) g'
    unit v = let nrm = sqrt (dot v v) in map (/ (if nrm == 0 then 1 else nrm)) v
    mulA v = [dot row v | row <- a]
    go it p q
      | it >= 300 || (it > 0 && 1 - abs (dot p p') < 1e-12 && 1 - abs (dot q q') < 1e-12) = (p', q')
      | otherwise = go (it + 1) p' q'
      where
        y1 = unit (solve chol p)
        y2' = solve chol q
        y2 = unit (zipWith (\b e -> b - dot y2' y1 * e) y2' y1)
        ay1 = mulA y1
        ay2 = mulA y2
        (b11, b12, b22) = (dot y1 ay1, dot y1 ay2, dot y2 ay2)
        theta = 0.5 * atan2 (2 * b12) (b11 - b22)
        (cs, sn) = (cos theta, sin theta)
        e1 = zipWith (\s t -> cs * s + sn * t) y1 y2
        e2 = zipWith (\s t -> negate sn * s + cs * t) y1 y2
        l1 = b11 * cs * cs + 2 * b12 * cs * sn + b22 * sn * sn
        l2 = b11 + b22 - l1
        (p', q') = if l1 <= l2 then (e1, e2) else (e2, e1)

-- | Lower-triangular Cholesky factor as rows (row @i@ holds @i+1@ entries).
cholesky :: [[Double]] -> [[Double]]
cholesky a = reverse (foldl' step [] a)
  where
    step done arow =
      let prev = reverse done
          offs = foldl' (\acc (lj, aij) -> acc ++ [(aij - dot acc lj) / last lj]) [] (zip prev arow)
          d2 = arow !! length prev - dot offs offs
       in if d2 <= 0 then error "laplacianPair: matrix is not positive definite" else (offs ++ [sqrt d2]) : done

-- | Solve @L Lᵀ x = b@.
solve :: [[Double]] -> [Double] -> [Double]
solve rows b = backSub (forwardSub rows b)
  where
    forwardSub ls bs = reverse (foldl' (\ys (row, bi) -> (bi - dot (reverse ys) row) / last row : ys) [] (zip ls bs))
    cols = [drop i col | (i, col) <- zip [0 ..] (transpose [row ++ replicate (length rows - length row) 0 | row <- rows])]
    backSub y = foldr step [] (zip cols y)
    step (d : below, yi) xs = (yi - dot below xs) / d : xs
    step ([], _) _ = error "solve: ragged factor"

-- ------------------------------------------------------------------- md5

utf8Bytes :: String -> [Word8]
utf8Bytes = concatMap enc
  where
    enc ch
      | o < 0x80 = [w o]
      | o < 0x800 = [w (0xC0 .|. shiftR o 6), cont o]
      | o < 0x10000 = [w (0xE0 .|. shiftR o 12), cont (shiftR o 6), cont o]
      | otherwise = [w (0xF0 .|. shiftR o 18), cont (shiftR o 12), cont (shiftR o 6), cont o]
      where o = ord ch
    cont v = w (0x80 .|. (v .&. 0x3F))
    w :: Int -> Word8
    w = fromIntegral

-- | Lower-case hex MD5 of the bytes (RFC 1321), for the cache keys.
md5Hex :: [Word8] -> String
md5Hex msg = concatMap hex2 (concatMap le32 [a, b, c, d])
  where
    (a, b, c, d) = foldl' block (0x67452301, 0xefcdab89, 0x98badcfe, 0x10325476) (chunks (padded msg))
    hex2 x = let h = showHex x "" in if length h < 2 then '0' : h else h
    le32 x = [fromIntegral (x `shiftR` (8 * i)) | i <- [0 .. 3]] :: [Word8]
    padded m = m ++ [0x80] ++ replicate ((55 - length m) `mod` 64) 0
               ++ [fromIntegral ((toInteger (length m) * 8) `shiftR` (8 * i)) | i <- [0 .. 7]]
    chunks [] = []
    chunks xs = let (h, t) = splitAt 64 xs in h : chunks t
    block (a0, b0, c0, d0) chunk =
      let m = [foldr (\byte acc -> acc `shiftL` 8 .|. fromIntegral byte) 0 (take 4 (drop (4 * i) chunk)) | i <- [0 .. 15]] :: [Word32]
          (a1, b1, c1, d1) = foldl' (round' m) (a0, b0, c0, d0) [0 .. 63]
       in (a0 + a1, b0 + b1, c0 + c1, d0 + d1)
    round' m (a', b', c', d') i =
      let (f, g)
            | i < 16 = ((b' .&. c') .|. (complement b' .&. d'), i)
            | i < 32 = ((d' .&. b') .|. (complement d' .&. c'), (5 * i + 1) `mod` 16)
            | i < 48 = (b' `xor` c' `xor` d', (3 * i + 5) `mod` 16)
            | otherwise = (c' `xor` (b' .|. complement d'), (7 * i) `mod` 16)
          f' = f + a' + kTable !! i + m !! g
       in (d', b' + rotateL f' (shifts !! i), b', c')
    shifts = concatMap (concat . replicate 4) [[7, 12, 17, 22], [5, 9, 14, 20], [4, 11, 16, 23], [6, 10, 15, 21]]
    kTable = [floor (abs (sin (fromIntegral (i + 1) :: Double)) * 4294967296) | i <- [0 :: Int .. 63]] :: [Word32]

-- ------------------------------------------------------------------- CLI

-- | @ideonomy seriate [--grown] [--canon] [--catalog] [--all] [--canon-names 50] [--force]@
cli :: [String] -> IO ()
cli argv = do
  let a = parseArgs ["grown", "canon", "catalog", "all", "force"] argv
      on f = flag f a || flag "all" a
  case positionals a of
    [] -> pure ()
    _ -> usage "usage: ideonomy seriate [--grown] [--canon] [--catalog] [--all] [--canon-names 50] [--force]"
  when (on "grown") (runGrown (flag "force" a))
  when (on "canon") (runCanon (optInt "canon-names" 50 a) (flag "force" a))
  when (on "catalog") runCatalog
