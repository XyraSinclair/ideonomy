---
name: consult-the-atlas
description: >-
  Before planning or brainstorming in a territory the catalog already maps,
  retrieve the lists and maps the situation belongs to and run them as
  instruments: stand on the axis, label every member present / ruled-out /
  unlabeled, walk the edges for consequences the plan did not state, and take
  the pre-written probes. Use at the start of a hard plan, a negotiation, a
  raise, a pricing or survival call, or whenever a brainstorm sounds like the
  model's default. The failure it prevents: sampling the mode when a bounded
  denominator for the situation already exists on disk.
---

# consult-the-atlas

The catalog is a generator until something opens it at the moment of use.
This move opens it. Organon: P10 map + P11 gap-find + P18 filter + P37
residue-seed; the audit half composes `prove-the-coverage-denominator`.
Phase: SENSE -> ORIENT -> JUDGE.

## Procedure

1. **State the situation in your own words, then ask the atlas.**

   ```bash
   python3 -m ideonomy.consult "raising a seed round with four months of cash" --k 3
   python3 -m ideonomy.consult --file plan.md --kind map --k 2
   ```

   Every hit prints its `of` sentence. Reject a hit whose type the situation
   does not belong to; retrieval is lexical and a wrong-vocabulary miss is
   invisible unless you read `of`. Two rephrasings before concluding the
   territory is unmapped.

2. **Stand on the axis.** For each map, place the situation at one stop of the
   seriation and read its neighbors: those are what to expect next and what
   you are about to cross. An axis is an authored itinerary, not a scale.

3. **Label the denominator.**

   ```bash
   python3 -m ideonomy.consult --file plan.md --frame audit --k 2
   ```

   Every member gets exactly one label — present (where in the plan),
   ruled-out (why), unlabeled (what would decide it). A plan that "covers
   everything" and cannot fill this frame has not been checked.

4. **Walk the edges from every present member.** An edge label is a
   conditional claim about what the move recruits or forecloses. Write down
   each consequence the plan did not already state; those are the findings.

5. **Take the probes.** Each map's `next_question` is a small discriminating
   experiment already designed. Run one, or say why none applies.

6. **Route what resisted.** Members left unlabeled and edges you could not
   evaluate go to the residue ledger; the next fleet's brief reads them
   (`python3 -m ideonomy.consult --from-residue <topic>` shows what last
   session left open and which maps it lands in). A situation no list matches
   is a territory for `practice-deep-ideonomy`, not a shrug.

**The gate**

For at least one chosen map, every member is labeled and the count of
unlabeled members is stated (zero, or PARTIAL with the number), and at least
one edge consequence the plan did not state is written down. A consult that
produces neither a labeled denominator nor a new consequence produced nothing;
say so and route to `practice-deep-ideonomy` or `triangulate-without-oracle`.

## Example

Situation: a founder planning a raise with four months of runway. The consult
returns `runway-illusions`, `walkaway-manufactures`, and `dilution-carriers`.
On the runway axis the plan sits at the stop where watchers reprice the
founder's burn. The audit marks eleven carriers ruled-out, five present, one
unlabeled (a re-vest whose trigger the plan does not specify). The edge from
the insider bridge to the outside lead's terms yields the consequence the plan
missed: the bridge, once named, tells the lead the outsiders did not come. The
probe taken is the meter-in-weeks arithmetic on the bridge itself.
