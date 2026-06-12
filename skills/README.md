# Premier agent skills

Executable, distributable agent-skill files distilled from the respiratory
engine's run on its own highest-leverage question. Full catalog and method:
[`../PREMIER_SKILLS.md`](../PREMIER_SKILLS.md).

Each is a Claude-Code-style `SKILL.md` (frontmatter `name` + `description` with
its trigger, then the procedure and its executable gate). They are
**differentiated affordances**: concrete, nameable cognitive moves a stranger's
agent can execute end to end. Each gate is the anti-fool-yourself /
anti-vacuity check without which the move degrades into confident slop.

## The set

| Skill | The move it forces | The gate |
| --- | --- | --- |
| [`triangulate-without-oracle`](triangulate-without-oracle/SKILL.md) ★ | rigor when there is NO computable oracle — dimensionalize the value space, gather independent judgments, expose disagreement, name the irreducible call | honesty about the absence of a gate: ≥2 independent reads per axis, or a named irreducible judgment with an owner |
| [`build-the-oracle-before-the-answer`](build-the-oracle-before-the-answer/SKILL.md) ★ | commit the independent truth-check and its expected value *before* answering | a timestamped expected-value artifact exists before the answer; the oracle runs and matches |
| [`reframe-until-it-dissolves`](reframe-until-it-dissolves/SKILL.md) ★ | change altitude/basis/domain until the problem is mechanical — the general case is often easier | MDL: shorter statement, instance falls out free, a method unavailable before now available; else revert |
| [`carry-the-residue-forward-across-sessions`](carry-the-residue-forward-across-sessions/SKILL.md) | persist what resisted resolution as the seed for the next session | session N+1 cites session N's residue or it's a churn breath, not metabolism |
| [`compute-the-smallest-nontrivial-case`](compute-the-smallest-nontrivial-case/SKILL.md) | hand-compute the smallest case before generalizing | computed == predicted, or the general claim is rejected |
| [`refute-your-own-answer-blind`](refute-your-own-answer-blind/SKILL.md) | strip authorship, pay an adversary to destroy the answer | survives only when every attack fails *on execution*, not on rebuttal |
| [`enumerate-discriminating-alternatives`](enumerate-discriminating-alternatives/SKILL.md) | ≥4 hypotheses with discriminating predictions; no early convergence | exactly one survives its discriminating test, else generate a new one |
| [`coin-the-missing-concept`](coin-the-missing-concept/SKILL.md) | turn awkward circumlocution into a named concept with a membership test | `L(corpus\|structure)` drops, the definition predicts a real unlisted case |
| [`design-the-mechanism-from-the-desired-equilibrium`](design-the-mechanism-from-the-desired-equilibrium/SKILL.md) | build rules backward from the incentive-compatibility constraint | desired behavior is a verified best-response; machine-checked, not attested |
| [`localize-then-glue`](localize-then-glue/SKILL.md) | solve on patches; the obstruction to gluing is a named invariant | overlap discrepancy is zero (glues) or a named invariant with a reason |
| [`prove-the-coverage-denominator`](prove-the-coverage-denominator/SKILL.md) | partition the full space into covered / unpromoted / named-gap / ruled-out | zero unlabeled elements, or the work is explicitly "partial" |
| [`route-to-the-right-move`](route-to-the-right-move/SKILL.md) | diagnose the problem shape and dispatch to the right skill | the chosen skill's gate fires, else re-dispatch and log the misroute |

★ = top three by leverage × distance-from-LLM-default.

## Executable harnesses

Two skills ship with real, stdlib-only, offline-tested engines:

- **`triangulate-without-oracle`** → `python3 -m ideonomy.triangulate` — runs
  the independent-judges-per-axis panel and reports disagreement.
- **`carry-the-residue-forward-across-sessions`** → `python3 -m ideonomy.residue`
  — the durable cross-session residue ledger with the metabolism/churn gate.

They compose: `Triangulation.to_residue(ledger)` writes contested axes (P-9)
straight into the residue ledger (P-10).

## The two that are a matched pair

Route to `build-the-oracle-before-the-answer` when an honest oracle exists, to
`triangulate-without-oracle` when forcing one would measure the wrong thing.
Choosing wrong — fabricating a proxy oracle for a question that has none — is
the single failure both exist to prevent, and the reason `route-to-the-right-move`
makes that branch explicit.

The catalog applies to itself (P35): use these, measure them, revise them.
