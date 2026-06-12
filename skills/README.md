# Premier agent skills

Executable, distributable agent-skill files distilled from the respiratory
engine's run on its own highest-leverage question. Full catalog and method:
[`../PREMIER_SKILLS.md`](../PREMIER_SKILLS.md).

Each is a Claude-Code-style `SKILL.md` (frontmatter `name` + `description` with
its trigger, then the procedure and its executable gate). They are
**differentiated affordances**: concrete, nameable cognitive moves a stranger's
agent can execute end to end.

## The top three (scaffolded here)

| Skill | The move it forces | The gate |
| --- | --- | --- |
| [`triangulate-without-oracle`](triangulate-without-oracle/SKILL.md) | rigor when there is NO computable oracle — dimensionalize the value space, gather independent judgments, expose disagreement, name the irreducible call | honesty about the absence of a gate: ≥2 independent reads per axis, or an explicitly-named irreducible judgment with an owner |
| [`build-the-oracle-before-the-answer`](build-the-oracle-before-the-answer/SKILL.md) | commit the independent truth-check and its expected value *before* answering, breaking answer-then-rationalize | a timestamped expected-value artifact exists before the answer; the oracle runs and matches |
| [`reframe-until-it-dissolves`](reframe-until-it-dissolves/SKILL.md) | change altitude/basis/domain until the problem is mechanical — the general case is often easier | MDL: shorter statement, instance falls out free, a method unavailable before now available; else revert |

The first two are a matched pair: route to `build-the-oracle-before-the-answer`
when an honest oracle exists, to `triangulate-without-oracle` when forcing one
would measure the wrong thing. Choosing wrong — fabricating a proxy oracle for a
question that has none — is the single failure both exist to prevent.

## The other nine

`compute-the-smallest-nontrivial-case`, `refute-your-own-answer-blind`,
`enumerate-discriminating-alternatives`, `coin-the-missing-concept`,
`design-the-mechanism-from-the-desired-equilibrium`,
`localize-then-glue`, `carry-the-residue-forward-across-sessions`,
`prove-the-coverage-denominator`, and the meta-router `route-to-the-right-move`
are specified in [`../PREMIER_SKILLS.md`](../PREMIER_SKILLS.md) and will be
scaffolded as they earn use. The catalog applies to itself (P35): use these,
measure them, revise them.
