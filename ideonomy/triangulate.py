"""Executable triangulation for questions with no computable oracle — P-9.

The top-ranked premier skill, made real. For irreducibly normative / aesthetic
/ strategic questions, you must not fabricate a scalar oracle and optimize it
with false rigor. Instead: dimensionalize the value space, gather >=2
*independent* judgments per axis, and report the spread. Where independent
judges agree, the axis is settled and compresses; where they disagree, the
disagreement is the signal — it localizes exactly where the question genuinely
underdetermines its answer. Contested axes are named as residue (kind
`contested_axis`) and can be fed straight into the cross-session ledger (P-10),
so P-9 and P-10 compose.

Organon: P5 dimensionalize + P21 judge-panel + M4 cross-model triangulation +
P37 residue-seed. The gate is honesty about the absence of a gate: you either
produce independent reads per axis, or you name the judgment irreducible and
its owner — never a single manufactured number.

Judges are injectable so the logic is testable offline; for real use, back them
with `CommandModel` (any model CLI). Stdlib-only.
"""

from __future__ import annotations

import re
from dataclasses import dataclass, field
from typing import Any, Callable, Optional

# A judge scores one axis of one question.
Judge = Callable[[str, str], "Verdict"]


@dataclass
class Verdict:
    judge: str
    axis: str
    lean: float          # -1 (fails the axis) .. +1 (excels); 0 = neutral/uncertain
    stance: str          # one-line reason


@dataclass
class AxisResult:
    axis: str
    verdicts: list[Verdict] = field(default_factory=list)

    @property
    def leans(self) -> list[float]:
        return [v.lean for v in self.verdicts]

    @property
    def mean(self) -> float:
        xs = self.leans
        return round(sum(xs) / len(xs), 3) if xs else 0.0

    @property
    def spread(self) -> float:
        xs = self.leans
        return round(max(xs) - min(xs), 3) if xs else 0.0

    def contested(self, spread_threshold: float = 1.0) -> bool:
        """Contested if judges disagree in sign, one is uncertain while
        another is confident, or the spread is wide."""
        xs = self.leans
        if len(xs) < 2:
            return True                       # one read is not triangulation
        signs = {1 if x > 0.15 else (-1 if x < -0.15 else 0) for x in xs}
        if {1, -1} <= signs:                  # genuine sign disagreement
            return True
        if 0 in signs and any(abs(x) >= 0.6 for x in xs):
            return True                       # uncertain vs confident is a split
        return self.spread >= spread_threshold


@dataclass
class Triangulation:
    question: str
    axes: list[AxisResult] = field(default_factory=list)

    def contested(self) -> list[AxisResult]:
        return [a for a in self.axes if a.contested()]

    def settled(self) -> list[AxisResult]:
        return [a for a in self.axes if not a.contested()]

    def report(self) -> str:
        lines = [f"question: {self.question}",
                 f"axes: {len(self.axes)}  settled: {len(self.settled())}  "
                 f"contested: {len(self.contested())}", ""]
        for a in self.axes:
            tag = "CONTESTED" if a.contested() else "settled"
            lines.append(f"[{tag}] {a.axis}  mean={a.mean:+.2f} spread={a.spread:.2f}")
            for v in a.verdicts:
                lines.append(f"    {v.judge}: {v.lean:+.2f}  {v.stance}")
        if self.contested():
            lines += ["", "irreducible judgments (no oracle — owner must decide):"]
            for a in self.contested():
                lines.append(f"  - {a.axis}: judges split; owner=___ grounds=___")
        return "\n".join(lines)

    def to_residue(self, ledger: Any, origin: str = "P-9") -> list[str]:
        """Write each contested axis to a residue ledger (P-10). Returns ids."""
        ids = []
        for a in self.contested():
            r = ledger.add(f"contested axis: {a.axis} (spread {a.spread:.2f})",
                           "contested_axis", origin=origin)
            ids.append(r.id)
        return ids


def triangulate(question: str, axes: list[str], judges: list[Judge]) -> Triangulation:
    """Run every judge on every axis. The gate: >=2 independent judges, else
    this is not triangulation — raise and tell the caller to name the owner."""
    if len(judges) < 2:
        raise ValueError(
            "triangulation needs >=2 independent judges. With fewer, do not "
            "fabricate a verdict — name the judgment irreducible and its owner.")
    if not axes:
        raise ValueError("no value axes given; dimensionalize the question first "
                         "(P5) — a question with no named axes cannot be triangulated.")
    tri = Triangulation(question=question)
    for axis in axes:
        ar = AxisResult(axis=axis)
        for j in judges:
            ar.verdicts.append(j(axis, question))
        tri.axes.append(ar)
    return tri


# ----------------------------------------------------- model-backed judges
def model_judge(model: Callable[[str], str], name: str) -> Judge:
    """A judge backed by any model callable (e.g. CommandModel)."""
    def judge(axis: str, question: str) -> Verdict:
        prompt = (
            f"Judge ONE axis of the question below, independently. Do not try to "
            f"give an overall verdict.\n\nQuestion: {question}\nAxis: {axis}\n\n"
            "Reply with exactly two lines:\n"
            "LEAN: <a number from -1.0 (fails this axis) to +1.0 (excels), "
            "0 if genuinely uncertain>\n"
            "WHY: <one sentence>")
        reply = model(prompt)
        return Verdict(judge=name, axis=axis, lean=_parse_lean(reply),
                       stance=_parse_why(reply))
    return judge


def dimensionalize(question: str, model: Callable[[str], str], k: int = 4) -> list:
    """P5: ask a model for the 2-5 value axes the vague predicate comprises."""
    prompt = (
        f"The question below turns on a vague predicate (good/right/better). "
        f"Name the {k} concrete, independent value-axes it actually comprises — "
        f"the dimensions along which one would judge it. One per line, terse, "
        f"no numbering.\n\nQuestion: {question}")
    reply = model(prompt)
    axes = [ln.strip(" -*\t0123456789.)") for ln in reply.splitlines() if ln.strip()]
    axes = [a for a in axes if a]
    if not axes:
        # Refuse to manufacture the single vague axis this skill exists to
        # prevent. No axes -> the caller must dimensionalize by hand (P5).
        raise ValueError(
            "dimensionalization returned no axes; name the value axes "
            "yourself (P5) — refusing to fall back to a manufactured scalar.")
    return axes[:k]


def _parse_lean(text: str) -> float:
    m = re.search(r"LEAN:\s*([+-]?\d*\.?\d+)", text, re.IGNORECASE)
    if not m:
        m = re.search(r"([+-]?\d*\.?\d+)", text)
    try:
        return max(-1.0, min(1.0, float(m.group(1)))) if m else 0.0
    except ValueError:
        return 0.0


def _parse_why(text: str) -> str:
    m = re.search(r"WHY:\s*(.+)", text, re.IGNORECASE)
    if m:
        return m.group(1).strip()
    lines = text.strip().splitlines()
    return lines[-1][:160] if lines else "(no reason given)"


def main(argv: Optional[list] = None) -> int:
    import argparse
    from .models import CommandModel

    ap = argparse.ArgumentParser(
        prog="ideonomy.triangulate",
        description="Triangulate a no-oracle question: >=2 independent judges "
                    "per value axis; report the spread, never a single number.")
    ap.add_argument("question")
    ap.add_argument("--axis", action="append", default=[], help="value axis (repeatable)")
    ap.add_argument("--judge", action="append", default=[], required=True,
                    help="model command with {prompt} (repeatable; need >=2)")
    args = ap.parse_args(argv)
    if len(args.judge) < 2:
        ap.error("triangulation needs >=2 independent --judge commands; with "
                 "one judge, name the judgment irreducible and its owner instead")
    if len(set(args.judge)) < len(args.judge):
        ap.error("duplicate --judge commands: identical judges are one judge, "
                 "not a panel — independence is the point (M4). Vary the model "
                 "or the framing. (Distinct commands are necessary, not "
                 "sufficient; true independence is on you.)")

    judges_models = [CommandModel(c, name=f"judge-{i+1}") for i, c in enumerate(args.judge)]
    axes = args.axis or dimensionalize(args.question, judges_models[0])
    judges = [model_judge(m, m.name) for m in judges_models]
    tri = triangulate(args.question, axes, judges)
    print(tri.report())
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
