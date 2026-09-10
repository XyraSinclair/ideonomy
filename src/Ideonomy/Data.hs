-- | Where the shipped catalog lives. Resolution order: @$IDEONOMY_DATA@,
-- then @data/@ beside the executable's @bin/@, then @./data@.
module Ideonomy.Data (dataDir, dataFile, readCatalogJsonl) where

import Ideonomy.Json (Value, readJsonl)
import System.Directory (doesDirectoryExist)
import System.Environment (getExecutablePath, lookupEnv)
import System.FilePath (takeDirectory, (</>))

dataDir :: IO FilePath
dataDir = do
  env <- lookupEnv "IDEONOMY_DATA"
  exe <- getExecutablePath
  let beside = takeDirectory (takeDirectory exe) </> "data"
  firstExisting (maybe [] pure env ++ [beside, "data"])
  where
    firstExisting [] = ioError (userError "no data directory: set IDEONOMY_DATA or run from the repo")
    firstExisting (d : ds) = do
      ok <- doesDirectoryExist d
      if ok then pure d else firstExisting ds

dataFile :: FilePath -> IO FilePath
dataFile name = (</> name) <$> dataDir

readCatalogJsonl :: FilePath -> IO [Value]
readCatalogJsonl name = dataFile name >>= readJsonl
