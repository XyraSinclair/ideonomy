"""Vision-extraction campaign: 403 full-size Gunkel chart photos -> JSON.

Resumable: skips images whose output JSON already exists and parses. Each
image goes through codexpool (read-only sandbox) with a strict
transcribe-verbatim prompt; parse failures are kept as .raw.txt for retry.

    python3 extract_charts.py [--workers 4] [--limit N]
"""
import argparse
import concurrent.futures
import json
import pathlib
import re
import subprocess
import sys

ROOT = pathlib.Path(__file__).parent
RAW = ROOT / "raw" / "ideonomy.mit.edu"
OUT = ROOT / "extracted" / "charts"
CODEX = pathlib.Path.home() / ".codexpool" / "bin" / "codex"
SETS = ["mapsandlists-set1", "mapsandlists-set2", "scanned-charts"]
RAIL = "codex"
DIRS: list = []

PROMPT = """\
Transcribe the attached photographed chart from Patrick Gunkel's ideonomy archive. Output ONLY a JSON object, no prose, no code fences:
{"title": str, "kind": "list"|"mds-map"|"matrix"|"diagram"|"other", "legibility": "full"|"partial"|"illegible", "lists": [{"name": str, "of": "what one item is", "items": [str,...]}], "notes": str}
Transcribe verbatim - preserve wording and capitalization, do not invent or complete items you cannot read; omit unreadable items and set legibility accordingly. For an MDS map or radial diagram, transcribe the labels as one list.
"""


def images():
    if DIRS:
        for d in DIRS:
            for p in sorted((ROOT / d).glob("*.png")) + sorted((ROOT / d).glob("*.jpg")):
                yield pathlib.Path(d).name, p
        return
    for s in SETS:
        for p in sorted((RAW / s).glob("pic*.jpg")):
            if "-medium" in p.name or "-small" in p.name:
                continue
            yield s, p


def parse_json(text: str):
    j = text.rfind("}")
    if j < 0:
        return None
    starts = [m.start() for m in re.finditer(r"^\s*\{", text, re.M)]
    for i in reversed(starts):
        try:
            return json.loads(text[i:j + 1])
        except json.JSONDecodeError:
            continue
    return None


def one(job):
    set_name, img = job
    out = OUT / set_name / (img.stem + ".json")
    out.parent.mkdir(parents=True, exist_ok=True)
    if out.exists():
        return "skip"
    if RAIL == "gemini":
        cmd = ["consult-gemini", "-p",
               PROMPT + " @" + str(img.relative_to(ROOT))]
        kw = dict(capture_output=True, text=True, timeout=420, cwd=str(ROOT))
    else:
        cmd = [str(CODEX), "exec", "--sandbox", "read-only", "--skip-git-repo-check",
               "-m", "gpt-5.6-sol", "-c", 'model_reasoning_effort="low"',
               "-i", str(img), "-"]
        kw = dict(input=PROMPT, capture_output=True, text=True, timeout=420, cwd="/tmp")
    try:
        r = subprocess.run(cmd, **kw)
    except subprocess.TimeoutExpired:
        return f"timeout {img.name}"
    rec = parse_json(r.stdout)
    if rec is None or "title" not in rec:
        out.with_suffix(".raw.txt").write_text(r.stdout + "\n--STDERR--\n" + r.stderr[-2000:])
        return f"unparsed {img.name}"
    rec["source_image"] = f"https://ideonomy.mit.edu/{set_name}/{img.name}"
    rec["rail"] = RAIL
    out.write_text(json.dumps(rec, indent=1, ensure_ascii=False))
    n = sum(len(l.get("items", [])) for l in rec.get("lists", []))
    return f"ok {set_name}/{img.name} [{rec.get('legibility')}] {n} items"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--workers", type=int, default=4)
    ap.add_argument("--limit", type=int, default=0)
    ap.add_argument("--rail", choices=["codex", "gemini"], default="codex")
    ap.add_argument("--dirs", default="", help="comma-separated image dirs relative to corpus root (overrides chart sets)")
    args = ap.parse_args()
    global RAIL, DIRS
    RAIL = args.rail
    DIRS = [d for d in args.dirs.split(",") if d]
    jobs = list(images())
    if args.limit:
        jobs = jobs[:args.limit]
    done = fails = 0
    with concurrent.futures.ThreadPoolExecutor(args.workers) as ex:
        for res in ex.map(one, jobs):
            if res == "skip":
                continue
            done += 1
            if not res.startswith("ok"):
                fails += 1
            print(res, flush=True)
    print(f"campaign pass complete: {done} processed, {fails} failed, {len(jobs)} total")


if __name__ == "__main__":
    main()
