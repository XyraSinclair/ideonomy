# Brief: apply an independent critique to one ideonomic map (run 2026-09-08)

You are the repairer. The author and the critic are done; you reconcile them
into the record that will enter the atlas. Read, in order:

1. `corpus/fable-maps-2026-09-08-power/BRIEF.md` (standards, schema).
2. `skills/practice-deep-ideonomy/SKILL.md` ("The sharpening check": a criticism that merely replaces a strange mechanism with a respectable different one does not win; preserve the original unless the critic showed it actually fails).
3. The record `<slug>.json`, its ledger `<slug>.ledger.jsonl`, and the critique `<slug>.critique.json` (paths in your task).

## Rules

- Apply every `repair` and `cut` the critic justified. Where a repair domesticates a strange mechanism into a familiar one without showing the original fails, keep the original and record the disagreement in the ledger's `residue` (with `why`). Do not add new items of your own beyond the critic's repairs.
- When an item's text changes, update **every** place the old string appears: `items`, `relations[].from/to`, `priorities[].item`, `exploration.new_member`, `gate.checks.neighbors.*`. The validator in BRIEF.md must pass.
- Apply edge relabels/cuts; keep 4–7 edges. Apply seriation reorders if the critic argued them; update `seriation.note` accordingly.
- Set `source.gate.independent_review` to the critic's `independent_review_line` (verbatim, or lightly corrected to match what you actually applied).
- Set `source.gate.checks.target_preserved` to a sentence naming the critic's judgment (it is no longer a self-read).
- Append the critic's `best_unresolved_seed` to `boundary_claim` only if it is a limit; otherwise leave it for the ledger.
- Append **one** line to the ledger: `{"t": <ISO-8601 UTC now>, "before": <items before>, "candidates": <items before>, "kept": <items after>, "keep_rate": <kept/before>, "gaps": [<the critic's strongest_objection, condensed>], "by": "fable-repair", "breath": 3, "reviewed_by": "Fable critic (fresh context)", "accepted": [<repaired item texts>], "residue": [<cut items and preserved-against-critic items with why>], "gate": "independent sharpening check applied", "limits": [<any new limits>], "seed": <best_unresolved_seed>}`. Also set `reviewed_by` on the two existing ledger lines from `"pending"` to `"Fable critic (fresh context)"` without changing anything else in them.
- Set `made_by` to `"fable(deep ideonomy; Fable critic admission, 2026-09-08)"`.
- Run the BRIEF.md validator on the final record. Touch nothing outside these three files.

Reply with: the count of items/edges repaired, cut, and preserved-against-critic, and one sentence on the most consequential change.
