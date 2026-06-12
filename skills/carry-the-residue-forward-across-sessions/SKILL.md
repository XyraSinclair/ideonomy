---
name: carry-the-residue-forward-across-sessions
description: >-
  Stop re-deriving from zero every session. At the close of any non-trivial
  work session, extract what RESISTED resolution — anomalies, reframes that
  failed, objections that survived, named-but-unfilled gaps, contested
  judgments, the unexplained core of a distillation — and persist it as the
  retrievable SEED for the next session. At the start of the next session,
  retrieve and cite it before expanding. The failure it prevents: total amnesia
  between sessions, where residue evaporates and nothing compounds. Triggers at
  session boundaries, before "I'll pick this up later", and whenever you notice
  you're re-discovering something a past session already surfaced.
---

# carry-the-residue-forward-across-sessions

The respiratory engine's whole thesis is that what carries structure forward
across breaths is the residue. Within a session it lives in context; across
sessions it dies unless it is persisted and *cited before the next expansion*.
This skill is that durable seed store, with the distinction the engine cares
about made executable: a session that compresses without ingesting prior
residue is a **churn breath** (motion without gain); a session that opens on
prior residue and resolves or seeds some of it is a **metabolism breath** (work
that compounds).

Organon: P31 episodic-memory + P32 variant-archive + P37 residue-seed + P30
ledger. Phase: PERSIST.

## The tool

A real, stdlib-only ledger ships with the organon —
`ideonomy/residue.py`, scoped per topic, JSON-backed:

```bash
python3 -m ideonomy.residue --topic <topic> open      # surfaces prior residue — cite it
python3 -m ideonomy.residue --topic <topic> add "<text>" --kind <kind> --from <skill>
python3 -m ideonomy.residue --topic <topic> seed <id> ...      # mark as fuel for now
python3 -m ideonomy.residue --topic <topic> resolve <id> [--note .. | --drop | --defer]
python3 -m ideonomy.residue --topic <topic> status    # strict/lenient, metabolism vs churn
python3 -m ideonomy.residue --topic <topic> close     # classifies the breath
```

Residue kinds map to the skills that produce them: `anomaly` (P-5/sensing),
`failed_reframe` (P-3 reverted), `surviving_attack` (P-4), `named_gap` (P-11),
`contested_axis` (P-9), `unexplained_core` (distillation), `open_question`.

## Procedure

1. **Open on prior residue.** Start the session with `open`. It surfaces every
   carried item. Read them — this is the citation that makes the breath a
   metabolism, not a churn. Opening without engaging is the churn the gate
   catches.

2. **Seed what fuels this session.** `seed` the residue items the current work
   is actually advancing. This is P37 in action: the unexplained from last time
   is the expansion seed for this time.

3. **Work.** Use the other premier skills. When one of them produces residue —
   a reframe the MDL gate reverts, an attack that survives, a coverage gap, a
   contested axis with no oracle — `add` it immediately with its kind and
   origin, rather than letting it evaporate.

4. **Close honestly.** Before ending, `resolve` what genuinely closed,
   `--drop` what's ruled out (with a reason), `--defer` accepted debt (it stays
   visible in the strict/lenient gap), and `close`. The session is classified
   metabolism or churn.

## The gate

Session N+1 must **retrieve and engage** session N's residue before expanding.
Concretely: a session that closes having added/compressed but with zero seeded
and zero resolved prior items is logged as a **churn breath**. A run of churn
breaths means the work is not compounding — the ledger makes that visible
rather than letting it hide. The dual strict/lenient score ratchets across
sessions: strict = adjudicated/total, lenient counts deferred too, and the gap
is the accepted-debt meter.

## Example

Close an ingestion session by recording the named residual gaps
(`add "gov corpus uncovered" --kind named_gap --from P-11`) and the unexplained
slow drain (`--kind anomaly`). Days later the next session `open`s, sees both,
`seed`s the gov-corpus gap as the work it's about to do, lands it, and
`resolve`s it with a note — closing as a metabolism breath while the drain
anomaly stays open and visible for whoever picks it up. Nothing re-derived;
the residue was the bridge.
