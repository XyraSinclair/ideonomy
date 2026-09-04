"""Gunkel's recovered corpus as data — the canon layer of the database.

A canon list is an `Ideolist` whose `source["tier"] == "canon"`: recovered
verbatim from Patrick Gunkel's own publications, never machine-generated.
Each record carries its provenance (original URL, archive route, page title).
The layers ship inside the package as JSONL files under `data/` — one file
per acquisition layer (`canon-wayback.jsonl` is the pre-redesign
ideonomy.mit.edu text; chart and monograph layers land as they are
extracted). Machine-grown extensions belong in a `Store`, gated by
`trial`/`triangulate`/`cycles`, and never masquerade as canon.

    python3 -m ideonomy.canon ls
    python3 -m ideonomy.canon show essays.traits.positive-traits
    python3 -m ideonomy.canon sample whatcando.what-ideonomy-can-do --n 5
"""

from __future__ import annotations

import json
from importlib import resources
from typing import Optional

from .lists import Ideolist


def lists(tier: str = "canon") -> "dict[str, Ideolist]":
    """Lists of one provenance tier ("canon" by default; "grown" for the
    machine-extended layer), keyed by name, freshly loaded from package data."""
    out: "dict[str, Ideolist]" = {}
    data = resources.files(__package__) / "data"
    for entry in sorted(data.iterdir(), key=lambda e: e.name):
        if not entry.name.endswith(".jsonl"):
            continue
        for line in entry.read_text().splitlines():
            if line.strip():
                lst = Ideolist.from_dict(json.loads(line))
                if (lst.source or {}).get("tier") == tier:
                    out[lst.name] = lst
    return out


def get(name: str, tier: str = "canon") -> Ideolist:
    lst = lists(tier).get(name)
    if lst is None:
        raise KeyError(f"no {tier} list named {name!r}")
    return lst


def main(argv: Optional[list] = None) -> int:
    import argparse

    ap = argparse.ArgumentParser(
        prog="ideonomy.canon",
        description="Gunkel's recovered lists, shipped as data.")
    ap.add_argument("--tier", default="canon", choices=["canon", "grown"])
    sub = ap.add_subparsers(dest="cmd", required=True)
    sub.add_parser("ls")
    p = sub.add_parser("show"); p.add_argument("name")
    p = sub.add_parser("sample"); p.add_argument("name")
    p.add_argument("--n", type=int, default=3); p.add_argument("--seed", type=int)
    args = ap.parse_args(argv)

    try:
        if args.cmd == "ls":
            all_ = lists(args.tier)
            for name, lst in sorted(all_.items()):
                print(f"{len(lst.items):5d}  {name}  |  {lst.of}")
            print(f"total: {len(all_)} lists, "
                  f"{sum(len(l.items) for l in all_.values())} items")
        elif args.cmd == "show":
            lst = get(args.name, args.tier)
            src = lst.source or {}
            print(f"{lst.name}  of: {lst.of}")
            print(f"source: {src.get('url', '?')} (via {src.get('via', '?')})")
            for x in lst.items:
                print(f"  - {x}")
        elif args.cmd == "sample":
            for x in get(args.name, args.tier).sample(args.n, seed=args.seed):
                print(f"- {x}")
    except KeyError as exc:
        print(f"error: {exc.args[0]}")
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
