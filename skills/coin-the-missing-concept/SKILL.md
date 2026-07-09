---
name: coin-the-missing-concept
description: >-
  When the same awkward phrase keeps recurring — "the kind of bug where...",
  "this class of lines that...", "that pattern we keep tripping on but have no
  name for" — treat the repetition as residue signaling a missing concept. Coin
  a precise noun, give it a decidable membership test, and keep it only if the
  corpus compresses. The failure it prevents: endless circumlocution standing
  in for a concept, where the model repeatedly gestures at the same structure
  but never binds a handle that lets the structure be reused or tested.
  Triggers on repeated locutions, taxonomic awkwardness, and any review where
  the same explanation is written three times with different wording.
---

# coin-the-missing-concept

Grothendieck's concept-making fused with Feynman's bit-measuring and von
Neumann's invariant discipline: a new noun earns its keep only by compressing
the structure and predicting more than the old prose could. Organon: P8 name +
P36 distill + P7 typify + P37 residue-seed. Phase: ORIENT. Respiratory: the MDL
ratchet keeps the name only if the breath gets shorter and sharper.

## Procedure

1. **Collect the repeated locutions.** Gather the awkward phrases, examples,
   and near-duplicates that seem to point at one unnamed structure.

2. **Isolate the type behind them.** Separate what is essential from what is
   incidental until the repeated cases read as members of one candidate type.

3. **Coin the smallest precise name and definition.** Write one noun phrase and
   a one-sentence definition that says what belongs and what does not.

4. **Make membership decidable.** Give a test another reader could apply to a
   fresh case without seeing the original examples.

5. **Measure compression, then predict outward.** Re-express the corpus with the
   new concept and ask whether total description length fell. Then use the
   definition to identify a real case that was not on the original list.

6. **Keep or kill the concept.** If it compresses and predicts, keep it. If it
   merely sounds elegant, delete it.

**The gate**

After coining, `L(corpus|structure)` must drop sharply, `L(structure)` must not
rise enough to erase the gain, and the definition must predict a real
previously-unlisted case. If any of those fail, the concept is decorative and
dies. A clever label with no compression benefit is not a concept; it is copy.

This is a soft gate — for prose corpora the MDL terms are judged, not
computed (see the gate-hardness classification in PREMIER_SKILLS.md). The
out-of-sample prediction clause is the hard part of the gate; lean on it.

## Example

A review keeps repeating "changes that fix the visible page but leave the
coverage claim local." Coin the type: `denominator-local fix` — a fix that
resolves a seen instance without stating or covering the full case space.
Membership test: does the change land one example while the denominator remains
unstated? Applied back to the notes, three clumsy paragraphs compress to the
one term, and it correctly flags an untouched corpus-ingestion patch as another
member. The noun earns its keep.
