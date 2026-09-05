"""The widen axis: grow the meta-list of lists worth making.

Deepening (climb.py) grows a list along its own gap gradient. Widening grows
the *set of lists* — Gunkel's "reapplication" move. It proposes new list
specs, each a {name, of} an agent could hand straight to climb.py, seeded
from three streams that a single model would never span alone:

  - Xyra's stated domains (strategy, somatics, math, tactics, ops, first-
    strike, cooperation, convincing, deal flow, psyop) crossed with the
    generative angle each domain under-serves;
  - Gunkel's 236 divisions as lenses (each division names a kind of list);
  - the existing lists themselves, as parents for cross-products.

Output: candidate specs -> gate (is this a genuine, enumerable, non-duplicate
list of real categories?) -> data/list-specs.jsonl. Nothing is grown here;
this only decides WHICH lists deserve a climb. Cheap by construction.

    python3 corpus/widen.py --k 40
"""
import argparse
import json
import pathlib
import random
import sys

ROOT = pathlib.Path(__file__).resolve().parent
REPO = ROOT.parent
OUT = REPO / "ideonomy" / "data" / "list-specs.jsonl"
sys.path.insert(0, str(ROOT))
sys.path.insert(0, str(REPO))

from climb import ask, CHEAP, STRONG, load_grown  # noqa: E402
from ideonomy import divisions as D                # noqa: E402

DOMAINS = ["strategy", "somatics", "mathematics", "tactics", "operations",
           "first-strike / preemption", "cooperation", "persuasion",
           "deal flow", "influence operations", "negotiation", "epistemics",
           "logistics", "timing", "leverage", "risk"]


def existing_names() -> set:
    have = set()
    for f in (OUT,):
        if f.exists():
            have |= {json.loads(l)["name"] for l in f.read_text().splitlines() if l.strip()}
    have |= set(load_grown())
    return have


def propose(k: int, seed: int) -> list:
    rng = random.Random(seed)
    lenses = rng.sample(list(D.DIVISIONS.items()), 24)
    lens_str = "\n".join(f"- {theme.title()} ({greek})" for theme, greek in lenses)
    dom_str = ", ".join(DOMAINS)
    prompt = (
        "You are enumerating LISTS WORTH MAKING for an ideonomy database — "
        "Patrick Gunkel's science of systematic lists. A good list spec is a "
        "family of real, mutually-distinct categories that an analyst would "
        "find load-bearing, phrased so its items combine with other lists.\n\n"
        f"Seed domains (bias toward these): {dom_str}.\n\n"
        "Gunkel divisions to use as lenses (each names a KIND of list):\n"
        f"{lens_str}\n\n"
        f"Propose exactly {k} list specs. Each must be a list that does NOT yet "
        "obviously exist as a standard reference, is enumerable (10-200 real "
        "items), and is genuinely useful for thinking about the seed domains. "
        "Cross a domain with a lens where it yields something sharp (e.g. "
        "'failure modes of coalitions', 'invariants preserved under "
        "renegotiation', 'somatic tells of deception'). Reply as JSON: "
        '{"specs": [{"name": "kebab-case-id", "of": "what ONE item is, a '
        'precise noun/verb phrase", "why": "one clause on what it is for"}]}')
    return ask(CHEAP, prompt, want_json=True).get("specs", [])


def gate(specs: list, have: set) -> list:
    fresh = [s for s in specs if s.get("name") and s["name"] not in have]
    if not fresh:
        return []
    listing = "\n".join(
        f'{i}. {s["name"]}: {s.get("of","")}  [{s.get("why","")}]'
        for i, s in enumerate(fresh))
    judged = ask(STRONG,
                 "Gate these proposed list specs for an ideonomy database. KEEP "
                 "a spec only if it is (a) a genuine family of distinct, real "
                 "categories — not a vague theme or a single question; (b) "
                 "actually enumerable to 10+ concrete items; (c) not a trivial "
                 "restatement of another kept spec; (d) its 'of' precisely says "
                 "what one item is. Be strict; most proposals are vague.\n\n"
                 f"{listing}\n\n"
                 'Reply JSON: {"verdicts":[{"i":int,"keep":bool,"why":str}]}',
                 want_json=True)
    out = []
    for v in judged.get("verdicts", []):
        i = v.get("i")
        if isinstance(i, int) and 0 <= i < len(fresh) and v.get("keep"):
            s = dict(fresh[i]); s["gate_why"] = v.get("why", "")
            out.append(s)
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--k", type=int, default=40)
    ap.add_argument("--seed", type=int, default=0)
    args = ap.parse_args()
    have = existing_names()
    specs = propose(args.k, args.seed)
    kept = gate(specs, have)
    # de-dupe against prior specs by name
    seen = have.copy()
    kept = [s for s in kept if not (s["name"] in seen or seen.add(s["name"]))]
    OUT.parent.mkdir(parents=True, exist_ok=True)
    with OUT.open("a") as f:
        for s in kept:
            f.write(json.dumps({
                "name": s["name"], "of": s["of"],
                "why": s.get("why", ""), "gate_why": s.get("gate_why", ""),
                "status": "spec", "source": {"tier": "spec", "via": "widen.py"},
            }, ensure_ascii=False) + "\n")
    total = len(OUT.read_text().splitlines()) if OUT.exists() else 0
    print(f"proposed {len(specs)}, kept {len(kept)} new specs -> {OUT} ({total} total)")
    for s in kept:
        print(f"  + {s['name']}: {s['of']}")


if __name__ == "__main__":
    main()
