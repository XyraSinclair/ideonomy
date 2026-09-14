# Brief: fences as data (run 2026-09-14)

The atlas holds fifty-six ideonomic maps. Each map's `source.boundary_claim`
says in prose which neighbouring lists own the cases it refuses, and each
fleet critique tested one case at that fence. None of it is data the engine
can walk. This run promotes the fences to a typed field, `source.fences`,
so the engine can report the inter-map graph, find unreciprocated fences,
and route a situation from a map to its neighbours.

You extract; you do not invent. A fence exists in the data only if the
map's own text (its `of`, `boundary_claim`, items, relation labels,
priorities) or its critique (`boundary_case`, `neighbor_test`,
`duplication`) supports it. A neighbour named nowhere in that text is not
a fence, however plausible.

## Schema

Write `corpus/fences-2026-09-14/<slug>.fences.json`:

```json
{"name": "<slug>",
 "fences": [
   {"to": "<exact name of an existing list>",
    "kind": "fence" | "passage" | "dependency" | "loop",
    "rule": "<the conditional that decides which side a case falls on, or what changes across the passage>",
    "case": "<one concrete case that sits at this fence, stated so a reader can place it>",
    "case_is": "here" | "there"}
 ]}
```

- `to` must be an existing list name: a grown map or list (`bin/ideonomy canon --tier grown ls`) or a canon list (`bin/ideonomy canon ls`, full dotted name). Never the map's own name.
- `kind`:
  - `fence` — the two maps hold different item types and the rule sends a case to one side.
  - `passage` — the same mechanism seen from the other map's seat (the stall mistaken for exhaustion in `enumeration-stalls` is the edge mistaken for the world's edge in `context-horizons`); `rule` says what changes across.
  - `dependency` — an item here presupposes a member there.
  - `loop` — an item's changed next move lands there and a member there's next move lands back here.
- `rule` and `case` are one sentence each, concrete, in the map's register. `case_is` is where the case as stated sits: `there` when the map refuses it, `here` when it is in despite tempting the neighbour.
- Two to six fences per map. Where the critique's `boundary_case` exists, it is a fence; the ruling in the critique is authoritative over the author's, since the record was repaired to it.
- Do not edit any map record, ledger, or critique. Do not commit. Use a private scratch directory `/tmp/fences-<your group>` for scratch.

## Reading order per map

1. The record in `data/grown.jsonl` (`python3 -c` or `jq -c 'select(.name=="<slug>")'`): `of`, `source.boundary_claim`, `items`, `source.relations`, `source.priorities`, `source.exploration`.
2. Its critique if one exists: `corpus/fable-maps-*/<slug>.critique.json`, fields `boundary_case`, `neighbor_test`, `duplication`.
3. The `of` line of every list you name in `to`, to confirm it exists and holds the item type you send the case to.

Final reply: per map, its slug and the count of fences by kind; then the one fence you are least sure of and why. Nothing else.
