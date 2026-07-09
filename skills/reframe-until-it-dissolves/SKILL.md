---
name: reframe-until-it-dissolves
description: >-
  When a problem is grinding — casework piling up, effort scaling without
  progress, "it depends on everything" — stop answering at the level it was
  posed and change the representation until it becomes mechanical or
  disappears. Raise the abstraction (the general statement is often EASIER),
  change the basis (until the coupling vanishes), or transport the solution
  from a domain where it's already solved. The failure it prevents: the LLM's
  deepest default — answering at exactly the posed level, scaling effort
  instead of changing representation, conflating "this is hard" with "this is
  hard in these coordinates." Guarded by an MDL anti-vacuity gate so it never
  floats off into empty over-abstraction.
---

# reframe-until-it-dissolves

Grothendieck's rising sea (raise the water until the problem is submerged and
falls open) fused with von Neumann's change-of-representation (find the basis in
which the work is linear) and functor-transport (carry a solution from a solved
domain). The non-obvious content: **the general statement is frequently
*easier* than the special case** — the special case was hard only because it was
seen too specifically.

Organon: P16 lump-split + P13 analogize + P14 transpose + P5 dimensionalize +
P36 distill. Respiratory: the breath-out taken to its limit (distillation).

## The danger this skill must police

This cognitive style's failure mode is over-abstraction — building an elegant
cathedral that answers a class of size one while the actual instance sits
unsolved. Two hard guards below (the MDL gate and the ≥3-members guard) are
non-negotiable. The rising sea is a *means*, not an aesthetic: if the water
rises and the problem does not fall open of its own accord, descend and solve
the concrete case by hand.

## Procedure

1. **Locate where the difficulty lives** in the current framing: the case
   explosion, the cross-terms, the cycles, the "it depends."

2. **Run the reframe-operator menu** — try each until one collapses the
   difficulty:
   - **Raise the altitude (abstract up).** Circle every constant silently
     fixed (a number, a domain, a user, a platform); lift one to a variable;
     ask whether the *general* proof is shorter and the instance becomes a free
     corollary.
   - **Change the basis (linearize).** Eigenbasis (coupled → independent),
     dual (constraints ↔ objectives, max-flow ↔ min-cut), transform
     (convolution → product), log / order (products → sums, ranking →
     Pareto frontier), graph (relations → reachability), continuous relaxation
     (integer → convex, then round).
   - **Transport from a solved domain (functor).** Find a domain where a
     structurally identical problem is already solved; build the
     correspondence that preserves composition; transport the solution; the
     *unmapped remainder* is the only problem left, usually far smaller.

3. **Read off the answer in the new representation**, then map it back, checking
   the map was faithful on the relevant structure.

## The gate (MDL anti-vacuity — this is what keeps it honest)

Accept the reframe **only if all three hold**:

1. The reframed/general statement is **strictly shorter** to write down than
   the original attack (`L(structure)` did not rise).
2. The original instance **falls out with no bespoke argument** — if you still
   need a special case for it, the reframe was cosmetic; **revert it**.
3. A **method unavailable before is now available** (a closed form, a linear
   solve, a single sort, a reachability query).

Plus the **≥3-real-members guard**: do not build general apparatus unless three
*real* instances of the class exist. One triggering instance → solve it
directly; the foundation is premature.

Plus the **semantic-preservation check** (this is `preserve-the-target` applied
to reframing): a reframe can be MDL-shorter simply because it is *vaguer* — it
dropped a constraint that mattered. Shorter is necessary but not sufficient.
Verify the reframed statement still binds the original target's load-bearing
constraints; if the compression came from quietly discarding one, reject it. A
reframe that is shorter because it says less is not a dissolution, it is a loss.

Conceptually this is `cycles.py`'s ratchet: keep the breath only if codelen
drops — coverage up while the structure stays small. A reframe that grows
coverage on paper but leaves a huge residual (you still need per-case work) or
balloons the statement is over-abstraction; the ratchet reverts it.

For prose problems this is a soft gate — "shorter" and "binds the same
constraints" are judged, not computed (see the gate-hardness classification
in PREMIER_SKILLS.md). When the stakes are high, have a different model or
the human check clause 2 and the semantic-preservation clause: a reasoner
grading its own reframe is the known hole.

## Example

Asked to rank N candidate fixes by correctness, parsimony, and security where
the criteria trade off nonlinearly. Default agonizes over weights in scalar
space. Reframe (change of representation): map each candidate to a point in
criterion-space and take the **Pareto frontier** — a partial order, not a
scalar. Dominated candidates drop out with *no weighting at all*; N collapses
to the frontier set, and only that small set needs any further judgment. Gate:
a method unavailable before (order-theoretic dominance) is now available, the
statement is shorter, and the weighting agony — an artifact of forcing a partial
order into a scalar — evaporated. Accepted.
