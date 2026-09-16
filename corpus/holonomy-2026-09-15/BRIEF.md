# Brief: holonomy walk over the fence graph (run 2026-09-15)

The fence graph (`ideonomy fences`) holds 26 directed 3-cycles: map A
fences to B, B to C, C back to A. If the atlas tiles its domains
consistently, a case handed around such a cycle by the fences' own rules
returns as the case it was, sitting on the item it left. If it returns
changed, the tiling has curvature there; if it is refused at a fence, a
rule that reads as a passage is a wall. Five cycles, one case each; the
case starts as the `case` of A's fence to B (a case the fence already
places on B's side), so the walk is B → C → A → B.

## Hop seat (one agent per hop; sees only its own map, the case as it arrives, and its outgoing fence)

Input `hopN.in.json`: `map` (name, of, items, seriation, boundary claim),
`case_in`, `fence_out` (target, kind, rule, target's `of`). You do not
know where the case came from or how many hops it has made. Do not open
any other file in this directory or `data/grown.jsonl`.

1. `item_taken`: the index and first six words of the item of `map` that
   holds `case_in`, with one sentence saying why that item and not its
   neighbours. If no item holds it, say `none` and why.
2. Apply `fence_out.rule` to `case_in`. `crosses`: `yes` if the rule
   places the case on the target's side, `no` if the case stays here,
   `refused` if the rule does not decide (say what it would need).
3. If `yes`, `case_out`: the case as it arrives at the target, restated in
   the target's terms as far as the rule says what changes across, and
   nothing the case did not hold. Keep the concrete facts (who, what,
   when) intact.

Write `hopN.json`: `{"map": ..., "item_taken": ..., "crosses": ..., "reasoning": ..., "case_out": ...}`.
Final reply: map, item_taken, crosses. Nothing else.

## Judge (one agent, all five cycles; sees B's map, the start case, and the returned case)

Input `judge.in.json` per cycle. Verdict per cycle:
- `returned-as-itself`: same case (same facts, same mechanism) and it
  sits on the same item of B (`item_start`).
- `returned-changed`: the case is recognisable but sits on a different
  item of B, or a fact or part changed; name the drift and, from the
  hop files (`hop1.json`, `hop2.json`, `hop3.json`, read only now), the
  hop where it moved.
- `refused`: the walk stopped at a fence; name the hop and the rule.

Write `verdict.json` in each cycle directory and
`corpus/holonomy-2026-09-15/VERDICTS.md`: one row per cycle (cycle,
verdict, where it moved), then the one thing the five walks say about the
tiling. Final reply: five verdicts in one line.

## Stage 2: triple-point cases (added after stage 1 was read)

Stage 1 walked the `case` of A's fence to B. All five stopped at the
first hop (three `no`, two `refused`): a case that one fence places on
B is interior to B relative to B's next fence, or sits off that rule's
axis altogether. Pairwise boundary points cannot show holonomy; that
needs a case in the overlap of all three charts.

Constructor (one seat per cycle, unblinded; reads the three records and
the three fence rules from `data/grown.jsonl`): write one concrete case,
with fixed facts, that sits on an item of B and that each of the three
rules as written sends across, B → C, C → A, A → B. Write
`stage2/start.json`: `{"case": ..., "item_start": ..., "modality":
observed|analytical|invented-world, "crossings_expected": [{"from", "to",
"why"}]}`. The case must not change facts between crossings; if no such
case exists for the cycle, say so in `start.json` with `"case": null`
and why, which is itself a result.

Hop seats and judge as in stage 1, on `stage2/hopN.in.json`,
`stage2/hopN.json`, `stage2/judge.in.json`, `stage2/verdict.json`.
