"""Repo-grade extraction: Wayback HTML pages -> canon-wayback.jsonl.

Emits one JSON line per recovered Gunkel list, in the ideonomy repo's
Ideolist schema with a `source` provenance block (tier "canon"). Rules:

- every <ol>/<ul> block is a candidate; its name is the nearest preceding
  heading (<h1-6>, else trailing <b>/<strong> within 300 chars, else <title>)
- navigation is dropped two ways: known nav/index pages are skipped outright,
  and link-heavy blocks (>60% linked items) are kept only when their link
  text is substantive (median length >= 12 chars — e.g. the "What Ideonomy
  Can Do" section titles are canon; "pic001 / Next" wrappers are not)
- kept if >=10 items, or >=5 when the heading carries a count (numbered list)
- exact-duplicate item-sets across pages are emitted once
"""
import html
import json
import pathlib
import re
import sys

PAGES = pathlib.Path(__file__).parent / "raw" / "wayback" / "pages.jsonl"
OUT = pathlib.Path(__file__).parents[2] / "ideonomy" / "data" / "canon-wayback.jsonl"

TAG = re.compile(r"<[^>]+>")


def clean(s: str) -> str:
    return re.sub(r"\s+", " ", html.unescape(TAG.sub(" ", s))).strip()


def slug(s: str, limit: int = 64) -> str:
    s = s.split("(")[0]                      # drop count parentheticals
    return re.sub(r"[^a-z0-9]+", "-", s.lower()).strip("-")[:limit].strip("-")


NAV_PAGE = re.compile(r"(^|/)(index|mds|legacy-index)\.html$|menu", re.I)


records, seen = [], set()
for page in sorted(map(json.loads, PAGES.read_text(encoding="utf-8").splitlines()), key=lambda r: r["path"]):
    if not page["path"].endswith(".html"):
        continue
    t = page["html"]
    rel = page["path"]
    if NAV_PAGE.search(rel):
        continue
    title = clean((re.search(r"<title>(.*?)</title>", t, re.S | re.I) or [None, ""])[1])
    h1 = re.search(r"<h\d[^>]*>(.*?)</h\d>", t, re.S | re.I)
    page_head = clean(h1.group(1)) if h1 else title
    n = 0
    for m in re.finditer(r"<[ou]l[^>]*>(.*?)</[ou]l>", t, re.S | re.I):
        body = m.group(1)
        before = t[max(0, m.start() - 300):m.start()]
        head = ""
        hm = re.finditer(r"<(h\d|b|strong)\b[^>]*>(.*?)</\1>", before, re.S | re.I)
        for cand in reversed([clean(x.group(2)) for x in hm]):
            if len(cand) >= 4 and not re.search(r"back to|homepage", cand, re.I):
                head = cand
                break
        head = head or page_head or title or pathlib.Path(rel).stem
        raw_items = re.split(r"<li\b[^>]*>", body, flags=re.I)[1:]
        if not raw_items:
            continue
        linky = sum(1 for r in raw_items if re.search(r"<a\s", r, re.I))
        items = [clean(r.split("</li>")[0] if "</li>" in r.lower() else r) for r in raw_items]
        items = [re.sub(r"\s*Back to the Homepage\s*$", "", i) for i in items]
        items = [i for i in items if i and len(i) < 400]
        if not items:
            continue
        if linky / len(raw_items) > 0.6:
            lens = sorted(len(i) for i in items)
            if lens[len(lens) // 2] < 12:
                continue
        numbered = bool(re.search(r"\d", head))
        if len(items) < (5 if numbered else 10):
            continue
        key = tuple(items)
        if key in seen:
            continue
        seen.add(key)
        n += 1
        base = rel.removesuffix(".html").replace("/", ".")
        records.append({
            "name": f"{base}.{slug(head) or n}",
            "of": head,
            "items": items,
            "status": "open",
            "made_by": "extract(wayback-html)",
            "parents": [],
            "source": {
                "tier": "canon",
                "author": "Patrick Gunkel",
                "url": f"http://ideonomy.mit.edu/{rel}",
                "via": "web.archive.org",
                "page_title": title or page_head,
            },
        })

# uniquify any colliding names
counts = {}
for r in records:
    counts[r["name"]] = counts.get(r["name"], 0) + 1
    if counts[r["name"]] > 1:
        r["name"] += f"-{counts[r['name']]}"

OUT.parent.mkdir(parents=True, exist_ok=True)
with OUT.open("w") as f:
    for r in records:
        f.write(json.dumps(r, ensure_ascii=False) + "\n")

total = sum(len(r["items"]) for r in records)
print(f"wrote {len(records)} lists / {total} items -> {OUT}")
for r in sorted(records, key=lambda r: -len(r["items"]))[:12]:
    print(f'{len(r["items"]):5d}  {r["name"]}')
