"""Gunkel's generative operators as pure functions (no model required).

These are the GENERATE-phase primitives (P12-P17) in their mechanical form:
either direct computations (combine, gap_matrix) or prompt renderers
(vary, analogy_prompt, transpose_prompt, progressive_loop_prompt) whose
output you hand to any model — e.g. via models.CommandModel.
"""

from __future__ import annotations

import itertools
from collections.abc import Iterable, Sequence

# P15 vary: the named variation operators Gunkel used, plus the standard
# inventive-operator residue from morphological analysis / TRIZ.
VARIATION_OPERATORS: dict[str, str] = {
    # Templates must stay grammatical for ANY noun phrase substituted as {x}
    # ("ratcheting scores", "what you found") — no "anti-{x}", no "{x}s".
    "negate": "Assert the opposite or the absence of {x}. What is the anti-form of {x}? Where would {x}, presumed bad, be good?",
    "invert": "Swap the roles, direction, or figure/ground of {x}.",
    "extremize": "Push {x} to its minimum and maximum. What survives at each pole?",
    "miniaturize": "Shrink {x} to its smallest viable instance.",
    "magnify": "Scale {x} up by orders of magnitude.",
    "relax": "Drop one constraint that {x} presumes. Which constraint frees the most?",
    "tighten": "Add one constraint that makes {x} crisper.",
    "iterate": "Apply {x} to its own output. What does applying {x} to {x} yield?",
    "temporalize": "Make {x} a process in time: its genesis, growth, decay.",
    "spatialize": "Give {x} a geometry: nearness, boundary, gradient.",
    "pluralize": "Replace {x} with a population of interacting instances of {x}. What emerges from their interaction?",
    "hybridize": "Cross {x} with its nearest serious rival.",
}


def combine(a: Sequence[str], b: Sequence[str], template: str = "{a} {b}") -> list[str]:
    """P12 ideocombinatorics: cartesian product rendered through a template.

    Phrase list items to maximize syntactically coherent combinations, then
    read the product for live cells. Gunkel: 230 shapes x 74 orders = 17,020
    'shapes of order', each a question.
    """
    return [template.format(a=x, b=y) for x, y in itertools.product(a, b)]


def vary(idea: str, operators: Iterable[str] | None = None) -> dict[str, str]:
    """P15: render an idea through each named variation operator as a prompt."""
    ops = list(operators) if operators is not None else list(VARIATION_OPERATORS)
    out: dict[str, str] = {}
    for op in ops:
        try:
            out[op] = VARIATION_OPERATORS[op].format(x=idea)
        except KeyError as exc:
            raise KeyError(f"unknown variation operator: {op!r}") from exc
    return out


def analogy_prompt(source: str, target: str, n: int = 20) -> str:
    """P13: Gunkel's exhaustive-analogy exercise ('58 ways elephants resemble stars')."""
    return (
        f"Enumerate {n} distinct, substantive ways that {source} resembles "
        f"{target}. Number them. For each, name the shared structure "
        f"abstractly (one phrase), then state what the mapping predicts about "
        f"{target} that is not yet known or commonly noticed."
    )


def transpose_prompt(scheme: str, domain: str) -> str:
    """P14: re-apply one domain's organizing scheme wholesale to another."""
    return (
        f"Take the following organizing scheme and re-apply it wholesale to "
        f"the domain of {domain}: every category, level, and relation should "
        f"be re-instantiated. Report (1) the transposed scheme, (2) which "
        f"cells filled naturally, (3) which cells resisted — the resistance "
        f"is the finding.\n\nScheme:\n{scheme}"
    )


def gap_matrix(rows: Sequence[str], cols: Sequence[str],
               occupied: set[tuple[str, str]]) -> list[tuple[str, str]]:
    """P11 gap-find, mechanical form: the empty cells of a typology matrix."""
    return [(r, c) for r in rows for c in cols if (r, c) not in occupied]


def progressive_loop_prompt(subject: str, seed: Sequence[str]) -> str:
    """Gunkel's progressive loop (P1->P7->P11->refine) as a single instruction."""
    listing = "\n".join(f"- {s}" for s in seed)
    return (
        f"Subject: {subject}\n\nSeed list (non-exhaustive):\n{listing}\n\n"
        "1. Study the list and isolate the TYPES it contains (intension, not "
        "just grouping).\n"
        "2. Use the typology to reveal MISSING items the seed list lacks.\n"
        "3. Emit the refined list: every seed item assigned to a type, every "
        "discovered gap filled with at least one new item, every new item "
        "phrased parallel to the rest so the list composes combinatorially.\n"
        "4. Name the types. End with the residual gaps you could not fill."
    )
