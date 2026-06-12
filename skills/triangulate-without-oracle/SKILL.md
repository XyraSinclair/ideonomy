---
name: triangulate-without-oracle
description: >-
  Stay rigorous on questions that have NO computable oracle — taste, register,
  ethics, strategy, "is this good / right / worth it". Use when you catch
  yourself about to score an irreducibly normative or aesthetic thing with a
  single made-up number (7/10, "high quality", "this is the right call"). The
  danger it prevents: an LLM invents a metric, optimizes it with full rigor,
  and ships a confidently-wrong answer to a question that never had a metric —
  Goodhart at the epistemic level, worse than no rigor. Triggers on value
  judgments, design/copy review, prioritization, "which is better" where
  "better" is contested, and anywhere a proxy oracle would amputate the thing
  that mattered.
---

# triangulate-without-oracle

The top-ranked premier skill, because it patches the blind spot every strong
reasoning style shares: they assume a checkable oracle exists. When it doesn't,
the default move is to **manufacture one and trust it**. This skill refuses
that and stays honest instead.

Organon: P5 dimensionalize + P21 judge-panel + M4 cross-model triangulation +
P37 residue-seed. Respiratory: disagreement *is* the residue — consensus
compresses, disagreement points at where the real judgment lives.

## When NOT to use it

If a real, cheap, independent oracle exists (a test, a count, a derivation, a
unit check), use **build-the-oracle-before-the-answer** instead. This skill is
for the cases where forcing an oracle would measure the wrong thing precisely.
Misrouting *toward* a fake oracle is the exact failure it exists to prevent.

## The tool

An executable harness ships with the organon — `ideonomy/triangulate.py`:

```bash
python3 -m ideonomy.triangulate "<question>" \
    --axis "<axis 1>" --axis "<axis 2>" \
    --judge 'claude -p {prompt}' --judge '<a second, different model> {prompt}'
```

It refuses to run with fewer than two independent judges or with no axes
(omitting `--axis` auto-dimensionalizes via the first judge). It reports, per
axis, the spread of independent judgments — never a single collapsed number —
and names the contested axes as the residue an owner must decide. Those
contested axes feed straight into the cross-session ledger (P-10):
`Triangulation.to_residue(ledger)` writes each as a `contested_axis` item, so
P-9 and P-10 compose — a disagreement surfaced today is the seed carried to the
session that resolves it.

## Procedure

1. **Name that there is no oracle.** State plainly: "this question is
   irreducibly a judgment; there is no computation that returns its answer."
   Writing this down is the first defense against fabricating a proxy.

2. **Dimensionalize the value space (P5).** Decompose the vague predicate
   ("good", "right", "better") into 2–5 *named, concrete axes* it actually
   comprises. For Scry copy: austerity, exactness, structural clarity. For a
   strategy: reversibility, blast radius, option value, mission fit. Bad axes
   are themselves a finding — if you can't name them, you don't understand the
   judgment yet.

3. **Gather independent judgments per axis (P21, M4).** For each axis, get ≥2
   *independent* reads — different models, different framings, or genuinely
   separate passes that do not see each other's verdict (M3 blind). Independence
   is the point; two correlated reads are one read.

4. **Report the spread, do not average it (M4).** Where the independent reads
   *agree*, that axis is settled — compress it. Where they *disagree*, that
   disagreement is the highest-value signal: it localizes exactly where the
   question genuinely underdetermines its answer. Surface the disagreement;
   never launder it into a mean.

5. **Name the irreducible judgment and its owner.** For the axes that stay
   contested, state explicitly: "this is an irreducible judgment, owned by
   ___, to be made on grounds ___." Hand it to whoever legitimately owns it
   (often the human) rather than fabricating a resolution.

6. **Carry the disagreement forward (P37).** The contested axes are residue —
   the frontier of the question. Record them so the next pass starts there.

## The gate (anti-fake-oracle)

This is the only premier skill whose gate is **not machine-checkable** — it
gates on *honesty about the absence of a gate*. You pass iff:

- you produced **≥2 independent judgments per value-axis** and reported their
  spread, **OR**
- you **explicitly named the judgment as irreducible**, with an owner and the
  grounds it must be decided on.

You **fail** if you collapsed the question to a single manufactured scalar with
no named axes. Because the gate is honesty rather than execution, it needs a
cross-model or human audit (M4/M6) to stay real — build that audit in for
anything high-stakes.

## Example

"Is Scry's landing copy in the right register?" — Default: "It's solid, 8/10."
This skill: name no-oracle; dimensionalize into {austerity, exactness,
structural clarity, absence of SaaS-soup}; get two independent reads per axis;
they agree it's austere and structurally clear, **disagree** on whether one
line is exact or vague — that single disagreement is the actual review finding;
name "the exactness call on line 3 is the human's, on the grounds of whether it
overclaims." No fabricated number; the real decision surfaced and routed.
