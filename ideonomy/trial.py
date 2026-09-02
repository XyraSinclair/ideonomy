"""Ideonomic trials — adversarial adjudication of one idea (P22 + P21 + M4).

The evaluation bottleneck, solved as a courtroom instead of a scalar: an
*advocate* builds the strongest case for the claim, an *adversary* the
strongest case against, they cross-examine for a fixed number of rounds, and
a separate *judge* issues a verdict with grounds. The burden of proof is set
by claim class: an unproven claim is rejected, never split-the-difference.

Balance is structural, not hoped for:
  - both sides get the identical prompt scaffold and the same number of turns;
  - no callable may hold two roles (an idea must not adjudicate itself);
  - `balanced_trial` re-runs the trial with advocate/adversary models swapped —
    a verdict that flips under the swap is model bias, not idea quality, and
    comes back CONTESTED.

Contested and rejected outcomes feed the residue ledger (P-10), so trials
compound instead of evaporating. Roles are injectable callables for offline
testing; back them with `CommandModel` for real heterogeneous panels.
"""

from __future__ import annotations

import re
from dataclasses import dataclass, field
from typing import Any, Callable, Optional, Sequence

Model = Callable[[str], str]

BURDENS = {"preponderance": 0.15, "high": 0.6}

_CASE = (
    "You are the {side} in a structured trial of an idea. Build the single "
    "strongest case {direction} the claim — concrete, specific, no hedging. "
    "You will be cross-examined on it.\n\nClaim: {claim}\n{context}"
)
_CROSS = (
    "You are the {side} in a structured trial of an idea. Below is the "
    "opposing side's latest argument. Answer its strongest point directly — "
    "concede what is true, destroy what is not. Do not repeat your case.\n\n"
    "Claim: {claim}\n\nOpposing argument:\n{opposing}"
)
_JUDGE = (
    "You are the judge in a structured trial of an idea. Both sides argued "
    "under equal terms; the full transcript is below. Weigh only the "
    "arguments, not the eloquence. Reply with exactly two lines:\n"
    "LEAN: <-1.0 (claim destroyed) .. +1.0 (claim proven), 0 if the "
    "arguments genuinely balance>\n"
    "GROUNDS: <one sentence naming the argument that decided it>\n\n"
    "Claim: {claim}\n\nTranscript:\n{transcript}"
)


@dataclass
class Turn:
    role: str          # "advocate" | "adversary" | "judge"
    speaker: str       # model name
    text: str


@dataclass
class Trial:
    claim: str
    burden: str
    turns: list[Turn] = field(default_factory=list)
    leans: list[float] = field(default_factory=list)     # one per judge
    grounds: list[str] = field(default_factory=list)
    forced_contested: str = ""                            # set by balanced_trial

    @property
    def lean(self) -> float:
        return round(sum(self.leans) / len(self.leans), 3) if self.leans else 0.0

    @property
    def verdict(self) -> str:
        """UPHELD only past the burden; unproven is REJECTED; judge sign-split
        or swap instability is CONTESTED — never averaged away."""
        if self.forced_contested:
            return "CONTESTED"
        signs = {1 if x > 0.15 else (-1 if x < -0.15 else 0) for x in self.leans}
        if {1, -1} <= signs:
            return "CONTESTED"
        return "UPHELD" if self.lean >= BURDENS[self.burden] else "REJECTED"

    def report(self) -> str:
        lines = [f"claim: {self.claim}",
                 f"verdict: {self.verdict}  (lean {self.lean:+.2f}, "
                 f"burden {self.burden}={BURDENS[self.burden]:+.2f})"]
        if self.forced_contested:
            lines.append(f"contested because: {self.forced_contested}")
        for g in self.grounds:
            lines.append(f"grounds: {g}")
        lines.append("")
        for t in self.turns:
            lines.append(f"[{t.role}:{t.speaker}] {t.text}")
        return "\n".join(lines)

    def to_residue(self, ledger: Any, origin: str = "P22") -> list[str]:
        """CONTESTED verdicts are residue; a clean verdict already closed."""
        if self.verdict != "CONTESTED":
            return []
        why = self.forced_contested or "judges split on sign"
        r = ledger.add(f"trial contested: {self.claim} ({why})",
                       "contested_axis", origin=origin)
        return [r.id]


def trial(claim: str, advocate: Model, adversary: Model, judges: Sequence[Model],
          rounds: int = 1, burden: str = "preponderance", context: str = "",
          names: Optional[dict] = None) -> Trial:
    """Run one trial. Gate: three distinct roles, or this is self-adjudication."""
    if burden not in BURDENS:
        raise ValueError(f"unknown burden {burden!r}; one of {sorted(BURDENS)}")
    if advocate is adversary:
        raise ValueError("advocate and adversary are the same callable: an idea "
                         "must not prosecute and defend itself.")
    for j in judges:
        if j is advocate or j is adversary:
            raise ValueError("a judge is also a party: the bench must be "
                             "independent of both sides.")
    if not judges:
        raise ValueError("no judges: without a bench this is a debate, not a trial.")
    nm = names or {}
    t = Trial(claim=claim, burden=burden)
    ctx = f"Context: {context}\n" if context else ""

    def speak(role: str, model: Model, prompt: str) -> str:
        text = model(prompt)
        t.turns.append(Turn(role=role, speaker=nm.get(role, role), text=text))
        return text

    a_case = speak("advocate", advocate, _CASE.format(
        side="advocate", direction="FOR", claim=claim, context=ctx))
    b_case = speak("adversary", adversary, _CASE.format(
        side="adversary", direction="AGAINST", claim=claim, context=ctx))
    for _ in range(rounds):
        a_case = speak("advocate", advocate, _CROSS.format(
            side="advocate", claim=claim, opposing=b_case))
        b_case = speak("adversary", adversary, _CROSS.format(
            side="adversary", claim=claim, opposing=a_case))

    transcript = "\n\n".join(f"[{x.role}] {x.text}" for x in t.turns)
    for i, judge in enumerate(judges):
        reply = judge(_JUDGE.format(claim=claim, transcript=transcript))
        t.turns.append(Turn(role="judge", speaker=nm.get("judge", f"judge-{i+1}"),
                            text=reply))
        t.leans.append(_last_lean(reply))
        t.grounds.append(_grounds(reply))
    return t


def balanced_trial(claim: str, model_a: Model, model_b: Model,
                   judges: Sequence[Model], rounds: int = 1,
                   burden: str = "preponderance", context: str = "") -> Trial:
    """The balance guarantee: run twice with the side-models swapped. A verdict
    that survives the swap is about the idea; one that flips is about the
    models, and comes back CONTESTED with that named as the ground."""
    t1 = trial(claim, model_a, model_b, judges, rounds, burden, context)
    t2 = trial(claim, model_b, model_a, judges, rounds, burden, context)
    if t1.verdict == t2.verdict:
        return t1
    keep = t1 if abs(t1.lean) >= abs(t2.lean) else t2
    keep.forced_contested = (
        f"verdict unstable under role swap ({t1.verdict} vs {t2.verdict}) — "
        f"model bias, not idea quality")
    return keep


def _last_lean(text: str) -> float:
    """LAST lean line wins: the judge prompt itself contains 'LEAN:', so an
    instruction-echoing judge must not have its echo read as the ruling."""
    ms = re.findall(r"LEAN:\s*([+-]?\d*\.?\d+)", text, re.IGNORECASE)
    try:
        return max(-1.0, min(1.0, float(ms[-1]))) if ms else 0.0
    except ValueError:
        return 0.0


def _grounds(text: str) -> str:
    ms = re.findall(r"GROUNDS:\s*(.+)", text, re.IGNORECASE)
    return ms[-1].strip() if ms else "(no grounds given)"


def main(argv: Optional[list] = None) -> int:
    import argparse
    from .models import CommandModel

    ap = argparse.ArgumentParser(
        prog="ideonomy.trial",
        description="Try one idea: advocate vs adversary under equal terms, "
                    "independent bench, burden of proof, verdict with grounds.")
    ap.add_argument("claim")
    ap.add_argument("--advocate", required=True, help="model command with {prompt}")
    ap.add_argument("--adversary", required=True, help="model command with {prompt}")
    ap.add_argument("--judge", action="append", default=[], required=True,
                    help="bench model command (repeatable)")
    ap.add_argument("--rounds", type=int, default=1)
    ap.add_argument("--burden", choices=sorted(BURDENS), default="preponderance")
    ap.add_argument("--context", default="")
    ap.add_argument("--no-swap", action="store_true",
                    help="single pass without the role-swap balance check")
    args = ap.parse_args(argv)
    if args.advocate == args.adversary:
        ap.error("advocate and adversary must be distinct commands — an idea "
                 "must not prosecute and defend itself.")
    a = CommandModel(args.advocate, name="A")
    b = CommandModel(args.adversary, name="B")
    judges = [CommandModel(c, name=f"judge-{i+1}") for i, c in enumerate(args.judge)]
    run = trial if args.no_swap else balanced_trial
    t = run(args.claim, a, b, judges, rounds=args.rounds,
            burden=args.burden, context=args.context)
    print(t.report())
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
