# Brief: author one ideonomic map — timing fleet (run 2026-09-10)

Make one **ideonomic map** for the Ideonomy atlas in the territory of timing, reversibility, and option expiry: when to move, whether a move can be undone, and what quietly stops being available while nobody declines it.

Read first, in this order:
1. `skills/practice-deep-ideonomy/SKILL.md` — the practice.
2. The admitted map `walkaway-manufactures` in `data/grown.jsonl` — one admitted map record. Your output must have exactly this schema (same keys, same nesting).
3. `corpus/climb-ledger/walkaway-manufactures.jsonl` — the per-breath ledger.
4. Skim `bin/ideonomy canon --tier grown ls` so your map does not duplicate an existing list. The lists nearest this territory are: lead-time-floors, runway-illusions, clocks-that-are-not-clocks, pivot-invariants, clean-exits, forms-of-return, deal-deaths, market-deaths, walkaway-manufactures, term-sheet-powers, dilution-carriers, power-trades, tollgates-that-must-buy, who-can-be-bound, status-conversions, pressure-transmutations, witness-architectures, traces-of-the-unlived, fertile-forgettings, first-mover-forecloses, hardening-vulnerabilities, risk-rebound-effects. Your map must not restate any of them; where an item is adjacent to one, say what it adds.

## Territories (one per author; your task names yours)

- **option-expiries** — a mechanism by which a previously available course of action becomes unavailable without its holder rejecting it, named with the condition lost (a permission, a capability, a counterparty, a coordination), its carrier, and the last intervention that could have preserved it. An option becoming unattractive is not the same as becoming unexercisable; keep the type on unexercisable. A protected seed: a pause whose upkeep creates a deadline the original situation did not have.
- **undo-costs** — a mechanism by which reversing a move incurs a cost held outside that move's own account, named with who bears it, who discovers it and when, and what the reversal cannot restore. `clean-exits` studies what a leaving conserves and `forms-of-return` studies what sameness licenses a return; this map exposes the missing reversal bill.
- **hold-up-mints** — a mechanism by which an ongoing process makes a previously replaceable party indispensable to its completion, named with the dependency created, the moment substitution stops working, and what extinguishes the resulting power. The unit is the transition into pivotality, not a catalog of gatekeepers; `power-trades` already holds "Key man's lever" and `tollgates-that-must-buy` holds the gate's own compulsion.
- **witness-powers** — a mechanism by which an existing trace lets a specified party take an otherwise unavailable action, named with the carrier, the rule or dependency that makes it effective, and what ends the power. `witness-architectures` covers what must exist for a trace to form; this covers what the trace lets someone do, separating possession of the trace, recognition of it, and activation.
- **advantages-spent-by-use** — a mechanism by which exercising an advantage consumes a condition that made it advantageous, named with what that condition becomes, whether it regenerates, and the observable mark that it was spent. Spending money or stamina is too shallow; `status-conversions` and `power-trades` already hold several social cases, so say what each item adds.
- **learning-that-commits** — a mechanism by which obtaining decision-relevant knowledge changes the available choices before the learner can act on the answer, named with the inquiry, the commitment it creates, and whether a less committing inquiry exists. The distinguishing question is whether "find out first, decide afterward" is actually available.

## Register for this fleet

Written for someone deciding when to move and whether the move can be taken
back: a founder timing a raise or a hire, an operator holding an option that
is going stale, a negotiator whose leverage has a shelf life, a person with
one shot. Operator-grade and concrete: what holds the option, what the clock
is made of, where the cost of undoing is actually kept and who finds it,
which hand has the power at the moment it matters. Illustrative cases from
real raises, contracts, hiring, litigation, logistics, medicine, treaties,
auctions, engineering and field operations. No venture-twitter vocabulary,
no consultant vocabulary, no motivational tone. Willing to be strange: show
the party, the carrier, the threshold, and the changed next move; mark
speculation; make each conditional edge support an inference the bare list
could not.

## Standards (these are the gate; a map that fails them is copy, not a map)

- Every item is a distinct **mechanism**, not a theme, tip, or example.
- Each relation `label` is a conditional claim.
- 16–18 items is a work bound, not a target: a smaller map with separating cases beats a padded one.

## Outputs

- `corpus/fable-maps-2026-09-10-timing/<slug>.json` — the full record, one JSON object, `name` == `<slug>` (kebab-case, no existing list name).
- `corpus/fable-maps-2026-09-10-timing/<slug>.ledger.jsonl` — two lines, one per breath, schema as the exemplar ledger (`reviewed_by: "pending"`).

Validate before you finish:
```
bin/ideonomy check <path>
```
Final reply: slug, one-line `of`, the axis, and the single most surprising item. Nothing else.
