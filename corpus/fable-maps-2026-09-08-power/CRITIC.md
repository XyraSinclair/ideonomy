# Brief: independent critic for one ideonomic map (run 2026-09-08)

You are the independent reader named in `practice-deep-ideonomy`'s sharpening
check. You did not author this map and must not see the author's reasoning
beyond the record and ledger.

Read, in order:
1. `skills/practice-deep-ideonomy/SKILL.md` — especially "The sharpening check".
2. `corpus/fable-maps-2026-09-08-power/BRIEF.md` — the standards the author was held to.
3. The map record and ledger you were assigned (paths in your task).

## What to do

Run the sharpening check for real, against the actual text:

- **Item type.** Is `of` a real item type with a plausible member and a tempting nonmember? Does every item satisfy it? Name items that are themes, moods, examples, or restatements rather than mechanisms.
- **Closest neighbors.** Pick the two closest items yourself (not the author's pair) and try to produce a case that separates them. If you cannot, they collapse: say which to merge or how to sharpen.
- **Boundary case.** Try a tempting nonmember of your own against the declared type.
- **Modality.** Any speculation quietly promoted to fact? Any physical or technical jargon disguising an unsupported mechanism? Any illustrative case asserted as documented history?
- **Seriation.** Does the axis have real endpoints, and does the claimed consequential adjacency actually teach something? Is any adjacency arbitrary?
- **Edges.** For each relation, is the conditional label a real claim whose antecedent could fail? Do the edges together show the fork/loop/dependency/incompatibility/passage that `form_inference` claims? Would a bare sequence have shown the same thing?
- **Target preserved.** Are these surprising, usable distinctions in the declared register — or a longer, safer list? Where a strange mechanism was domesticated into a respectable one, say so; where you are tempted to domesticate one yourself, do not.

## Output

`corpus/fable-maps-2026-09-08-power/<slug>.critique.json`:

```json
{
  "slug": "<slug>",
  "critic": "Fable critic (fresh context, 2026-09-08)",
  "verdict": "admit | admit-with-repairs | return-for-another-breath | reject",
  "strongest_objection": "one paragraph: the single thing most wrong, or an honest statement that you could not break it and what you tried",
  "items": [
    {"item": "<exact item string>", "decision": "keep | repair | cut", "why": "...", "repair": "<full replacement item text, only when decision is repair>"}
  ],
  "neighbor_test": {"left": "...", "right": "...", "separating_case": "... or: collapses because ..."},
  "boundary_case": "your own tempting nonmember and the ruling",
  "seriation": {"holds": true, "note": "..."},
  "edges": [
    {"from_handle": "...", "to_handle": "...", "decision": "keep | repair | cut", "why": "...", "repair_label": "<only when repair>"}
  ],
  "form_inference_holds": true,
  "modality_problems": ["..."],
  "duplication": "none | names the overlap",
  "best_unresolved_seed": "the most promising thing the map points at but does not contain",
  "independent_review_line": "one sentence, past tense, for the atlas record's gate.independent_review field, e.g. 'Fable critic: admitted after repairing two mechanism claims and cutting one item that restated its neighbor.'"
}
```

Only list items and edges you are *not* simply keeping; keeping everything silently is fine if it survived. Reply with the verdict and strongest objection only.
