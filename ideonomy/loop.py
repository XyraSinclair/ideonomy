"""The metabolic loop: SENSE -> ORIENT -> GENERATE -> JUDGE -> ACT -> PERSIST.

A Cycle is a path through the phases. Tension in, structure out; the residue
of each cycle (ledger + lessons) is substrate for the next. This engine is a
working skeleton: stages are plain functions over a shared State, so loops
are composed in Python rather than configured in YAML.
"""

from __future__ import annotations

import json
import time
from collections.abc import Callable
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any


@dataclass
class Tension:
    """A represented mismatch between is and ought."""

    key: str
    description: str
    source: str = ""                 # which sensor surfaced it (P2/P3)
    status: str = "open"             # open | resolved | refuted | deferred
    resolution: str = ""
    evidence: list[str] = field(default_factory=list)


@dataclass
class State:
    subject: str
    tensions: dict[str, Tension] = field(default_factory=dict)
    structures: dict[str, Any] = field(default_factory=dict)   # lists, typologies, trees
    lessons: list[str] = field(default_factory=list)            # P31
    history: list[dict[str, Any]] = field(default_factory=list)  # P30 ledger entries

    # -- ledger (P30): dual reading so deferred debt stays visible ----------
    def score(self) -> dict[str, float]:
        total = len(self.tensions) or 1
        adjudicated = sum(          # genuinely metabolized: resolved or shown false
            1 for t in self.tensions.values()
            if t.status in ("resolved", "refuted")
        )
        deferred = sum(1 for t in self.tensions.values() if t.status == "deferred")
        return {
            "strict": round(adjudicated / total, 4),
            "lenient": round((adjudicated + deferred) / total, 4),
            "accepted_debt": deferred,        # the strict/lenient gap, kept visible
            "open": total - adjudicated - deferred,
        }

    def record(self, phase: str, note: str) -> None:
        self.history.append({
            "t": time.strftime("%Y-%m-%dT%H:%M:%S"),
            "phase": phase,
            "note": note,
            "score": self.score(),
        })

    # -- persistence ---------------------------------------------------------
    def save(self, path: str | Path) -> None:
        p = Path(path)
        p.write_text(json.dumps({
            "subject": self.subject,
            "tensions": {k: vars(t) for k, t in self.tensions.items()},
            "structures": self.structures,
            "lessons": self.lessons,
            "history": self.history,
        }, indent=2))

    @classmethod
    def load(cls, path: str | Path) -> State:
        d = json.loads(Path(path).read_text())
        s = cls(subject=d["subject"], structures=d.get("structures", {}),
                lessons=d.get("lessons", []), history=d.get("history", []))
        s.tensions = {k: Tension(**v) for k, v in d.get("tensions", {}).items()}
        return s


Stage = Callable[[State], State]


def cycle(state: State, stages: list[tuple[str, Stage]],
          ledger_path: str | Path | None = None) -> State:
    """Run one metabolic cycle: each stage is (phase_name, fn)."""
    for phase, fn in stages:
        state = fn(state)
        state.record(phase, fn.__name__ if hasattr(fn, "__name__") else phase)
        if ledger_path is not None:
            state.save(ledger_path)
    return state


def run_until(state: State, stages: list[tuple[str, Stage]],
              done: Callable[[State], bool], max_cycles: int = 10,
              ledger_path: str | Path | None = None) -> State:
    """P33 in miniature: repeat cycles until `done` or budget exhausted.

    The loop driver is boring on purpose. Wire external signals (P4) by
    calling this from cron/queues, not by making it cleverer.
    """
    for _ in range(max_cycles):
        if done(state):
            break
        state = cycle(state, stages, ledger_path=ledger_path)
    return state
