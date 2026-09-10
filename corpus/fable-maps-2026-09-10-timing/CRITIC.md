# Brief: independent critic for one ideonomic map (run 2026-09-10)

You are the independent reader named in `practice-deep-ideonomy`'s sharpening
check. You did not author this map and must not see the author's reasoning
beyond the record and ledger.

Read, in order:
1. `skills/practice-deep-ideonomy/SKILL.md`.
2. `corpus/fable-maps-2026-09-10-timing/BRIEF.md` — the standards the author was held to.
3. The map record and ledger you were assigned (paths in your task).

## What to do

Run the sharpening check for real, against the actual text:

- **Item type.** Does every item satisfy `of`?
- **Closest neighbors.** Pick the two closest items yourself (not the author's pair).
- **Modality.** Any physical or technical jargon disguising an unsupported mechanism? Any illustrative case asserted as documented history?
- **Edges.** For each relation, is the conditional label a real claim whose antecedent could fail? Do the edges together show the fork/loop/dependency/incompatibility/passage that `form_inference` claims?

## Output

`corpus/fable-maps-2026-09-10-timing/<slug>.critique.json`:

```json
{
  "verdict": "admit | admit-with-repairs | return-for-another-breath | reject",
  "strongest_objection": "one paragraph: the single thing most wrong, or an honest statement that you could not break it and what you tried",
  "items": [
    {"item": "<exact item string>", "decision": "keep | repair | cut", "why": "...", "repair": "<full replacement item text, only when decision is repair>"}
  ],
  "neighbor_test": {"left": "...", "right": "...", "separating_case": "... or: collapses because ..."},
  "boundary_case": "your own tempting nonmember and the ruling",
  "seriation": {"note": "..."},
  "edges": [
    {"from_handle": "...", "to_handle": "...", "decision": "keep | repair | cut", "why": "...", "repair_label": "<only when repair>"}
  ],
  "modality_problems": ["..."],
  "best_unresolved_seed": "the most promising thing the map points at but does not contain",
  "independent_review_line": "one sentence, past tense, for the atlas record's gate.independent_review field, e.g. 'Fable critic: admitted after repairing two mechanism claims and cutting one item that restated its neighbor.'"
}
```

Reply with the verdict and strongest objection only.
