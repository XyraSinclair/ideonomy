"""Consult the atlas — the lists and maps a situation belongs to, handed back
as instruments.

The catalog stores its information in denominators, partitions, orders, and
gates (README). A plan or brainstorm that never opens the atlas samples the
mode of the model's training distribution; this module is the door in. Give
it a situation and it returns the lists whose item type the situation
belongs to, each rendered as something to *use*: an axis to stand on,
members to check off, edges to walk, probes already written as small
experiments.

Retrieval is lexical and offline, so a map whose vocabulary differs from
yours can be missed — every hit prints its `of` sentence so the miss is
visible. The judgment is the caller's: which members the plan contains,
which are ruled out, which stay unlabeled. `--frame audit` prints the
coverage frame that turns that judgment into a labeled denominator instead
of a feeling (the gate of `prove-the-coverage-denominator`).

    python3 -m ideonomy.consult "raising a seed round with four months of cash"
    python3 -m ideonomy.consult --file plan.md --frame audit --k 2
    python3 -m ideonomy.consult --from-residue mywork      # what last session left open
    python3 -m ideonomy.consult --file plan.md --frame audit --model 'claude -p {prompt}'

Stdlib-only. Deterministic: same catalog, same query, same order.
"""

from __future__ import annotations

import math
import re
from dataclasses import dataclass, field
from pathlib import Path
from typing import Iterable, Optional

from . import canon
from .lists import Ideolist

STOP = frozenset("""
a an the and or but if then than that this these those of for to in on at by
with from as is are was were be been being it its into over under about
between through after before during without within against not no nor so
such can could may might must shall should will would do does did done have
has had having we our you your they their them he she his her who whom which
what when where why how any all each every some more most much many one two
first next also just only very own same other another there here out up down
per via etc make keep get use way thing three four five six seven eight nine ten
""".split())

FIELD_WEIGHTS = (
    ("name", 3.0), ("of", 3.0), ("questions", 2.0), ("axis", 2.0),
    ("register", 1.5), ("items", 1.0), ("labels", 1.0), ("limits", 0.5),
)


def _stem(t: str) -> str:
    if len(t) > 4 and t.endswith("ies"):
        return t[:-3] + "y"
    if len(t) > 4 and t.endswith("ing"):
        return t[:-3]
    if len(t) > 3 and t.endswith("s") and not t.endswith("ss"):
        return t[:-1]
    return t


def tokens(text: str) -> list:
    return [_stem(t) for t in re.findall(r"[a-z0-9]+", (text or "").lower())
            if len(t) > 2 and t not in STOP]


def handle(item: str, width: int = 60) -> str:
    """The memorable name in front of an item's mechanism sentence; canon
    items carry no colon and are returned whole (clipped)."""
    head, sep, _ = item.partition(":")
    if sep and len(head) <= width:
        return head.strip()
    return item if len(item) <= width else item[: width - 1].rstrip() + "…"


@dataclass
class Instrument:
    name: str
    tier: str
    kind: str
    of: str
    score: float = 0.0
    hits: list = field(default_factory=list)      # query tokens that matched
    axis: str = ""
    axis_note: str = ""
    members: list = field(default_factory=list)   # (handle, full item text)
    edges: list = field(default_factory=list)     # (from_handle, to_handle, label)
    probes: list = field(default_factory=list)    # (horizon, handle, next_question)
    questions: list = field(default_factory=list) # first_question, changed_question
    limits: list = field(default_factory=list)


def instrument(lst: Ideolist) -> Instrument:
    src = lst.source or {}
    by_text = {it: handle(it) for it in lst.items}
    inst = Instrument(
        name=lst.name, tier=src.get("tier", "session"), kind=src.get("kind", "list"),
        of=lst.of, members=[(by_text[it], it) for it in lst.items])
    ser = src.get("seriation") or {}
    inst.axis = ser.get("axis", "") or ""
    inst.axis_note = ser.get("note", "") or ""
    for e in src.get("relations") or []:
        inst.edges.append((by_text.get(e.get("from"), handle(e.get("from", ""))),
                           by_text.get(e.get("to"), handle(e.get("to", ""))),
                           e.get("label", "")))
    for p in src.get("priorities") or []:
        inst.probes.append((p.get("horizon", ""), by_text.get(p.get("item"), handle(p.get("item", ""))),
                            p.get("next_question", "")))
    ex = src.get("exploration") or {}
    inst.questions = [q for q in (ex.get("first_question"), ex.get("changed_question")) if q]
    inst.limits = list(src.get("boundary_claim") or [])
    return inst


def _fields(inst: Instrument, register: str) -> dict:
    return {
        "name": inst.name.replace("-", " ").replace(".", " "),
        "of": inst.of,
        "questions": " ".join(inst.questions),
        "axis": inst.axis,
        "register": register,
        "items": " ".join(t for _, t in inst.members),
        "labels": " ".join(l for _, _, l in inst.edges),
        "limits": " ".join(inst.limits),
    }


class Atlas:
    """The whole catalog, both provenance tiers, indexed once per process."""

    def __init__(self, tiers: Iterable[str] = ("canon", "grown")) -> None:
        self.instruments: list = []
        self._tf: list = []          # per instrument: {token: weighted tf}
        df: dict = {}
        for tier in tiers:
            for lst in canon.lists(tier).values():
                inst = instrument(lst)
                tf: dict = {}
                for fname, w in FIELD_WEIGHTS:
                    for t in tokens(_fields(inst, (lst.source or {}).get("register", "") or "")[fname]):
                        tf[t] = tf.get(t, 0.0) + w
                for t in tf:
                    df[t] = df.get(t, 0) + 1
                self.instruments.append(inst)
                self._tf.append(tf)
        n = max(len(self.instruments), 1)
        self._idf = {t: math.log(1.0 + n / d) for t, d in df.items()}

    def consult(self, query: str, k: int = 3, tier: str = "all",
                kind: str = "all") -> list:
        q = sorted(set(tokens(query)))
        scored = []
        for inst, tf in zip(self.instruments, self._tf):
            if tier != "all" and inst.tier != tier:
                continue
            if kind != "all" and inst.kind != kind:
                continue
            hits = [t for t in q if t in tf]
            if not hits:
                continue
            score = sum(self._idf[t] * math.log1p(tf[t]) for t in hits)
            scored.append((score, inst, hits))
        scored.sort(key=lambda s: (-s[0], s[1].name))
        out = []
        for score, inst, hits in scored[:k]:
            inst = Instrument(**{**inst.__dict__, "score": round(score, 3), "hits": hits})
            out.append(inst)
        return out


# ---------------------------------------------------------------- rendering

def render(inst: Instrument, full: bool = False) -> str:
    lines = [f"=== {inst.name}  [{inst.tier} {inst.kind}; score {inst.score}; "
             f"matched: {', '.join(inst.hits)}]",
             f"of: {inst.of}"]
    if inst.axis:
        lines.append(f"axis: {inst.axis}")
        lines.append("  Place the situation on this axis before reading the members: "
                     "the neighbors of that stop are what to expect next.")
    lines.append(f"members ({len(inst.members)}):")
    for h, t in inst.members:
        lines.append(f"  - {t}" if full else f"  - {h}")
    if inst.edges:
        lines.append("edges (what a move recruits or forecloses):")
        for a, b, label in inst.edges:
            lines.append(f"  {a} -> {b}: {label}")
    if inst.probes:
        lines.append("probes (the cheapest discriminating experiment already written):")
        for horizon, h, q in inst.probes:
            lines.append(f"  [{horizon}] {h}: {q}")
    if inst.limits:
        lines.append(f"limit: {inst.limits[0]}")
    return "\n".join(lines)


def render_audit(insts: list, situation: str) -> str:
    """The coverage frame: every member of every chosen map gets a label, or
    the audit is declared partial. Zero unlabeled elements is the gate."""
    out = ["COVERAGE AUDIT",
           "Situation:", situation.strip(), "",
           "For each map below, label EVERY member exactly once:",
           "  present   — the plan contains or assumes this mechanism (say where)",
           "  ruled-out — it cannot apply here (say why)",
           "  unlabeled — you could not decide (say what would decide it)",
           "Then walk each edge whose `from` member is present and state the "
           "consequence the plan did not. Finish with: zero unlabeled, or the "
           "word PARTIAL and the count.", ""]
    for inst in insts:
        out.append(f"--- {inst.name}: {inst.of}")
        for h, t in inst.members:
            out.append(f"[ ] {h} — {t[len(h):].lstrip(': ') if t.startswith(h) else t}")
        for a, b, label in inst.edges:
            out.append(f"edge {a} -> {b}: {label}")
        out.append("")
    return "\n".join(out)


# ---------------------------------------------------------------------- CLI

def main(argv: Optional[list] = None) -> int:
    import argparse

    ap = argparse.ArgumentParser(
        prog="ideonomy.consult",
        description="The lists and maps a situation belongs to, as instruments.")
    ap.add_argument("situation", nargs="?", default="",
                    help="the plan, question, or situation in your own words")
    ap.add_argument("--file", help="read the situation from a file (a plan, a brief)")
    ap.add_argument("--k", type=int, default=3, help="instruments to return (default 3)")
    ap.add_argument("--tier", default="all", choices=["all", "canon", "grown"])
    ap.add_argument("--kind", default="all", choices=["all", "list", "map"])
    ap.add_argument("--full", action="store_true", help="print whole items, not handles")
    ap.add_argument("--frame", choices=["instrument", "audit"], default="instrument",
                    help="instrument: axis/members/edges/probes; audit: the coverage frame")
    ap.add_argument("--from-residue", metavar="TOPIC",
                    help="consult once per open residue item of a residue ledger topic")
    ap.add_argument("--store", help="residue store path (default ./.residue/<topic>.json)")
    ap.add_argument("--model", help="run the frame through a CLI model, e.g. 'claude -p {prompt}'")
    args = ap.parse_args(argv)

    atlas = Atlas()

    if args.from_residue:
        from .residue import Ledger
        path = Path(args.store) if args.store else Path(".residue") / f"{args.from_residue}.json"
        led = Ledger.load(path)
        open_items = [r for r in led.residue.values() if r.status == "open"]
        if not open_items:
            print(f"no open residue in {path}")
            return 1
        for r in open_items:
            hits = atlas.consult(r.text, k=2, tier=args.tier, kind=args.kind)
            print(f"residue {r.id} [{r.kind}]: {r.text}")
            for inst in hits:
                print(f"  -> {inst.name}: {inst.of}")
            if not hits:
                print("  -> nothing in the atlas matches; a territory to grow")
            print()
        return 0

    situation = Path(args.file).read_text() if args.file else args.situation
    if not situation.strip():
        ap.error("give a situation, --file, or --from-residue")
    insts = atlas.consult(situation, k=args.k, tier=args.tier, kind=args.kind)
    if not insts:
        print("nothing in the atlas matches; say it in other words, or this is a territory to grow")
        return 1
    if args.frame == "audit":
        text = render_audit(insts, situation)
    else:
        text = "\n\n".join(render(i, full=args.full) for i in insts)
    if args.model:
        from .models import CommandModel
        print(CommandModel(args.model)(text))
        return 0
    print(text)
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except BrokenPipeError:      # `| head` is a normal way to read an instrument
        raise SystemExit(0)
