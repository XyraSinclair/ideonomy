# ideonomy

Patrick Gunkel's ideonomy — "the pure and applied science of ideas and their
laws, and of the use of same to describe, generate, investigate, or otherwise
treat all possible ideas related to any subject, problem, thing, or other
idea" — rebuilt as inference-time machinery.

Gunkel (1947–2017, MIT) pursued it by hand and with 1980s combinatorics
programs: hundreds of systematic lists, 236 named divisions of the field,
cross-products yielding tens of thousands of candidate ideas (230 elementary
shapes × 74 types of order = 17,020 "shapes of order"), each a question
someone could take seriously. The method's bottleneck was always evaluation —
a human cannot read 84,496 two-word psychological states. Models can.
Ideonomy is an LLM-era project that arrived forty years early.

## Before and after

Ask an agent whether a product's landing copy is in the right register.

**Default:** "It's solid, 8/10." A confident score with nothing under it.

**With [`triangulate-without-oracle`](skills/triangulate-without-oracle/SKILL.md)
loaded:** the agent names that no computable answer exists, splits the judgment
into axes — austerity, exactness, structural clarity — and gets two independent
reads per axis. The reads agree the copy is austere and structurally clear, and
disagree on whether one line overclaims. That disagreement is the actual review
finding, and it goes to the human who owns the call, with the grounds named.
No fabricated number.

Every skill here packages one such move, with an explicit trigger and a gate
that says whether the move actually worked.

## What's here

Three layers, each usable alone:

1. **[`skills/`](skills/) — 14 premier agent skills.** Compound cognitive
   moves that default LLM workflows do badly, each with an explicit trigger
   and an anti-fool-yourself gate: precommit the oracle before answering,
   stay rigorous when *no* oracle exists, audit what a passing check actually
   certifies, prove the coverage denominator, carry residue across sessions,
   preserve the target through every transformation. Distilled from a
   three-persona panel (Feynman, von Neumann, Grothendieck), then twice
   adversarially reviewed by independent frontier models — the surviving
   weaknesses are documented in
   [PREMIER_SKILLS.md](PREMIER_SKILLS.md).

2. **[ORGANON.md](ORGANON.md) — the catalog of 37 inference-time cognitive
   primitives**, synthesized from three streams that converge on the same
   tension-metabolizing loop (SENSE → ORIENT → GENERATE → JUDGE → ACT →
   PERSIST): Gunkel's ideonomy, automatic taxonomy induction, and automatic
   codebase improvement. **[CYCLES.md](CYCLES.md)** adds the orthogonal
   respiratory axis — expansion↔compression breaths ratcheted on
   minimum-description-length — that turns the catalog into an engine.

3. **[`ideonomy/`](ideonomy/) — the engines and Gunkel's corpus as data.**
   Stdlib-only Python 3.9+, zero dependencies, fully offline-testable: the
   respiratory engine ([`cycles.py`](ideonomy/cycles.py)), the cross-session
   residue ledger ([`residue.py`](ideonomy/residue.py)), the no-oracle
   triangulation harness ([`triangulate.py`](ideonomy/triangulate.py)), the
   trial engine ([`trial.py`](ideonomy/trial.py)) — advocate vs adversary
   under equal terms, independent bench, burden of proof, role-swap balance
   check — the multi-party constraint solver ([`parley.py`](ideonomy/parley.py))
   — rotating proposals, sovereign constraint scoring, maximin at impasse —
   the persistent applicative list algebra ([`lists.py`](ideonomy/lists.py)) —
   typed, provenanced lists that combine, gate, grow, and compound across
   sessions — its first pristine seed, 48 mixable emotional registers
   ([`registers.py`](ideonomy/registers.py)), the growing canon layer
   ([`canon.py`](ideonomy/canon.py) + [`data/`](ideonomy/data/)) — Gunkel's
   own lists recovered verbatim from the archived pre-redesign
   ideonomy.mit.edu, each with per-URL provenance (the 638 primary
   personality traits, 291 criticisms, 152 generic bads, the full "What
   Ideonomy Can Do" table, the paths corpus…) — the metabolic loop skeleton
   ([`loop.py`](ideonomy/loop.py)), and Gunkel's 236
   divisions ([`divisions.py`](ideonomy/divisions.py)) and generative
   operators ([`operators.py`](ideonomy/operators.py)), machine-usable —
   plus a seeded drawer ([`draw.py`](ideonomy/draw.py)) that forces
   non-default lenses from their 2,832-pair cross-product.
   Model-agnostic by construction: any CLI or callable is a model
   ([`models.py`](ideonomy/models.py)).

## Sixty seconds

```bash
git clone https://github.com/XyraSinclair/ideonomy && cd ideonomy
python3 -m ideonomy.cycles_demo     # watch the engine breathe over its own catalog — offline
python3 -m unittest discover tests  # the whole suite, no network, no deps
```

The demo prints a breath log: `grp` is how many groups the compression found,
`codelen` the cost of writing that structure down plus encoding the corpus
through it, and `raw` the cost of the corpus with no structure at all. `ratio`
is raw over codelen — above 1.0 the structure pays for itself, and a cycle is
kept only if the ratio holds or rises — while `resid` counts the items the
structure fails to explain, which seed the next cycle.

## Install the skills

Claude Code, one command:

```
/plugin marketplace add XyraSinclair/ideonomy
```

(then install the `ideonomy` plugin; skills appear as `/ideonomy:<skill-name>`.)

Any other agent that reads `SKILL.md` files:

```bash
./install.sh                        # copies skills/ into ~/.claude/skills/
```

Or load any single skill by putting its `SKILL.md` in context — each is one
page, self-contained, with its trigger in the frontmatter and its gate in the
body (the `P…`/`M…` keys inside are provenance pointers into
[ORGANON.md](ORGANON.md), not prerequisites). Start with the top three: `triangulate-without-oracle`,
`build-the-oracle-before-the-answer`, `reframe-until-it-dissolves` — or
install `route-to-the-right-move` and let it dispatch.

## Use the library

```python
from ideonomy import operators, divisions, primitives, cycles

# Ideocombinatorics (P12): cross two lists, read the product for live cells.
qs = operators.combine(
    ["recurrence", "symmetry", "cascade"],
    ["grief", "negotiation", "metabolism"],
    template="Can there be {a} of {b}?",
)

# Gunkel's divisions (236 recovered), each a fault-model for thought.
divisions.DIVISIONS["ANALOGIES"]          # -> 'Icelology'
print(divisions.lens_prompt("ANOMALIES", "the git commit graph"))

# The organon, machine-readable.
[p.key for p in primitives.PRIMITIVES if p.phase == "JUDGE"]

# The respiratory engine: breathe over any corpus of text items.
state = cycles.seed(["symmetry of grief", "cascade of negotiation"])
cycles.run(state, cycles=5)               # expand -> judge -> compress, MDL-ratcheted
```

Model-backed, with any CLIs you have (heterogeneous panels are the point):

```bash
python3 -m ideonomy.demo --model 'claude -p {prompt}' --model 'ollama run llama3.3'
python3 -m ideonomy.triangulate "Is this landing copy in the right register?" \
    --axis austerity --axis exactness \
    --judge 'claude -p {prompt}' --judge 'codex exec {prompt}'
python3 -m ideonomy.trial "this API should be deprecated" \
    --advocate 'claude -p {prompt}' --adversary 'codex exec {prompt}' \
    --judge 'ollama run llama3.3'                 # adversarial trial, swap-balanced
python3 -m ideonomy.parley "name the release" \
    --party ops='claude -p {prompt}' --party brand='codex exec {prompt}' \
    --constraint 'ops:must be greppable' --constraint 'brand:must not be generic'
python3 -m ideonomy.residue --topic mywork open   # cross-session residue ledger
python3 -m ideonomy.draw "your problem" --n 3     # forced non-default lenses, offline
python3 -m ideonomy.registers "the launch post" --n 2   # forced register mixes, offline
python3 -m ideonomy.lists ls                      # the cross-chat list store

```

(The residue ledger stores its state in `./.residue/<topic>.json`, created on
first use; override with `--store`.)

## The database

Two provenance tiers, never confused (`ideonomy/data/`, load via
`python3 -m ideonomy.canon ls` and `... --tier grown ls`):

- **canon** — Gunkel's own lists, recovered verbatim with per-source
  provenance: the archived pre-redesign ideonomy.mit.edu text
  (`canon-wayback.jsonl`), all 403 of his photographed charts transcribed by
  vision models with legibility labels (`canon-charts.jsonl`), and monograph
  pages stitched from page scans (`canon-monographs.jsonl` — "23 Diverse
  Ideonomic Lists" recovered whole, every list's count verified against its
  printed title). ~530 lists, ~31k items.
- **grown** — the machine-extended edge, produced by the hill-climb
  (`climb.py`): each list breathes through grow → typology → gap-fill → gate
  → ratchet, where an independent strong-model pass induces the list's own
  typology, names the types it *neglects* (the climb's gradient), and gates
  every candidate for genuine-category / distinctness / combinatorial
  phrasing, recording drops as residue with reasons. Plateau is flagged when
  the keep-rate falls, so a list stops claiming easy growth. Grown lists
  carry `source.tier == "grown"` and can never masquerade as canon.

Within the grown tier, the operative quality standard is itself a grown list:
**list-excellences** — the dimensions along which an ideonomic list is judged
(denominator honesty, joint-carving, recognition shock, mutual exclusion,
depth gradient, …). Every fable-direct breath self-gates against it and
records residue; older machine-grown lists are periodically re-gated against
it, with cuts logged as ledger residue.

Grown-tier conventions, all carried in `source` with zero schema change:

- **Registers** — each list is written in one named voice (`source.register`,
  e.g. "elegiac-anthropological", "clinical epistemology"); the register is a
  deliberate lean into a different part of the model, not an accident.
- **Maps** — `source.kind == "map"` marks lists whose items are positioned
  structures rather than flat instances. First instance: `advice-antinomies`,
  where each item is `pole ↔ pole — hinge:` and the hinge is a checkable
  discriminator (a map of both-sided advice is a map of hidden hinges).
- **Seriation** — the item order can itself be a claim (Gunkel's seriation;
  cf. gwern's embedding-TSP `seriate.py`). Two rails: model-direct (an agent
  names candidate axes and sorts, e.g. `model-collapse-markers` as a disease
  course, `somatic-atoms` by autonomic depth) and algorithmic —
  `ideonomy/seriate.py` is a stdlib-pure ordering algebra (Fiedler spectral
  seriation, greedy chaining, and `smoothness`, the objective all orders
  compete on), driven at scale by the corpus repo's `seriate_drive.py`
  (embeddings → order → **seriability** score, the smoothness gain over
  random order that measures how strongly a hidden 1-D dimension runs
  through a list → a strong model names the axis and judges it revelatory
  vs mere clustering). A seriated grown list stores its axis and scores in
  `source.seriation` and ships in its order; canon stays verbatim — canon
  orders live as indices in `data/seriations.jsonl`. Self-application:
  `data/catalog-map.jsonl` seriates the catalog itself (list centroids →
  the database's master axis + 2D coordinates).
- **Boundary claims** — when growth discovers the list's universe has an
  edge, the claim is recorded (`source.boundary_claim`) and the excluded
  universe gets a sibling list (somatic-atoms ↔ interoceptive-atoms).

The per-list breath ledger (residue, keep-rates, `by:` provenance for
model-direct vs pipeline breaths) lives in the corpus repo's `climb-ledger/`.

This is Gunkel's progressive loop (list → induce types → find missing items →
refine) made executable, with the evaluation gate he lacked. The catalog
applies to itself: the same gate-and-typology discipline the skills prescribe
is what grows the database.

## Status

The catalog, skills, and offline engines are substantive and tested. Two
pieces of empirical evidence are now committed:
[docs/breath-log-external.txt](docs/breath-log-external.txt) — the MDL engine
run on two real external corpora, finding named structure where it exists
(ratio 1.110) and honestly reporting near-null where it doesn't (1.011) — and
[docs/heterogeneous-trial-r7.txt](docs/heterogeneous-trial-r7.txt) — the first
real three-vendor trial (Claude vs Gemini argued, sides swapped for balance,
local Qwen judged), whose swap-stable verdict went *against* the maintainer's
own publication decision and is committed unedited: the trial engine does not
flatter its owner. Still undemonstrated: compression depth beyond token-level
MDL (semantic grouping with model-backed judges). The
full labeled denominator of what "canonical" means here — covered, named-gap,
ruled-out, nothing unlabeled — is [docs/canonicality.md](docs/canonicality.md).
The catalog applies to itself: gap-find it, vary it, and keep what survives
refutation (P11, P15, P22, P35).

## Lineage and related work

Everything here descends from **Patrick Gunkel** (the primary source:
[ideonomy.mit.edu](https://ideonomy.mit.edu/), five scanned volumes and ~400
charts) via **Grace Kind's revival essays**
([intro](https://gracekind.net/writing/ideonomy/intro/)), which named the
field's three open problems: evaluating idea quality, contextualizing
ideation strategies, and effective AI-driven ideation. This repo's center of
gravity is the first two — gates and routing — which is also what
distinguishes it from its siblings:

- [`latentwill/ideonomy-skill`](https://github.com/latentwill/ideonomy-skill)
  — a well-made pair of Claude skills built on Kind's essays: an external
  random picker (8 operators × 17 organons × 29 dimension-prompts) against
  ideation mode-collapse. Take its thesis seriously — `draw.py` here is that
  idea pointed at Gunkel's full catalog. What it deliberately lacks is what
  this repo is for: evaluation gates and cross-session accumulation.
- [`Morpheis/ideonomy-engine`](https://github.com/Morpheis/ideonomy-engine)
  — a TypeScript CLI curating 28 of Gunkel's divisions into agent-usable
  lenses with chaining/synthesis verbs. Good curation; the composition is
  string templates, and there is no judgment layer.
- [`kindgracekind/ideonomy-legacy`](https://github.com/kindgracekind/ideonomy-legacy)
  — Kind's own 2023 experiments, including the first stab at the
  idea-quality problem (`discriminator.py`).

Distilled research notes with full provenance: [docs/gunkel.md](docs/gunkel.md).
This repo packaged as a capability a stranger's agent can execute end to end:
[AFFORDANCE.md](AFFORDANCE.md).

MIT licensed.
