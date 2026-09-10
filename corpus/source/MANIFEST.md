# Ideonomy corpus manifest

The coverage denominator for the Gunkel acquisition campaign
(`prove-the-coverage-denominator` applied to the corpus itself). Every known
source artifact is one of: **acquired**, **extracted** (structured data
produced), **partial**, **pending**, or **ruled-out** (with reason). The
campaign may not call itself complete while any row is unlabeled.

Acquired 2026-09-03. This directory is acquisition and extraction staging
for the canon tier in `data/`; list production (growth, widening,
seriation drivers and their ledgers) lives one level up in `corpus/`. Raw
scans and page renders are gitignored (`raw/ideonomy.mit.edu/`,
`raw/uh-mirror/*.pdf`, `raw/pageimg/`); the page renders regenerate with
`pdftoppm -png -r 300` from the UH-mirror PDF, and the scans plus the
pre-fold staging history are archived off-repo.

## A. ideonomy.mit.edu legacy archive (live site, mirrored)

| Artifact | Contents | Status |
|---|---|---|
| `raw/ideonomy.mit.edu/pdf/` | 6 PDFs: Orange, Blue, Green monographs; Yellow glossary; What Ideonomy Can Do; The Science of Ideas | acquired — **OCR done** (`extracted/ocr/`, per-page text); LLM structuring pending |
| `raw/ideonomy.mit.edu/png/` | 230 per-page PNGs (blue/green/orange/whatcan/yellow) | acquired — extraction pending |
| `raw/ideonomy.mit.edu/mapsandlists-set1/` | 122 full-size chart/list photos (+mediums, +wrappers) | **extracted** — all 403 charts transcribed 2026-09-03 (codex+gemini rails), promoted to repo `canon-charts.jsonl` |
| `raw/ideonomy.mit.edu/mapsandlists-set2/` | 226 full-size chart/list photos | **extracted** — see above |
| `raw/ideonomy.mit.edu/scanned-charts/` | 55 full-size chart photos | **extracted** — see above (2 illegible, labeled) |

Full-size coverage audited 2026-09-03: every `picNNN.html` wrapper has its
`picNNN.jpg` original (403/403). Total mirror 1.1 GB.

## B. Pre-redesign textual site (Wayback Machine)

| Artifact | Contents | Status |
|---|---|---|
| `raw/wayback/pages.jsonl` | 269 captures, one `{path, timestamp, html}` record each (all 301 tier-1 URLs, 0 failures): `/divisions/`, `/essays/`, `/investigable/`, `/analogy/`, `/maps/`, `/whatcan*/`, `/slides/`, top-level |  acquired; **extracted** — 19 lists / 1,931 items in the repo's `canon-wayback.jsonl` (the staging pass was a subset plus two site-navigation lists, not kept) |
| Non-`<li>` list matter on those pages | mds.html (144 items), tables, `<br>`-separated lists, ~169k words prose | partial — staging parser only caught `<ol>/<ul>` blocks ≥10 items |
| `/wiki/` (2,645 archived URLs) | Default MediaWiki install, no content ("MediaWiki has been successfully installed"; About page empty) | ruled-out — verified empty 2026-09-03 |
| `raw/wayback/ideonomy_cdx_full.txt` | Full CDX index (10,591 rows) | acquired — reference |

## C. University of Houston mirror (gnawali)

| Artifact | Contents | Status |
|---|---|---|
| `raw/uh-mirror/` | 16 PDFs: "23 Diverse Ideonomic Lists", "A Book of 3080 Random Character Trait-Thing Dyads", "Book Ideas", brain-hypotheses volumes, metacomputer papers, speculative physics, etc. | acquired — OCR done; **"23 Diverse" fully extracted** (23/23 lists, 2,748 items, vision+stitch, in repo `canon-monographs.jsonl`); rest pending |

## D. Other known sources

| Source | Contents | Status |
|---|---|---|
| gracekind.net/resources/gunkelpdfs/ | Same 5 monographs + Book_Ideas.pdf (duplicate of A/C holdings) | ruled-out as duplicate — spot-check before monograph OCR in case scans differ |
| MIT ArchivesSpace resource 1353 | Gunkel's physical papers | pending — not digitized; physical access only; revisit if the digitized corpus exhausts |
| thebeautyproject.site/gunkel-maps/ | Curated presentation of MDS maps | pending — check for cleaner map reproductions than set1/set2 photos |
| Morpheis/ideonomy-engine, latentwill/ideonomy-skill, kindgracekind/ideonomy-legacy | Derived works, no primary data beyond what is held here | ruled-out as sources (kept as related work in repo README) |

## Extraction pipeline status

1. Wayback HTML → structured lists: **repo-grade done** (19 lists / 1,931
   items in the repo's `canon-wayback.jsonl`; the earlier staging pass was
   an exact subset plus two site-navigation lists and is not kept).
   Remaining: non-`<li>` matter (DL glossaries, prose-embedded lists).
2. 403 chart photos → vision extraction: **done 2026-09-03** — 490 lists /
   26,578 items in the repo's `canon-charts.jsonl`, per-image provenance,
   legibility labels, rail recorded per record. Transcriptions: one JSONL
   per chart set in `extracted/charts/` (`{"image", ...}`; unparsed
   attempts kept as `{"image", "raw"}` for retry).
3. Monographs (6 + 16 PDFs) → OCR: **done 2026-09-03**, 3,266/3,266 pages
   (`extracted/ocr/<document>.jsonl`, one `{"page", "text"}` record per
   page, tesseract 300dpi; 163 near-blank chart pages flagged for the
   vision rail). LLM structuring into canon lists: pending.
4. Growth loop (grow → gate → admit → commit): active in the Ideonomy checkout,
   alongside the differentiated grown lists and offline atlas. The local
   publication checkpoint includes the portable drivers and ledgers; publication
   awaits approval of the proposed Harvest statement and terms.
