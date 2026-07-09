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
| A1 | Every count stated in prose (37 primitives, 14 skills, 6+6 axes, test count, division count) matches the machine-readable source, enforced by a test, not by care | covered — `tests/test_consistency.py` |
| A2 | ORGANON.md ↔ `primitives.py` agree on every key, name, and phase | covered — enforced by test |
| A3 | No dead links: every intra-repo link resolves; no links to private or nonexistent repos | covered — enforced by test |
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
| C2 | The catalog applies to itself and the receipts exist in-repo | covered — this file; adversarial reviews in `PREMIER_SKILLS.md`; residue ledger |
| C3 | Weaknesses are documented as prominently as strengths | covered — gate-hardness classification, "rigor theater" caveat |
| C4 | The engine has been run on at least one real external corpus with a logged compression curve | named-gap — bootstrap step 2 in CYCLES.md; honest status: not yet |
| C5 | Multi-model triangulation exercised with real heterogeneous panels, results logged | named-gap — requires operator model access; harness ships, receipts don't |
| C6 | Longitudinal use: residue ledger with multiple metabolism breaths on a real topic | named-gap — the mechanism ships; its own history is young |

## D. Craft

| # | Property | Label |
|---|----------|-------|
| D1 | Stdlib-only core; zero runtime dependencies | covered |
| D2 | Every module has a stated reason to exist; no dead code | covered |
| D3 | Packaging metadata is complete and installation paths are tested | covered — pyproject with license/urls/classifiers; plugin validated |
| D4 | Skill files satisfy the agent-skill spec (frontmatter name+description with trigger conditions) | covered — enforced by test |
| D5 | Prose is austere; no slop registers, no unearned adjectives | covered — de-slop passes; external reviews hunted this specifically |

## E. Stewardship

| # | Property | Label |
|---|----------|-------|
| E1 | License present and unambiguous | covered — MIT |
| E2 | The revision discipline is stated: how the catalog changes (P35 utility-gated self-modification), what counts as evidence | covered — ORGANON/CYCLES/PREMIER_SKILLS |
| E3 | Release tagged; repo description and topics accurate | covered — v0.2.0 |
| E4 | Community scaffolding (CONTRIBUTING, issue templates, CI) | ruled-out for now — a one-author kernel; premature apparatus violates the ≥3-real-members guard. Revisit on the third external contributor |

## The honest summary

Covered: the kernel is consistent, testable, installable, self-applied, and
honestly scoped. Named gaps: C4–C6 — the *empirical* depth claims. The prose
never asserts what only the gaps could prove; the compression curve on a real
corpus is the next piece of evidence this repo owes, and the claim to depth is
carried by demonstrated compression, never by adjectives.
