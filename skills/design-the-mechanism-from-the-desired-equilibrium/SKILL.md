---
name: design-the-mechanism-from-the-desired-equilibrium
description: >-
  When the task is to set rules, incentives, or metrics — "how should we score
  this", "what policy makes agents tell the truth", "how do we reward the right
  behavior" — do not propose a rule and hope it induces the outcome. Start from
  the behavior you want as a best-response and build backward through a
  strategyproof template, treating the metric-gamer, often the model itself, as
  adversary. The failure it prevents: hope-based governance and gamable
  metrics, where the optimizer satisfies the letter of the score while defecting
  against the intent. Triggers on rubrics, auctions, evaluation design, agent
  incentives, and any metric someone will optimize against.
---

# design-the-mechanism-from-the-desired-equilibrium

Von Neumann's inverse design fused with adversarial gaming-hardening and
Feynman's refusal to trust unopposed incentives: define the equilibrium you
want, then make it the cheapest honest move. Organon: P3 fault-model + P15 vary
+ P22 adversarial-refute + P24 multi-oracle-gate + P30 ledger. Phase: ACT /
PERSIST, grounded by SENSE on the deviation class. Respiratory: build backward
from the equilibrium, then keep a strict/lenient ledger so gaming stays
visible.

## Procedure

1. **State the desired behavior as a best-response.** Write what each actor
   should do when the mechanism is working, not merely what outcome you hope to
   observe.

2. **Model the gamer.** Treat the optimizer, reviewer, bidder, or model as an
   adversary looking for a profitable unilateral deviation from that behavior.

3. **Choose the nearest strategyproof template.** Start from Vickrey / VCG,
   proper-scoring, commit-reveal, or stake-slash before inventing bespoke rules.

4. **Derive the rule backward.** Adjust information flow, payouts, penalties,
   and verification so the desired behavior strictly dominates the obvious
   deviations.

5. **Check deviations mechanically.** Enumerate the main unilateral deviations
   and verify none improves payoff or score.

6. **Enforce with independent ledgers.** Ship only when a machine-checked
   conjunction of oracles gates the mechanism, and track strict versus lenient
   performance so accepted debt cannot masquerade as success.

**The gate**

The desired behavior passes only if it is a verified best-response: no
profitable unilateral deviation remains. Enforcement must be a machine-checked
conjunction with a dual strict/lenient ledger, not an attestation that people
"should behave." If the gamer can win by gaming, the mechanism failed.

## Example

Suppose an agent benchmark rewards "bugs found." That score invites padding
with low-value or duplicate reports. Reframe the target behavior: surface only
real, non-duplicate bugs with evidence. Model the gamer, then design backward:
credit only findings that survive independent reproduction and dedup oracles,
slash duplicates, and keep strict versus lenient tallies for unresolved reports.
Now padding is not a best-response; verified signal is.
