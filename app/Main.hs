-- | One binary, one subcommand per engine: @ideonomy <command> [args]@.
module Main (main) where

import Control.Exception (ErrorCall (..), catch, throwIO)
import GHC.IO.Exception (IOErrorType (ResourceVanished), ioe_type)
import Ideonomy.Cli (usage)
import Ideonomy.Version (version)
import System.Environment (getArgs)
import System.Exit (ExitCode (..), exitWith)
import System.IO (hPutStrLn, stderr)
import qualified Ideonomy.Commands as C

-- | A usage error ('Ideonomy.Cli.die') is one line on stderr and exit 2;
-- @| head@ is a normal way to read an instrument, so a closed pipe is not
-- an error.
main :: IO ()
main = (dispatch `catch` usageError) `catch` closedPipe
  where
    usageError (ErrorCall msg) = hPutStrLn stderr ("ideonomy: " ++ msg) >> exitWith (ExitFailure 2)
    closedPipe e = if ioe_type e == ResourceVanished then pure () else throwIO e

dispatch :: IO ()
dispatch = getArgs >>= \case
  [] -> usage help
  ["--help"] -> usage help
  ["version"] -> putStrLn version
  (cmd : rest) -> case lookup cmd C.commands of
    Just run -> run rest
    Nothing -> usage ("unknown command " ++ show cmd ++ "\n\n" ++ help)

help :: String
help = unlines $
  [ "ideonomy " ++ version ++ " — Gunkel's science of ideas as inference-time machinery"
  , ""
  , "usage: ideonomy <command> [args]"
  , "" ]
  ++ ["  " ++ pad n ++ d | (n, d) <- C.summaries]
  ++ ["  " ++ pad "version" ++ "print the version"]
  where pad s = s ++ replicate (14 - length s) ' '
