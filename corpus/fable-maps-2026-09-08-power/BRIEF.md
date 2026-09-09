# Brief: author one ideonomic map — power fleet (run 2026-09-08)

You are one of six independent authors. Each of you makes one **ideonomic
map** for the Ideonomy atlas (https://xyrasinclair.github.io/ideonomy/catalog-map.html)
in the territory of power exchanges, negotiation, startup fundraising, and venture.
Paths below are relative to the repository root.

Read first, in this order:
1. `skills/practice-deep-ideonomy/SKILL.md` — the practice.
2. The admitted map `witness-architectures` in `ideonomy/data/grown.jsonl` — one admitted map record. Your output must have exactly this schema (same keys, same nesting). Study the item form: `Handle: mechanism sentence; discriminator clause` — the handle is a memorable name, the mechanism says how it works with an illustrative case, the discriminator says what it is *not* or what an answer must do.
3. `corpus/climb-ledger/witness-architectures.jsonl` — the per-breath ledger: candidates, kept, residue with reasons, gaps that changed the question.
4. Skim `python3 -c "import json;[print(json.loads(l)['name'],'—',json.loads(l)['of']) for l in open('ideonomy/data/grown.jsonl')]"` so your map does not duplicate an existing list. The business-adjacent lists already present are: cooperation-mechanisms, cooperative-masks, coalition-frictions, cooperation-integrity-hinges, contribution-credit-hinges, deal-flow-sources, deal-flow-reflexivities, exchange-ontologies, first-mover-forecloses, ghost-leverages, leverage-discoveries, negotiator-check-loops, persuasion-moves, strategy-generic-moves, velocity-bottlenecks, hinge-kinds, deal-flow-attractors, deal-deaths, clean-exits, what-a-price-does, tollgates-that-must-buy, who-can-be-bound, status-conversions, register-jumps, cooperation-ignitions. Your map must not restate any of them; where an item is adjacent to one, say what it adds.

## Register for this fleet

Written for a founder in a raise, a partner at a fund, or anyone at a table
where power changes hands. Operator-grade and concrete: what a term lets a
party do in which future state, what a clock does to a price, how an
outside option is built or faked, how ownership drains by routes other than
the round price. Mechanisms, not advice. Illustrative cases from real raises,
funds, acquisitions, labor bargains, treaties, hostage and ransom
negotiations, auctions. No venture-twitter vocabulary ("alignment", "value-add", "founder-friendly", "conviction" as
virtues); no consultant vocabulary; no motivational tone.

## Standards (these are the gate; a map that fails them is copy, not a map)

- 13–18 items. Every item is a distinct **mechanism**, not a theme, tip, or example.
- Financial or economic jargon is not a mechanism.
- **4–7 relations**, each `from`/`to` an exact item string, each `label` a conditional claim ("If … then …" / "Can recruit: if …"). Name the relation a sequence conceals in `gate.checks.form_inference`.
- `boundary_claim`: 3–5 honest limits.
- Set `gate.independent_review` to `"pending"` — a separate critic in a fresh context will fill it. `empirical_validation: false`.
- `made_by`: `"fable(deep ideonomy, 2026-09-08)"`.
- Your territory is a **pointer**. If the fieldwork teaches you the live question is elsewhere, follow it and retitle — but record the change in `exploration` and the ledger `gaps`.

## Outputs

- `corpus/fable-maps-2026-09-08-power/<slug>.json` — the full record, one JSON object, `name` == `<slug>` (kebab-case, no existing list name).
- `corpus/fable-maps-2026-09-08-power/<slug>.ledger.jsonl` — two lines, one per breath, schema as the exemplar ledger (`reviewed_by: "pending"`).

Validate before you finish:
```
python3 -c "import json,sys; r=json.load(open(sys.argv[1])); s=r['source']; it=set(r['items']); assert 13<=len(it)<=18 and len(it)==len(r['items']); assert 4<=len(s['relations'])<=7; assert all(e['from'] in it and e['to'] in it and e['label'].strip() for e in s['relations']); assert all(p['item'] in it for p in s['priorities']); assert s['exploration']['new_member'] in it; print('ok', r['name'], len(it), 'items', len(s['relations']), 'edges')" <path>
```
Final reply: slug, one-line `of`, the axis, and the single most surprising item. Nothing else.
