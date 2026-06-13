# Premier skills: compound moves LLMs don't default to

This is the distilled output of running the respiratory engine on its own
highest-leverage question: *what should agents do that default LLM workflows
do badly?* The method was itself a breath —

- **EXPAND (M2 diversity):** three subagents embodying near-orthogonal
  cognitive operating systems each proposed seven differentiating compound
  moves: **Feynman** (concretize down — drop to the simplest instance you can
  actually compute), **von Neumann** (operationalize across — turn the vague
  into a formal machine/game/invariant), **Grothendieck** (abstract up — raise
  the ambient structure until the problem dissolves).
- **JUDGE + COMPRESS:** a fourth agent adversarially distilled the 21
  candidates — clustering, killing the weak, fusing where styles converged so
  each premier skill welds ≥2 operating systems.
- **RESIDUE (the prize):** all three panels were *oracle-assuming, solo,
  single-shot* thinkers. The gap-find surfaced what their shared genome could
  not see — and the top-ranked skill came from that negative space, not from
  any panel.

A **compound move** composes ≥2 organon primitives (`ORGANON.md`) into a
capability no single prompt gives. Every premier skill carries an **executable
gate** — the anti-fool-yourself / anti-vacuity oracle without which the move
degrades into confident slop.

## The eight families

The 21 candidates clustered into eight cognitive families (each spanning ≥2
panels — convergence from independent styles is the evidence a family is real):

| Family | The move | Panels |
| --- | --- | --- |
| A · build-the-check-before-the-answer | commit an independent truth-signal before answering | F, vN |
| B · concretize-the-smallest-instance | hand-compute the smallest case before generalizing | F, vN |
| C · reframe-until-it-collapses | change altitude/basis/domain until the problem is mechanical | G, vN (densest) |
| D · adversarial-execution-gate | model the answer's producer as adversary; attacks must fail on execution | F, vN |
| E · enumerate-discriminating-alternatives | ≥4 hypotheses with discriminating predictions; no early convergence | F, vN, G |
| F · coin-the-concept / MDL-ratchet | compress to the minimal regenerating rule; keep only if codelen drops | F, G, vN |
| G · inverse-design-from-equilibrium | build rules backward from the incentive-compatibility constraint | vN |
| H · build-foundation-for-the-class | amortize across instances — *suspect* (empty-cathedral risk) | G, vN |

Family H was demoted: its only honest content is a **≥3-real-members guard**
(don't build apparatus until three real instances exist), now attached as a
precondition to the reframing skills.

## The premier set

Eight within-session skills, three cross-cutting gap-skills, one meta-router.
Each links the organon primitives it composes.

### Within-session

**P-1 · build-the-oracle-before-the-answer** — Write the independent
truth-check and commit its expected value *before* producing the answer, so you
cannot rationalize backward. *Fuses* F (oracle-first) + vN (the formal object
whose solution concept makes the check mechanical) + F (units/magnitude as the
cheapest oracle). *Counters* answer-then-rationalize. *Primitives* P19+P3+P20,
M1; JUDGE-before-GENERATE. *Gate*: a timestamped expected-value artifact exists
*before* the answer; the answer is scored against it. If no oracle is writable,
that fact is logged and routed to P-9.

**P-2 · compute-the-smallest-nontrivial-case** — Instantiate and hand-compute
the smallest case that still exercises the core mechanism, before generalizing.
*Fuses* F (simplest-case) + F (limiting cases / dimensional anchor) + vN (read
the invariant off the small orbit). *Counters* leaping to a general claim no
concrete instance was checked against. *Primitives* P15+P19+P11. *Gate*:
`computed == predicted` on the hand-worked case, or the general claim is
rejected (not patched).

**P-3 · reframe-until-the-problem-dissolves** — Refuse to answer at the posed
level; change altitude (abstract up), basis (linearize), or domain (transport
from a solved one) until the answer becomes mechanical or the problem
disappears. *Fuses* G (raise-abstraction) + vN (change-representation) + G
(functor-transport) + vN (formalize to the object with a mechanical solution
concept). *Counters* the LLM's deepest default — answering at exactly the level
posed, scaling effort instead of changing representation. *Primitives*
P16+P13+P14+P5+P36; ORIENT, the distillation limit of COMPRESS. *Gate (MDL
anti-vacuity)*: the reframed statement is strictly shorter AND the original
instance falls out with no bespoke argument AND a method unavailable before is
now available — else the reframe was cosmetic; revert. Carries the
≥3-real-members guard.

**P-4 · refute-your-own-answer-blind-on-execution** — Strip
authorship/confidence, pay an adversary to destroy the answer, require attacks
to fail *on execution* not on counter-prose. *Fuses* F (refute-blind) + vN
(model the producer — including this model — as the adversary) + F (assault the
load-bearing weakest step). *Counters* self-preference / plausibility bias.
*Primitives* P22+P21+M3+M1+P37; JUDGE. *Gate*: survives only when every attack
provably fails when *run*; uniform high per-step confidence triggers a harder
attack on the weakest link.

**P-5 · enumerate-discriminating-alternatives** — ≥4 hypotheses each consistent
with observation, each with a *discriminating* prediction; forbid convergence
while ≥2 share all confirmed predictions. *Fuses* F (all-paths) + vN
(players×strategies as the alternative space) + G (vary the base to break
ties). *Counters* premature single-narrative convergence. *Primitives*
P1+P17+P22+P23. *Gate*: exactly one hypothesis survives its discriminating
test; if ≥2 survive, generate a *new* test — never vote.

**P-6 · coin-the-missing-concept-and-measure-the-bits** — Treat awkward
repeated locutions as residue signaling a missing noun; coin a name + decidable
membership test; keep it only if it compresses. *Fuses* G (coin-concept) + F
(measure residual bits) + vN (the invariant is the concept). *Counters* endless
circumlocution standing in for a concept. *Primitives* P8+P36+P7+P37; ORIENT
(the MDL ratchet itself). *Gate*: after coining, `L(corpus|structure)` drops
sharply, `L(structure)` doesn't rise, and the definition predicts a real
previously-unlisted case — else it's decorative; kill it.

**P-7 · design-the-mechanism-from-the-desired-equilibrium** — Inverse-design:
start from the behavior you want as a best-response and build backward via
strategyproof templates (Vickrey/VCG/proper-scoring/commit-reveal/stake-slash),
modeling the metric-gamer (often the model itself) as adversary. *Fuses* vN
(derive-mechanism) + vN (gaming-hardening) + F (adversary discipline).
*Counters* proposing rules and *hoping* for the intended behavior; metrics the
optimizer trivially games. *Primitives* P3+P15+P22+P24+P30; ACT/PERSIST. *Gate*:
the desired behavior is a verified best-response (no profitable unilateral
deviation), enforced by a machine-checked conjunction with a dual strict/lenient
ledger — not an attestation.

**P-8 · localize-then-glue-and-name-the-obstruction** — Solve on tractable
patches, compute the discrepancy on overlaps; the obstruction to gluing is a
named invariant that either fixes (coboundary) or *explains the impossibility*.
*Fuses* G (localize-then-glue) + vN (conserved quantity = the obstruction) + G
(morphisms on overlaps). *Counters* monolithic global attack that silently
fails, or false claims of a clean global solution. *Primitives* P16+P10+P11+P24.
*Gate*: patches verified locally AND overlap discrepancy is either zero (glues)
or a named non-zero invariant with a stated reason it can't vanish. "It mostly
works" is not a verdict.

### Cross-cutting — the gap-find (what all three panels missed)

**P-9 · triangulate-the-judgment-when-no-oracle-exists** — *(top-ranked)* For
irreducibly normative/aesthetic/strategic questions, refuse to fake a scalar
oracle; dimensionalize the value space, gather *independent* judgments along
each axis, expose disagreement as signal, and name the irreducible judgment
explicitly rather than launder it through a proxy. *Patches the confessed blind
spot of all three panels.* *Counters* the most dangerous shared failure: the
model invents a fake metric, optimizes it with full rigor, and ships a
confidently-wrong answer to a question that had no metric — Goodhart at the
epistemic level, worse than no rigor. *Primitives* P5+P21+M4+P37; JUDGE
(disagreement *is* the residue). *Gate (the anti-fake-oracle gate)*: either
produce ≥2 independent judgments per value-axis and report their spread, OR
explicitly name "this is an irreducible judgment, owned by ___ on grounds ___."
You may not collapse it to one manufactured number. This is the only gate in
the set that is not machine-checkable — it gates on *honesty about the absence
of a gate*, and needs cross-model/human audit (M4/M6) to stay real.

**P-10 · carry-the-residue-forward-across-sessions** — At session close,
extract what resisted resolution (anomalies, failed reframes, surviving
attacks, named-but-unfilled gaps) and persist it scoped+retrievable as the
*seed* for the next session's expansion. *Pure gap* — every one of the 21 was a
within-session move, contradicting CYCLES.md's own thesis ("what carries
structure forward across breaths is the residue"). *Counters* total amnesia
between sessions; every session re-derives from zero. *Primitives*
P31+P32+P37+P30; PERSIST. *Gate*: session N+1 must retrieve and cite session
N's residue before expanding; a session that compresses without ingesting prior
residue is logged as a churn breath, not a metabolism breath.

**P-11 · prove-the-coverage-denominator** — Make exhaustiveness explicit: state
the denominator (the full space of cases/sources/branches), partition every
element into covered / replayable-unpromoted / named-gap / ruled-out, and
forbid "done" until every element has a label. *Counters* declaring completeness
because the largest/easiest case landed. *Primitives* P11+P1+P30; JUDGE/PERSIST.
*Gate*: zero unlabeled elements of the stated denominator, or the work is
explicitly "partial" with the residual named.

### Meta — the dispatcher

**P-0 · route-to-the-right-move** — Diagnose the problem's shape and dispatch to
the right premier skill instead of defaulting to fluent prose. Routing: oracle
cheap → P-1; tiny instance reveals the mechanism → P-2; over-hard at the posed
level → P-3; answer suspiciously clean / high stakes → P-4; one narrative
dominating early → P-5; the same phrase keeps recurring → P-6; setting
incentives/metrics → P-7; global attack stalling → P-8; **no oracle exists /
it's taste or strategy → P-9** (the branch the others skip); claiming
completeness → P-11; session ending → P-10. *Primitives* P3+P35+M4. *Gate*: the
chosen skill's own gate fires; if it can't (e.g. P-1 chosen but no oracle
writable), re-dispatch (→P-9) and log the misroute for routing-table revision.

## Ranking (leverage × distance-from-default)

Distance dominates: low-distance skills are partly "free" because an undirected
model sometimes does them anyway.

1. **P-9** triangulate-without-oracle — very high distance; the confessed blind
   spot of all three styles; LLMs *never* do it natively, they fake a number.
2. **P-1** build-oracle-before-answer — widest blast radius; independently
   rediscovered by von Neumann, by Feynman, and by desloppify's strict/lenient
   ledger.
3. **P-3** reframe-until-dissolves — inverts the LLM's single deepest default;
   non-obvious content: the general case is often *easier*.
4. P-10 carry-residue-across-sessions · 5. P-4 refute-blind · 6. P-11
   coverage-denominator · 7. P-6 coin-concept · 8. P-5 discriminating-alts ·
   9. P-7 mechanism-design · 10. P-8 localize-then-glue.

The top three are scaffolded as executable skill files under
[`skills/`](skills/). They are v0 — meant to be used, measured, and revised
under P-35 (the catalog applies to itself).

## Adversarial review (external, M4)

The set was put through an external adversarial pass by a strong non-Claude
frontier model, explicitly hunting slop rather than reassurance — the library
eating its own cooking (P-4 refute-blind + M4 cross-model triangulation).
Triangulated against our own judgment, the surviving findings forced real
changes, recorded here rather than hidden:

- **The dangerous case is the *middle*, not the absence of an oracle.** The
  P-1 (oracle exists) vs P-9 (no oracle) binary missed the most common failure:
  a *weak/proxy* oracle trusted as exact (tests that miss the spec, metrics
  that proxy value, evals that proxy safety, backtests on drifted systems).
  **Fix shipped:** a new skill, `audit-the-oracle-coverage`, the three-way
  partition exact / proxied / uncovered, mandatory between P-1 and P-9.

- **"Executable gate" was overclaimed.** The gates are not uniform. Honest
  classification:
  - **Hard (machine-checkable / coded):** P-7 (best-response check), P-9
    (≥2 independent reads, enforced in `triangulate.py`), P-10 (cite-prior /
    metabolism-vs-churn, enforced in `residue.py`), P-11 (zero unlabeled),
    P-1 (timestamped pre-commit), and the new `audit-the-oracle-coverage`.
  - **Soft (disciplined judgment in formal clothing):** P-3 (MDL "shorter" is
    a judgment for prose), P-4 ("serious attack fails on execution" only when
    the attack is actually executable), P-6 (MDL drop is not yet operational),
    P-2 (which case is "smallest nontrivial" is a call). These are still
    valuable, but they are disciplines, not proofs — labelling them as proofs
    is itself a slop risk.

- **P-0 is control-plane, not a premier cognitive move**, and its gate ("the
  chosen skill's gate fires") is circular. Reclassified: a dispatcher/utility
  that *organizes* the set, not a peer within it.

- **P-2 and P-4 are tactics in the verification family, with P-1 the
  distinctive member.** Kept — the verification stack (P-2 → P-1 → P-4) is a
  real sequence — but they are not three co-equal premier skills. P-1
  (precommit the oracle and its expected value, blind) is the genuinely
  non-default move; P-2 and P-4 are close to what a careful model already does.

- **P-6 is the weakest** — close to "invent a label", which models overdo, with
  a "false essence" risk (a crisp name for a blurry cluster, then reasoning as
  if the boundary were real). Kept, because a *decidable membership test* plus
  out-of-sample prediction is more than relabeling — but its gate is tightened:
  the "predicts a real previously-unlisted case" clause is **mandatory**, not
  optional, or the coinage is rejected as branding.

- **Genuinely differentiated (a strong model does NOT do these unprompted):**
  P-1 (precommit oracle), P-7 (backward design from equilibrium under
  metric-gaming), P-11 (denominator accounting), and the gap-find pair P-9/P-10
  in composition.

- **The sharpest critique, kept as a standing caveat.** The deepest risk is not
  answering too fast. It is **formalizing the wrong oracle, denominator, or
  frame, and drawing false confidence from a workflow that *looks* rigorous —
  rigor theater.** Every hard gate in this set certifies that a *procedure* ran,
  never that the procedure was aimed at the right target. The honest use of this
  library treats its own apparent rigor as the thing most in need of P-9's
  question: *is there really an oracle here, or did I just build one that
  flatters me?*

### Second pass: GPT-5.5 Pro (the real Oracle, browser-background)

A second external review by GPT-5.5 Pro Extended Thinking **converged** with the
first on every structural point — the partial/proxy-oracle middle (it independently
proposed the same `P-11 + P-1 + P-9` decomposition fix), P-0/P-3/P-6 as weakest,
P-1/P-7/P-10/P-11 as the genuinely-differentiated core, and the verification
stack (F) as "one protocol, P-1 the anchor, P-2/P-4 subroutines." Convergence of
two independent strong models on the same de-slop verdict is the strongest signal
available that those findings are real, not one model's bias.

It also sharpened the deepest critique into a **constructive, shippable
invariant** — the highest-value outcome of the whole review:

- **Gate laundering → the target-preservation pre-gate.** Every skill
  *transforms* the target; a gate can fire cleanly on a transformed target that
  is no longer the one that mattered ("high-assurance wrongness — beautifully
  verified cognition aimed one degree away from the real problem"). **Fix
  shipped:** a new cross-cutting skill, `preserve-the-target`, the universal
  pre-gate every other skill inherits — name the target property before a move,
  verify the artifact still binds it after, reject gate-passed-but-drifted moves.

- **P-3 needs semantic preservation, not just MDL-shorter** (a reframe can be
  shorter because it is vaguer — it dropped a constraint). P-3's gate is tightened
  accordingly; this is `preserve-the-target` applied to reframing.

- **Further missing high-value combos** (beyond `audit-the-oracle-coverage`):
  `P-5 + P-1 + P-4` (diagnostic tournament: enumerate live hypotheses → precommit
  expected test results → blind-attack the survivor), `P-11 + P-8 + P-3`
  (structural safety: prove the cover before gluing patches), and `P-7 + P-4`
  (mechanism design must be adversarially red-teamed for unmodeled deviations,
  sybils, side-channels, equilibrium-selection failure).

Tooling note: this pass was run fully in the background via a browser-engine
oracle (GPT-5.5 Pro, ~5 min, zero foreground). The launcher mechanics are
operator-local tooling, not part of this library.

## Why this matters beyond the repos

Each premier skill is a **differentiated affordance** in the exact sense the
mission means it: a concrete, nameable capability a stranger's agent can
execute end to end. A premier set of these is the kind of thing that makes
querying *how to think well about X* return an executable move rather than a
platitude — agent-first epistemic infrastructure for cognitive work, not just
for text retrieval.
