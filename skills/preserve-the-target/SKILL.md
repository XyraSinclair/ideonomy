---
name: preserve-the-target
description: >-
  The universal pre-gate that wraps every other skill. Every cognitive move
  TRANSFORMS the problem — tests it, reframes it, localizes it, names it,
  formalizes it, dimensionalizes it, persists it — and the sharpest failure is
  not that the move is non-executable, it is that the move executes CLEANLY on a
  transformed target that is no longer the one that mattered. The failure it
  prevents: gate laundering / high-assurance wrongness — an oracle for the wrong
  claim, a smallest case that misses the phase transition, an MDL-shorter reframe
  that dropped a constraint, a coined concept that compresses language but not
  reality, a mechanism equilibrium under the wrong utility, a coverage
  denominator that omits the real branch, a ledger that preserves yesterday's
  wrong frame. Run it before and after any skill that changes the problem.
---

# preserve-the-target

Identified independently by two external adversarial reviews as the single
deepest risk in the whole skill library: an executable gate prevents vacuity
only if it is attached to the *real target*. Most gates can fire on a surrogate
artifact. This is the meta-gate that makes the others trustworthy — a property
the individual skills inherit rather than a move you reach for in isolation.

Organon: P3 fault-model (the defect = target drift) + P19 oracle (binding check)
+ P37 residue-seed (drift becomes the next question). It is to the skill set what
an invariant is to a loop: checked before and after every iteration.

## Procedure (wraps any other skill S)

1. **Before S fires — name the target property.** State, in one line, the
   property of the *real* problem that must survive S: the proposition actually
   in question, the value actually at stake, the behavior actually wanted, the
   denominator actually relevant. Write it down before the transformation.

2. **Run S** (reframe, build-oracle, localize, coin-concept, triangulate,
   whatever) and let S's own gate fire.

3. **After S fires — verify the artifact still binds the target.** Check that
   S's output is still *about* the property from step 1, not about the
   transformed surrogate. Concretely ask: did the oracle check the actual claim
   or an adjacent proxy? Did the reframe drop a constraint that mattered? Does
   the smaller case exercise the mechanism that fails at scale? Does the coined
   concept predict reality or just shorten the prose? Is the equilibrium under
   the utility that's actually wanted?

4. **If the binding broke, reject the move — even though its own gate passed.**
   A skill whose gate fires on a drifted target has produced high-assurance
   wrongness; that is worse than visible uncertainty. Re-run S aimed at the real
   target, or route the drift to `triangulate-without-oracle` if the "real
   target" is itself a contested judgment.

## The gate

A move is accepted only when (a) a preserved-target property was named *before*
the move, and (b) the post-move artifact is shown to still bind it. "The skill's
gate fired" is necessary but not sufficient — gate-passed-but-target-drifted is
the exact failure this exists to catch. The named property and the binding check
are the receipt; without both, the move is unverified no matter how rigorous it
looked.

Known limit: this gate is self-attested — the same agent can name a surrogate
target and certify its own binding, which reproduces the drift one level up.
It catches *unintentional* drift, which is most drift. For high-stakes moves,
the binding check must be performed by a different model or the human
(M1 generator/critic split, M6 human-gate-last), not by the mover.

## Example

Reframing "is our search good?" via `reframe-until-it-dissolves` into "does
BM25+vector RRF dominate pure-vector?" passes the MDL gate (shorter, a method
now available). But the preserved target was *good for our users on our corpus*,
and the reframe quietly swapped it for *wins an offline ranking metric*. The
post-move binding check catches the drift: the elegant, verified answer is one
degree off the real question. The fix is to carry "user value on our corpus" as
the target and treat the offline metric as a proxy (audit-the-oracle-coverage),
not as the target itself.
