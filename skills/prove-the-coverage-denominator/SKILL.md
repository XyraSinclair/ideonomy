---
name: prove-the-coverage-denominator
description: >-
  Whenever you are tempted to say "done", "complete", "fully reviewed", "all
  sources covered", or "the migration is comprehensive", force the denominator
  into the open first. State the full space of cases, sources, branches, or
  entities under discussion, then label every element. The failure it prevents:
  declaring exhaustiveness because the largest or easiest visible case landed
  while the rest of the denominator stayed implicit and therefore unjudged.
  Triggers on audits, corpus ingestion, test coverage, literature reviews,
  source enumeration, and any completeness claim that could hide an unlabeled
  remainder.
---

# prove-the-coverage-denominator

Feynman's insistence on the full case space fused with gap-finding and a
persistent ledger: completeness is not a feeling, it is a labeled denominator.
Organon: P11 gap-find + P1 enumerate + P30 ledger. Phase: JUDGE / PERSIST,
with SENSE doing the enumeration that makes the claim auditable. Respiratory:
coverage compresses only after the residual denominator is named.

## Procedure

1. **State the denominator explicitly.** Define the full set whose coverage is
   being claimed: files, branches, sources, users, pathways, experiments.

2. **Enumerate its elements.** Materialize the list or the partition that makes
   every member inspectable.

3. **Label every element exactly once.** Each member must be one of: covered,
   replayable-unpromoted, named-gap, or ruled-out.

4. **Explain every non-covered label.** A named gap needs the missing condition;
   a ruled-out case needs the reason it is outside scope; replayable-unpromoted
   means it exists and can be rerun, but is not yet promoted to done.

5. **Refuse the word "complete" until the labels close.** If any element lacks a
   label, the work is partial. If the denominator itself is unstable, that is
   the first named gap.

6. **Persist the residual denominator.** Carry forward the named gaps rather
   than letting them vanish under a summary sentence.

**The gate**

There are zero unlabeled elements of the stated denominator, or the work is
explicitly reported as partial with the residual named. A claim of completeness
with an implicit or shifting denominator does not pass.

The denominator's *source* must be stated too — what fixed this as the full
space (a spec, a directory listing, a census, a stakeholder)? A denominator
chosen by the same move it gates is self-serving until checked against the
real target (`preserve-the-target`); a conveniently narrow denominator passed
cleanly is the vacuous firing this clause exists to block.

## Example

A corpus ingest says "all government sources are covered." The denominator is
made explicit: federal, state, county, and municipal sources on the scoped list.
Enumeration shows federal and state are covered, county feeds are
replayable-unpromoted, and municipal archives are a named gap because no
resolver exists yet. Because the denominator has labeled residue, the honest
status is partial, not complete.
