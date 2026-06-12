# Gunkel and ideonomy: distilled research notes

Compiled 2026-06 from primary sources. Machine-usable forms live in
`ideonomy/divisions.py` and `ideonomy/operators.py`.

## The man and the program

Patrick M. Gunkel (1947–2017): high-school dropout, no college; researcher
under Edward Fredkin at MIT's computer science lab ~1971–1987; earlier at the
Hudson Institute under Herman Kahn; supported from 1984 by a Lounsbery
Foundation grant. Front-page WSJ profile 1987-06-01: "Patrick Gunkel Is An
Idea Man Who Thinks in Lists" (full text at ideonomy.mit.edu/gunkel.html).
His papers are in the MIT archives. The site ideonomy.mit.edu (static since
2006, maintained as a memorial by/for Whitman Richards) hosts five scanned
monograph volumes — Orange, Blue, Pastel Green, Bright Green ("What Ideonomy
Can Do," 132 sections), Yellow (glossary) — and ~400 photographed charts.

His definition: ideonomy is "the pure and applied science of ideas and their
laws, and of the use of same to describe, generate, investigate, or otherwise
treat all possible ideas related to any subject, problem, thing, or other
idea." Pure ideonomy discovers the laws of ideas; applied ideonomy uses them
on any subject. He sketched a nine-part partition of the field:
philosophical, foundational, thematic, terminological, theoretical,
methodological, experimental, technological, applied.

## The method

**The progressive loop** (the core algorithm, and the seed of everything in
ORGANON.md):

1. Start with a non-exhaustive list of examples of a thing.
2. Study the list to isolate and identify *types*.
3. The typology reveals *missing items*.
4. Refine the primary list; iterate.

Two constraints on list items: they must cover genuine categories of nature,
and they must be *phrased to maximize syntactically coherent combinations* —
the lists are designed as combinatorial feedstock, not just records.

**Ideocombinatorics** — systematic cross-products, computer-generated:

- 230 Universal Elementary Shapes × 74 Types of Order = 17,020 "shapes of
  order," each phrased as a question ("Can there be pits of recurrence?").
- 638 personality traits; traits × emotions = 84,496 two-word psychological
  states ("arrogant affection," "insecure acceptance").
- 45,540 what-if questions about toxins for microbiologist David Bermudes;
  one led to a novel toxin-classification approach.
- 58 ways elephants resemble stars; proportional analogies from size lists
  ("a blood cell is to a pea as an oil tanker is to the atmosphere").
- Negation applied to "disease" yielded "proseases" — good diseases —
  anticipating communicable probiotic therapy.

**Organons**: any artifact that captures/treats ideas — lists, charts,
matrices, atlases, scales, dictionaries, MDS maps. Organons expand through
"combination, permutation, transformation, generalization, specialization,
intersection, interaction, reapplication, recursive use" of existing
organons. With Richards he laid lists out as multidimensional-scaling maps
and countermaps (28 generic motions, 38+ emotions, 159 archetypal analogs).

**Divisions**: 235 claimed subfields, each a binomen (THEME → coined Greek
field name): ANALOGIES→Icelology, HIERARCHIES→Climology, NEGATIONS→Arnesology…
The division list is itself a taxonomy of meta-level structural concepts —
a catalog of cognitive operations and structures. See `divisions.py`.

## Lineage

Gunkel's acknowledged predecessors: Leibniz (characteristica universalis),
Roget (the thesaurus as concept taxonomy), Mendeleev (combining
element-family lists reveals gaps), and above all **Fritz Zwicky** — "the
grandfather of ideonomy" — for morphological analysis: exhaustive exploration
of a parameter-space box. Adjacent fields: TRIZ, computational creativity,
systems theory.

## Why now

The method's bottleneck was always evaluation: a human cannot adjudicate
84,496 generated psychological states, so the cross-products sat unread.
Grace Kind's revival (gracekind.net/writing/ideonomy/intro/, 2024–2026, with
a digitized Gunkel-document archive) names the LLM-era unlock precisely:
models can (a) evaluate idea spaces of that size, doing the "subjective"
scoring, and (b) draw cross-domain connections from broad corpora. The open
problems she lists — how to evaluate idea goodness, context-dependence of
ideation strategy — are exactly the JUDGE-phase problems the codebase-repair
literature has spent five years industrializing (judge panels, adversarial
refutation, multi-oracle gates). That convergence is the thesis of this repo.

Note: no dedicated gwern/LessWrong treatment of ideonomy was found in
targeted searching; the contemporary revival is essentially Grace Kind's.
Treat any "gwern wrote about ideonomy" claim as unverified.

## Sources

- https://ideonomy.mit.edu/ · /intro.html · /division.html · /whatcando.html
  · /gunkel.html · /mds.html
- https://en.wikipedia.org/wiki/Ideonomy ·
  https://en.wikipedia.org/wiki/Patrick_Gunkel
- https://gracekind.net/writing/ideonomy/intro/ ·
  https://gracekind.net/resources/gunkelpdfs/
- https://archivesspace.mit.edu/repositories/2/resources/1353
