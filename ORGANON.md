# The Organon: Inference-Time Building Blocks for Generic Cognitive Work

This is the canonical catalog of composable inference-time operations for doing
generic cognitive work with language models — especially in multi-model
configurations. It was synthesized from three convergent streams:

1. **Ideonomy** — Patrick Gunkel's science of ideas: his generative operators
   (combination, permutation, transformation, generalization, specialization,
   intersection, recursion) and his progressive loop (enumerate → typify →
   find gaps → refine).
2. **Automatic taxonomy induction** — TaxoGen → TnT-LLM → TopicGPT →
   Chain-of-Layer → Anthropic Clio: the modern corpus-grounded instantiation
   of Gunkel's loop.
3. **Automatic codebase improvement** — desloppify, Agentless, Codeflash,
   CodeMender, SapFix, CodeMonkeys, SICA/DGM: the most evolved industrial
   ecosystem of detect → generate → verify → persist loops.

The striking empirical fact: **all three streams converge on the same loop.**
The same ~35 primitives recur whether the substrate is ideas, categories, or
code. That convergence is the evidence that these are genuinely *generic*
cognitive building blocks, not domain tricks.

## The metabolic frame

Every loop here is a **tension-metabolizing cycle**. Tension is a represented
mismatch between *is* and *ought* — a defect, a gap in a typology, an
unanswered question, an unexploited combination. Cognition at inference time
is the conversion of tension into structure:

```
SENSE → ORIENT → GENERATE → JUDGE → ACT → PERSIST → (sense again)
```

- Tension that is sensed but not structured is noise.
- Tension that is structured but not resolved is a backlog.
- Resolution that is not verified is hallucination.
- Verification that is not persisted is wasted compute.

A system metabolizes tension when each cycle leaves it with more structure,
better memory, and sharper sensors than the last — when the residue of
resolution becomes substrate for the next cycle. The persistence primitives
(P30–P35) are what distinguish *metabolism* from one-shot *digestion*.

## Phase I — SENSE: surface tension

**P1. enumerate** — Collect instances of the thing before theorizing about it.
Gunkel started every investigation with a non-exhaustive seed list; taxonomy
pipelines start with candidate-term extraction; code tools start with a scan.
- Signature: `subject → [instances]`
- Metabolizes: vagueness → evidence
- Provenance: Gunkel's progressive lists; HiExpan term extraction; Clio facet
  extraction; every scanner.

**P2. detector-bank** — Many small deterministic sensors feeding one queue.
Reserve model judgment for what rules cannot express. Cheap, repeatable,
auditable.
- Signature: `artifact → [findings(detector, location, confidence)]`
- Metabolizes: ambient unease → located, typed findings
- Provenance: desloppify mechanical detectors; aislop's 50+ rules; Semgrep;
  ruff; lintian fixers.

**P3. fault-model** — Define the defect/possibility class explicitly *before*
searching for instances. "What counts as bad (or interesting)" is a
configurable artifact, not an implicit vibe.
- Signature: `domain → class definitions → targeted search/generation`
- Metabolizes: unfalsifiable taste → testable class membership
- Provenance: ACH's targeted mutants; CodeMender vulnerability classes;
  Continue's team-defined slop rules; Gunkel's divisions as fault-models for
  thought.

**P4. external-signal** — Wire the loop to event streams so it runs
continuously: CI failures, fuzzer crashes, cron ticks, corpus drift, labels.
The loop driver is boring infrastructure, not the model.
- Signature: `event stream → triggered cycle`
- Metabolizes: staleness → liveness
- Provenance: SapFix↔Sapienz; CodeMender↔OSS-Fuzz; OpenHands↔`fix-me` label;
  gh-aw cron.

**P5. dimensionalize** — Identify the axes/facets along which the thing
varies. The single highest-leverage orienting move: a good facet set turns an
amorphous pile into a navigable space.
- Signature: `[instances] → [dimensions(name, range)]`
- Metabolizes: blob → coordinate system
- Provenance: Gunkel's Usiology (properties & dimensions); Zwicky's
  morphological box; Clio facets; TaxoAdapt's multi-dimensional taxonomies;
  desloppify's review dimensions.

## Phase II — ORIENT: structure the field

**P6. cluster** — Group instances by similarity before naming anything.
- Signature: `[instances] → [[instances]]`
- Provenance: Gunkel's Botryology and MDS maps; HDBSCAN/BERTopic; Clio
  semantic clustering; desloppify triage clustering.

**P7. typify** — Study the clusters to isolate *types* — the move from
extension to intension. Gunkel's step two.
- Signature: `[[instances]] → [types(intension, members)]`
- Provenance: Gunkel's Typology/Taxology; LLMs4OL term typing; TnT-LLM label
  induction.

**P8. name** — Bind a precise label and one-sentence definition to each type.
Naming is compression; bad names leak tension forever.
- Signature: `type → (label, definition)`
- Provenance: Gunkel's binomens; TopicGPT/Clio cluster titling; the entire
  practice of API design.

**P9. hierarchize** — Arrange types into levels with consistent granularity
per level and proper-subset children.
- Signature: `[types] → tree`
- Provenance: Gunkel's Climology/Levels/Niveaus; Chain-of-Layer top-down
  induction; Clio multi-level hierarchy.

**P10. map** — Build a structural index of the territory that the model can
navigate instead of raw-reading it: repo maps, call graphs, MDS layouts,
dependency graphs.
- Signature: `territory → cheap navigable structure`
- Metabolizes: token-expensive groping → indexed retrieval
- Provenance: aider repo map; AutoCodeRover AST search; Moderne LST; Gunkel's
  trajectory maps.

**P11. gap-find** — The typology reveals the missing cell. Run the structure
back over the instances and ask what *should* exist but doesn't. Mendeleev's
move; the heart of Gunkel's method.
- Signature: `(structure, [instances]) → [absences]`
- Metabolizes: complacent coverage claims → named residual gaps
- Provenance: Gunkel's progressive loop step 3; taxonomy-expansion literature;
  coverage-gap-driven test generation (Qodo Cover); "exhaustiveness is a
  search-quality property."

## Phase III — GENERATE: candidate moves

**P12. combine** — Cartesian product of lists; phrase items to maximize
syntactically coherent combinations, then read the product for live cells.
Gunkel's ideocombinatorics: 230 shapes × 74 orders = 17,020 questions.
- Signature: `(list_a, list_b, template) → [composites]`
- Metabolizes: exhausted single lists → combinatorial frontier

**P13. analogize** — Transfer structure across domains: find the mapping that
makes an elephant resemble a star 58 ways, then mine the unmapped remainder.
- Signature: `(source structure, target domain) → mapping + transfer candidates`
- Provenance: Gunkel's Icelology; CoRel relation transfer; "proof is a tree."

**P14. transpose** — Re-apply one domain's *organizing scheme* (not just one
analogy) wholesale to another domain and see what it forces into view.
- Signature: `(scheme, new domain) → reorganized domain`
- Provenance: Gunkel's projections/representations; applying code-review
  dimension sets to prose; applying taxonomy-quality criteria to APIs.

**P15. vary** — Systematic variation operators: negate, invert, extremize,
permute, relax, miniaturize. Gunkel negated "disease" and got probiotic
therapy decades early.
- Signature: `idea → [variants by named operator]`
- Provenance: Gunkel's Negations/Inversions/Extremes; mutation testing;
  counterfactual class generation.

**P16. lump-split** — Generalize and specialize as paired, reversible moves.
Every level of a hierarchy is a lump/split decision that can be revisited.
- Signature: `type ⇄ (supertype | [subtypes])`
- Provenance: Gunkel's Generalizations; TopicGPT merge/refine; width/depth
  expansion.

**P17. sample-many** — Generate N independent candidates cheaply; never bet on
the first draw. Generation is cheap; *selection is the product.*
- Signature: `prompt → [candidate₁ … candidateₙ]`
- Provenance: Agentless multi-diff sampling; Codeflash candidate
  optimizations; CodeMonkeys parallel trajectories.

## Phase IV — JUDGE: metabolize tension into resolution

This is the densest cluster in every mature system, and the research frontier:
**verifier headroom exceeds generator headroom** (CodeMonkeys: 57% with their
selector vs 66% oracle — selection quality is the bottleneck).

**P18. filter** — Cheap mechanical winnow before expensive judgment. Kill the
obviously dead candidates with rules, types, parsers, and dedup before any
model sees them.
- Signature: `[candidates] → [survivors]`

**P19. oracle** — Get or *make* an executable truth signal: tests, builds,
benchmarks, reproductions. Generate the oracle before or alongside the fix
(AlphaCodium's enriched tests; Agentless's reproduction test; Codeflash's
regression tests).
- Signature: `claim → executable check`
- Metabolizes: plausibility → ground truth

**P20. self-verify** — Re-run the sensor that found the tension against the
proposed resolution. The cheapest honest verification available: Semgrep
re-scans its own fix; the janitor rebuilds the package.
- Signature: `(finding, resolution) → still-fires?`

**P21. judge-panel** — N model critics with *distinct lenses* (correctness,
security, parsimony, taste), not N identical voters. Diversity catches failure
modes redundancy cannot.
- Signature: `candidate → [verdict(lens)]`
- Provenance: CriticGPT (dedicated critic ≠ generator); CodeMender LLM-judge
  stage; multi-model triangulation.

**P22. adversarial-refute** — Prompt skeptics to *destroy* the candidate, with
refuted-by-default priors. A finding that survives motivated refutation is
worth acting on; one that merely sounded plausible is not.
- Signature: `claim → survives? (majority of refuters fail)`
- Provenance: adversarial verification loops; mutation-as-adversary (ACH);
  re-fuzzing patches (CodeMender).

**P23. tournament** — Treat selection as its own agentic subproblem: voting,
ranked pairwise playoff, and — when votes tie — *generate new discriminating
tests* to break the tie (CodeMonkeys' selection state machine).
- Signature: `[candidates] → winner + reasons`

**P24. multi-oracle-gate** — Ship only on the *conjunction* of independent
oracles: correct AND faster (Codeflash); runs AND passes AND increases
coverage (TestGen-LLM). Single-oracle gates get gamed.
- Signature: `candidate → all-of([oracle₁ … oracleₙ])`

**P25. rubric-first** — Draft the evaluation rubric before judging; refine it
once against reality; then apply it repeatedly. Score is written LAST, after
observation and reasoning, to fight anchoring (desloppify's observe→judge
split).
- Signature: `task → rubric → repeated judgment`

## Phase V — ACT: constrained actuation

**P26. constrained-actuator** — Effects flow only through guardrailed
interfaces that reject malformed actions instantly (SWE-agent's linted editor;
OpenRewrite recipes as deterministic tool calls). Guardrails at the actuator,
not just the prompt.
- Signature: `intent → validated action | rejection`

**P27. atomic-rollback** — Backup → apply → check → auto-revert on red. Git is
the enabler; cheap snapshot/restore is what makes search over states possible.
- Signature: `action → committed | reverted`

**P28. minimal-diff** — The smallest change that resolves the tension. Smaller
diffs are easier to verify and easier to get past the human gate.
- Signature: `resolution → minimized resolution`

**P29. safety-classes** — Explicit applicability labels per action class
(safe / unsafe / display-only), conservative by default, promotable by config
(ruff's fix-safety taxonomy; Copilot Autofix's "fails testing → show nothing").
- Signature: `action class → safety label → default behavior`

## Phase VI — PERSIST: the residue becomes structure

**P30. ledger** — A persistent score that must ratchet, with a **dual
strict/lenient reading** so accepted debt stays visible instead of being
laundered (desloppify's strict-vs-lenient gap). A number that must go up
converts one-shot fixing into metabolism.
- Signature: `state → score(strict, lenient) over time`

**P31. episodic-memory** — Lessons from failures stored in natural language,
scoped, and retrieved by applicability (Reflexion; CodeRabbit learnings;
Semgrep triage memories).
- Signature: `failure → lesson → retrieved-when-relevant`

**P32. variant-archive** — Keep a *population* of attempts including
currently-suboptimal stepping stones, not a single greedy lineage (Darwin
Gödel Machine vs SICA). Ensembles of variants beat every individual member.
- Signature: `attempts → archive → recombination substrate`

**P33. scheduler** — Cron, queues, labels, watchers. Continuity comes from
boring loop drivers, not from model heroics.
- Signature: `work → queued, prioritized, resumed`

**P34. policy-file** — A standing constitution versioned with the work it
governs (AGENTS.md, `.openhands_instructions`, source-controlled slop rules).
Policy drift is itself a tension to sense.
- Signature: `norms → versioned artifact → loaded each cycle`

**P35. self-modify** — The loop edits its own prompts, rubrics, detectors, and
tools; keeps an edit only if measured utility improves (SICA's utility
function; DGM's archive). The organon applies to itself — this catalog is
itself an organon under P11 gap-finding and P35 revision.
- Signature: `loop → candidate self-edit → utility-gated adoption`

## Orthogonal axis — MULTI-MODEL patterns

These compose with every phase above:

- **M1. generator/critic split** — the model that makes is never the only
  model that judges (CriticGPT).
- **M2. diversity over redundancy** — distinct lenses, distinct models,
  distinct prompts; N identical voters share blind spots.
- **M3. blind review** — strip current scores, authorship, and prior verdicts
  before judging (desloppify's blind packets) to prevent anchoring and
  self-preference bias.
- **M4. cross-model triangulation** — disagreement between strong models is
  itself a high-value tension signal: route it to deeper investigation rather
  than averaging it away.
- **M5. ensemble selection** — selection over a pool of multi-model outputs
  outperforms the best single member; invest compute in the selector.
- **M6. human-gate-last** — machine senses, generates, and verifies; the human
  adjudicates only verified survivors (SapFix, CodeMender, Janitor — every
  production system converges here).

## Using the catalog

A practical loop is a *path* through the phases with explicit choices at each
step. Two worked instantiations live in sibling repos:

- [`autotaxon`](../autotaxon) — P1→P5→P6→P7→P8→P9→P11→P16→(P18,P25)→P30:
  corpus to faceted taxonomy.
- [`metabolize`](../metabolize) — P2/P3→P10→P6→P17→(P21,P22,P24)→P26–P29→P30–P33:
  continuous codebase improvement.

The machine-readable form of this catalog is
[`ideonomy/primitives.py`](ideonomy/primitives.py).
