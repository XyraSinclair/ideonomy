-- | A test is a name and an action that returns the failure, if any. No
-- framework: the suite is a list, the runner a fold.
module Harness
  ( Test, test, assert, assertEq, assertIn, assertLeft, throws, run, firstJust
  ) where

import Control.Exception (SomeException, evaluate, try)
import Data.List (isInfixOf)
import System.Exit (exitWith, ExitCode (..))

type Test = (String, IO (Maybe String))

test :: String -> IO (Maybe String) -> Test
test = (,)

assert :: String -> Bool -> IO (Maybe String)
assert msg ok = pure (if ok then Nothing else Just msg)

assertEq :: (Eq a, Show a) => String -> a -> a -> IO (Maybe String)
assertEq msg want got = pure (if want == got then Nothing else Just (msg ++ ": expected " ++ show want ++ ", got " ++ show got))

assertIn :: String -> String -> String -> IO (Maybe String)
assertIn msg needle hay = pure (if needle `isInfixOf` hay then Nothing else Just (msg ++ ": " ++ show needle ++ " not in " ++ show (take 300 hay)))

assertLeft :: Show b => String -> Either a b -> IO (Maybe String)
assertLeft _ (Left _) = pure Nothing
assertLeft msg (Right v) = pure (Just (msg ++ ": expected failure, got " ++ show v))

-- | The action must throw (or force an error).
throws :: String -> IO a -> IO (Maybe String)
throws msg act = do
  r <- try (act >>= evaluate >> pure ()) :: IO (Either SomeException ())
  pure $ case r of
    Left _ -> Nothing
    Right _ -> Just (msg ++ ": expected an exception")

run :: [(String, [Test])] -> IO ()
run groups = do
  results <- concat <$> mapM one groups
  let failed = [(n, e) | (n, Just e) <- results]
  mapM_ (\(n, e) -> putStrLn ("FAIL " ++ n ++ "\n     " ++ e)) failed
  putStrLn ("Ran " ++ show (length results) ++ " tests, " ++ show (length failed) ++ " failed")
  if null failed then pure () else exitWith (ExitFailure 1)
  where
    one (grp, ts) = mapM (\(n, act) -> do
      r <- try act :: IO (Either SomeException (Maybe String))
      pure (grp ++ "." ++ n, either (Just . ("exception: " ++) . show) id r)) ts

-- | The first failure among several checks.
firstJust :: [Maybe a] -> Maybe a
firstJust xs = case [x | Just x <- xs] of
  [] -> Nothing
  (x : _) -> Just x
