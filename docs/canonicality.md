# Canonicality: the coverage denominator for this repo

`prove-the-coverage-denominator` applied to the repository itself. "Canonical"
is not a feeling; it is this labeled list. Every property is one of:
**covered** (holds, verified), **named-gap** (does not hold; the gap is the
work), or **ruled-out** (deliberately out of scope, with the reason). The
repo may not call itself finished while any row is unlabeled.

Target property (`preserve-the-target`): *a stranger's agent, and a demanding
human, can pick this up cold, get first value in under a minute, keep finding
value after 100 hours, and find nothing they would need to change before
trusting it.*

## A. Truth and internal consistency

| # | Property | Label |
|---|----------|-------|
| A1 | The load-bearing prose counts (primitives, skills, divisions, plugin versions) match the machine-readable source, enforced by tests, not by care; counts outside that enforced set are avoided rather than asserted | covered — `tests/test_consistency.py` |
| A2 | ORGANON.md ↔ `primitives.py` agree on every key, name, and phase | covered — enforced by test |
| A3 | No dead links: every intra-repo link resolves (test-enforced); external links verified live at release | covered — `tests/test_consistency.py` + manual sweep per release |
| A4 | No stale claims (docs describing an earlier state of the repo) | covered — swept this release; consistency tests catch the recurring class |
| A5 | Claims about external systems (Gunkel's counts, cited tools) carry provenance | covered — `docs/gunkel.md` |

## B. First contact (the 60-second property)

| # | Property | Label |
|---|----------|-------|
| B1 | One command after clone produces a real, meaningful result offline | covered — `python3 -m ideonomy.cycles_demo` |
| B2 | README states what this is, for whom, and why care — in the first screen | covered |
| B3 | Tests run offline with no dependencies, one command | covered — `python3 -m unittest discover tests` |
| B4 | The skills are installable into an agent, not just readable | covered — Claude Code plugin (`/plugin marketplace add XyraSinclair/ideonomy`) + `install.sh` for plain skill dirs |
| B5 | Works with any model CLI, no SDK lock-in | covered — `models.CommandModel` |

## C. Depth (the 100-hour property)

| # | Property | Label |
|---|----------|-------|
| C1 | The core abstractions are load-bearing, not decorative: primitives compose into skills, skills carry gates, gates have executable harnesses where honest | covered |
| C2 | The catalog applies to itself and the receipts exist in-repo | covered — this file; adversarial reviews in `PREMIER_SKILLS.md` + `docs/oracle_review_gpt55pro.md`; the release residue ledger `docs/residue-ideonomy.json` |
| C3 | Weaknesses are documented as prominently as strengths | covered — gate-hardness classification, "rigor theater" caveat |
| C4 | The engine has been run on at least one real external corpus with a logged compression curve | named-gap — bootstrap step 2 in CYCLES.md; honest status: not yet |
| C5 | Multi-model triangulation exercised with real heterogeneous panels, results logged | named-gap — requires operator model access; harness ships, receipts don't |
| C6 | Longitudinal use: residue ledger with multiple metabolism breaths on a real topic | named-gap — the mechanism ships; its own history is young |

## D. Craft

| # | Property | Label |
|---|----------|-------|
| D1 | Stdlib-only core; zero runtime dependencies | covered |
| D2 | Every module has a stated reason to exist; no dead code | covered |
| D3 | Packaging metadata is complete and installation paths exercised | covered — pyproject with license/urls/classifiers; `claude plugin validate` passes; `install.sh` and `pip install .` exercised on a fresh clone (Python 3.9) |
| D4 | Skill files satisfy the agent-skill spec (frontmatter name+description with trigger conditions) | covered — enforced by test |
| D5 | Prose is austere; no slop registers, no unearned adjectives | covered — de-slop passes; external reviews hunted this specifically |

## E. Stewardship

| # | Property | Label |
|---|----------|-------|
| E1 | License present and unambiguous | covered — MIT |
| E2 | The revision discipline is stated: how the catalog changes (P35 utility-gated self-modification), what counts as evidence | covered — ORGANON/CYCLES/PREMIER_SKILLS |
| E3 | Release tagged; repo description and topics accurate | covered — tag `v0.2.0` and repo metadata are created at publish of this revision; verify with `git tag` and the repo page |
| E4 | Community scaffolding (CONTRIBUTING, issue templates, CI) | ruled-out for now — a one-author kernel; premature apparatus violates the ≥3-real-members guard. Revisit on the third external contributor |

## Summary

Covered: the kernel is consistent, testable, installable, self-applied, and
honestly scoped. Named gaps: C4–C6 — the *empirical* depth claims. The prose
never asserts what only the gaps could prove; the compression curve on a real
corpus is the next piece of evidence this repo owes, and the claim to depth is
carried by demonstrated compression, never by adjectives.
