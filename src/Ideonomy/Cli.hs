-- | The smallest option parser that serves every subcommand: positionals,
-- @--flag@, @--key value@, and repeated @--key@ collected in order.
module Ideonomy.Cli
  ( Args, parseArgs, positionals, flag, opt, optInt, optDouble, optSeed, opts, require
  , usage, die
  ) where

import Data.List (isPrefixOf)
import Ideonomy.Rng (seedFromClock)
import System.Exit (exitWith, ExitCode (..))
import System.IO (hPutStrLn, stderr)
import Text.Read (readMaybe)

data Args = Args { pos :: [String], kv :: [(String, String)], flags :: [String] }
  deriving (Show)

-- | @boolFlags@ names options that take no value; @valueOpts@ names the
-- ones that take the next word. Any other @--name@ is a usage error, so a
-- misspelled option cannot silently become a default. A bare @--@ ends
-- option parsing.
parseArgs :: [String] -> [String] -> [String] -> Args
parseArgs boolFlags valueOpts = go (Args [] [] [])
  where
    go a [] = a { pos = reverse (pos a), kv = reverse (kv a) }
    go a ("--" : rest) = go a { pos = reverse rest ++ pos a } []
    go a (w : rest)
      | "--" `isPrefixOf` w =
          let name = drop 2 w
           in case break (== '=') name of
                (n, '=' : v) -> go a { kv = (n, v) : kv a } rest
                _ | name `elem` boolFlags -> go a { flags = name : flags a } rest
                  | name `notElem` valueOpts -> die ("unknown option --" ++ name)
                  | (v : rest') <- rest -> go a { kv = (name, v) : kv a } rest'
                  | otherwise -> die ("--" ++ name ++ " expects a value")
      | otherwise = go a { pos = w : pos a } rest

positionals :: Args -> [String]
positionals = pos

flag :: String -> Args -> Bool
flag n a = n `elem` flags a

opt :: String -> Args -> Maybe String
opt n a = lookup n (kv a)

-- | Every value given for a repeated option, in order.
opts :: String -> Args -> [String]
opts n a = [v | (k, v) <- kv a, k == n]

optInt :: String -> Int -> Args -> Int
optInt n d a = maybe d (\v -> maybe (die ("--" ++ n ++ " expects an integer, got " ++ show v)) id (readMaybe v)) (opt n a)

optDouble :: String -> Double -> Args -> Double
optDouble n d a = maybe d (\v -> maybe (die ("--" ++ n ++ " expects a number, got " ++ show v)) id (readMaybe v)) (opt n a)

-- | @--seed N@: the clock when absent (no replay asked for), a usage error
-- when present but not an integer.
optSeed :: Args -> IO Int
optSeed a = case opt "seed" a of
  Nothing -> seedFromClock
  Just v -> maybe (die ("--seed expects an integer, got " ++ show v)) pure (readMaybe v)

require :: String -> Args -> String
require n a = maybe (die ("missing --" ++ n)) id (opt n a)

usage :: String -> IO a
usage text = hPutStrLn stderr text >> exitWith (ExitFailure 2)

-- | A usage error, exit code 2. Pure callers use it for malformed input.
die :: String -> a
die msg = errorWithoutStackTrace ("error: " ++ msg)
