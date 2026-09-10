-- | Offline tests for model adapters: panels and refutation with fake
-- models; the command adapter against @cat@, @printf@, and @false@.
module ModelsTest (tests) where

import Control.Exception (throwIO)
import Data.Either (isLeft)
import Harness
import Ideonomy.Models

says :: String -> Model
says reply _ = pure reply

boom :: Model
boom _ = throwIO (userError "down")

tests :: [Test]
tests =
  [ -- panel
    test "failed model yields exception, not a sunk panel" $ do
      out <- panel [(says "ok", "p"), (boom, "p")]
      r1 <- assertEq "first" [Just "ok", Nothing] (map (either (const Nothing) Just) out)
      r2 <- assert "second is the exception" (case out of [_, e] -> isLeft e; _ -> False)
      pure (firstJust [r1, r2])
  , test "distinct prompts reach their judges" $ do
      out <- panel [(pure, "a"), (pure, "b")]
      assertEq "prompts" [Just "a", Just "b"] (map (either (const Nothing) Just) out)
    -- refute
  , test "majority survives and majority refuted" $ do
      let s = says "reasoning...\nVERDICT: SURVIVES"
          r = says "counterexample!\nVERDICT: REFUTED"
      ok <- refute [s, s, r] "claim" ""
      no <- refute [s, r, r] "claim" ""
      r1 <- assertEq "majority survives" True ok
      r2 <- assertEq "majority refuted" False no
      pure (firstJust [r1, r2])
  , test "prompt echo is not a survival vote" $ do
      -- The refuter prompt itself contains "VERDICT: SURVIVES"; a model that
      -- quotes its instructions and votes REFUTED must count as REFUTED.
      let echoer p = pure (p ++ "\nVERDICT: REFUTED")
      v <- refute [echoer, echoer, echoer] "the moon is cheese" ""
      assertEq "refuted" False v
  , test "unparseable reply is refuted by default" $ do
      v <- refute (replicate 3 (says "hmm, hard to say")) "c" ""
      assertEq "refuted" False v
  , test "erroring refuters count against survival" $ do
      v <- refute [says "VERDICT: SURVIVES", boom, boom] "c" ""
      assertEq "refuted" False v
    -- command
  , test "stdin mode" $ do
      out <- command (mkCommand "cat" "") { viaStdin = True } "hello"
      assertEq "echoed" "hello" out
  , test "template substitution is shell safe" $ do
      out <- command (mkCommand "printf '%s' {prompt}" "") "a; echo pwned"
      assertEq "quoted" "a; echo pwned" out
  , test "literal braces in command survive" $ do
      -- jq/JSON-style commands carry braces that are not placeholders.
      out <- command (mkCommand "printf '%s' {prompt} '{\"k\":1}'" "") "x"
      assertEq "braces kept" "x{\"k\":1}" out
  , test "nonzero exit raises" $
      throws "false must fail" (command (mkCommand "false" "f") { viaStdin = True } "p")
  ]
