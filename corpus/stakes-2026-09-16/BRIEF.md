# Brief: stakes annotation (run 2026-09-16)

Question: does the atlas have a consequence field? Every map today is a
uniform mesh: about eighteen items at one grain, one rule per fence, the
same context cost per item whether one item's difference is nothing or
is the line between a recoverable and an unrecoverable outcome. If
items carry a stakes coordinate that independent readers agree on, the
mesh can refine where it is steep and coarsen where it is flat, and a
distance can be reported in consequence rather than in items. This run
measures whether the coordinate exists: two blind seats per map, three
maps, agreement between seats, and one prediction against instruments
already run on `option-expiries`.

Maps: three from `data/grown.jsonl`, in `source.json` here with name,
`of`, and items in canonical order. Seats never see `source.json`.

## Seat (six agents: map0..map2, seats p and q)

Read only your input file `in/<map>.<seat>.json`: a list of items under
letters, in an order that is not the map's, with the map's name and its
`of` withheld. Each item is a named situation with its mechanism. For
each letter, judge the situation from inside it, for the person or body
it happens to, and write:

- `magnitude` (1-5): how much of that person's outcome turns on this
  situation going one way or the other. 1: a footnote. 3: a bad month or
  a lost deal. 5: a life, a livelihood, a body, a company, or an
  institution's continuation.
- `reversibility`: `reversible` (can be undone at ordinary cost),
  `costly` (can be undone, at a cost that changes the decision), or
  `irreversible` (no later action recovers what this loses).
- `latency`: when the person finds out the consequence has landed.
  `immediate` (as it happens), `delayed` (weeks to years later),
  `hidden` (may never be attributed to this).
- `cliff`: true if the item contains a point past which no action by
  the holder recovers the position; false otherwise.
- `lost`: one sentence naming what is lost when it goes wrong, concrete.

Judge each item by its own text. Do not rank against the other letters;
the same magnitude for many letters is a finding, not a failure. Do not
infer what map this is or what the atlas would want.

Write `out/<map>.<seat>.json`:

```json
{"seat": "<map>.<seat>",
 "items": {"A": {"magnitude": 4, "reversibility": "irreversible",
                 "latency": "delayed", "cliff": true, "lost": "..."}, ...}}
```

Every letter in the input must appear. Write the file and stop.

## Analysis (lead, after both seats of each map are in)

Unblind with the key. Per map: Spearman rho between the two seats'
magnitudes, exact agreement on reversibility, latency, and cliff, and the
map's mean magnitude and cliff count. Across maps: the flat control
(`discovery-delights`) should carry the lowest mean magnitude and fewest
cliffs; if it does not, the coordinate is not measuring stakes.
Prediction on `option-expiries`: the items the register-survival re-ask
manufactured on (`../register-survival-2026-09-14/matrix2.md`, column
non-S) and the item the holonomy walk drifted on (Chair grown over, 8)
should sit above the map's median stakes. Report the correlation and the
split, whichever way it falls.
