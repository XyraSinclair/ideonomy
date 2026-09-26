#!/usr/bin/env python3
"""Read the five stance ledgers and print one table.

Per condition: candidates per breath, pooled keep rate, accepted count,
distinct first words of accepted items (a crude region count), the
fraction of accepted items that are a case of some seed item under the
stall reader's own near test (asymmetric "the text above is a case of
this rule", self and far anchors carried per call, near = above the
log-odds midpoint), how many distinct seed items those near ones sit on,
and the fraction carrying written-instrument vocabulary. Judge calls are
cached to out/near-seed.json so a rerun is offline.
Run from the repo root: python3 corpus/stance-2026-09-25/measure.py
"""
import json, math, os, re, subprocess, sys
HERE = os.path.dirname(os.path.abspath(__file__))
SRC = json.load(open(os.path.join(HERE, "source.json")))
SEED_NAME, CONDS = SRC["seed_map"], list(SRC["conditions"])
grown = [json.loads(l) for l in open("data/grown.jsonl") if l.strip()]
seed = next(r for r in grown if r["name"] == SEED_NAME)["items"]
far = next(r for r in grown if r.get("source", {}).get("kind") == "map")["items"][0]  # what farItem picks: the copies are not maps, so it wraps to the first map
WRITTEN = re.compile(r"\b(writ\w*|sign\w*|clause|paper\w*|record\w*|document\w*|deed|terms?|contract\w*|ledger|filed?|stamp\w*|notar\w*|minutes)\b", re.I)

def ledger(c):
    p = f"corpus/climb-ledger/{SEED_NAME}--{c}.jsonl"
    return [json.loads(l) for l in open(p) if l.strip()]

def logit(p):
    p = min(1 - 1e-6, max(1e-6, p)); return math.log(p / (1 - p))

def judge(states):
    """states: list of texts; returns per state {id: p} for self, far, s0..s17."""
    cache_p = os.path.join(HERE, "out", "near-seed.json")
    cache = json.load(open(cache_p)) if os.path.exists(cache_p) else {}
    todo = [s for s in states if s not in cache]
    if todo:
        qs = lambda: [{"id": "self", "type": "noul"}, {"id": "far", "type": "noul"}] + [{"id": f"s{i}", "type": "noul"} for i in range(len(seed))]
        lines = []
        for s in todo:
            q = qs(); rules = [s, far] + seed
            for qi, r in zip(q, rules): qi["text"] = "The text above is a case of this rule: " + r[:220]
            lines.append(json.dumps({"state": s, "questions": q}, ensure_ascii=False))
        out = subprocess.run(["judge", "--jsonl"], input="\n".join(lines) + "\n", capture_output=True, text=True, check=True).stdout
        rows = [json.loads(l) for l in out.splitlines() if l.strip()]
        assert len(rows) == len(todo), (len(rows), len(todo))
        for s, r in zip(todo, rows):
            if "error" in r: raise SystemExit(r)
            cache[s] = {a["id"]: a["p"] for a in r["answers"]}
        json.dump(cache, open(cache_p, "w"), indent=0, ensure_ascii=False)
    return [cache[s] for s in states]

rows = []
for c in CONDS:
    L = ledger(c)
    acc = [a for b in L for a in b["accepted"]]
    cands = [b["candidates"] for b in L]; kept = [b["kept"] for b in L]
    first = {a.split()[0].lower().strip(":,") for a in acc}
    ps = judge(acc)
    near, plates = 0, set()
    for p in ps:
        mid = (logit(p["self"]) + logit(p["far"])) / 2
        best = max(range(len(seed)), key=lambda i: p[f"s{i}"])
        if logit(p[f"s{best}"]) > mid: near += 1; plates.add(best)
    written = sum(1 for a in acc if WRITTEN.search(a))
    rows.append(dict(stance=c, breaths=len(L), candidates=cands, kept=kept,
        keep_rate=round(sum(kept) / max(1, sum(cands)), 2), accepted=len(acc),
        first_words=len(first), near_seed=near, seed_plates=len(plates), written=written,
        gaps=[g for b in L for g in b["gaps"]]))
json.dump(rows, open(os.path.join(HERE, "out", "table.json"), "w"), indent=1, ensure_ascii=False)
print("| stance | cand/breath | kept/breath | keep rate | accepted | distinct first words | near a seed item | seed items they sit on | written vocab |")
print("|---|---|---|---|---|---|---|---|---|")
for r in rows:
    print(f"| {r['stance']} | {'/'.join(map(str, r['candidates']))} | {'/'.join(map(str, r['kept']))} | {r['keep_rate']:.2f} | {r['accepted']} | {r['first_words']} | {r['near_seed']}/{r['accepted']} | {r['seed_plates']} | {r['written']}/{r['accepted']} |")
print("\nfar anchor:", far[:80])
for r in rows: print(r["stance"], "gaps:", r["gaps"])
