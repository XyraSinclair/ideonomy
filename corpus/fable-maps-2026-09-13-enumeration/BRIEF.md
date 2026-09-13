# Brief: author one ideonomic map — enumeration and reasoning-graph fleet (run 2026-09-13)

Make one **ideonomic map** for the Ideonomy atlas in one of two territories: (A) enumeration itself, the practice this atlas is made by: how lists get made, what a register does to them, and how model passes compose to enumerate better; (B) reasoning graphs: a reasoner that sees only a window, gets its outputs back through an environment, and is sometimes many windows wired together.

Read first, in this order:
1. `skills/practice-deep-ideonomy/SKILL.md` — the practice.
2. The admitted map `option-expiries` in `data/grown.jsonl` — one admitted map record. Your output must have exactly this schema (same keys, same nesting).
3. `corpus/climb-ledger/option-expiries.jsonl` — the per-breath ledger.
4. Skim `bin/ideonomy canon --tier grown ls` so your map does not duplicate an existing list. The lists nearest these territories are: list-excellences, question-metamorphoses, decision-tree-topologies, register-jumps, mathematical-moves, model-collapse-markers, invariant-kinds, discovery-delights, passages-between-levels, domain-entry-keys, importance-detectors, witness-architectures, fertile-forgettings, traces-of-the-unlived, learning-that-commits, clocks-that-are-not-clocks. Your map must not restate any of them; where an item is adjacent to one, say what it adds.
5. For territory (A), the repo's own practice is one source of cases: `src/Ideonomy/*.hs` (the passes: `Climb`, `Widen`, `SeriateDrive`, `Triangulate`, `Parley`, `Trial`, `Consult`), the fleet briefs under `corpus/fable-maps-*/`, and the ledgers under `corpus/climb-ledger/`. For territory (B), the same files are cases too (a fleet is a window graph; a ledger is an environment loop), but do not let the map become a description of this repo.

## Territories (one per author; your task names yours)

- **enumeration-stalls** — a mechanism by which an enumeration stops yielding new members before its universe is exhausted while feeling complete, named with what the stall is made of (the frame's grammar, an exemplar's gravity, a register's ceiling, the enumerator's own memory, the judge's saturation, a typology's filled cells, a reader's exhausted experience), the tell that separates it from exhaustion and who can read that tell (the enumerator alone, a fresh judge, a reader from another domain, only a denominator, nobody), and the move that restarts it. The repo's climb flags a plateau on keep rate alone and cannot tell which kind it found; that is a case, not the map. `list-excellences` judges a finished list and `model-collapse-markers` diagnoses a framework; this map holds the process.
- **denominator-manufactures** — a mechanism by which an enumerator obtains a universe to count against when none was given, named with the carrier (a partition, a product of dimensions, a corpus, a rival's independent list, a generating grammar, a physical bound, the list's own rediscovery statistics, an accumulation curve's asymptote, a declared refusal), what it makes countable, what it silently excludes, and the tell that the denominator was manufactured rather than found. Real estimators have distinct blind spots (a rediscovery estimator cannot see members no process reaches; two correlated nets miss the same things for the same reason; a product of dimensions excludes what does not decompose along them). The product of dimensions belongs here as a universe and to `form-yields` only through what its empty cell yields.
- **item-grains** — a mechanism by which the unit of an enumeration is fixed (a grammatical frame, a required part, a case requirement, a name form, a count bound, a declared modality), named with what the grain admits and forbids, what the same subject yields at a neighbouring grain, and the tell of the wrong grain (a list of 85 that is 12 with synonyms; a map of 18 that is 3 mechanisms with cases). The catalog holds same-domain pairs at different grains (`somatic-atoms` beside `somatic-signals`; `mathematical-moves` at 128 verb phrases beside maps of 18 mechanisms with carrier, cost, and tell); `pricing-unit-metamorphoses` is the business analogue, and the passage between them is real: change the unit and you change what is being bought.
- **form-yields** — a mechanism by which a form imposed on a pile (an order, a partition, a product, a graph, a hierarchy, a projection) produces a member, an absence, or a distinction the pile did not hold, named with the form, what it makes visible, what it costs (members forced into the wrong cell, an axis whose claim is false), the yield by the form's failure to hold, and the tell that the form manufactured the item (an item that reads as its cell's name plus a case). Mendeleev's empty cell is the canonical case; the endpoints of a seriation axis demanding their limiting members is the same mechanism in this repo. The practice's own finish condition ("the chosen form supports an inference the bare pile did not") has no map of its mechanisms.
- **register-yields** — a mechanism by which the register an enumeration is written in admits a member the neutral register cannot reach, refuses one it could, or manufactures one the subject does not have, named with the register, the member, what it costs, and the tell that the register rather than the subject produced the item (an item that cannot be restated flat without losing its truth was the register's; an item that exists only as the exception to its neighbour was the legal register's; an item with no observed case is the invented-world register's and must say so). `bin/ideonomy registers --ls` asserts each register's unlock; the map must also carry the register's artifacts. `register-jumps` moves a live situation between registers; this map is what a register does to a list.
- **composition-yields** — a mechanism by which composing two or more passes (a fresh-context critic, a seriator, a blind judge, a rotated register, an adversarial trial, an embedding neighbour, a second model family, a repairer who may only cut) produces a member, an ordering, or a distinction no single pass yields, named with the composition's shape, what crosses between the passes (an artifact, a summary, a verdict, an embedding, nothing but a name), where the judgment ends up sitting, and the degradation (consensus collapse, anchoring, a verdict attractor, averaging the shape away). Two observed cases from this repo's corpus: all 38 critiques across three fleets returned `admit-with-repairs`, never any of the other three verdicts, a distribution set by the verdict menu and the seat rather than the maps; and `Seriate` splits measuring the order (the engine) from naming the axis (the caller), so the composition yields an order nobody authored and a claim nobody measured. The doctrine of splitting generator from critic is the catalog's own and is not an item; the mechanism under it is.
- **context-horizons** — a mechanism by which the edge of what a reasoner can currently see changes what it can conclude, named with what lies past the edge (a file, a compacted earlier turn, a subagent's transcript, the environment's live state, the reasoner's own earlier output, the shape of its own input: that a thing sits mid-window, that there were three exemplars, that a schema was the designer's and not the world's), the carrier that could bring it in, what bringing it in costs in the window, and the failure in which the edge is mistaken for the world's edge. That failure is the twin of the stall mistaken for exhaustion in `enumeration-stalls`; name the passage. A summary's loss belongs here only as something past the edge now; how the summary was made belongs to `window-successions`.
- **environment-loops** — a mechanism by which a reasoner's output returns to it as input through an environment (a compiler, a test, a file it wrote, a tool result, a critic, a user, a git tree, a clock, a ledger), named with the loop's carrier, what the environment adds that the reasoner could not have known, the loop's latency and whether it can be re-asked (a compiler answers in seconds, a user in hours, a git tree never unless asked, a fresh-context critic once and cannot be re-asked the same question), and the degenerate closure in which the reasoner reads its own output, or its own rule, back as evidence. An observed degenerate closure from this repo: the repair breath forbids adding items and the ledger counts items after over items before, so its keep rate can fall by a cut and never rise by a find; the rule manufactures a ceiling of one, and 41 of 44 repair ledgers sit on it, so a reader who takes the rate as a measure reads the pipeline's own rule back as a result. The loop returns to the same reasoner; what one window leaves for a different one is `window-successions`.
- **window-successions** — a mechanism by which what one reasoner leaves for a successor that will never share its context (a file, a summary, a test, a name, a ledger line, a commit, the environment's state, nothing) fixes what the successor can conclude, must re-derive, or cannot know it lacks, named with the carrier, what it strips and who chose the stripping (the predecessor under its own limit, a compactor, a rule, nobody), the tell of a lossy handoff readable from the successor's side, and what re-deriving costs. A hand-written handoff note, a compaction summary, a ship's log at watch change, a relay baton, a test suite left as the specification, a ledger's `seed` field: the leaving is authored under a limit and the successor cannot check what was stripped. Not `fertile-forgettings` (loss that creates a capacity) and not `traces-of-the-unlived`; here the loss is the price of the crossing and the question is what the carrier can and cannot carry.

## Register for this fleet

Written for someone who makes lists and runs reasoners for a living: an
enumerator filling a catalog, a critic, a person wiring windows together,
who has to tell a stall from an end, a manufactured denominator from a
given one, a register's artifact from a subject's member, and a signal
from the environment from an echo of their own output. Operator-grade and
concrete: what the stall is made of, what the denominator counts and
excludes, what crosses the edge and what it strips, what the loop adds and
how long it takes, which pass or which hand produced the item, and the
tell that says so. Cases from this repo's own ledgers and critiques (the
climb's plateau flag, the 38 verdicts, the breath-3 keep rate, the
measure/name split in seriation), named by role and tier and never by a
model's pet name, and from outside: Mendeleev's empty cells, Good–Turing
and capture–recapture, Zwicky's box, species accumulation curves, the
OED's reading programme, the census undercount, field guides, patent
classes, court dockets, compilers' error lists, double-blind trials,
air-traffic handoffs, ship's logs, relay races. Banned: prompt-craft
vocabulary (hallucination, few-shot, chain-of-thought, temperature,
lost-in-the-middle, mode collapse, retrieval-augmented, agentic, context
engineering), the organon's labels (no item cites a P-number or an
M-number; it shows the mechanism), consultant vocabulary, motivational
tone, and any item that is a tip. Each item declares its modality
(observed, analytical, speculative, invented-world). Willing to be
strange: show the enumerator or the reasoner, the carrier, the threshold,
the tell, and the changed next move; make each conditional edge support
an inference the bare list could not.

## Standards (these are the gate; a map that fails them is copy, not a map)

- Every item is a distinct **mechanism**, not a theme, tip, or example.
- Each relation `label` is a conditional claim.
- 16–18 items is a work bound, not a target: a smaller map with separating cases beats a padded one.

## Outputs

- `corpus/fable-maps-2026-09-13-enumeration/<slug>.json` — the full record, one JSON object, `name` == `<slug>` (kebab-case, no existing list name).
- `corpus/fable-maps-2026-09-13-enumeration/<slug>.ledger.jsonl` — two lines, one per breath, schema as the exemplar ledger (`reviewed_by: "pending"`). Write the record and the first ledger line as soon as breath one is done, then overwrite after breath two, so a death mid-run leaves a usable artifact.

Validate before you finish:
```
bin/ideonomy check <path>
```
Final reply: slug, one-line `of`, the axis, and the single most surprising item. Nothing else.
