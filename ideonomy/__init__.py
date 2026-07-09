"""Computational ideonomy: Gunkel's science of ideas as inference-time machinery.

Submodules (import explicitly, e.g. `from ideonomy import cycles`):

- primitives  — the organon, machine-readable (37 primitives, 6 phases)
- divisions   — Gunkel's 236 divisions, each a fault-model lens
- operators   — Gunkel's generative operators as pure functions
- draw        — seeded non-default lens draws (division x operator)
- cycles      — the respiratory engine (expand<->compress, MDL ratchet)
- loop        — the metabolic loop skeleton
- models      — model adapters: any CLI/callable is a model
- residue     — cross-session residue ledger (P-10)
- triangulate — no-oracle triangulation harness (P-9)

Deliberately no eager submodule imports: `python3 -m ideonomy.<mod>` stays
clean, and importing the package costs nothing.
"""

from __future__ import annotations

__all__ = [
    "cycles",
    "divisions",
    "draw",
    "loop",
    "models",
    "operators",
    "primitives",
    "residue",
    "triangulate",
]
