-- | Gunkel's generative operators as pure functions (no model required).
--
-- These are the GENERATE-phase primitives (P12-P17) in their mechanical
-- form: either direct computations ('combine', 'gapMatrix') or prompt
-- renderers ('vary', 'analogyPrompt', 'transposePrompt',
-- 'progressiveLoopPrompt') whose output you hand to any 'Ideonomy.Models.Model'.
module Ideonomy.Operators
  ( variationOperators, combine, vary
  , analogyPrompt, transposePrompt, gapMatrix, progressiveLoopPrompt
  ) where

import Ideonomy.Util (replace)

-- | P12 ideocombinatorics: cartesian product rendered through a template
-- naming @{a}@ and @{b}@. Phrase list items to maximize syntactically
-- coherent combinations, then read the product for live cells. Gunkel:
-- 230 shapes x 74 orders = 17,020 'shapes of order', each a question.
combine :: String -> [String] -> [String] -> [String]
combine template xs ys = [replace "{b}" y (replace "{a}" x template) | x <- xs, y <- ys]

-- | P15: render an idea through each named variation operator as a prompt.
-- @Nothing@ means every operator, in catalog order.
vary :: String -> Maybe [String] -> Either String [(String, String)]
vary idea ops = mapM one (maybe (map fst variationOperators) id ops)
  where
    one op = case lookup op variationOperators of
      Nothing -> Left ("unknown variation operator: " ++ show op)
      Just tpl -> Right (op, replace "{x}" idea tpl)

-- | P13: Gunkel's exhaustive-analogy exercise ('58 ways elephants resemble stars').
analogyPrompt :: String -> String -> Int -> String
analogyPrompt source target n =
  "Enumerate " ++ show n ++ " distinct, substantive ways that " ++ source ++ " resembles "
  ++ target ++ ". Number them. For each, name the shared structure "
  ++ "abstractly (one phrase), then state what the mapping predicts about "
  ++ target ++ " that is not yet known or commonly noticed."

-- | P14: re-apply one domain's organizing scheme wholesale to another.
transposePrompt :: String -> String -> String
transposePrompt scheme domain =
  "Take the following organizing scheme and re-apply it wholesale to "
  ++ "the domain of " ++ domain ++ ": every category, level, and relation should "
  ++ "be re-instantiated. Report (1) the transposed scheme, (2) which "
  ++ "cells filled naturally, (3) which cells resisted — the resistance "
  ++ "is the finding.\n\nScheme:\n" ++ scheme

-- | P11 gap-find, mechanical form: the empty cells of a typology matrix.
gapMatrix :: [String] -> [String] -> [(String, String)] -> [(String, String)]
gapMatrix rows cols occupied = [(r, c) | r <- rows, c <- cols, (r, c) `notElem` occupied]

-- | Gunkel's progressive loop (P1->P7->P11->refine) as a single instruction.
progressiveLoopPrompt :: String -> [String] -> String
progressiveLoopPrompt subject seed =
  "Subject: " ++ subject ++ "\n\nSeed list (non-exhaustive):\n" ++ listing ++ "\n\n"
  ++ "1. Study the list and isolate the TYPES it contains (intension, not "
  ++ "just grouping).\n"
  ++ "2. Use the typology to reveal MISSING items the seed list lacks.\n"
  ++ "3. Emit the refined list: every seed item assigned to a type, every "
  ++ "discovered gap filled with at least one new item, every new item "
  ++ "phrased parallel to the rest so the list composes combinatorially.\n"
  ++ "4. Name the types. End with the residual gaps you could not fill."
  where
    listing = case seed of
      [] -> ""
      (s : ss) -> "- " ++ s ++ concatMap ("\n- " ++) ss

-- P15 vary: the named variation operators Gunkel used, plus the standard
-- inventive-operator residue from morphological analysis / TRIZ.
-- Templates must stay grammatical for ANY noun phrase substituted as {x}
-- ("ratcheting scores", "what you found") — no "anti-{x}", no "{x}s".
variationOperators :: [(String, String)]
variationOperators =
  [ ("negate", "Assert the opposite or the absence of {x}. What is the anti-form of {x}? Where would {x}, presumed bad, be good?")
  , ("invert", "Swap the roles, direction, or figure/ground of {x}.")
  , ("extremize", "Push {x} to its minimum and maximum. What survives at each pole?")
  , ("miniaturize", "Shrink {x} to its smallest viable instance.")
  , ("magnify", "Scale {x} up by orders of magnitude.")
  , ("relax", "Drop one constraint that {x} presumes. Which constraint frees the most?")
  , ("tighten", "Add one constraint that makes {x} crisper.")
  , ("iterate", "Apply {x} to its own output. What does applying {x} to {x} yield?")
  , ("temporalize", "Make {x} a process in time: its genesis, growth, decay.")
  , ("spatialize", "Give {x} a geometry: nearness, boundary, gradient.")
  , ("pluralize", "Replace {x} with a population of interacting instances of {x}. What emerges from their interaction?")
  , ("hybridize", "Cross {x} with its nearest serious rival.")
  ]
