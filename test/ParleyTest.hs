-- | Offline gates for the multi-party constraint solver. Every test defends
-- a balance guarantee or a sovereignty/impasse semantic.
module ParleyTest (tests) where

import Data.IORef (modifyIORef, newIORef, readIORef)
import Data.List (isInfixOf, isPrefixOf, tails)
import Harness
import Ideonomy.Parley

-- | Accepts a proposal iff it contains @want@; proposes its own keyword.
keywordParty :: String -> String -> Party
keywordParty nm want = Party { name = nm, model = model, constraints = ["must include " ++ want] }
  where
    model prompt
      | "You are" `isPrefixOf` prompt && "SAT:" `isInfixOf` prompt =
          let prop = afterFirst "Proposal:\n" prompt
           in pure $ if want `isInfixOf` prop
                then "SAT: 1.0\nWHY: has " ++ want
                else "SAT: -1.0\nWHY: lacks " ++ want
      | otherwise = pure ("plan with " ++ want)

-- | Python's @s.split(sep, 1)[1]@.
afterFirst :: String -> String -> String
afterFirst sep s = case [drop (length sep) t | t <- tails s, sep `isPrefixOf` t] of
  (x : _) -> x
  [] -> ""

tests :: [Test]
tests =
  [ -- gates
    test "one party is a monologue" $ do
      r <- parley "t" [keywordParty "a" "x"] 4 0.15
      assertLeft "one party" r
  , test "party without stakes is refused" $ do
      let idle = Party { name = "b", model = \_ -> pure "", constraints = [] }
      r <- parley "t" [keywordParty "a" "x", idle] 4 0.15
      assertLeft "no constraints" r
    -- sovereignty
  , test "each constraint scored only by its owner" $ do
      asked <- newIORef ([] :: [(String, String)])
      let recorder nm = Party { name = nm, constraints = [nm ++ "-charter"], model = \prompt ->
            if "SAT:" `isInfixOf` prompt
              then do
                let c = takeWhile (/= '\n') (afterFirst "Constraint: " prompt)
                modifyIORef asked (++ [(nm, c)])
                pure "SAT: -1.0\nWHY: no"
              else pure "proposal" }
      _ <- parley "t" [recorder "a", recorder "b"] 1 0.15
      log' <- readIORef asked
      r1 <- assertEq "a's charter only" ["a-charter"] [c | (n, c) <- log', n == "a"]   -- never b's charter
      r2 <- assertEq "b's charter only" ["b-charter"] [c | (n, c) <- log', n == "b"]   -- never a's charter
      pure (firstJust [r1, r2])
    -- balance
  , test "proposal rights rotate" $ do
      let parties = [keywordParty "a" "impossible-x", keywordParty "b" "impossible-y"]
      r <- parley "t" parties 4 0.15
      case r of
        Left e -> pure (Just e)
        Right st -> assertEq "equal rights" ["a", "b", "a", "b"] [x.proposer | x <- st.rounds]
  , test "impasse selects maximin, not loudest" $ do
      let st = Parley { task = "t", accept = 0.15, rounds =
            [ Round { proposer = "a", proposal = "p1", readings =
                [Reading "a" "c1" 0.9 "", Reading "b" "c2" (-0.9) ""] }
            , Round { proposer = "b", proposal = "p2", readings =
                [Reading "a" "c1" 0.1 "", Reading "b" "c2" 0.0 ""] } ] }
      r1 <- assertEq "worst -0.9 loses to worst 0.0" (Just "p2") ((.proposal) <$> best st)
      r2 <- assertEq "no accord" Nothing (accord st)
      pure (firstJust [r1, r2])
    -- outcomes
  , test "joint feasibility reaches accord" $ do
      -- The proposer sees the charters; a proposer that echoes every declared
      -- keyword satisfies both parties.
      let synthesist prompt = pure $ if "SAT:" `isInfixOf` prompt then "SAT: 1.0\nWHY: fine" else "plan with alpha and beta"
          a = Party { name = "a", model = synthesist, constraints = ["must include alpha"] }
          b = keywordParty "b" "beta"
      r <- parley "t" [a, b] 2 0.15
      case r of
        Left e -> pure (Just e)
        Right st -> case accord st of
          Nothing -> pure (Just "expected an accord")
          Just acc -> assert "worst clears the bar" (worst acc >= 0.15)
  , test "impasse names binding constraints as residue" $ do
      let parties = [keywordParty "a" "impossible-x", keywordParty "b" "impossible-y"]
      r <- parley "t" parties 2 0.15
      case r of
        Left e -> pure (Just e)
        Right st -> do
          r1 <- assertEq "no accord" Nothing (accord st)
          let items = residueItems st
          r2 <- assert "residue present" (not (null items))
          r3 <- assert "names the conflict" (any (("impossible" `isInfixOf`) . fst) items)
          pure (firstJust [r1, r2, r3])
  ]
