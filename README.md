# ideonomy

Computational ideonomy: Patrick Gunkel's science of ideas, rebuilt as
inference-time machinery.

Gunkel (1947–2017, MIT) defined ideonomy as "the pure and applied science of
ideas and their laws, and of the use of same to describe, generate,
investigate, or otherwise treat all possible ideas related to any subject,
problem, thing, or other idea." He pursued it by hand and with 1980s
combinatorics programs: hundreds of systematic lists, 235 named divisions of
the field, cross-products yielding tens of thousands of candidate ideas
(230 elementary shapes × 74 types of order = 17,020 "shapes of order"), each a
question someone could take seriously. The method's bottleneck was always
evaluation — a human cannot read 84,496 two-word psychological states. Models
can. Ideonomy is an LLM-era project that arrived forty years early.

This repo holds three things:

1. **[ORGANON.md](ORGANON.md)** — the canonical catalog of 37 inference-time
   cognitive building blocks, synthesized from ideonomy, automatic taxonomy
   induction, and automatic codebase improvement. All three streams converge
   on the same tension-metabolizing loop: SENSE → ORIENT → GENERATE → JUDGE →
   ACT → PERSIST. **[CYCLES.md](CYCLES.md)** adds the orthogonal respiratory
   axis — the breath of expansion and compression, ratcheted on
   minimum-description-length — that turns the catalog into an engine for
   open-ended cognitive work. This is the kernel; sibling repos instantiate it.
2. **Gunkel's corpus as data** — the divisions of ideonomy
   ([`ideonomy/divisions.py`](ideonomy/divisions.py)), his generative
   operators ([`ideonomy/operators.py`](ideonomy/operators.py)), and his
   progressive loop, all machine-usable.
3. **A minimal metabolic loop engine** ([`ideonomy/loop.py`](ideonomy/loop.py))
   and the **respiratory engine** ([`ideonomy/cycles.py`](ideonomy/cycles.py))
   — expand↔compress breaths with an MDL ratchet, model-agnostic (any CLI or
   callable is a model), multi-model by default, stdlib-only Python. See it
   breathe over its own catalog: `python3 -m ideonomy.cycles_demo`.

## Sibling repos

- [`../autotaxon`](../autotaxon) — autotaxonomization: corpus → faceted,
  quality-scored taxonomy. The orient phase of the organon, industrialized.
- [`../metabolize`](../metabolize) — continuous multi-model codebase
  improvement. The full loop pointed at code, picking up where
  [desloppify](https://github.com/peteromallet/desloppify) stops (multi-model
  judgment, adversarial verification, continuity).

## Quick start

```bash
cd ideonomy
python3 -m ideonomy.demo          # run Gunkel operators on a seed list, no model needed
python3 -m ideonomy.demo --model 'claude -p {prompt}'   # multi-model generation + judging
```

```python
from ideonomy import operators, divisions, primitives

# Ideocombinatorics: cross two lists, read the product for live cells.
qs = operators.combine(
    ["recurrence", "symmetry", "cascade"],
    ["grief", "negotiation", "metabolism"],
    template="Can there be {a} of {b}?",
)

# Gunkel's divisions (236 recovered), each a fault-model for thought.
divisions.DIVISIONS["ANALOGIES"]        # -> 'Icelology'

# The organon, machine-readable.
[p.key for p in primitives.PRIMITIVES if p.phase == "JUDGE"]
```

## Sources

- https://ideonomy.mit.edu/ — Gunkel's five scanned volumes and ~400 charts
- https://gracekind.net/writing/ideonomy/intro/ — the contemporary revival
- `docs/gunkel.md` — distilled research notes with full provenance

## Status

Early. The organon catalog and Gunkel data are substantive; the loop engine is
a working skeleton meant to be grown by use. The catalog applies to itself:
gap-find it, vary it, and keep what survives refutation.
