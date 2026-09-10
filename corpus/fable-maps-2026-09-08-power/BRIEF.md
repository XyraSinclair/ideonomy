# Brief: author one ideonomic map — power fleet (run 2026-09-08)

Make one **ideonomic map** for the Ideonomy atlas in the territory of power exchanges, negotiation, startup fundraising, and venture.

Read first, in this order:
1. `skills/practice-deep-ideonomy/SKILL.md` — the practice.
2. The admitted map `witness-architectures` in `data/grown.jsonl`. Your output must have exactly this schema (same keys, same nesting).
3. `corpus/climb-ledger/witness-architectures.jsonl` — the per-breath ledger.
4. Skim `bin/ideonomy canon --tier grown ls` so your map does not duplicate an existing list. The business-adjacent lists already present are: cooperation-mechanisms, cooperative-masks, coalition-frictions, cooperation-integrity-hinges, contribution-credit-hinges, deal-flow-sources, deal-flow-reflexivities, exchange-ontologies, first-mover-forecloses, ghost-leverages, leverage-discoveries, negotiator-check-loops, persuasion-moves, strategy-generic-moves, velocity-bottlenecks, hinge-kinds, deal-flow-attractors, deal-deaths, clean-exits, what-a-price-does, tollgates-that-must-buy, who-can-be-bound, status-conversions, register-jumps, cooperation-ignitions. Your map must not restate any of them; where an item is adjacent to one, say what it adds.

## Register for this fleet

Written for a founder in a raise, a partner at a fund, or anyone at a table
where power changes hands. Operator-grade and concrete: what a term lets a
party do in which future state, what a clock does to a price, how an
outside option is built or faked, how ownership drains by routes other than
the round price. Illustrative cases from real raises,
funds, acquisitions, labor bargains, treaties, hostage and ransom
negotiations, auctions. No venture-twitter vocabulary ("alignment", "value-add", "founder-friendly", "conviction" as
virtues); no consultant vocabulary; no motivational tone.

## Standards (these are the gate; a map that fails them is copy, not a map)

- Every item is a distinct **mechanism**, not a theme, tip, or example.
- Each relation `label` is a conditional claim.

## Outputs

- `corpus/fable-maps-2026-09-08-power/<slug>.json` — the full record, one JSON object, `name` == `<slug>` (kebab-case, no existing list name).
- `corpus/fable-maps-2026-09-08-power/<slug>.ledger.jsonl` — two lines, one per breath, schema as the exemplar ledger (`reviewed_by: "pending"`).

Validate before you finish:
```
bin/ideonomy check <path>
```
Final reply: slug, one-line `of`, the axis, and the single most surprising item. Nothing else.
