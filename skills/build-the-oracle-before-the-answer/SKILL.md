---
name: build-the-oracle-before-the-answer
description: >-
  Defeat answer-then-rationalize: when a claim is checkable more cheaply than
  it is producible (a row count, a benchmark number, "this refactor preserves
  behavior", a combinatorial count, "this query returns X"), write the
  independent truth-check AND commit its expected value BEFORE you produce the
  answer. The failure it prevents: an LLM emits a fluent answer and then
  manufactures support for whatever it already said — verification collapses
  into self-agreement because the check was built after the answer. Triggers on
  any quantitative or verifiable claim, especially counts, latencies, "this
  works", and anything you'd be tempted to assert without running.
---

# build-the-oracle-before-the-answer

Feynman's master move, independently rediscovered by von Neumann (the
recompute-script gate) and by production code-quality systems (the
gated-not-attested ledger). The single differentiating insight is **temporal**:
build the truth-signal *before and independently of* the answer, and commit to
its expected value blind. Justification produced *after* an answer is
rationalization, not verification.

Organon: P19 oracle + P3 fault-model + P20 self-verify, M1 generator/critic
split. Respiratory: pre-commits the compression target before the breath in.

## When NOT to use it

If the question is irreducibly normative/aesthetic/strategic and no honest
independent check exists, do **not** fabricate one — that is the exact Goodhart
failure. Route to **triangulate-without-oracle** instead. The discipline is:
oracle-first when an honest oracle exists; named-judgment when it doesn't.

## Procedure

1. **Before answering, write the oracle.** The smallest *independent*
   computation that returns a value or TRUE/FALSE for the claim: a
   `SELECT count(*)`, a five-line script, a closed-form recomputation, a unit /
   order-of-magnitude derivation, a property the answer must satisfy. It must
   not reuse the answer's intermediate values — if it does, it's circular and
   disqualified.

2. **Commit the expected value now, blind.** Write down what the oracle *should*
   return if you are right — before you have the answer. Timestamp it (a file,
   a note). This commitment is what makes the check honest; an expectation
   formed after seeing the output proves nothing.

3. **Pick the cheapest honest oracle for the shape of the claim:**
   - counts / "returns N rows" → run the query, check `ROW_COUNT` and a
     monotonicity/uniqueness property.
   - quantities / latency / cost → units must algebra-out to the demanded
     units, and the answer within ~3× of a one-significant-figure mental
     estimate; sanity-check limiting cases (0, ∞).
   - "behavior preserved" → a test or a re-run of the originating check.
   - combinatorics → hand-compute the smallest case (see
     compute-the-smallest-nontrivial-case) and require the formula to reduce
     to it.

4. **Produce the answer** by your main reasoning path.

5. **Run the oracle. Three-way compare** expected vs oracle vs answer. Any
   disagreement → stop; the answer is unproven; reconcile before reporting.

## The gate

A timestamped expected-value artifact exists **before** the answer, the oracle
is **independent** of the answer's derivation, it **executes**, and its value
**matches** the committed expectation and the answer. "I considered whether
it's right and it seems fine" (narrated) does not pass; "I committed N=10
blind, ran it, got 10" (executed) does. If no oracle was writable, log that
fact and route to triangulate-without-oracle — do not silently skip the gate.

## Example

Task: "this SQL returns the 10 most-cited papers." Default writes the query and
asserts it. This skill first commits the oracle blind: "if right, exactly 10
rows, citation_count monotone non-increasing, no duplicate paper id." Then runs
it: 11 rows — a JOIN fan-out duplicated one paper. Caught *only* because the
"= 10" was committed before seeing output. The narration-only path ships the
dup with full confidence.
