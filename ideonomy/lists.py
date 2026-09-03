"""The never-ending list-making structure — ideonomy as an unbounded process.

Gunkel worked in lists; this makes the list the first-class object. An
`Ideolist` is named, *typed* (`of` says what one item is), provenanced
(every list records the operation and parents that made it), and persistent
(a `Store` survives across chats, so enumeration compounds instead of
restarting). The algebra is applicative — lists apply to lists — and closes
over itself: the operations are themselves shipped as an Ideolist
(`OPERATIONS`), so the structure can enumerate, vary, and judge its own moves.

Type signatures (the algebra):

    combine : Ideolist a -> Ideolist b -> template -> Ideolist (a x b)
    gate    : Ideolist a -> (item -> bool)         -> (kept, residue)
    grow    : Ideolist a -> Model -> k             -> Ideolist a
    sample  : Ideolist a -> n -> seed              -> [item]
    corpus  : Ideolist a                           -> cycles.State   (MDL triage)

Every operation is pure — parents are never mutated — and every result
carries lineage, so any derived list can answer "what made you?" The tier
discipline: `grow` is where a cheap frontier model earns its keep
(enumeration is cheap); judging what grew belongs to the strong model via
`trial`/`triangulate`, and to no model at all via `corpus` + MDL. Status is
honest: a list is `open` until its denominator is proven, then `closed` —
claiming closure is a coverage assertion, not a vibe (P-11).

    python3 -m ideonomy.lists new registers-of-refusal "a way to say no"
    python3 -m ideonomy.lists add registers-of-refusal "the soft deferral"
    python3 -m ideonomy.lists grow registers-of-refusal --model 'claude -p {prompt}' --k 10
    python3 -m ideonomy.lists combine registers-of-refusal moods --template 'Refuse via {a} while feeling {b}.'
    python3 -m ideonomy.lists ls
"""

from __future__ import annotations

import json
import random
import re
from dataclasses import dataclass, field
from pathlib import Path
from typing import Callable, Optional, Sequence

Model = Callable[[str], str]

STATUSES = ("open", "closed")   # closed == denominator proven, not "we stopped"


@dataclass
class Ideolist:
    name: str
    of: str                                  # what ONE item is: the type
    items: list = field(default_factory=list)
    status: str = "open"
    made_by: str = "seed"                    # operation that produced this list
    parents: list = field(default_factory=list)   # names of source lists

    def __post_init__(self) -> None:
        if self.status not in STATUSES:
            raise ValueError(f"status {self.status!r}; one of {STATUSES}")

    # ------------------------------------------------------------- algebra
    def combine(self, other: "Ideolist", template: str = "{a} {b}",
                name: Optional[str] = None, of: Optional[str] = None) -> "Ideolist":
        """combine : Ideolist a -> Ideolist b -> Ideolist (a x b).  P12."""
        from .operators import combine as cross
        return Ideolist(
            name=name or f"{self.name}x{other.name}",
            of=of or f"({self.of}) x ({other.of})",
            items=cross(self.items, other.items, template=template),
            made_by=f"combine({template!r})",
            parents=[self.name, other.name])

    def gate(self, pred: Callable[[str], bool],
             why: str = "pred") -> tuple["Ideolist", "Ideolist"]:
        """gate : Ideolist a -> (a -> bool) -> (kept, residue).  P18.
        The residue is a real list, not a discard — it seeds the next cycle."""
        kept = [x for x in self.items if pred(x)]
        rest = [x for x in self.items if not pred(x)]
        mk = lambda tag, xs: Ideolist(  # noqa: E731
            name=f"{self.name}/{tag}", of=self.of, items=xs,
            made_by=f"gate({why})", parents=[self.name])
        return mk("kept", kept), mk("residue", rest)

    def grow(self, model: Model, k: int = 10, hint: str = "") -> "Ideolist":
        """grow : Ideolist a -> Model -> Ideolist a.  The cheap-tier move:
        enumeration is cheap; judgment of what grew is not done here."""
        shown = "\n".join(f"- {x}" for x in self.items[-40:])
        prompt = (
            f"Extend this list. Each item is: {self.of}.\n"
            f"{('Guidance: ' + hint) if hint else ''}\n"
            f"Existing items (do not repeat, do not rephrase):\n{shown}\n\n"
            f"Give exactly {k} NEW items, one per line, no numbering, no "
            f"commentary. Vary along dimensions the existing items neglect.")
        have = {x.casefold().strip() for x in self.items}
        new = [ln.strip(" -*\t") for ln in model(prompt).splitlines()]
        new = [x for x in new if x and x.casefold() not in have]
        return Ideolist(name=self.name, of=self.of, items=self.items + new[:k],
                        status="open",           # growth reopens any closure
                        made_by=f"grow(k={k})", parents=[self.name])

    def sample(self, n: int = 3, seed: Optional[int] = None,
               avoid: Sequence[str] = ()) -> list:
        """sample : forced non-default picks (mode-collapse resistance)."""
        pool = [x for x in self.items if x not in set(avoid)]
        if n > len(pool):
            raise ValueError(f"asked for {n}, only {len(pool)} available")
        return random.Random(seed).sample(pool, n)

    def corpus(self):
        """corpus : Ideolist -> cycles.State — hand the list to the MDL
        engine; structure and residue fall out with no model calls at all."""
        from . import cycles
        return cycles.seed(self.items)

    # -------------------------------------------------------- persistence
    def to_dict(self) -> dict:
        return {"name": self.name, "of": self.of, "items": self.items,
                "status": self.status, "made_by": self.made_by,
                "parents": self.parents}

    @classmethod
    def from_dict(cls, d: dict) -> "Ideolist":
        known = {k: d[k] for k in
                 ("name", "of", "items", "status", "made_by", "parents") if k in d}
        return cls(**known)


class Store:
    """A directory of Ideolists — the part that never ends. Default path
    `.lists/` beside the residue ledger; both are the cross-chat memory."""

    def __init__(self, root: str = ".lists") -> None:
        self.root = Path(root)

    def _path(self, name: str) -> Path:
        if not re.fullmatch(r"[a-zA-Z0-9._/-]+", name) or ".." in name:
            raise ValueError(f"unusable list name {name!r}")
        return self.root / f"{name}.json"

    def save(self, lst: Ideolist) -> Path:
        p = self._path(lst.name)
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text(json.dumps(lst.to_dict(), indent=1, ensure_ascii=False))
        return p

    def load(self, name: str) -> Ideolist:
        return Ideolist.from_dict(json.loads(self._path(name).read_text()))

    def names(self) -> list:
        if not self.root.exists():
            return []
        return sorted(str(p.relative_to(self.root))[:-5]
                      for p in self.root.rglob("*.json"))


# ------------------------------------------------------- self-application
OPERATIONS = Ideolist(
    name="list-operations",
    of="an operation in the list algebra, as a type signature",
    items=[
        "combine : Ideolist a -> Ideolist b -> template -> Ideolist (a x b)",
        "gate : Ideolist a -> (item -> bool) -> (kept, residue)",
        "grow : Ideolist a -> Model -> k -> Ideolist a",
        "sample : Ideolist a -> n -> seed -> [item]",
        "corpus : Ideolist a -> cycles.State",
        "save/load : Ideolist a <-> Store",
    ],
    made_by="seed",
)


def main(argv: Optional[list] = None) -> int:
    import argparse

    ap = argparse.ArgumentParser(
        prog="ideonomy.lists",
        description="The persistent applicative list store. Lists are typed, "
                    "provenanced, and compound across chats.")
    ap.add_argument("--store", default=".lists")
    sub = ap.add_subparsers(dest="cmd", required=True)
    sub.add_parser("ls")
    p = sub.add_parser("new"); p.add_argument("name"); p.add_argument("of")
    p = sub.add_parser("add"); p.add_argument("name"); p.add_argument("item", nargs="+")
    p = sub.add_parser("show"); p.add_argument("name")
    p = sub.add_parser("sample"); p.add_argument("name")
    p.add_argument("--n", type=int, default=3); p.add_argument("--seed", type=int)
    p = sub.add_parser("combine"); p.add_argument("a"); p.add_argument("b")
    p.add_argument("--template", default="{a} {b}"); p.add_argument("--name")
    p = sub.add_parser("grow"); p.add_argument("name")
    p.add_argument("--model", required=True, help="model command with {prompt}")
    p.add_argument("--k", type=int, default=10); p.add_argument("--hint", default="")
    args = ap.parse_args(argv)
    st = Store(args.store)

    try:
        if args.cmd == "ls":
            for n in st.names():
                l = st.load(n)
                print(f"{n}  [{l.status}]  {len(l.items)} items  of: {l.of}")
        elif args.cmd == "new":
            st.save(Ideolist(name=args.name, of=args.of))
            print(f"created {args.name}")
        elif args.cmd == "add":
            l = st.load(args.name)
            l.items.extend(x for x in args.item if x not in l.items)
            st.save(l)
            print(f"{args.name}: {len(l.items)} items")
        elif args.cmd == "show":
            l = st.load(args.name)
            print(f"{l.name}  [{l.status}]  of: {l.of}  made_by: {l.made_by}"
                  + (f"  parents: {', '.join(l.parents)}" if l.parents else ""))
            for x in l.items:
                print(f"  - {x}")
        elif args.cmd == "sample":
            for x in st.load(args.name).sample(args.n, seed=args.seed):
                print(f"- {x}")
        elif args.cmd == "combine":
            out = st.load(args.a).combine(st.load(args.b),
                                          template=args.template, name=args.name)
            st.save(out)
            print(f"{out.name}: {len(out.items)} items  of: {out.of}")
        elif args.cmd == "grow":
            from .models import CommandModel
            l = st.load(args.name)
            grown = l.grow(CommandModel(args.model), k=args.k, hint=args.hint)
            st.save(grown)
            for x in grown.items[len(l.items):]:
                print(f"+ {x}")
    except (FileNotFoundError, ValueError) as exc:
        print(f"error: {exc}")
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
