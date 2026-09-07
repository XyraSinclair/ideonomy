"""OCR campaign: all scanned Gunkel PDFs -> per-page text, resumable.

Two-stage doctrine: cheap local OCR for every page now; pages whose OCR is
sparse (charts, handwriting) get routed to the vision rail later. Runs
nice'd; page PNGs are transient.

    python3 ocr_monographs.py [--workers 4]
"""
import argparse
import concurrent.futures
import pathlib
import subprocess
import tempfile

ROOT = pathlib.Path(__file__).parent
OUT = ROOT / "extracted" / "ocr"
PDF_DIRS = [ROOT / "raw" / "ideonomy.mit.edu" / "pdf", ROOT / "raw" / "uh-mirror"]


def pages_of(pdf: pathlib.Path) -> int:
    info = subprocess.run(["pdfinfo", str(pdf)], capture_output=True, text=True)
    for line in info.stdout.splitlines():
        if line.startswith("Pages:"):
            return int(line.split()[1])
    return 0


def ocr_pdf(pdf: pathlib.Path) -> str:
    stem = pdf.stem.replace(" ", "_")
    outdir = OUT / stem
    outdir.mkdir(parents=True, exist_ok=True)
    n = pages_of(pdf)
    done = 0
    with tempfile.TemporaryDirectory() as tmp:
        for p in range(1, n + 1):
            txt = outdir / f"page{p:03d}.txt"
            if txt.exists():
                done += 1
                continue
            base = pathlib.Path(tmp) / f"p{p}"
            subprocess.run(["nice", "-n", "19", "pdftoppm", "-png", "-r", "300",
                            "-f", str(p), "-l", str(p), str(pdf), str(base)],
                           capture_output=True)
            pngs = sorted(pathlib.Path(tmp).glob(f"p{p}-*.png"))
            if not pngs:
                txt.write_text("")   # rasterization failed; mark visited
                continue
            subprocess.run(["nice", "-n", "19", "tesseract", str(pngs[0]),
                            str(txt.with_suffix(""))], capture_output=True)
            pngs[0].unlink(missing_ok=True)
            if not txt.exists():
                txt.write_text("")
            done += 1
    return f"{stem}: {done}/{n} pages"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--workers", type=int, default=4)
    args = ap.parse_args()
    pdfs = sorted(p for d in PDF_DIRS for p in d.glob("*.pdf"))
    with concurrent.futures.ThreadPoolExecutor(args.workers) as ex:
        for res in ex.map(ocr_pdf, pdfs):
            print(res, flush=True)
    print("ocr campaign complete")


if __name__ == "__main__":
    main()
