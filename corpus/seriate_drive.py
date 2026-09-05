"""The seriation drive: relentless, idempotent concept-space mapping.

Runs the package's pure seriation algebra (ideonomy.seriate) over the whole
database with LM meaning-binding on top:

  1. embed every list's items (Gemini embedding, cached in embcache/)
  2. order each list (spectral vs greedy, smoothest wins)
  3. measure SERIABILITY: smoothness gain over random order — how strongly
     a hidden 1-D dimension runs through the list (low gain = genuine set)
  4. name the axis with a strong model (the order is a claim; the name
     binds it), which may also reverse the direction
  5. store: grown lists carry the order in-object (source.seriation);
     canon stays verbatim — orders live in data/seriations.jsonl as indices
  6. self-apply: seriate the catalog itself (list centroids -> the master
     axis of the whole database + 2D map coords -> data/catalog-map.jsonl)

    python3 corpus/seriate_drive.py --grown            # seriate + name all grown
    python3 corpus/seriate_drive.py --canon            # order all canon (axes for --canon-names largest)
    python3 corpus/seriate_drive.py --catalog          # the catalog's own map
    python3 corpus/seriate_drive.py --all

Idempotent: cached embeddings, already-seriated lists skipped (--force to redo).
"""
import argparse
import hashlib
import json
import pathlib
import random
import sys
import time
from concurrent.futures import ThreadPoolExecutor

ROOT = pathlib.Path(__file__).resolve().parent
REPO = ROOT.parent
GROWN = REPO / "ideonomy" / "data" / "grown.jsonl"
SERIATIONS = REPO / "ideonomy" / "data" / "seriations.jsonl"
CATMAP = REPO / "ideonomy" / "data" / "catalog-map.jsonl"
CACHE = ROOT / "embcache"
sys.path.insert(0, str(ROOT))
sys.path.insert(0, str(REPO))

from ideonomy.lists import Ideolist                      # noqa: E402
from ideonomy import canon                               # noqa: E402
from ideonomy.seriate import (sim_matrix, best_order,    # noqa: E402
                              smoothness, spectral_order)
from climb import ask, _key                              # noqa: E402  (reuse the rail)
import urllib.request                                    # noqa: E402

EMBED_MODEL = "gemini-embedding-001"
STRONG = "gemini-3.1-pro-preview"
DIM = 256


# ---------------------------------------------------------------- embeddings
def _embed_batch(texts):
    body = {"requests": [
        {"model": f"models/{EMBED_MODEL}",
         "content": {"parts": [{"text": t}]},
         "outputDimensionality": DIM} for t in texts]}
    req = urllib.request.Request(
        f"https://generativelanguage.googleapis.com/v1beta/models/{EMBED_MODEL}"
        f":batchEmbedContents?key={_key()}",
        data=json.dumps(body).encode(), headers={"Content-Type": "application/json"})
    for attempt in range(4):
        try:
            with urllib.request.urlopen(req, timeout=120) as r:
                out = json.load(r)
            return [e["values"] for e in out["embeddings"]]
        except Exception:
            if attempt == 3:
                raise
            time.sleep(5 * (attempt + 1))


def embed_items(name: str, items: list) -> list:
    CACHE.mkdir(exist_ok=True)
    h = hashlib.md5(json.dumps(items, ensure_ascii=False).encode()).hexdigest()[:12]
    path = CACHE / f"{name}.{h}.json"
    if path.exists():
        return json.loads(path.read_text())
    vecs = []
    for i in range(0, len(items), 100):
        vecs += _embed_batch(items[i:i + 100])
    path.write_text(json.dumps(vecs))
    return vecs


# ---------------------------------------------------------------- measurement
def order_and_score(name: str, items: list) -> dict:
    vecs = embed_items(name, items)
    sim = sim_matrix(vecs)
    order, method, s = best_order(sim)
    rng = random.Random(7)
    rand = []
    for _ in range(20):
        p = list(range(len(items)))
        rng.shuffle(p)
        rand.append(smoothness(sim, p))
    baseline = sum(rand) / len(rand)
    return {"order": order, "method": method, "smoothness": round(s, 4),
            "random_smoothness": round(baseline, 4),
            "seriability": round(s - baseline, 4), "sim": sim}


def name_axis(of: str, ordered_items: list) -> dict:
    shown = "\n".join(ordered_items)
    return ask(STRONG,
               "A list has been seriated — ordered so adjacent items are most "
               f"similar. Each item is: {of}.\nThe seriated order, first to last:\n"
               f"{shown}\n\n"
               "Name the latent axis this order runs along, as a one-line claim "
               "(the order's meaning, e.g. 'autonomic depth: from performable to "
               "unfakeable'). If the order reads more naturally reversed, say so. "
               "Judge honestly whether the axis is REVELATORY (reading the order "
               "start-to-finish teaches something the unordered list could not) "
               "or merely local clustering. Reply as JSON: "
               '{"axis": str, "reverse": bool, "revelatory": bool, "note": str}',
               want_json=True)


# ---------------------------------------------------------------- tiers
def run_grown(force: bool = False) -> None:
    grown = {}
    for line in GROWN.read_text().splitlines():
        if line.strip():
            l = Ideolist.from_dict(json.loads(line))
            grown[l.name] = l
    todo = [l for l in grown.values()
            if force or "seriation" not in (l.source or {})]
    print(f"grown: {len(todo)} lists to seriate")
    results = {}
    for l in todo:
        results[l.name] = order_and_score(l.name, l.items)
    with ThreadPoolExecutor(6) as ex:
        named = {name: ex.submit(name_axis, grown[name].of,
                                 [grown[name].items[i] for i in r["order"]])
                 for name, r in results.items()}
        named = {k: f.result() for k, f in named.items()}
    for name, r in results.items():
        l, ax = grown[name], named[name]
        order = list(reversed(r["order"])) if ax.get("reverse") else r["order"]
        l.items = [l.items[i] for i in order]
        l.source["seriation"] = {
            "axis": ax.get("axis"), "revelatory": bool(ax.get("revelatory")),
            "method": r["method"], "smoothness": r["smoothness"],
            "random_smoothness": r["random_smoothness"],
            "seriability": r["seriability"], "named_by": STRONG}
        print(f"  {name}: seriability {r['seriability']:+.3f} "
              f"{'REVELATORY' if ax.get('revelatory') else 'clustering'} — {ax.get('axis','')[:70]}")
    with GROWN.open("w") as f:
        for n in sorted(grown):
            f.write(json.dumps(grown[n].to_dict(), ensure_ascii=False) + "\n")


def run_canon(canon_names: int = 50, force: bool = False) -> None:
    done = set()
    if SERIATIONS.exists() and not force:
        done = {json.loads(x)["name"] for x in SERIATIONS.read_text().splitlines() if x.strip()}
    lists_ = canon.lists(tier="canon")
    todo = [l for l in lists_.values() if l.name not in done and len(l.items) >= 8]
    print(f"canon: {len(todo)} lists to order (axes for the {canon_names} largest)")
    scored = []
    for i, l in enumerate(todo):
        r = order_and_score(l.name, l.items)
        scored.append((l, r))
        if (i + 1) % 50 == 0:
            print(f"  ...{i + 1}/{len(todo)} ordered")
    by_size = sorted(scored, key=lambda t: -len(t[0].items))[:canon_names]
    to_name = {l.name for l, _ in by_size}
    with ThreadPoolExecutor(6) as ex:
        futures = {l.name: ex.submit(name_axis, l.of or l.name,
                                     [l.items[i] for i in r["order"]])
                   for l, r in scored if l.name in to_name}
        axes = {k: f.result() for k, f in futures.items()}
    now = time.strftime("%Y-%m-%dT%H:%M:%S")
    with SERIATIONS.open("a") as f:
        for l, r in scored:
            ax = axes.get(l.name, {})
            order = list(reversed(r["order"])) if ax.get("reverse") else r["order"]
            f.write(json.dumps({
                "name": l.name, "tier": "canon", "t": now,
                "order": order, "method": r["method"],
                "smoothness": r["smoothness"],
                "random_smoothness": r["random_smoothness"],
                "seriability": r["seriability"],
                "axis": ax.get("axis"), "revelatory": ax.get("revelatory"),
            }, ensure_ascii=False) + "\n")
    top = sorted(scored, key=lambda t: -t[1]["seriability"])[:5]
    flat = sorted(scored, key=lambda t: t[1]["seriability"])[:3]
    print("most seriable:", [(l.name, r["seriability"]) for l, r in top])
    print("least (true sets):", [(l.name, r["seriability"]) for l, r in flat])


def run_catalog() -> None:
    import numpy as np
    all_lists = {**canon.lists(tier="canon"), **canon.lists(tier="grown")}
    names, cents, tiers = [], [], []
    for l in all_lists.values():
        if len(l.items) < 8:
            continue
        vecs = np.array(embed_items(l.name, l.items))
        names.append(l.name)
        cents.append(vecs.mean(axis=0))
        tiers.append((l.source or {}).get("tier", "canon"))
    X = np.array(cents)
    norms = np.linalg.norm(X, axis=1, keepdims=True)
    norms[norms == 0] = 1.0                    # guard: a zero centroid poisons everything
    X /= norms
    W = X @ X.T
    np.fill_diagonal(W, 0.0)
    # kNN-sparsify: a near-complete graph localizes the Fiedler vector on one
    # outlier (observed run 1: one list at -0.995, the bulk at ~0.001); a
    # sparse mutual-neighborhood graph spreads the spectrum into a real map.
    k = 10
    thresh = np.sort(W, axis=1)[:, -k][:, None]
    W = np.where((W >= thresh) | (W >= thresh.T), W, 0.0)
    L = np.diag(W.sum(1)) - W
    vals, vecs = np.linalg.eigh(L)
    fiedler, third = vecs[:, 1], vecs[:, 2]
    order = np.argsort(fiedler)
    ax = name_axis("an ideonomic list (shown by name) in Gunkel's catalog of the "
                   "dimensions of ideas", [names[i] for i in order])
    if ax.get("reverse"):
        order = order[::-1]
        fiedler = -fiedler
    now = time.strftime("%Y-%m-%dT%H:%M:%S")
    with CATMAP.open("w") as f:
        f.write(json.dumps({"_meta": {"t": now, "n": len(names),
                                      "axis": ax.get("axis"),
                                      "revelatory": ax.get("revelatory"),
                                      "note": ax.get("note")}}) + "\n")
        for i in order:
            f.write(json.dumps({"name": names[i], "tier": tiers[i],
                                "items_hash": hashlib.sha256(json.dumps(
                                    sorted(all_lists[names[i]].items),
                                    ensure_ascii=False).encode()).hexdigest(),
                                "x": round(float(fiedler[i]), 6),
                                "y": round(float(third[i]), 6)},
                               ensure_ascii=False) + "\n")
    print(f"catalog map: {len(names)} lists; master axis: {ax.get('axis')}")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--grown", action="store_true")
    ap.add_argument("--canon", action="store_true")
    ap.add_argument("--catalog", action="store_true")
    ap.add_argument("--all", action="store_true")
    ap.add_argument("--canon-names", type=int, default=50)
    ap.add_argument("--force", action="store_true")
    args = ap.parse_args()
    if args.grown or args.all:
        run_grown(force=args.force)
    if args.canon or args.all:
        run_canon(canon_names=args.canon_names, force=args.force)
    if args.catalog or args.all:
        run_catalog()


if __name__ == "__main__":
    main()
