"""Seeded draws from the full Gunkel catalog — variation with teeth.

LLMs default to the same few ideation moves; an external chooser forces
non-default ones (mode-collapse resistance, an idea due to latentwill's
ideonomy-skill picker). This drawer composes from a much larger space:
236 divisions x 12 variation operators (2,832 lens-operator pairs), each
rendered as one prompt over your subject.

The draw supplies *variation*; relevance is not the drawer's job. Judge the
outputs (P18 filter, P22 adversarial-refute), keep the live cells, and route
what resists to the residue ledger. A draw is an expansion half-breath —
worthless without the compression that follows (CYCLES.md).

    python3 -m ideonomy.draw "your subject"                # 3 draws, random
    python3 -m ideonomy.draw "your subject" --n 5 --seed 7 # deterministic

Stdlib-only. Deterministic under --seed for testing and replay.
"""

from __future__ import annotations

import random
from dataclasses import dataclass
from typing import Optional

from .divisions import DIVISIONS, lens_prompt
from .operators import VARIATION_OPERATORS


@dataclass(frozen=True)
class Draw:
    division: str      # Gunkel theme, e.g. "ANOMALIES"
    binomen: str       # its coined field, e.g. "Xenology"
    operator: str      # variation operator, e.g. "invert"

    def prompt(self, subject: str) -> str:
        lens = lens_prompt(self.division, subject)
        vary = VARIATION_OPERATORS[self.operator].format(x="what you found")
        return (f"{lens}\n\nThen apply one forced variation — "
                f"[{self.operator}] {vary}\n"
                f"Keep only what survives judgment; name what resists as residue.")


def draw(n: int = 3, seed: Optional[int] = None,
         avoid: Optional[set[tuple[str, str]]] = None) -> list[Draw]:
    """Draw n distinct (division, operator) pairs, uniformly, optionally seeded.

    `avoid` excludes already-used pairs (bring your own memory — e.g. pairs
    recorded in a residue ledger); the drawer itself is deliberately stateless.
    """
    rng = random.Random(seed)
    pool = [(d, op) for d in DIVISIONS for op in VARIATION_OPERATORS]
    if avoid:
        pool = [p for p in pool if p not in avoid]
    if n > len(pool):
        raise ValueError(f"asked for {n} draws; only {len(pool)} pairs available")
    picks = rng.sample(pool, n)
    return [Draw(division=d, binomen=DIVISIONS[d], operator=op) for d, op in picks]


def main(argv: Optional[list] = None) -> int:
    import argparse

    ap = argparse.ArgumentParser(
        prog="ideonomy.draw",
        description="Forced non-default lenses: seeded draws of "
                    "(Gunkel division x variation operator) over a subject.")
    ap.add_argument("subject")
    ap.add_argument("--n", type=int, default=3, help="number of draws (default 3)")
    ap.add_argument("--seed", type=int, default=None,
                    help="deterministic draw for replay/testing")
    args = ap.parse_args(argv)

    for i, d in enumerate(draw(args.n, args.seed), 1):
        print(f"--- draw {i}: {d.binomen} ({d.division.lower()}) x {d.operator}")
        print(d.prompt(args.subject))
        print()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
