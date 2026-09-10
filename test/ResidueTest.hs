-- | Offline tests for the cross-session residue ledger (P-10).
module ResidueTest (tests) where

import Control.Exception (finally)
import GHC.IO.Handle (hDuplicate, hDuplicateTo)
import Harness
import Ideonomy.Json ((!?))
import qualified Ideonomy.Json as J
import Ideonomy.Residue
import System.Directory (getTemporaryDirectory, removeDirectoryRecursive, createDirectoryIfMissing)
import System.FilePath ((</>))
import System.IO (IOMode (..), hClose, stdout, withFile)

-- | Unwrap a pure ledger step inside a test, failing the test on Left.
step :: Either String a -> IO a
step = either (ioError . userError) pure

tests :: [Test]
tests =
  [ test "session_lifecycle_and_persistence" $ do
      ((_, carried), l1) <- step (openSession "t0" emptyLedger { topic = "t" })
      r0 <- assertEq "clean start" [] carried
      (_, l2) <- step (add "why is drain slow" Anomaly "P-5" l1)
      (_, l3) <- step (add "source X uncovered" NamedGap "P-11" l2)
      (_, l4) <- step (closeSession "t1" l3)
      tmp <- getTemporaryDirectory
      let dir = tmp </> "ideonomy-residuetest"
          p = dir </> "l.json"
      createDirectoryIfMissing True dir
      save p l4
      back <- load p
      removeDirectoryRecursive dir
      led2 <- step back
      r1 <- assertEq "two residue items" 2 (length led2.residue)
      r2 <- assertEq "added but engaged no prior" [Just Churn] (map (.breath) led2.sessions)
      r3 <- assertEq "round trip" l4 led2
      pure (firstJust [r0, r1, r2, r3])
  , test "metabolism_vs_churn" $ do
      -- session 1: produce residue
      (_, l1) <- step (openSession "t0" emptyLedger)
      (r, l2) <- step (add "contested register" ContestedAxis "" l1)
      (s1, l3) <- step (closeSession "t1" l2)
      r0 <- assertEq "first breath" (Just Churn) s1.breath
      -- session 2: open (cites prior) and resolve it -> metabolism
      ((_, carried), l4) <- step (openSession "t2" l3)
      r1 <- assertEq "prior surfaced" [r.id_] (map (.id_) carried)
      (_, l5) <- step (seed r.id_ l4)
      (_, l6) <- step (resolve r.id_ "decided by human" Resolve l5)
      (s2, _) <- step (closeSession "t3" l6)
      r2 <- assertEq "second breath" (Just Metabolism) s2.breath
      pure (firstJust [r0, r1, r2])
  , test "open_session_gate_requires_close" $ do
      (_, l1) <- step (openSession "t0" emptyLedger)
      assertLeft "cannot open twice" (fst <$> openSession "t1" l1)
  , test "add_requires_open_and_valid_kind" $ do
      r0 <- assertLeft "no open session" (fst <$> add "x" Anomaly "" emptyLedger)
      r1 <- assertLeft "unknown kind" (readKind "not_a_kind")
      pure (firstJust [r0, r1])
  , test "dual_score" $ do
      (_, l1) <- step (openSession "t0" emptyLedger)
      (a, l2) <- step (add "a" Anomaly "" l1)
      (b, l3) <- step (add "b" NamedGap "" l2)
      (_, l4) <- step (add "c" OpenQuestion "" l3)
      (_, l5) <- step (resolve a.id_ "" Resolve l4)
      (_, l6) <- step (resolve b.id_ "" Drop l5)     -- dropped counts as adjudicated
      let sc = score l6
      r0 <- assert "strict ~ 2/3" (abs (sc.strict - 2 / 3) < 5e-4)
      r1 <- assertEq "open residue" 1 sc.openResidue
      pure (firstJust [r0, r1])
  , test "same_session_resolution_is_not_metabolism" $ do
      -- resolving an item born THIS session must not count as engaging the
      -- prior residue surfaced at open.
      (_, l1) <- step (openSession "t0" emptyLedger)
      (_, l2) <- step (add "old tension" Anomaly "" l1)
      (_, l3) <- step (closeSession "t1" l2)
      ((s2, _), l4) <- step (openSession "t2" l3)
      r0 <- assertEq "cited_prior" 1 s2.citedPrior
      (new, l5) <- step (add "brand new" OpenQuestion "" l4)
      (_, l6) <- step (resolve new.id_ "" Resolve l5)   -- engages nothing prior
      (s, _) <- step (closeSession "t3" l6)
      r1 <- assertEq "breath" (Just Churn) s.breath
      pure (firstJust [r0, r1])
  , test "dropping_prior_residue_is_engagement_not_churn" $ do
      -- Ruling out a prior false gap with a note is adjudication; the
      -- session must close as metabolism.
      (_, l1) <- step (openSession "t0" emptyLedger)
      (r, l2) <- step (add "suspected gap" NamedGap "" l1)
      (_, l3) <- step (closeSession "t1" l2)
      (_, l4) <- step (openSession "t2" l3)
      (_, l5) <- step (resolve r.id_ "checked: not a real gap" Drop l4)
      (s, _) <- step (closeSession "t3" l5)
      assertEq "breath" (Just Metabolism) s.breath
  , test "forward_compat_load_ignores_unknown_fields" $ do
      (_, l1) <- step (openSession "t0" emptyLedger)
      (_, l2) <- step (add "x" Anomaly "" l1)
      (_, l3) <- step (closeSession "t1" l2)
      let d = toValue l3
          future = J.Object
            [ (k, if k == "residue" then withResidueField v
                  else if k == "sessions" then J.Array [J.Object (kvs ++ [("future_field", J.int 2)]) | J.Object kvs <- J.asArray v]
                  else v)
            | (k, v) <- J.asObject d ]
          withResidueField v = J.Object [(rid, J.Object (J.asObject rv ++ [("future_field", J.int 1)])) | (rid, rv) <- J.asObject v]
      led2 <- step (fromValue future)            -- must not fail
      r0 <- assertEq "one residue" 1 (length led2.residue)
      r1 <- assert "future field really was present" (future !? "sessions" /= d !? "sessions")
      pure (firstJust [r0, r1])
  , test "cli_smoke" $ do
      tmp <- getTemporaryDirectory
      let dir = tmp </> "ideonomy-residuetest-cli"
          store = dir </> "l.json"
      createDirectoryIfMissing True dir
      silenced (do
        cli ["--store", store, "open"]
        cli ["--store", store, "add", "q", "--kind", "open_question"]
        cli ["--store", store, "status"]
        cli ["--store", store, "close"])
      back <- load store
      removeDirectoryRecursive dir
      led <- step back
      r0 <- assertEq "one residue" 1 (length led.residue)
      r1 <- assertEq "breath" [Just Churn] (map (.breath) led.sessions)
      pure (firstJust [r0, r1])
  ]

-- | Run an action with stdout sent to /dev/null (Python's redirect_stdout).
silenced :: IO a -> IO a
silenced act = do
  saved <- hDuplicate stdout
  withFile "/dev/null" WriteMode (`hDuplicateTo` stdout)
  (act `finally` (hDuplicateTo saved stdout >> hClose saved))
