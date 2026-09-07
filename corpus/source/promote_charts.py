"""Promote chart transcriptions -> ideonomy repo data/canon-charts.jsonl.

Only lists that carry real transcribed content are promoted: legibility
full/partial, >=5 items. Every record keeps the source photograph URL; the
`via` field is honest about the vision-model route.
"""
import json
import pathlib
import re

ROOT = pathlib.Path(__file__).parent
CHARTS = ROOT / "extracted" / "charts"
OUT = pathlib.Path.home() / "projects" / "ideonomy" / "ideonomy" / "data" / "canon-charts.jsonl"


def slug(s: str, limit: int = 64) -> str:
    s = s.split("(")[0]
    return re.sub(r"[^a-z0-9]+", "-", s.lower()).strip("-")[:limit].strip("-")


records, seen = [], set()
n_files = 0
for f in sorted(CHARTS.rglob("pic*.json")):
    n_files += 1
    rec = json.loads(f.read_text())
    if rec.get("legibility") == "illegible":
        continue
    set_name = f.parent.name
    for i, lst in enumerate(rec.get("lists", []), 1):
        items = [x.strip() for x in lst.get("items", []) if x and x.strip()]
        if len(items) < 5:
            continue
        key = tuple(items)
        if key in seen:
            continue
        seen.add(key)
        name = f"charts.{set_name.replace('mapsandlists-', 'maps')}.{f.stem}.{slug(lst.get('name') or rec.get('title') or f.stem) or i}"
        records.append({
            "name": name,
            "of": lst.get("of") or lst.get("name") or rec.get("title", ""),
            "items": items,
            "status": "open",
            "made_by": "extract(chart-photo)",
            "parents": [],
            "source": {
                "tier": "canon",
                "author": "Patrick Gunkel",
                "url": rec.get("source_image", ""),
                "via": "vision-transcription (gpt-5.6, verbatim prompt)",
                "page_title": rec.get("title", ""),
                "legibility": rec.get("legibility"),
            },
        })

counts = {}
for r in records:
    counts[r["name"]] = counts.get(r["name"], 0) + 1
    if counts[r["name"]] > 1:
        r["name"] += f"-{counts[r['name']]}"

OUT.parent.mkdir(parents=True, exist_ok=True)
with OUT.open("w") as fh:
    for r in records:
        fh.write(json.dumps(r, ensure_ascii=False) + "\n")

total = sum(len(r["items"]) for r in records)
print(f"promoted {len(records)} lists / {total} items from {n_files} charts -> {OUT}")
