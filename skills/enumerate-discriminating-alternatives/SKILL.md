---
name: enumerate-discriminating-alternatives
description: >-
  When one narrative starts dominating early — a bug explanation, a market
  story, a user motive, "the obvious cause" — stop converging and force at
  least four live alternatives, each still consistent with what has been seen
  and each carrying a prediction that would distinguish it from the others. The
  failure it prevents: premature single-story convergence, where an LLM locks
  onto the first coherent explanation and then merely accumulates supporting
  details for it. Triggers on diagnosis, causal inference, incident review,
  strategy explanation, and anywhere two different stories could still fit the
  same facts.
---

# enumerate-discriminating-alternatives

Feynman's all-paths discipline fused with von Neumann's structured alternative
space and Grothendieck's base-variation tie-breaker: do not let one explanation
win because it arrived first. Organon: P1 enumerate + P17 sample-many + P22
adversarial-refute + P23 tournament. Phase: SENSE -> GENERATE -> JUDGE.
Respiratory: expand the hypothesis set first; compress only by tests that break
ties.

## Procedure

1. **Freeze the observed facts.** Write only what is actually known so far, in
   a form every candidate must explain.

2. **Generate at least four hypotheses.** Each one must be genuinely distinct
   and still consistent with the facts already observed. Similar phrasings of
   the same story do not count.

3. **Attach a discriminating prediction to each hypothesis.** For every live
   candidate, name an observation, test, or future trace that would separate it
   from at least one rival.

4. **Run the cheapest discriminating tests first.** Eliminate candidates only
   when their own prediction fails, not because another story sounds better.

5. **Forbid convergence while predictions tie.** If two or more hypotheses
   still share every confirmed prediction, do not vote. Generate a new test that
   would break the tie and run it.

6. **Name the survivor and the killed alternatives.** The output is not only
   the winner; it is the tournament record that made the winner honest.

**The gate**

Exactly one hypothesis survives its discriminating test. If two or more
hypotheses still survive, the next move is a new test, never a vote. A single
plausible story with no killed rivals does not pass as explanation.

## Example

An ingestion job slows down after a schema change. Four live hypotheses:
database lock amplification, larger payloads, cache bypass, or retry storm.
Two quick checks kill payload growth and cache bypass. Lock amplification and
retry storm still fit all facts, so the process may not choose. A new test
inspects lock wait time under retries disabled; wait time collapses. Now exactly
one hypothesis survives, and the explanation is earned rather than narrated.
