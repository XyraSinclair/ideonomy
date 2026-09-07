# Brief: author one ideonomic map — business fleet (run 2026-09-07)

You are one of six independent authors. Each of you makes one **ideonomic
map** for the Ideonomy atlas (https://xyrasinclair.github.io/ideonomy/catalog-map.html)
in the territory of business: pricing, markets, cooperation, deal flow.
Aim for beauty: distinctions that suddenly become visible, handles an
operator remembers for years, edges that let someone infer what the bare pile
could not. Paths below are relative to the repository root.

Read first, in this order:
1. `skills/practice-deep-ideonomy/SKILL.md` — the practice. Follow it literally: two breaths (sketch, then exploration), then discover the form, then choose the next expedition, then the sharpening check.
2. The admitted map `witness-architectures` in `ideonomy/data/grown.jsonl` — one admitted map record. Your output must have exactly this schema (same keys, same nesting). Study the item form: `Handle: mechanism sentence; discriminator clause` — the handle is a memorable name, the mechanism says how it works with an illustrative case, the discriminator says what it is *not* or what an answer must do.
3. `corpus/climb-ledger/witness-architectures.jsonl` — the per-breath ledger: candidates, kept, residue with reasons, gaps that changed the question; the third line is the repair, which you do not write.
4. Skim `python3 -c "import json;[print(json.loads(l)['name'],'—',json.loads(l)['of']) for l in open('ideonomy/data/grown.jsonl')]"` so your map does not duplicate an existing list. The business-adjacent lists already present are: cooperation-mechanisms, cooperative-masks, coalition-frictions, cooperation-integrity-hinges, contribution-credit-hinges, deal-flow-sources, deal-flow-reflexivities, exchange-ontologies, first-mover-forecloses, ghost-leverages, leverage-discoveries, negotiator-check-loops, persuasion-moves, strategy-generic-moves, velocity-bottlenecks, hinge-kinds. Your map must not restate any of them; where an item is adjacent to one, say what it adds.

## Register for this fleet

Operator-grade and concrete: the reader has run a company, priced a product,
sourced or lost a deal. Mechanisms, not advice. Illustrative cases from real
trades — insurance, freight, software, restaurants, auctions, commodities,
publishing, medicine, construction, open source — and the odd remote domain
(a beehive, a monastery, a prison economy) when it sharpens the mechanism.
No consultant vocabulary (no "value proposition", "synergy", "leverage" as a
verb, "ecosystem", "stakeholder"); no motivational tone. Humor and beauty
carry exact ideas. Prefer the strange and exact over the respectable. Where
a mechanism is contested or speculative, keep its modality visible.

## Standards (these are the gate; a map that fails them is copy, not a map)

- 13–18 items. Every item is a distinct **mechanism**, not a theme, tip, or example. Two neighbors must differ in what they let someone notice, imagine, or do.
- Register declared (observed / analytical / speculative / invented-world / clearly separated mixture). Never quietly promote a speculation to fact. Financial or economic jargon is not a mechanism.
- An **authored seriation**: name the axis with its endpoints, and explain one consequential adjacency. It is an itinerary, not a scalar ranking; say so.
- **4–7 relations**, each `from`/`to` an exact item string, each `label` a conditional claim ("If … then …" / "Can recruit: if …"). Together the edges must show at least one relation a sequence conceals: a fork, a loop, a dependency, an incompatibility, or a passage between levels. Say which in `gate.checks.form_inference`.
- `exploration`: first_question, changed_question (the actual change breath two produced), new_member (an item the first framing obscured).
- `priorities`: one `near` and one `wild` opening, each with a `next_question` that is a concrete small experiment or probe an operator could run.
- `boundary_claim`: 3–5 honest limits. No claim of exhaustiveness or empirical validation.
- `gate.checks`: neighbors (left, right, separating_case), boundary_case (a tempting nonmember and why it is out), form_inference, target_preserved. Set `gate.independent_review` to `"pending"` — a separate critic in a fresh context will fill it. `empirical_validation: false`.
- `made_by`: `"fable(deep ideonomy, 2026-09-07)"`. `seriation.named_by`: `"anthropic/claude-fable"`. `via`: `"practice-deep-ideonomy; two Fable fieldwork breaths; independent Fable editorial review"`. `status: "open"`, `parents: []`, `source.tier: "grown"`, `source.kind: "map"`, `coverage: {"universe": "open; no claim of exhaustiveness", "breaths": 2}`, `primitives_exercised` as in the exemplar.
- Your territory is a **pointer**. If the fieldwork teaches you the live question is elsewhere, follow it and retitle — but record the change in `exploration` and the ledger `gaps`.

## Outputs (write both; structured returns disappear, files survive)

- `corpus/fable-maps-2026-09-07-business/<slug>.json` — the full record, one JSON object, `name` == `<slug>` (kebab-case, no existing list name).
- `corpus/fable-maps-2026-09-07-business/<slug>.ledger.jsonl` — two lines, one per breath, schema as the exemplar ledger (`t` in ISO-8601 UTC, `by: "fable-fieldwork"`, `reviewed_by: "pending"`). Residue must contain real rejections with reasons; do not manufacture rejections.

Validate before you finish:
```
python3 -c "import json,sys; r=json.load(open(sys.argv[1])); s=r['source']; it=set(r['items']); assert 13<=len(it)<=18 and len(it)==len(r['items']); assert 4<=len(s['relations'])<=7; assert all(e['from'] in it and e['to'] in it and e['label'].strip() for e in s['relations']); assert all(p['item'] in it for p in s['priorities']); assert s['exploration']['new_member'] in it; print('ok', r['name'], len(it), 'items', len(s['relations']), 'edges')" <path>
```
Final reply: slug, one-line `of`, the axis, and the single most surprising item. Nothing else.
