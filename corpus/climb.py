"""The list hill-climb: Gunkel's progressive loop, machine-run.

One breath per list per invocation:

  1. GROW      (cheap tier)   propose k items along neglected dimensions
  2. TYPOLOGY  (strong tier)  induce types over the list; name missing and
                              underpopulated types — the climb's gradient
  3. GAP-FILL  (cheap tier)   targeted growth per named gap
  4. GATE      (strong tier)  judge every candidate: genuine category,
                              distinct, combinatorially phrased; drops are
                              recorded residue, not silence
  5. RATCHET                  keep-rate below threshold => plateau flagged;
                              the list stops claiming easy growth

Grown lists carry source.tier == "grown" and never masquerade as canon.
State compounds in ideonomy/data/grown.jsonl (the database's growing edge)
plus a per-list ledger in corpus/climb-ledger. Set GEMINI_API_KEY in the
environment before running; model calls use the configured account's quota.

    python3 corpus/climb.py                  # one breath over every seeded domain
    python3 corpus/climb.py --only strategy-generic-moves --breaths 2
    python3 corpus/climb.py --forever        # continuous: leaky-bucket-paced gradient ascent

Continuous mode is the calendar-free shape: spend level is a decayed sum
over the climb ledger's own timestamps (level = sum exp(-age/tau); the log
is the ledger, no second store, restart-safe). A breath is admitted when
level <= burst - 1; each admitted breath goes to the argmax-gradient
target (last keep_rate, cold starts optimistic at 1.0, ties to the
stalest list). Plateaued lists aren't banned — they compete with their
real low gradient and only win when nothing better exists. Saturated =>
sleep exactly the drain horizon tau*ln(level/(burst-1)). Sustained rate
= burst/tau breaths per hour. Run exactly one grower at a time; crashes
are the supervisor's job (the level survives restarts by construction).
"""
import argparse
from datetime import datetime
import json
import math
import os
import pathlib
import sys
import time
import urllib.request

ROOT = pathlib.Path(__file__).resolve().parent
REPO = ROOT.parent
GROWN = REPO / "ideonomy" / "data" / "grown.jsonl"
LEDGER = ROOT / "climb-ledger"
sys.path.insert(0, str(REPO))

from ideonomy.lists import Ideolist  # noqa: E402

CHEAP = "gemini-3-flash-preview"
STRONG = "gemini-3.1-pro-preview"
PLATEAU_KEEP_RATE = 0.25


def _key() -> str:
    if os.environ.get("GEMINI_API_KEY"):
        return os.environ["GEMINI_API_KEY"]
    raise SystemExit("Set GEMINI_API_KEY in the environment before running this driver")


def ask(model: str, prompt: str, want_json: bool = False, retries: int = 3):
    body = {"contents": [{"parts": [{"text": prompt}]}]}
    if want_json:
        body["generationConfig"] = {"responseMimeType": "application/json"}
    req = urllib.request.Request(
        f"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={_key()}",
        data=json.dumps(body).encode(), headers={"Content-Type": "application/json"})
    for attempt in range(retries):
        try:
            with urllib.request.urlopen(req, timeout=180) as r:
                out = json.load(r)
            text = out["candidates"][0]["content"]["parts"][0]["text"]
            return json.loads(text) if want_json else text
        except Exception as e:                       # noqa: BLE001 — retry then surface
            if attempt == retries - 1:
                raise
            time.sleep(10 * (attempt + 1))


# ---------------------------------------------------------------- seeds
def seed_lists():
    S = [
        ("strategy-generic-moves",
         "a generic strategic move available to any agent in a contested field, phrased as a verb phrase",
         ["Concentrate force at the decisive point", "Trade space for time",
          "Threaten two objectives with one motion", "Deny the opponent tempo by forcing responses",
          "Change the game's boundaries rather than the position", "Commit last, after the opponent reveals",
          "Build optionality before committing force", "Escalate to de-escalate",
          "Encircle the objective to cut reinforcement", "Force a bifurcation where every branch costs the opponent"]),
        ("somatic-signals",
         "a bodily state or signal that carries decision-relevant information, phrased as a noun phrase",
         ["The tightening chest before an overcommitment", "The exhale that precedes genuine agreement",
          "Grounded weight in the feet under pressure", "The forward lean of premature closure",
          "The gut drop of a wrong decision recognized late", "The jaw set of an unvoiced objection",
          "The softened gaze of real listening", "Breath held while hearing a half-truth",
          "The energizing clarity after a true decision", "Restlessness signaling an unnamed tension"]),
        ("mathematical-moves",
         "a generic mathematical move that transforms a problem into a more tractable one, phrased as a verb phrase",
         ["Pass to the dual", "Quotient out the symmetry", "Linearize around a fixed point",
          "Compactify the space", "Introduce a generating function", "Exchange the order of summation",
          "Find the conserved quantity", "Relax to a continuous problem, then round",
          "Lift to a covering space", "Diagonalize", "Take the adjoint",
          "Add a dimension to separate the crossings"]),
        ("invariant-kinds",
         "a kind of invariant — a quantity or structure preserved under a class of transformations, phrased as a noun phrase",
         ["Energy under time translation", "Parity under exchange", "Topological genus under deformation",
          "Rank under row operations", "Trace under conjugation", "The loop invariant under iteration",
          "Type under program refactoring", "Measure under measure-preserving maps",
          "Euler characteristic under triangulation", "Information under lossless encoding"]),
        ("tactical-maneuvers",
         "a generic tactical maneuver executable within a single engagement, phrased as a verb phrase",
         ["Feint on one axis, strike on another", "Refuse the flank", "Draw the commitment, then counter",
          "Attack the seam between two responsibilities", "Commit the second wave while the first absorbs",
          "Cut the communication line before the assault", "Present a false weakness",
          "Overload one axis to unmask another", "Withdraw under cover to a prepared position",
          "Time the strike to the opponent's rotation"]),
        ("operational-patterns",
         "a generic operational pattern for sustaining a campaign over time, phrased as a noun phrase",
         ["Rotation of fresh units through the front", "Forward staging of supplies before a tempo increase",
          "Parallel lines of advance with mutual support", "The operational pause to consolidate gains",
          "Awareness of the culminating point before overextension", "Interior lines exploited for faster reinforcement",
          "Logistics throughput as the true rate limiter", "The reserve committed only at the breakthrough",
          "Sequenced objectives, each enabling the next", "A sustainment rhythm matched to burn rate"]),
        ("first-mover-forecloses",
         "a first-mover action that forecloses the responder's best options, phrased as a verb phrase",
         ["Seize the standard before rivals coordinate", "Lock the scarce input with long-term contracts",
          "Define the category in the audience's mind first", "Occupy the high ground that cannot be contested twice",
          "Set the default that inertia will protect", "Recruit the key talent before the market prices them",
          "File the patent that blocks the design space", "Establish the marketplace whose liquidity self-reinforces",
          "Ship the interface others build upon", "Choose the battlefield before the opponent knows there is one"]),
        ("cooperation-mechanisms",
         "a mechanism that makes cooperation stable among self-interested parties, phrased as a noun phrase",
         ["Repeated interaction with a long shadow of the future", "Mutual vulnerability deliberately exchanged",
          "Reputation legible to future partners", "Escrow held by a neutral third party",
          "Tit-for-tat with forgiveness", "Costly signaling of commitment",
          "Shared fate through cross-shareholding", "Verification protocols in place of trust",
          "Focal points that coordinate without communication", "Graduated sanctions within a monitored commons"]),
        ("persuasion-moves",
         "a move that legitimately shifts a person's belief or decision, phrased as a verb phrase",
         ["Steelman their position before answering it", "Let them derive the conclusion themselves",
          "Convert the abstract claim into a concrete case", "Name the shared value the proposal serves",
          "Show the cost of the status quo, not only the gain of change", "Offer a reversible first step",
          "Cite the evidence they already trust", "Make the desired path the easy path",
          "Acknowledge uncertainty to earn credibility on the certain part",
          "Ask the question whose honest answer is the argument"]),
        ("deal-flow-sources",
         "a source or mechanism that generates a stream of potential deals, phrased as a noun phrase",
         ["Referral loops from past counterparties", "Content that makes buyers self-identify",
          "The broker network paid on completion", "Auctions watched for mispriced lots",
          "Cold outreach sequenced by trigger events", "The community whose members trade with each other first",
          "Distressed-asset lists from lenders", "Conference corridors after the panels",
          "Inbound generated by published expertise", "Partnerships with those upstream of the need"]),
        ("psyop-patterns",
         "a generic pattern by which an influence operation shapes an audience's perception (catalogued for recognition and defense), phrased as a noun phrase",
         ["The repeated claim mistaken for the verified one", "Flooding the channel to drown the signal",
          "The manufactured consensus of coordinated voices", "Framing the question so every answer concedes it",
          "The leak timed to eclipse the inconvenient story", "The trusted-messenger relay of untrusted content",
          "Ambiguity preserved to enable deniability", "The divided audience turned against itself",
          "Prestige transferred from the credible host", "The false middle positioned between two engineered extremes"]),
    ]
    return {name: Ideolist(name=name, of=of, items=items,
                           made_by="seed(xyra-domains-2026-09-04)",
                           source={"tier": "grown", "via": "human seed"})
            for name, of, items in S}


# ---------------------------------------------------------------- store
def load_grown() -> dict:
    out = {}
    if GROWN.exists():
        for line in GROWN.read_text().splitlines():
            if line.strip():
                l = Ideolist.from_dict(json.loads(line))
                out[l.name] = l
    return out


def save_grown(lists_: dict) -> None:
    GROWN.parent.mkdir(parents=True, exist_ok=True)
    with GROWN.open("w") as f:
        for name in sorted(lists_):
            if not lists_[name].items:      # untouched cold-started specs don't persist
                continue
            f.write(json.dumps(lists_[name].to_dict(), ensure_ascii=False) + "\n")


# ---------------------------------------------------------------- breath
def breath(lst: Ideolist) -> Ideolist:
    have = list(lst.items)
    shown = "\n".join(f"- {x}" for x in have)
    frame = f"Each item is: {lst.of}.\n"
    for field in ("register", "mode", "boundary_claim"):
        if field in (lst.source or {}):
            frame += f"{field}: {json.dumps(lst.source[field], ensure_ascii=False)}\n"

    # 1. GROW (cheap)
    g = ask(CHEAP,
            f"Extend this list. {frame}"
            f"Existing items:\n{shown}\n\n"
            "Offer up to 15 distinct additions, one per line, no numbering or commentary. "
            "Try a changed scale, reversal, remote analogy, or overlooked intermediate; "
            "follow the move that reveals something. Match the register and conceptual "
            "grain. A memorable name must carry a definite distinction, not just rename "
            "an existing member.")
    cand = [x.strip(" -*\t") for x in g.splitlines() if x.strip()]

    # 2. TYPOLOGY (strong) — the gradient
    t = ask(STRONG,
            f"{frame}Existing items:\n{shown}\n\n"
            "Induce the most revealing typology these items support. Then name "
            "neglected or underpopulated types within the same item kind. Prefer "
            "gaps that would change how the field is understood, not simply add "
            "easy examples. Put the most fertile gaps first. Reply as JSON: "
            '{"types": [{"name": str, "members": int}], "missing_types": [str], '
            '"underpopulated_types": [str]}', want_json=True)
    gaps = (t.get("missing_types", []) + t.get("underpopulated_types", []))[:3]

    # 3. GAP-FILL (cheap, targeted)
    for gap in gaps:
        g2 = ask(CHEAP,
                 f"{frame}Existing items:\n{shown}\n\n"
                 f"The list neglects this type: {gap}\n"
                 "Offer up to 6 distinct additions of that type. Let an unusual "
                 "case refine the distinction. One per line, no numbering or "
                 "commentary, matching the register and conceptual grain.")
        cand += [x.strip(" -*\t") for x in g2.splitlines() if x.strip()]

    lower = {x.casefold() for x in have}
    cand = [c for c in cand if c and c.casefold() not in lower]

    # 4. GATE (strong)
    judged = ask(STRONG,
                 f"You are sharpening a curated list. {frame}"
                 f"Existing list:\n{shown}\n\nCandidates:\n"
                 + "\n".join(f"{i}. {c}" for i, c in enumerate(cand))
                 + "\n\nFor each candidate judge: KEEP only if it is (a) a recognizable "
                 "member with a definite distinction, including speculative or humorous "
                 "members when the declared register permits; (b) distinct from every "
                 "existing and other kept item, not a rephrasing; (c) phrased in the "
                 "list's register and grain. Judge the offered mechanism, not a safer "
                 "substitute. A declared possibility is not a claim of established fact. "
                 'Reply as JSON: {"verdicts": [{"i": int, "keep": bool, "why": str}]}',
                 want_json=True)
    keep, residue = [], []
    for v in judged.get("verdicts", []):
        i = v.get("i")
        if isinstance(i, int) and 0 <= i < len(cand):
            (keep if v.get("keep") else residue).append((cand[i], v.get("why", "")))

    # 5. RATCHET + PERSIST
    rate = len(keep) / max(1, len(cand))
    source = dict(lst.source or {})
    for field in ("seriation", "coverage", "gate", "exploration",
                  "priorities", "primitives_exercised"):
        source.pop(field, None)
    source.update(tier="grown", via=f"climb.py grow={CHEAP} judge={STRONG}",
                  typology=t.get("types", []), gaps_targeted=gaps,
                  plateau=rate < PLATEAU_KEEP_RATE)
    out = Ideolist(
        name=lst.name, of=lst.of, items=have + [k for k, _ in keep],
        status="open", made_by=f"climb(breath keep_rate={rate:.2f})",
        parents=[lst.name],
        source=source)
    LEDGER.mkdir(exist_ok=True)
    with (LEDGER / f"{lst.name}.jsonl").open("a") as f:
        f.write(json.dumps({
            "t": time.strftime("%Y-%m-%dT%H:%M:%S"),
            "before": len(have), "candidates": len(cand), "kept": len(keep),
            "keep_rate": round(rate, 3), "gaps": gaps,
            "residue": [{"item": r, "why": w} for r, w in residue],
        }, ensure_ascii=False) + "\n")
    print(f"  {lst.name}: {len(have)} -> {len(out.items)} "
          f"(cand {len(cand)}, keep_rate {rate:.2f}"
          f"{', PLATEAU' if rate < PLATEAU_KEEP_RATE else ''}) gaps: {gaps}")
    return out


def load_pool() -> dict:
    """Grown store + human seeds + widen.py specs (cold-started, of-only)."""
    grown = load_grown()
    for name, seeded in seed_lists().items():
        if name not in grown:
            grown[name] = seeded
    specs = REPO / "ideonomy" / "data" / "list-specs.jsonl"
    if specs.exists():
        for line in specs.read_text().splitlines():
            if not line.strip():
                continue
            s = json.loads(line)
            if s["name"] not in grown:
                grown[s["name"]] = Ideolist(
                    name=s["name"], of=s["of"], items=[],
                    made_by="spec(widen.py)",
                    source={"tier": "grown", "via": "widen.py spec, cold-started"})
    return grown


# ---------------------------------------------------------------- continuous
def last_breath(name: str):
    """(keep_rate, epoch) of the list's most recent breath; optimistic cold start."""
    path = LEDGER / f"{name}.jsonl"
    if not path.exists():
        return 1.0, 0.0
    for line in reversed(path.read_text().splitlines()):
        e = json.loads(line)
        if e.get("by") != "fable-regate":     # survival rate is not growth yield
            return e["keep_rate"], datetime.fromisoformat(e["t"]).timestamp()
    return 1.0, 0.0


def ledger_level(tau_s: float) -> float:
    """Decayed breath count over the whole ledger — the spend level."""
    now = time.time()
    level = 0.0
    for path in LEDGER.glob("*.jsonl"):
        for line in path.read_text().splitlines():
            if line.strip():
                t = datetime.fromisoformat(json.loads(line)["t"]).timestamp()
                level += math.exp(-(now - t) / tau_s)
    return level


def pick_target(grown: dict) -> str:
    """Argmax gradient: highest last keep_rate, ties to the stalest list."""
    return max(grown, key=lambda n: (last_breath(n)[0], -last_breath(n)[1]))


def forever(burst: float, tau_hours: float) -> None:
    tau_s = tau_hours * 3600
    print(f"continuous climb: burst {burst}, tau {tau_hours}h "
          f"(sustained {burst / tau_hours:.2f} breaths/h)")
    while True:
        level = ledger_level(tau_s)
        if level > burst - 1:
            horizon = tau_s * math.log(level / (burst - 1))
            print(f"  level {level:.2f}/{burst} — draining {horizon / 60:.0f}m")
            time.sleep(horizon)
            continue
        grown = load_pool()          # re-read each breath: widen feeds climb live
        name = pick_target(grown)
        grown[name] = breath(grown[name])
        save_grown(grown)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--only", default="")
    ap.add_argument("--breaths", type=int, default=1)
    ap.add_argument("--forever", action="store_true",
                    help="continuous leaky-bucket-paced gradient ascent")
    ap.add_argument("--burst", type=float, default=6.0)
    ap.add_argument("--tau-hours", type=float, default=6.0)
    args = ap.parse_args()

    if args.forever:
        forever(args.burst, args.tau_hours)
        return

    grown = load_pool()
    targets = [n for n in grown if not args.only or n == args.only]

    for b in range(args.breaths):
        print(f"breath {b + 1}/{args.breaths}")
        for name in targets:
            if grown[name].source and grown[name].source.get("plateau"):
                print(f"  {name}: plateaued, skipping")
                continue
            grown[name] = breath(grown[name])
            save_grown(grown)
    total = sum(len(l.items) for l in grown.values())
    print(f"grown store: {len(grown)} lists / {total} items -> {GROWN}")


if __name__ == "__main__":
    main()
