"""Stitch the per-page vision transcriptions of "23 Diverse (But Very Old)
Ideonomic Lists" into whole canon lists -> canon-monographs.jsonl.

Pages are walked in order; a page whose list carries a real title starts a
new canonical list, untitled/continuation pages append to the current one.
Leading item numbers ("24. Completeness.") are stripped; where present they
are used to sanity-check continuity (gaps are reported, not hidden).
"""
import json
import pathlib
import re

ROOT = pathlib.Path(__file__).parent
PAGES = ROOT / "extracted" / "charts" / "23-diverse.jsonl"
OUT = ROOT.parents[1] / "ideonomy" / "data" / "canon-monographs.jsonl"
SRC_PDF = "https://www2.cs.uh.edu/~gnawali/gunkel/23%20Diverse%20(But%20Very%20Old)%20Ideonomic%20Lists.pdf"

CONT = re.compile(r"^\s*$|continu|untitled|unnamed|unknown|numbered list|^items \d", re.I)
NUM = re.compile(r"^(\d+)[.)]\s*")


def slug(s: str, limit: int = 64) -> str:
    s = s.split("(")[0]
    return re.sub(r"[^a-z0-9]+", "-", s.lower()).strip("-")[:limit].strip("-")


current = None
out = []
warnings = []

def flush():
    global current
    if current and len(current["items"]) >= 5:
        out.append(current)
    current = None

pages = sorted((json.loads(l) for l in PAGES.read_text().splitlines()),
               key=lambda r: int(re.search(r"(\d+)", r["image"]).group(1)))
for rec in pages:
    page_no = int(re.search(r"(\d+)", rec["image"]).group(1))
    for lst in rec.get("lists", []):
        title = (lst.get("name") or rec.get("title") or "").strip()
        title = title.strip('":').strip().strip('"')
        if "23 DIVERSE" in title.upper():
            continue        # the cover's table of contents, not a list
        if page_no == 1 and not NUM.match((lst.get("items") or [""])[0] or ""):
            continue        # unnumbered cover matter
        items = [x.strip() for x in lst.get("items", []) if x.strip()]
        first_num = NUM.match(items[0]) if items else None
        is_new = bool(title) and not CONT.search(title)
        # numbering says continuation even if a title got re-printed
        if is_new and first_num and int(first_num.group(1)) > 1 and current:
            is_new = False
        if is_new:
            flush()
            current = {
                "name": f"monographs.23-diverse.{slug(title)}",
                "of": title,
                "items": [],
                "status": "open",
                "made_by": "extract(monograph-page-vision)",
                "parents": [],
                "source": {
                    "tier": "canon",
                    "author": "Patrick Gunkel",
                    "url": SRC_PDF,
                    "via": "vision-transcription (gemini, verbatim prompt), stitched across pages",
                    "pages": [],
                },
            }
        if current is None:   # continuation before any title: recover under doc name
            current = {
                "name": "monographs.23-diverse.untitled-opening",
                "of": "item of the document's opening list",
                "items": [], "status": "open",
                "made_by": "extract(monograph-page-vision)", "parents": [],
                "source": {"tier": "canon", "author": "Patrick Gunkel",
                           "url": SRC_PDF, "via": "vision-transcription (gemini), stitched",
                           "pages": []},
            }
        # continuity check
        if current["items"] and first_num:
            prev = NUM.match(current["items"][-1]) if False else None
        expected = len(current["items"]) + 1
        if first_num and int(first_num.group(1)) != expected:
            warnings.append(f"page {page_no}: {current['name']} expected item "
                            f"{expected}, page starts at {first_num.group(1)}")
        current["items"].extend(NUM.sub("", x) for x in items)
        current["source"]["pages"].append(page_no)
flush()

# unique names
counts = {}
for r in out:
    counts[r["name"]] = counts.get(r["name"], 0) + 1
    if counts[r["name"]] > 1:
        r["name"] += f"-{counts[r['name']]}"

with OUT.open("w") as fh:
    for r in out:
        fh.write(json.dumps(r, ensure_ascii=False) + "\n")

print(f"stitched {len(out)} lists / {sum(len(r['items']) for r in out)} items -> {OUT}")
for r in out:
    print(f"{len(r['items']):5d}  {r['of'][:70]}")
print(f"\n{len(warnings)} continuity warnings:")
for w in warnings[:20]:
    print(" ", w)
