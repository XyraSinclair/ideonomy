# Affordance entry: differentiated agenting tooling

This file packages the repository as a **differentiated affordance**: a
concrete, nameable capability a person can exercise through their agent,
distributed as minimal instructions an arbitrary stranger's agent can execute
end to end.

## The capability

**Differentiated agenting tooling that serious builders should probably have
access to** — a small, composable library of inference-time cognitive moves
that default LLM workflows do *not* do adequately, each carrying an executable
anti-fool-yourself gate, plus two running engines and a meta-gate.

What an agent can do with it, concretely:

- Equip itself with 14 **premier skills** (`skills/`) — compound cognitive moves
  distilled from a diverse genius-style panel and twice adversarially reviewed
  by independent frontier models. Each is a `SKILL.md` a stranger's agent can
  load and execute, with a named gate that says when the move actually worked.
- Run **triangulate-without-oracle** (`python3 -m ideonomy.triangulate`) on a
  question that has no computable oracle (taste, strategy, ethics): dimensionalize
  the value space, gather ≥2 independent judgments per axis, expose disagreement,
  name the irreducible call — instead of fabricating a confident number.
- Run the **cross-session residue ledger** (`python3 -m ideonomy.residue`) so
  work compounds across sessions instead of resetting — with a machine-checked
  metabolism-vs-churn gate.
- Apply **preserve-the-target**, the universal pre-gate, so verified cognition
  stays aimed at the real problem rather than a drifted surrogate.

## Minimal instructions (first successful action)

```bash
git clone https://github.com/XyraSinclair/ideonomy
cd ideonomy
python3 -m ideonomy.cycles_demo          # see the engine breathe (offline, no model)
cat skills/README.md                     # the 14 premier skills, each with its gate
python3 -m unittest discover tests       # offline test suite, no network
```

To use a skill, load its `SKILL.md` into your agent's context and follow the
procedure + gate. Start with the top three: `triangulate-without-oracle`,
`build-the-oracle-before-the-answer`, `reframe-until-it-dissolves`.

## Provenance and rating

- **Source:** https://github.com/XyraSinclair/ideonomy (public, MIT-spirit).
- **Lineage:** Patrick Gunkel's ideonomy + automatic taxonomy induction +
  automatic codebase improvement; method and reviews documented in
  `PREMIER_SKILLS.md`, `ORGANON.md`, `CYCLES.md`, `docs/`.
- **Rating dimensions** (the affordance-index judgement axes):
  - *steps-to-first-success:* one `git clone` + one command (low).
  - *unattended reliability:* offline core is deterministic and fully tested.
    Model-backed paths depend on the operator's own model CLIs.
  - *fragility:* low for the offline engine; the model-backed skills inherit
    whatever model access the operator wires in.
  - *platform coverage:* any environment with Python 3.11+;
    skills are model-agnostic (any CLI/callable is a model).
  - *clarity:* each skill is one page with an explicit trigger and gate.

## Freshness contract

The library is a kernel meant to be used and revised (P-35 self-modify). The
catalog applies to itself; treat the git history as the freshness signal.
Re-validate against `tests/` and the live skill files rather than this summary.

## Scope and honesty

This is a **methods/tooling** affordance, not a data corpus. The offline engine
and tests are real and verified; the deepest value (model-backed expansion,
multi-model triangulation) requires the operator to supply model access. Two
independent frontier-model reviews found the genuinely differentiated core to be
precommit-the-oracle, mechanism-design-from-equilibrium, denominator accounting,
cross-session residue, and the target-preservation pre-gate; the weaker moves
and their tightened gates are documented honestly in `PREMIER_SKILLS.md`.
