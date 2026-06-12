---
name: refute-your-own-answer-blind
description: >-
  When an answer arrives suspiciously clean — especially on a high-stakes
  claim, a safety judgment, or anything your own confidence is trying to launder
  into truth — strip authorship and confidence, pay an adversary to destroy it,
  and require the attacks to fail on execution rather than on counter-prose.
  The failure it prevents: self-preference and plausibility bias, where the
  model protects its own first answer because it sounds coherent and every
  review quietly reuses that same coherence. Triggers on "this should work",
  policy/safety claims, migration plans, root-cause explanations, and answers
  whose per-step confidence is uniformly high.
---

# refute-your-own-answer-blind

Feynman's blind refutation fused with von Neumann's producer-as-adversary
discipline: the answer's maker, including this model, is treated as the thing
to defeat. Organon: P22 adversarial-refute + P21 judge-panel + M3 blind review
+ M1 generator/critic split + P37 residue-seed. Phase: JUDGE. Respiratory:
surviving attacks are residue; uniform confidence is itself a cue to attack
harder.

## Procedure

1. **Strip provenance.** Remove authorship, scores, and prior confidence from
   the answer so the critic does not inherit your preference for it.

2. **Locate the weakest load-bearing step.** Find the assumption whose failure
   would collapse the whole answer, not the easiest sentence to nitpick.

3. **Generate attacks that can execute.** Ask an adversary to break the answer
   with counterexamples, failing inputs, replayed commands, or alternative
   explanations that can be run, not merely narrated.

4. **Run every serious attack.** An attack only counts if it fails under
   execution: the test still passes, the counterexample does not land, the
   deviation is not profitable, the replay does not reproduce the claimed bug.

5. **Escalate when the answer feels too smooth.** If every step carried high
   confidence, assume the weakest link has not been stressed enough and design a
   harsher attack there.

6. **Keep the survivors as residue.** Any attack that still stands is not a
   debate point; it is the unresolved core to carry forward.

**The gate**

The answer survives only when every attack provably fails when run. A clean
counter-argument in prose does not save it; execution does. If an attack lands,
the answer is not "mostly right" — it failed the gate. If confidence was
uniformly high and the attacks were mild, the gate has not really fired.

## Example

Claim: "the migration preserves all user settings." Blind the plan, then attack
the weakest step: the settings backfill for users with null locale and deleted
workspace memberships. Re-run the migration on a fixture with exactly that
shape. One settings row disappears. The attack executed, so the answer fails;
the surviving attack becomes the real work item, not a footnote.
