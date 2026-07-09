---
name: localize-then-glue
description: >-
  When a global attack stalls — the system is too coupled, the proof too wide,
  the rollout too distributed, the synthesis too brittle — stop pretending the
  whole thing must yield in one piece. Solve it on tractable patches, then
  compute exactly what fails on the overlaps. The failure it prevents: the
  monolithic global attack that silently fails, or the false clean solution that
  "mostly works" locally but never actually glues. Triggers on distributed
  changes, patchwise proofs, cross-service migrations, multi-part synthesis,
  and any task whose local pieces are easier than their boundary conditions.
---

# localize-then-glue

Grothendieck's patchwise attack fused with von Neumann's conserved-obstruction
instinct: the overlap discrepancy is not housekeeping, it is the named reason
the global solution exists or fails. Organon: P16 lump-split + P10 map + P11
gap-find + P24 multi-oracle-gate. Phase: GENERATE -> ORIENT -> JUDGE.
Respiratory: solve locally, then treat the overlap residue as the real object to
metabolize.

## Procedure

1. **Choose a patch cover.** Partition the territory into pieces that are
   locally tractable and whose overlaps are explicit rather than accidental.

2. **Solve and verify each patch locally.** Produce a local solution for every
   piece and check it with the oracle appropriate to that patch.

3. **Compute the overlap discrepancies.** On every intersection, compare what
   the adjoining local solutions demand. The difference is the candidate
   obstruction.

4. **Name the obstruction.** If the discrepancy is nonzero, bind it to the
   invariant or compatibility condition it violates.

5. **Either cancel it or accept impossibility honestly.** If the obstruction is
   a coboundary, adjust the patches and glue. If it cannot vanish, say that the
   global solution is impossible for this reason.

6. **Report the global verdict only after the overlaps clear.** Local success is
   evidence, not completion.

**The gate**

Pass only when the patches are verified locally and every overlap discrepancy is
either zero, so the pieces glue, or a named nonzero invariant with a stated
reason it cannot vanish. "It mostly works" fails the gate because gluing is the
whole question.

The cover itself is a claim: show that the patches exhaust the territory and
that the overlaps you checked are all the overlaps there are
(`prove-the-coverage-denominator` applied to the cover). A one-patch cover
glues trivially and proves nothing.

## Example

A rollout migrates user identifiers across three services. Each service passes
its local tests after the change. On the overlaps, one service canonicalizes
deleted users to `null` and another preserves tombstone IDs. The discrepancy is
not clerical; it names the obstruction: inconsistent identity semantics on
deleted users. Until that invariant is made zero or declared impossible to
reconcile, there is no global migration success.
