---
name: compute-the-smallest-nontrivial-case
description: >-
  When a general claim arrives too easily — a formula, an invariant, "this
  mechanism works", "the query logic is correct" — force it down to the
  smallest concrete instance that still exercises the core mechanism and
  compute it by hand before you generalize. The failure it prevents: leaping to
  a clean universal statement that was never made to survive contact with even
  one concrete case. Triggers on derivations, counting arguments, algorithm
  claims, edge behavior, and anywhere the words "obviously for all n" appear
  before one nontrivial n was worked.
---

# compute-the-smallest-nontrivial-case

Feynman's concretize-down fused with von Neumann's invariant-reading: do not
trust the general statement until the smallest live instance has been made to
speak. Organon: P15 vary + P19 oracle + P11 gap-find. Phase: GENERATE ->
JUDGE, with ORIENT reading the invariant off the small orbit. Respiratory:
shrink the problem until the mechanism is exposed, then generalize only what
survives.

## Procedure

1. **Find the smallest case that is still alive.** Strip size, parameters, and
   decoration until one more simplification would remove the core mechanism.
   The smallest case is not the easiest case; it is the first case where the
   phenomenon actually occurs.

2. **State what the general claim predicts on that case.** Reduce the claimed
   formula, rule, or invariant to a concrete expected value or behavior for the
   chosen instance before you compute it.

3. **Hand-compute the instance.** Do the arithmetic, trace the execution, or
   enumerate the configurations directly. No appeal to the general argument is
   allowed inside the hand computation; otherwise the check is circular.

4. **Compare prediction to computation.** If they differ, reject the general
   claim. Do not patch the prose around the miss and keep the claim alive.

5. **Read off the invariant only after the case agrees.** Ask what stayed fixed
   through the small orbit, and only lift that structure back to the general
   statement.

**The gate**

Pass only if `computed == predicted` on the hand-worked case. If the smallest
nontrivial case disagrees with the claim, the claim is rejected, not softened.
A narrated "the small case seems consistent" does not pass; a fully worked case
with explicit values does.

## Example

Claim: "this dedup query returns one row per paper." Take the smallest live join
where one paper has two citation rows and one author row. The general claim
predicts one output row for that paper. Hand-compute the join: two rows appear.
The small case already falsifies the universal statement, so the claim dies
before a larger dataset can hide the fan-out.
