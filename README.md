# ideonomy

**Source-available under [Harvest Commercial 1.0](LICENSE).** Commercial use of
new protected contributions requires a separate paid license; no donation or
self-assessed zero substitutes for an agreement. Prior MIT grants and
third-party rights remain intact. Commercial licensing: [contact@exopriors.com](mailto:contact@exopriors.com),
attention Xyra Sinclair.

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

## Where the information lives

A model's default generations sample the mode of its training distribution:
ask for ideas and you get the densest neighborhood, fluently. Ideonomic work
is the deliberate traversal of the rest of the space, and everything in this
repo stores its information in one of five places:

- **The denominator.** A list is a bounded claim about a region of idea-space:
  which universe it enumerates and how much of that universe it has actually
  covered. Coverage is labeled — covered, named-gap, ruled-out — never
  implied.
- **The partition.** An induced typology is a structural claim, tested by
  whether the types exclude each other and whether naming a neglected type
  yields real new members. The neglected types are the gradient the growth
  climbs.
- **The order.** A seriation axis or relational map asserts geometry the
  underlying embedding does not certify; axes and verdicts stay labeled as
  interpretation, and canon order is never overwritten.
- **The gate.** Generation is cheap and discrimination scarce, so value
  concentrates in what was refused and why. Every drop is recorded as residue
  with its reason, and residue seeds the next pass.
- **The ratchet.** Structure is kept only while it pays for itself in
  description length; a cycle that does not hold the compression ratio is
  reverted, so the corpus cannot bloat its way to the appearance of progress.

Gunkel could work the first three by hand. The last two are what models make
affordable, and they are where this repo differs from its siblings: gates and
accumulation.

## Before and after

Ask an agent whether a product's landing copy is in the right register.

**Default:** "It's solid, 8/10."

**With [`triangulate-without-oracle`](skills/triangulate-without-oracle/SKILL.md)
loaded:** the agent names that no computable answer exists, splits the judgment
into axes — austerity, exactness, structural clarity — and gets two independent
reads per axis. The reads agree on two axes and disagree on whether one line
overclaims. That disagreement is the actual review finding, and it goes to the
human who owns the call, with the grounds named. No fabricated number.

## What's here

Three layers, each usable alone:

1. **[`skills/`](skills/) — agent skills.** Each is one page, self-contained,
   with its trigger in the frontmatter and its gate in the body. Start with
   [`practice-deep-ideonomy`](skills/practice-deep-ideonomy/SKILL.md) for
   list-making that discovers its own grammar, or the oracle trio —
   `triangulate-without-oracle`, `build-the-oracle-before-the-answer`,
   `audit-the-oracle-coverage` — for judgment with and without a computable
   check. The original three-persona distillation and its independent
   adversarial reviews are in [docs/premier-skills.md](docs/premier-skills.md).

2. **[ORGANON.md](ORGANON.md) — 37 inference-time cognitive primitives** in
   one tension-metabolizing loop (SENSE → ORIENT → GENERATE → JUDGE → ACT →
   PERSIST), synthesized from three streams that converge on it: Gunkel's
   ideonomy, automatic taxonomy induction, and automatic codebase improvement.
   **[CYCLES.md](CYCLES.md)** adds the orthogonal expansion↔compression axis,
   ratcheted on minimum description length, that turns the catalog into an
   engine.

3. **[`ideonomy/`](ideonomy/) — the engines and Gunkel's corpus as data.**
   Stdlib-only Python 3.9+, zero dependencies, fully offline-testable.
   Engines: [`cycles.py`](ideonomy/cycles.py) (MDL-ratcheted
   expansion/compression), [`triangulate.py`](ideonomy/triangulate.py)
   (independent judgments per axis when no oracle exists),
   [`trial.py`](ideonomy/trial.py) (advocate vs adversary, swap-balanced,
   independent bench), [`parley.py`](ideonomy/parley.py) (multi-party
   constraint solving, maximin at impasse),
   [`residue.py`](ideonomy/residue.py) (cross-session ledger),
   [`lists.py`](ideonomy/lists.py) (typed, provenanced list algebra),
   [`seriate.py`](ideonomy/seriate.py) (spectral ordering with an explicit
   smoothness objective). Corpus: Gunkel's divisions
   ([`divisions.py`](ideonomy/divisions.py)) and generative operators
   ([`operators.py`](ideonomy/operators.py)) machine-usable, and his lists
   recovered verbatim with per-URL provenance in the canon layer
   ([`canon.py`](ideonomy/canon.py) + [`data/`](ideonomy/data/)). Any CLI or
   callable is a model ([`models.py`](ideonomy/models.py)).

## Quick start

```bash
git clone https://github.com/XyraSinclair/ideonomy && cd ideonomy
python3 -m ideonomy.cycles_demo     # the MDL engine over its own catalog — offline
python3 -m unittest discover tests  # the whole suite, no network, no deps
```

The demo prints a cycle log: `grp` is how many groups the compression found,
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
page, self-contained (the `P…`/`M…` keys inside are provenance pointers into
[ORGANON.md](ORGANON.md), not prerequisites). Start with the top three:
`triangulate-without-oracle`, `build-the-oracle-before-the-answer`,
`reframe-until-it-dissolves` — or install `route-to-the-right-move` and let it
dispatch.

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

# The respiratory engine: expand -> judge -> compress over any corpus of text.
state = cycles.seed(["symmetry of grief", "cascade of negotiation"])
cycles.run(state, cycles=5)               # MDL-ratcheted
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

Browse the [published catalog atlas](https://xyrasinclair.github.io/ideonomy/catalog-map.html)
or its [offline copy](docs/catalog-map.html) to search names, types, and
items, then read a list in its stored or canon-sidecar order. Coverage counts
are derived from the data, and a stored projection is shown only while its
item fingerprints match — growing a list hides its stale point rather than
pretending the old map still measures it. Rebuild without network access:
`python3 -m ideonomy.atlas`.

Two provenance tiers, never confused (`ideonomy/data/`, load via
`python3 -m ideonomy.canon ls` and `... --tier grown ls`):

- **canon** — Gunkel's own lists, recovered verbatim with per-source
  provenance: the archived pre-redesign ideonomy.mit.edu text
  (`canon-wayback.jsonl`), all 403 of his photographed charts transcribed by
  vision models with legibility labels (`canon-charts.jsonl`), and monograph
  pages stitched from page scans (`canon-monographs.jsonl`). Canon text is
  never edited; even its seriation orders live in a sidecar
  (`data/seriations.jsonl`).
- **grown** — the machine-extended edge, produced by the hill-climb
  ([`corpus/climb.py`](corpus/climb.py)): grow → induce the list's own
  typology → name the types it neglects → gap-fill → gate every candidate for
  genuine-category, distinctness, and combinatorial phrasing → ratchet, with
  drops recorded as residue and a plateau flagged when the keep-rate falls.
  Grown lists carry `source.tier == "grown"` and can never masquerade as
  canon.

Grown-tier conventions all ride in `source` with zero schema change:
**registers** (each list written in one named voice, a deliberate lean rather
than an accident), **maps** (`source.kind == "map"`, relations with exact item
endpoints so reordering cannot silently change them), **openings**
(`source.priorities` names a near-term lead and a wild branch — attention
choices, not confidence scores), **seriation** (model-direct or spectral via
[`corpus/seriate_drive.py`](corpus/seriate_drive.py); the axis, smoothness,
and seriability score are stored in `source.seriation`, and smoothness alone
is not treated as proof of a one-dimensional spectrum), and **boundary
claims** (a discovered edge of the universe is recorded and the excluded
universe gets a sibling list). The operative quality bar is itself a grown
list — **list-excellences** — and every authored breath self-gates against it,
recording residue.

The per-list ledger (residue, keep-rates, `by:` run labels) is in
[`corpus/climb-ledger/`](corpus/climb-ledger/). The growth, widening, and
seriation drivers in [`corpus/`](corpus/) require `GEMINI_API_KEY` and make
billable model calls; the atlas and everything in `ideonomy/` need neither.
Dated fieldwork records — specimen admissions, a Gemini 3.8 Flash sketching
experiment, growth checkpoints, each with its repairs and limits — are in
[docs/fieldnotes.md](docs/fieldnotes.md).

This is Gunkel's progressive loop (list → induce types → find missing items →
refine) made executable, with the evaluation gate he lacked. The catalog
applies to itself: the same gate-and-typology discipline the skills prescribe
is what grows the database.

## Status

The catalog, skills, and offline engines are substantive and tested. Committed
empirical evidence:
[docs/breath-log-external.txt](docs/breath-log-external.txt) — the MDL engine
run on two real external corpora, finding named structure where it exists
(ratio 1.110) and reporting near-null where it doesn't (1.011) — and
[docs/heterogeneous-trial-r7.txt](docs/heterogeneous-trial-r7.txt) — a real
three-vendor trial (Claude vs Gemini argued, sides swapped for balance, local
Qwen judged) whose swap-stable verdict went *against* the maintainer's own
publication decision and is committed unedited: the trial engine does not
flatter its owner. Still undemonstrated: compression depth beyond token-level
MDL (semantic grouping with model-backed judges). The full labeled denominator
of what "canonical" means here — covered, named-gap, ruled-out, nothing
unlabeled — is [docs/canonicality.md](docs/canonicality.md).

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

## License and compensation

[Harvest Commercial 1.0](LICENSE) is in force for new protected contributions.
Personal non-commercial study, qualifying research and teaching, independent
public-interest scrutiny, and narrowly necessary emergency use have a no-fee
grant. Commercial use requires a separately executed license with payment terms
agreed before use. Those terms may use fixed fees, minimum guarantees,
milestones, royalties, or value-sharing grounded in an agreed Shapley model.
Attribution, a donation, or an honest zero is not commercial permission.

This is **source-available, not OSI-approved open source**. No license can
create copyright over ideas, guarantee collection, or turn an undefined
contribution score into a debt. The paid agreement defines the amount, scope,
reporting, due dates, and dispute process.

The [earlier MIT grant](LICENSE-MIT) remains available for material already
published through commit `52d5ca477c23ab160318a21ab1e4f2a5b030af38`; it is
not revoked or extended to later protected contributions. Private preparation
history is not part of the public release.

Gunkel's recovered material is third-party work: source URLs establish
provenance, not permission to relicense it. No new grant from its rightsholders
was established in preparing this release; Harvest does not supply one.
