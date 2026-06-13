---
name: audit-the-oracle-coverage
description: >-
  The dangerous case is not "no oracle" — it is a WEAK oracle you falsely
  believe is exact. Before trusting any test suite, metric, benchmark, eval,
  or proof as if it settled the question, state explicitly what it CERTIFIES
  and what it does NOT — the gap between the proxy and the target. The failure
  it prevents: false certainty from a passing check that silently misses the
  spec (tests green but the spec was wrong), proxies value (offline metric up,
  user value flat), or has drifted (backtest on a system that has since
  changed). Triggers whenever a check comes back positive and you are tempted
  to call the thing "verified", and as the mandatory middle step between
  build-the-oracle-before-the-answer and triangulate-without-oracle.
---

# audit-the-oracle-coverage

The matched pair `build-the-oracle-before-the-answer` (oracle exists) vs
`triangulate-without-oracle` (no oracle) is a false binary. Most real work
lives in the **middle**: a partial or proxy oracle that certifies *something*
but not the whole claim, and the characteristic failure is treating that
partial certificate as a full one. This skill is the three-way partition the
binary was missing — **exact / partial-proxy / none** — and it routes each part
to the right discipline instead of laundering a weak signal into confidence.

Fuses build-the-oracle-before-the-answer (P-1) with prove-the-coverage-denominator
(P-11) applied to the oracle itself, and routes the uncovered residual to
triangulate-without-oracle (P-9). Organon: P3 fault-model + P11 + P19 oracle +
P37 residue-seed. Phase: JUDGE.

## Procedure

1. **State what the oracle actually certifies.** Write the precise claim the
   check establishes when it passes — not the claim you wish it established.
   "All 412 tests pass" certifies *the behaviors those tests assert*, not "the
   code is correct."

2. **Name the gap between proxy and target (P3).** What is true of the target
   that the oracle does *not* see? Spec ambiguity it never probed, inputs it
   never ran, the distribution it was built on but no longer matches, the
   value it proxies but is not. If you cannot name a single thing the oracle
   misses, the audit did not happen — that itself is the red flag.

3. **Partition the claim (P11 over the oracle).** Label every part of what you
   are asserting as:
   - **covered** — the oracle directly certifies it;
   - **proxied** — the oracle correlates with it but with a known, named gap;
   - **uncovered** — the oracle says nothing about it.

4. **Route each part to its discipline.** Covered → trust it. Proxied →
   either strengthen the oracle (`build-the-oracle-before-the-answer` on the
   gap) or carry the gap as explicit risk. Uncovered → if it is testable,
   build an oracle for it; if it is irreducibly normative/strategic, route to
   `triangulate-without-oracle` and name the owner.

5. **Report the partition, not a binary verdict.** "Verified" is replaced by
   "covered: X; proxied with gap: Y; uncovered, routed to Z."

## The gate

You may not report a claim as "verified" until its parts are partitioned into
covered / proxied / uncovered, **with at least one named thing the oracle does
not certify**. An audit that finds the oracle covers everything is presumed to
have not looked — partial oracles always miss something; name it or the gate
fails. The proxied and uncovered parts must be routed, not folded into the
covered set.

## Example

A migration's test suite passes, and the instinct is "settled, ship it." The
audit: *covered* = the 412 asserted behaviors; *proxied* = "preserves user
settings" (the tests check three settings shapes, correlated but not the full
space); *uncovered* = users with null locale and deleted workspace memberships
(no test exists). Routing the uncovered case to a targeted fixture (build an
oracle for the gap) finds one settings row that silently drops — exactly the
case "all tests pass" was about to certify away. The binary "verified vs not"
would have shipped it; the coverage partition caught it.
