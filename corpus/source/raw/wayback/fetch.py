"""Polite Wayback fetcher: reads 'timestamp url' lines, saves id_ raw captures."""
import pathlib, sys, time, urllib.request, urllib.parse

root = pathlib.Path(__file__).parent
lines = [l.split(None, 1) for l in (root / "wb_tier1.txt").read_text().splitlines() if l.strip()]
done = fail = 0
for ts, url in lines:
    url = url.strip()
    p = urllib.parse.urlparse(url)
    rel = (p.path.lstrip("/") or "index.html")
    if rel.endswith("/"):
        rel += "index.html"
    out = root / "pages" / rel
    if out.exists():
        done += 1
        continue
    out.parent.mkdir(parents=True, exist_ok=True)
    wb = f"https://web.archive.org/web/{ts}id_/{url}"
    for attempt in range(3):
        try:
            req = urllib.request.Request(wb, headers={"User-Agent": "ideonomy-archive-mirror (contact: contact@exopriors.com)"})
            data = urllib.request.urlopen(req, timeout=45).read()
            out.write_bytes(data)
            done += 1
            break
        except Exception as e:
            if attempt == 2:
                print(f"FAIL {url}: {e}", flush=True)
                fail += 1
            else:
                time.sleep(8 * (attempt + 1))
    time.sleep(1.2)
print(f"done={done} fail={fail} of {len(lines)}")
