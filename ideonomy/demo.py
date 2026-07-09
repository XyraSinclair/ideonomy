"""Demo: the organon exercising itself.

No model:    python3 -m ideonomy.demo
With models: python3 -m ideonomy.demo --model 'claude -p {prompt}' \
                                      --model 'codex exec {prompt}'
"""

from __future__ import annotations

import argparse

from . import divisions, operators, primitives
from .models import CommandModel, panel


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--model", action="append", default=[],
                    help="command template with {prompt} (repeatable -> panel)")
    ap.add_argument("--subject", default="tension metabolism in agent loops")
    args = ap.parse_args()

    print(f"organon: {len(primitives.PRIMITIVES)} primitives across "
          f"{len(primitives.PHASES)} phases; "
          f"{len(divisions.DIVISIONS)} Gunkel divisions recovered\n")

    # P12 combine — mechanical, no model needed.
    combos = operators.combine(
        ["recurrence", "inversion", "saturation"],
        ["judgment", "memory", "delegation"],
        template="Can there be {a} of {b}?",
    )
    print("P12 combine (3x3 of 9):")
    for q in combos:
        print(f"  {q}")

    # P15 vary — render one idea through three operators. The {x} templates
    # read best with an article-free noun phrase.
    print("\nP15 vary ('ratcheting scores'):")
    for op, prompt in operators.vary("ratcheting scores",
                                     ["negate", "iterate", "pluralize"]).items():
        print(f"  [{op}] {prompt}")

    # P3/P14 — a Gunkel division as a lens.
    print(f"\nP3 lens (ANOMALIES -> Xenology) over {args.subject!r}:")
    print("  " + divisions.lens_prompt("ANOMALIES", args.subject)[:160] + "...")

    if not args.model:
        print("\n(no --model given; stopping at the mechanical layer)")
        return

    models = [CommandModel(m, name=m.split()[0]) for m in args.model]
    print(f"\nrunning P21 judge-panel across {len(models)} model(s)...")
    results = panel(models, operators.progressive_loop_prompt(
        args.subject,
        ["a detector fires", "a judge panel disagrees", "a test goes red",
         "a taxonomy cell is empty", "a score plateaus"],
    ))
    for m, r in zip(models, results):
        head = r if isinstance(r, Exception) else r[:400]
        print(f"\n--- {m.name} ---\n{head}")


if __name__ == "__main__":
    main()
