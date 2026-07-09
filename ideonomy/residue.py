"""The cross-session residue ledger — P-10 made durable.

The respiratory engine's thesis is that what carries structure forward across
breaths is the residue: the unexplained, the failed reframe, the surviving
attack, the named-but-unfilled gap, the contested judgment. Within a session
that residue lives in context. Across sessions it evaporates unless it is
persisted and *cited before the next expansion*. This module is that durable
seed store, with the distinction the engine cares about made executable:

    metabolism breath — opened on prior residue and seeded, resolved, or
                        adjudicated (dropped/deferred) some of it: the work
                        compounded.
    churn breath      — compressed/added without ever engaging prior residue:
                        motion without gain.

The classifier is an anti-forgetting aid, not an anti-adversarial one: an
operator determined to game it (e.g. a last-minute `seed` after unrelated
work) can — the ledger records what was touched, not whether the touching was
sincere. Cross-model or human audit (M6) is the backstop where that matters.

Organon: P31 episodic-memory + P32 variant-archive + P37 residue-seed + P30
ledger. Stdlib-only, JSON-backed, model-agnostic. CLI: `python3 -m ideonomy.residue`.

The CLI is load/mutate/save with no locking: concurrent invocations against
one store are last-writer-wins. Scope ledgers per topic (one writer each).
"""

from __future__ import annotations

import json
import sys
import time
from dataclasses import dataclass, field, asdict
from pathlib import Path
from typing import Any, Optional

# Residue kinds, each tied to the premier skill that tends to produce it.
KINDS = {
    "anomaly":          "a sensed misfit that resisted explanation (P2)",
    "failed_reframe":   "a reframe the MDL gate reverted as cosmetic (P-3)",
    "surviving_attack": "an objection that landed or a claim that barely held (P-4)",
    "named_gap":        "a coverage-denominator cell with no filler yet (P-11)",
    "contested_axis":   "a value-axis where independent judges disagreed (P-9)",
    "unexplained_core": "the residual a distillation could not compress (P36)",
    "open_question":    "a question left open at session close",
}

STATUSES = ("open", "seeded", "resolved", "dropped", "deferred")


@dataclass
class Residue:
    id: str
    text: str
    kind: str
    status: str = "open"
    origin: str = ""             # skill/breath that produced it
    born_session: str = ""
    touched_session: str = ""
    notes: list[str] = field(default_factory=list)


@dataclass
class Session:
    id: str
    opened: str
    cited_prior: int = 0         # how many prior residue items were surfaced at open
    added: list[str] = field(default_factory=list)
    seeded: list[str] = field(default_factory=list)
    resolved: list[str] = field(default_factory=list)
    adjudicated: list[str] = field(default_factory=list)   # dropped/deferred here
    closed: str = ""
    breath: str = ""             # "metabolism" | "churn" | "" (open)
    note: str = ""               # free-text close summary


@dataclass
class Ledger:
    topic: str = "default"
    residue: dict[str, Residue] = field(default_factory=dict)
    sessions: list[Session] = field(default_factory=list)
    _seq: int = 0

    # -- persistence --------------------------------------------------------
    def to_dict(self) -> dict[str, Any]:
        return {
            "topic": self.topic,
            "residue": {k: asdict(v) for k, v in self.residue.items()},
            "sessions": [asdict(s) for s in self.sessions],
            "_seq": self._seq,
        }

    @classmethod
    def from_dict(cls, d: dict[str, Any]) -> "Ledger":
        led = cls(topic=d.get("topic", "default"), _seq=d.get("_seq", 0))
        led.residue = {k: _fields(Residue, v) for k, v in d.get("residue", {}).items()}
        led.sessions = [_fields(Session, s) for s in d.get("sessions", [])]
        return led

    def save(self, path: Path) -> None:
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(json.dumps(self.to_dict(), indent=2))

    @classmethod
    def load(cls, path: Path) -> "Ledger":
        if not path.exists():
            return cls()
        return cls.from_dict(json.loads(path.read_text()))

    # -- session lifecycle --------------------------------------------------
    def current(self) -> Optional[Session]:
        return self.sessions[-1] if self.sessions and not self.sessions[-1].closed else None

    def open_session(self, now: Optional[str] = None) -> tuple[Session, list[Residue]]:
        """Start a session and surface the open residue that must be cited (the gate)."""
        if self.current() is not None:
            raise RuntimeError("a session is already open; close it first")
        self._seq += 1
        sid = f"s{self._seq}"
        carried = [r for r in self.residue.values() if r.status in ("open", "seeded", "deferred")]
        sess = Session(id=sid, opened=now or _ts(), cited_prior=len(carried))
        self.sessions.append(sess)
        return sess, sorted(carried, key=lambda r: r.id)

    def add(self, text: str, kind: str, origin: str = "", now: Optional[str] = None) -> Residue:
        if kind not in KINDS:
            raise KeyError(f"unknown residue kind: {kind!r} (one of {', '.join(KINDS)})")
        sess = self._require_open()
        self._seq += 1
        rid = f"r{self._seq}"
        r = Residue(id=rid, text=text, kind=kind, origin=origin,
                    born_session=sess.id, touched_session=sess.id, notes=[])
        self.residue[rid] = r
        sess.added.append(rid)
        return r

    def seed(self, rid: str) -> Residue:
        """Mark a prior residue item as fuel for the current expansion."""
        sess = self._require_open()
        r = self._get(rid)
        r.status = "seeded"
        r.touched_session = sess.id
        if rid not in sess.seeded:
            sess.seeded.append(rid)
        return r

    def resolve(self, rid: str, note: str = "", drop: bool = False,
                defer: bool = False) -> Residue:
        sess = self._require_open()
        r = self._get(rid)
        r.status = "dropped" if drop else ("deferred" if defer else "resolved")
        r.touched_session = sess.id
        if note:
            r.notes.append(note)
        if drop or defer:
            if rid not in sess.adjudicated:
                sess.adjudicated.append(rid)     # ruling out IS engagement
        elif rid not in sess.resolved:
            sess.resolved.append(rid)
        return r

    def close_session(self, now: Optional[str] = None) -> Session:
        sess = self._require_open()
        sess.closed = now or _ts()
        # Metabolism iff prior residue existed, was surfaced, and was engaged —
        # where "engaged" means seeding, resolving, dropping, or deferring an
        # item born in an EARLIER session (ruling a prior gap out is
        # adjudication, not churn). Touching only residue added this same
        # session is motion within the session, not compounding across them.
        engaged = any(
            self.residue[rid].born_session != sess.id
            for rid in (*sess.seeded, *sess.resolved, *sess.adjudicated)
            if rid in self.residue
        )
        sess.breath = "metabolism" if (sess.cited_prior and engaged) else "churn"
        return sess

    # -- scoring (P30 dual ledger) -----------------------------------------
    def score(self) -> dict[str, Any]:
        total = len(self.residue) or 1
        resolved = sum(1 for r in self.residue.values() if r.status == "resolved")
        dropped = sum(1 for r in self.residue.values() if r.status == "dropped")
        deferred = sum(1 for r in self.residue.values() if r.status == "deferred")
        adjudicated = resolved + dropped
        breaths = [s.breath for s in self.sessions if s.closed]
        return {
            "open_residue": sum(1 for r in self.residue.values()
                                if r.status in ("open", "seeded", "deferred")),
            "strict": round(adjudicated / total, 4),
            "lenient": round((adjudicated + deferred) / total, 4),
            "metabolism_breaths": breaths.count("metabolism"),
            "churn_breaths": breaths.count("churn"),
        }

    # -- internals ----------------------------------------------------------
    def _require_open(self) -> Session:
        s = self.current()
        if s is None:
            raise RuntimeError("no open session; run `open` first (it surfaces prior residue — the gate)")
        return s

    def _get(self, rid: str) -> Residue:
        r = self.residue.get(rid)
        if r is None:
            raise KeyError(f"unknown residue id: {rid!r}")
        return r


def _ts() -> str:
    return time.strftime("%Y-%m-%dT%H:%M:%S")


def _fields(cls: Any, d: dict[str, Any]) -> Any:
    """Construct a dataclass from a dict, ignoring unknown keys — a store
    written by a future version with extra fields must still load."""
    import dataclasses
    known = {f.name for f in dataclasses.fields(cls)}
    return cls(**{k: v for k, v in d.items() if k in known})


# --------------------------------------------------------------------- CLI
def _store_path(args: Any) -> Path:
    if getattr(args, "store", None):
        return Path(args.store)
    topic = getattr(args, "topic", None) or "ledger"
    return Path(".residue") / f"{topic}.json"


def main(argv: Optional[list] = None) -> int:
    import argparse

    ap = argparse.ArgumentParser(prog="ideonomy.residue",
                                 description="Cross-session residue ledger (P-10).")
    ap.add_argument("--store", help="ledger JSON path (default .residue/<topic>.json)")
    ap.add_argument("--topic", help="topic scope for the default store path")
    sub = ap.add_subparsers(dest="cmd", required=True)

    sub.add_parser("open", help="start a session; surface prior residue to cite (the gate)")
    a = sub.add_parser("add", help="record a new residue item")
    a.add_argument("text")
    a.add_argument("--kind", required=True, choices=sorted(KINDS))
    a.add_argument("--from", dest="origin", default="", help="skill/breath that produced it")
    s = sub.add_parser("seed", help="mark prior residue as fuel for this expansion")
    s.add_argument("ids", nargs="+")
    r = sub.add_parser("resolve", help="resolve / drop / defer a residue item")
    r.add_argument("id")
    r.add_argument("--note", default="")
    g = r.add_mutually_exclusive_group()
    g.add_argument("--drop", action="store_true", help="ruled out")
    g.add_argument("--defer", action="store_true", help="accepted debt, stays visible")
    sub.add_parser("status", help="scores, kinds, metabolism vs churn history")
    c = sub.add_parser("close", help="finalize the session; classify the breath")
    c.add_argument("--note", default="")

    args = ap.parse_args(argv)
    path = _store_path(args)
    try:
        led = Ledger.load(path)
    except (ValueError, TypeError) as exc:   # corrupt store: refuse, don't clobber
        print(f"error: cannot read ledger {path}: {exc}", file=sys.stderr)
        return 2
    if args.topic:
        led.topic = args.topic
    try:
        rc = _dispatch(led, args, path)
    except (RuntimeError, KeyError) as exc:
        msg = exc.args[0] if exc.args else exc
        print(f"error: {msg}  [store: {path}]", file=sys.stderr)
        return 2                              # nothing mutated is saved
    led.save(path)
    return rc


def _dispatch(led: Ledger, args: Any, path: Path) -> int:
    if args.cmd == "open":
        sess, carried = led.open_session()
        print(f"session {sess.id} open  (topic={led.topic}, store={path})")
        if carried:
            print(f"prior residue to engage before you expand ({len(carried)}):")
            for r in carried:
                print(f"  {r.id} [{r.kind}/{r.status}] {r.text}")
            print("→ seed the ones fueling this work, resolve/drop what's done, "
                  "or this closes as a CHURN breath.")
        else:
            print("no prior residue — a clean start.")
        return 0
    if args.cmd == "add":
        r = led.add(args.text, args.kind, origin=args.origin)
        print(f"added {r.id} [{r.kind}] {r.text}")
        return 0
    if args.cmd == "seed":
        for rid in args.ids:
            r = led.seed(rid)
            print(f"seeded {r.id}")
        return 0
    if args.cmd == "resolve":
        r = led.resolve(args.id, note=args.note, drop=args.drop, defer=args.defer)
        print(f"{r.status} {r.id}")
        return 0
    if args.cmd == "status":
        sc = led.score()
        print(f"store={path}")
        print(f"topic={led.topic}  open_residue={sc['open_residue']}  "
              f"strict={sc['strict']:.0%}  lenient={sc['lenient']:.0%}")
        print(f"breaths: metabolism={sc['metabolism_breaths']}  churn={sc['churn_breaths']}")
        by_kind: dict[str, int] = {}
        for r in led.residue.values():
            if r.status in ("open", "seeded", "deferred"):
                by_kind[r.kind] = by_kind.get(r.kind, 0) + 1
        for k, n in sorted(by_kind.items()):
            print(f"  {k}: {n}")
        return 0
    if args.cmd == "close":
        sess = led.close_session()
        if args.note:
            sess.note = args.note
        print(f"session {sess.id} closed as a {sess.breath.upper()} breath  "
              f"(cited={sess.cited_prior} seeded={len(sess.seeded)} "
              f"resolved={len(sess.resolved)} added={len(sess.added)})")
        return 0
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
