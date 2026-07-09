# Cycles: the respiratory engine

The organon (`ORGANON.md`) lists 37 primitives across six phases. This file
adds the **orthogonal axis** that turns those primitives into an engine for
open-ended cognitive work: the breath of **expansion** and **compression**.

The six phases say *what kinds of move exist*. The respiratory axis says *how
the moves are sequenced over time* to make a system get deeper rather than
just busier. It is orthogonal the way the multi-model axis (M1–M6) is
orthogonal: every phase can be performed in an expanding or a compressing
register.

## The breath

```
        ┌──────────────── EXPAND ────────────────┐
        │  enumerate · combine · vary · analogize │
        │  sample-many · gap-find · transpose     │
   seed ┤  (diverge: raise cardinality, entropy)  │
        │                                          ▼
        │                                   [population]
        │                                          │
        │            JUDGE / FILTER  ◀─────────────┘
        │            (kill the dead)
        │                  │
        │                  ▼
        │           [survivors]
        │                  │
        ▲   COMPRESS ◀─────┘
        │   cluster · typify · name · hierarchize · DISTILL
        │   (converge: raise structure, lower entropy)
        │        │
        │        ▼
        │   [compression] ── MEASURE (MDL) ── RATCHET (keep iff it
        │        │            explains more with less; else revert)
        │        ▼
        └─── RESIDUE-EXTRACT ── what the compression fails to capture
                  │              becomes the highest-priority seed
                  └──────────────────────────────────────────► (breathe in again)
```

A breath in widens the considered space; a breath out renders it into less.
Neither half is the point. **The cycle is the point**, and what carries
structure forward across breaths is the residue.

## Residue is fuel, not error

Every compression leaves a residue: items that resist the structure,
anomalies, multiply-assigned members, gaps where a cell should be filled and
isn't. (The mechanical engine in `cycles.py` represents the first kind —
high-residual items and failed singletons under a hard partition; the
multiply-assigned and missing-cell kinds need the model-backed compress hook,
which is where they belong.) The near-universal mistake is to treat residue
as error to be minimized and forgotten. Here residue is the **highest-value seed for the
next expansion** — the unexplained is exactly where novelty and depth live.

This is the precise sense in which the engine "metabolizes tension." Tension
is the represented gap between the compression (the model, the *ought*) and
the corpus (the *is*). Each breath converts tension into structure; the act
of compressing generates fresh tension (new residue, new gaps); that tension
fuels the next expansion. A system metabolizes tension when each breath leaves
it explaining more of its corpus with a smaller structure — and when the
leftover it cannot yet explain is handed forward as the next question rather
than quietly discarded.

## The ratchet: compression as the measure of understanding

What stops expansion from being runaway noise and compression from collapsing
to triviality is an objective fitness from the minimum-description-length
principle. A two-part code:

```
codelen(corpus) = L(structure) + L(corpus | structure)
```

- `L(structure)` — the cost to write down the compression itself (its rules,
  labels, levels). Penalizes over-fitting: a structure with one rule per item
  explains everything and compresses nothing.
- `L(corpus | structure)` — the cost to encode each item *given* the
  structure: small when an item matches its group's rule, large when it
  doesn't. The large-residual items **are** the residue. Penalizes
  under-fitting: a trivial structure leaves everything unexplained.

A breath is **accepted** (P30 ledger / P32 variant-archive) only if the
corpus still compresses at least as well: the ratchet holds the **compression
ratio** `raw / codelen`, not absolute codelen — adding items always raises
absolute bits, so the scale-correct test is whether the new items joined the
structure (ratio holds or rises) or inflated the residue (ratio falls).
Otherwise the expansion is reverted and a different bias is tried. Two
honesty notes on the engine's implementation (`cycles.py`): a group's
distilled rule is kept only if it *pays* — encoding the members through the
rule must beat encoding them raw — so a claimed compression can never be
worse than no structure at all; and the code length has one free constant
(the label cost), which is harmless to the ratchet because accept/revert
decisions only ever compare structures under the same constant, but it means
absolute codelen values are proxies, not measurements. The ratchet is what
makes the loop a *metabolism* (compounding) rather than a *churn* (motion
without gain).

Failure modes the ratchet catches:

- **Expansion runaway** — accumulating candidates without ever compressing.
  Caught: codelen rises; force a distillation-only breath.
- **Premature compression** — collapsing to a tidy but shallow structure.
  Caught: `L(corpus | structure)` (residue) stays huge; the structure is
  rejected as under-fit however pretty it looks.
- **Slop expansion** — generating plausible-but-empty candidates. Caught at
  JUDGE by P18 filter + P22 adversarial-refute before they pollute the corpus.

## Multi-model disagreement as a residue source

The strongest version uses model diversity (M2) not just for robustness but as a
*generator of tension*. Run the compression under independent models; where
strong models derive **different** structures from the same corpus (M4
cross-model triangulation), the disagreement is high-value residue — a place
the corpus genuinely underdetermines its own organization. Route disagreement
into the next expansion rather than averaging it away. Consensus compresses;
disagreement points at where the real frontier is.

## Distillation ≠ naming

Compression has two depths. **Naming** (P8) compresses one type into a label.
**Distillation** (the new primitive below) compresses the *whole structure*
into the minimal generative rule that would regenerate it — the invariant, the
"proof is a tree" move. A taxonomy you can only enumerate is compressed once;
a taxonomy you can *regenerate from a rule* is compressed twice, and the rule
is usually the actual insight. Distillation is the breath out taken to its
limit.

## One engine, three registers

- **`ideonomy/cycles.py`** is the substrate-agnostic respiratory engine: it
  breathes over any corpus of text items with pluggable expand / judge /
  compress functions and the MDL ratchet built in. Mechanical defaults run
  offline; model hooks deepen every phase.
- **The breathe-out half, specialized** — autotaxonomization: corpus → graded
  faceted taxonomy, with a quality ledger as a domain-specific MDL proxy
  (the ORGANON "Using the catalog" reference path).
- **The full breath, specialized to code** — continuous codebase improvement,
  where the JUDGE phase has hard oracles (tests, builds, re-scan) instead of
  model panels — the strongest possible ratchet.

Open-ended cognitive work — research, theory-building, strategy, design — is
run as breaths of this engine with the corpus being claims, options,
mechanisms, or findings, and the human adjudicating verified survivors (M6).

## Conscientious bootstrap

The depth claim is **earned, not asserted**. The bootstrap path:

1. **Reflexive** (now). The engine breathes over its own substrate: gap-find
   missing primitives in the organon, recompress the catalog, improve this
   repo's own code and prose. Self-application is the honest first proof — if the
   engine cannot deepen its own design, it will not deepen anyone else's.
   `cycles_demo.py` runs this breath offline.
2. **One real corpus.** Point it at a single external open-ended problem and
   run breaths, *logging codelen every cycle*. The claim to depth is the
   measured compression curve plus a human confirming the surfaced structure
   was non-obvious — never the prose.
3. **Multi-model frontier.** Wire diverse model panels; test whether
   cross-model residue (M4) finds deeper frontiers than single-model.
4. **Continuity.** Schedule breaths (P33), accumulate a variant-archive (P32)
   of compressions, let it run; report the ledger, including the breaths that
   failed to compress — those are data, not embarrassments.

The discipline at every step: a breath that does not improve `codelen` is
logged as a failed expansion, not hidden; the differentiation claim is carried
by demonstrated compression on corpora the single-pass tools handle worse, not
by adjectives.
