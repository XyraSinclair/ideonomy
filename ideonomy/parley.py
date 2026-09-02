"""Balanced multi-party constraint solving over idea-space (P21 + M2 + P37).

A `panel` is parallel opinions; a *parley* is a negotiation. Each party holds
a model and a charter of declared constraints, and the solver searches for a
proposal inside the joint feasible region — every party's every constraint
satisfied, by that party's own reading.

Balance is structural:
  - proposal rights rotate round-robin, so no party frames more often;
  - each party is sovereign over exactly its own constraints — it scores
    those and nothing else, so no party grades another's charter;
  - at impasse the surviving proposal is chosen by maximin (the best worst
    satisfaction across all constraints), the balanced criterion — never the
    proposal one loud party liked most.

An accord is a proposal plus every party's on-the-record satisfaction. An
impasse names the binding constraints — the genuine conflict — and feeds them
to the residue ledger (P-10). Models are injectable callables for offline
testing; back them with `CommandModel` for real heterogeneous parleys.
"""

from __future__ import annotations

import re
from dataclasses import dataclass, field
from typing import Any, Callable, Optional, Sequence

Model = Callable[[str], str]

_PROPOSE = (
    "You are {name}, one party in a multi-party negotiation over the task "
    "below. Draft ONE concrete proposal that could satisfy every party's "
    "declared constraints — including the other parties'. Be specific; a "
    "vague proposal satisfies nothing.\n\nTask: {task}\n\n"
    "All declared constraints:\n{charters}\n{feedback}"
    "Reply with the proposal text only."
)
_SCORE = (
    "You are {name}. Score the proposal below against ONE of your declared "
    "constraints — only this one, only yours.\n\nConstraint: {constraint}\n\n"
    "Proposal:\n{proposal}\n\nReply with exactly two lines:\n"
    "SAT: <-1.0 (violates it) .. +1.0 (fully satisfies it), 0 if unclear>\n"
    "WHY: <one sentence>"
)


@dataclass
class Party:
    name: str
    model: Model
    constraints: list = field(default_factory=list)


@dataclass
class Reading:
    party: str
    constraint: str
    sat: float
    why: str


@dataclass
class Round:
    proposer: str
    proposal: str
    readings: list[Reading] = field(default_factory=list)

    @property
    def worst(self) -> float:
        return min((r.sat for r in self.readings), default=-1.0)


@dataclass
class Parley:
    task: str
    accept: float
    rounds: list[Round] = field(default_factory=list)

    @property
    def accord(self) -> Optional[Round]:
        """First round whose worst reading clears the acceptance bar."""
        for r in self.rounds:
            if r.readings and r.worst >= self.accept:
                return r
        return None

    @property
    def best(self) -> Optional[Round]:
        """Maximin: the proposal with the least-bad worst reading."""
        scored = [r for r in self.rounds if r.readings]
        return max(scored, key=lambda r: r.worst) if scored else None

    def binding(self) -> list[Reading]:
        """The constraints that block the best proposal — the real conflict."""
        b = self.best
        if b is None:
            return []
        return [r for r in b.readings if r.sat < self.accept]

    def report(self) -> str:
        lines = [f"task: {self.task}"]
        a = self.accord
        if a:
            lines.append(f"ACCORD after {len(self.rounds)} round(s) "
                         f"(proposer {a.proposer}, worst sat {a.worst:+.2f}):")
            lines.append(f"  {a.proposal}")
            for r in a.readings:
                lines.append(f"    {r.party} | {r.constraint}: {r.sat:+.2f}  {r.why}")
        else:
            lines.append(f"IMPASSE after {len(self.rounds)} round(s).")
            b = self.best
            if b:
                lines.append(f"best (maximin) proposal, proposer {b.proposer}, "
                             f"worst sat {b.worst:+.2f}:")
                lines.append(f"  {b.proposal}")
            lines.append("binding constraints (the genuine conflict):")
            for r in self.binding():
                lines.append(f"  - {r.party} | {r.constraint}: {r.sat:+.2f}  {r.why}")
        return "\n".join(lines)

    def to_residue(self, ledger: Any, origin: str = "P21") -> list[str]:
        """At impasse, each binding constraint is residue; an accord closed."""
        if self.accord is not None:
            return []
        ids = []
        for r in self.binding():
            item = ledger.add(
                f"parley impasse: {r.party}'s constraint unmet — "
                f"{r.constraint} (sat {r.sat:+.2f}): {r.why}",
                "contested_axis", origin=origin)
            ids.append(item.id)
        return ids


def parley(task: str, parties: Sequence[Party], max_rounds: int = 4,
           accept: float = 0.15) -> Parley:
    """Negotiate to joint feasibility or a named impasse.

    Gate: >=2 parties, each with a non-empty charter — one party is a
    monologue, and a party with no constraints has nothing at stake."""
    if len(parties) < 2:
        raise ValueError("a parley needs >=2 parties; one party is a monologue.")
    seen = set()
    for p in parties:
        if not p.constraints:
            raise ValueError(f"party {p.name!r} declares no constraints: "
                             "nothing at stake, nothing to negotiate.")
        if p.name in seen:
            raise ValueError(f"duplicate party name {p.name!r}")
        seen.add(p.name)

    charters = "\n".join(f"  {p.name}: {c}" for p in parties for c in p.constraints)
    st = Parley(task=task, accept=accept)
    feedback = ""
    for i in range(max_rounds):
        proposer = parties[i % len(parties)]          # equal proposal rights
        proposal = proposer.model(_PROPOSE.format(
            name=proposer.name, task=task, charters=charters, feedback=feedback))
        rnd = Round(proposer=proposer.name, proposal=proposal)
        for p in parties:
            for c in p.constraints:                   # sovereignty: own charter only
                reply = p.model(_SCORE.format(name=p.name, constraint=c,
                                              proposal=proposal))
                rnd.readings.append(Reading(party=p.name, constraint=c,
                                            sat=_last_sat(reply), why=_why(reply)))
        st.rounds.append(rnd)
        if rnd.worst >= accept:
            return st                                  # accord
        unmet = [r for r in rnd.readings if r.sat < accept]
        feedback = ("Previous proposal failed these constraints — address them "
                    "directly:\n" +
                    "\n".join(f"  {r.party} | {r.constraint}: {r.why}" for r in unmet)
                    + "\n")
    return st


def _last_sat(text: str) -> float:
    """LAST SAT line wins — the scoring prompt itself contains 'SAT:'."""
    ms = re.findall(r"SAT:\s*([+-]?\d*\.?\d+)", text, re.IGNORECASE)
    try:
        return max(-1.0, min(1.0, float(ms[-1]))) if ms else 0.0
    except ValueError:
        return 0.0


def _why(text: str) -> str:
    ms = re.findall(r"WHY:\s*(.+)", text, re.IGNORECASE)
    return ms[-1].strip() if ms else "(no reason given)"


def main(argv: Optional[list] = None) -> int:
    import argparse
    from .models import CommandModel

    ap = argparse.ArgumentParser(
        prog="ideonomy.parley",
        description="Balanced multi-party constraint solving: rotating "
                    "proposals, sovereign constraint scoring, maximin at "
                    "impasse. --party NAME=CMD (repeatable, >=2); "
                    "--constraint NAME:TEXT (repeatable).")
    ap.add_argument("task")
    ap.add_argument("--party", action="append", default=[], required=True,
                    help="NAME=model command with {prompt}")
    ap.add_argument("--constraint", action="append", default=[], required=True,
                    help="NAME:constraint text (NAME must match a --party)")
    ap.add_argument("--rounds", type=int, default=4)
    ap.add_argument("--accept", type=float, default=0.15)
    args = ap.parse_args(argv)

    parties: dict[str, Party] = {}
    for spec in args.party:
        name, _, cmd = spec.partition("=")
        if not cmd:
            ap.error(f"--party {spec!r}: expected NAME=CMD")
        parties[name] = Party(name=name, model=CommandModel(cmd, name=name))
    for spec in args.constraint:
        name, _, text = spec.partition(":")
        if name not in parties or not text:
            ap.error(f"--constraint {spec!r}: expected NAME:TEXT with a "
                     f"declared --party NAME")
        parties[name].constraints.append(text.strip())

    st = parley(args.task, list(parties.values()),
                max_rounds=args.rounds, accept=args.accept)
    print(st.report())
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
