# Brief: register-survival pilot (run 2026-09-14)

Question: what does a register do to a finished map's items? For each
item of one map, restated in a register from the roster and then re-asked
back in the map's own register, does the mechanism survive the round trip,
is something lost, or is something manufactured that the subject does not
have? This is the measurement `register-yields` describes and the atlas
has never taken.

Map: `option-expiries` (`source.json` here: name, of, the original
register, 18 items). Registers: one per family of `bin/ideonomy registers
--ls` plus the map's own register as the control:

- control: the map's own register (restate in place; measures the restater's drift)
- tenderness (TENDER), elegy (GRIEF), vertigo (AWE), scorn (FIRE),
  deadpan (PLAY), foreboding (DREAD), hunger (LONGING), austerity (STILL)

## Restater (one agent per register)

Read `source.json`. Your register's one-line unlock is the line for it in
`bin/ideonomy registers --ls`; embody it, never name it in the text.
For every item, in order:

1. `out`: restate the item wholly in your register. Keep it one item: the
   mechanism, its carrier, its threshold, its tell, its changed next move,
   as the register can carry them. Do not add a case the item does not
   hold; do not drop a part to make the register comfortable. Length free.
2. `back`: from `out` alone (do not look at the original while writing
   this), re-ask the item in the map's own register (the `register` field
   of `source.json`). Write it as an atlas item.

Write `corpus/register-survival-2026-09-14/<register>.json`:
`{"register": "...", "items": [{"i": 0, "out": "...", "back": "..."}, ...]}`
Write after every third item so a death mid-run leaves an artifact.
Final reply: register, item count, and the one item the register fought
hardest. Nothing else.

## Scorer (one agent, fresh context, sees originals and `back` only)

For every (item, register), compare the original item with `back` and
give one verdict:

- `survived`: the same mechanism, carrier, threshold, tell, and next move;
  wording may differ.
- `lost`: a named part of the mechanism is missing or has been blurred
  into a neighbour (say which part).
- `manufactured`: `back` holds a claim, case, or part the original does
  not (say what).
- `lost+manufactured` when both.

Score the control column first, blind to which column it is (the scorer
is handed columns under letters). Write
`corpus/register-survival-2026-09-14/matrix.json`:
`{"items": 18, "columns": {"A": {"register": ..., "verdicts": [{"i":0,"v":"survived","note":""}, ...]}, ...}}`
and `matrix.md`: the 18 × 9 grid (rows items by index and first six
words, columns registers, cells S / L / M / LM), then per-register totals,
then the control's totals as the noise floor, then the three cells that
say most. Final reply: the per-register totals in one line. Nothing else.

## Stage 2: the re-ask, done blind (added after stage 1 was read)

Stage 1's `back` came out at 0.94–1.00 similarity to the originals in
every register (the control, told to vary wording, sat at 0.58): the
restater held the original in its window and reproduced it. That measures
recall, not survival. Stage 2 gives the re-ask to a fresh agent that sees
only `out`.

Re-asker (one agent per register): read
`out/<register>.json` (`of`, the map's own register `map_register`, and
18 `out` texts). Never open `source.json`, `data/grown.jsonl`, or any
other file in this directory. For each `out`, write the atlas item it
describes in `map_register`: mechanism, carrier, threshold, tell, changed
next move, only as far as `out` supports them; nothing `out` does not
hold. Write `back/<register>.json` as
`{"register": "...", "items": [{"i": 0, "back": "..."}, ...]}`, after
every third item. Final reply: register, item count, the one item whose
`out` left the least to rebuild from. Nothing else.

Scorer: as above, on `blind2.json`; writes `matrix2.json` and `matrix2.md`.
`matrix.json`/`matrix.md` stay as the record of the contaminated run.
