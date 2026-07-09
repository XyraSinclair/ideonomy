"""The respiratory engine: expand <-> compress breaths with an MDL ratchet.

Substrate-agnostic. A corpus is text items; expand/judge/compress are
pluggable functions; the two-part minimum-description-length code decides
whether each breath is kept. Mechanical defaults run with no model so the
rhythm is testable offline; model hooks deepen every phase.

Design: CYCLES.md.
"""

from __future__ import annotations

import math
import re
from collections.abc import Callable
from dataclasses import dataclass, field
from typing import Any, Optional

_STOP = {"a", "an", "and", "are", "as", "at", "be", "by", "for", "from", "in",
         "is", "it", "of", "on", "or", "the", "to", "with", "that", "this"}

# Cost (in token-equivalents) of a dictionary pointer into the structure: a
# group label is just an index, not a fresh symbol, so it is cheap. This is
# the only free parameter in the code length; it is deliberately small.
LABEL_BITS = 1.0


def tokens(text: str) -> set[str]:
    return {w for w in re.findall(r"[a-z0-9]+", text.lower()) if w not in _STOP}


# --------------------------------------------------------------------- state
@dataclass
class Item:
    id: str
    text: str
    born: int = 0           # cycle it entered the corpus
    source: str = "seed"    # seed | expand:<op> | ...


@dataclass
class Compression:
    """A structure that explains the corpus: groups, each with a distilled rule."""

    groups: dict[str, list[str]]      # label -> member item ids
    rule: dict[str, set[str]]         # label -> shared-token invariant (distillation)

    def model_bits(self) -> float:
        """L(structure): cost to write the structure down.

        Only non-empty rules are structure. A singleton group carries an empty
        rule and contributes nothing here — it is an unexplained item, encoded
        raw in the data term, not a compression claim.
        """
        return sum(LABEL_BITS + len(toks) for toks in self.rule.values() if toks)


@dataclass
class State:
    corpus: dict[str, Item]
    compression: Compression | None = None
    residue: list[str] = field(default_factory=list)   # item ids handed forward
    history: list[dict[str, Any]] = field(default_factory=list)
    cycle: int = 0
    _next: int = 0

    def add(self, text: str, source: str) -> str:
        iid = f"i{self._next}"
        self._next += 1
        self.corpus[iid] = Item(id=iid, text=text, born=self.cycle, source=source)
        return iid


# ------------------------------------------------------- MDL: the ratchet
def data_bits(item: Item, rule: set[str]) -> float:
    """L(item | rule): tokens of the item not predicted by its group's rule.

    Symmetric difference: tokens the rule promised but the item lacks, plus
    tokens the item carries that the rule did not capture. Both are residual.
    """
    toks = tokens(item.text)
    if not rule:
        return float(len(toks) or 1)            # raw-encoded: no structure claimed
    # tokens the rule failed to predict, plus tokens the rule wrongly promised,
    # plus a small pointer into the dictionary for the group.
    return float(len(toks ^ rule)) + LABEL_BITS


def codelen(state: State, comp: Compression) -> float:
    """Two-part code length: L(structure) + sum L(item | structure)."""
    member_of = {iid: lbl for lbl, ids in comp.groups.items() for iid in ids}
    total = comp.model_bits()
    for iid, item in state.corpus.items():
        lbl = member_of.get(iid)
        total += data_bits(item, comp.rule.get(lbl, set()) if lbl else set())
    return total


def raw_bits(state: State) -> float:
    """Codelen with no structure — the corpus encoded item by item."""
    return sum(float(len(tokens(it.text)) or 1) for it in state.corpus.values())


# ----------------------------------------------- mechanical phase defaults
def compress_mechanical(state: State, threshold: float = 0.45) -> Compression:
    """COMPRESS (P6/P7/P8/distill): greedy agglomeration by token coverage;
    each group's rule is the majority-shared token set (the distilled invariant).

    Similarity is coverage — the fraction of the new item's tokens the cluster
    vocabulary already holds — not Jaccard, so large clusters are not penalised
    by their growing vocabulary's effect on a union denominator.
    """
    ids = list(state.corpus)
    reps: dict[str, set[str]] = {}               # label -> accumulated cluster tokens
    groups: dict[str, list[str]] = {}
    for iid in ids:
        toks = tokens(state.corpus[iid].text)
        best, best_sim = None, 0.0
        for lbl, acc in reps.items():
            sim = len(toks & acc) / (len(toks) or 1)
            if sim > best_sim:
                best, best_sim = lbl, sim
        if best is not None and best_sim >= threshold:
            groups[best].append(iid)
            reps[best] |= toks                   # the cluster's vocabulary grows
        else:
            lbl = f"g{len(reps)}"
            reps[lbl] = set(toks)
            groups[lbl] = [iid]
    # distill each group's rule (P-distill): tokens shared by >= half its
    # members. Singletons get an empty rule — one item is not yet structure.
    rule: dict[str, set[str]] = {}
    for lbl, members in groups.items():
        if len(members) < 2:
            rule[lbl] = set()
            continue
        counts: dict[str, int] = {}
        for iid in members:
            for t in tokens(state.corpus[iid].text):
                counts[t] = counts.get(t, 0) + 1
        # MDL-optimal rule: include a token iff a strict majority of members
        # carry it (then including saves more residual than it costs).
        need = len(members) // 2 + 1
        rule[lbl] = {t for t, c in counts.items() if c >= need}
    return Compression(groups=groups, rule=rule)


def residue_extract(state: State, comp: Compression, quantile: float = 0.7) -> list[str]:
    """RESIDUE: items whose per-item data cost is in the top tail, plus
    singleton groups (structure that failed to generalize).

    A flat cost distribution has no tail: when every item resists equally,
    nothing resists *more*, so nothing is residue — items at the global
    minimum are excluded so ties cannot flood the seed with the whole corpus.
    """
    member_of = {iid: lbl for lbl, ids in comp.groups.items() for iid in ids}
    costs = {
        iid: data_bits(it, comp.rule.get(member_of.get(iid, ""), set()))
        for iid, it in state.corpus.items()
    }
    if not costs:
        return []
    ordered = sorted(costs.values())
    cut = ordered[min(len(ordered) - 1, int(quantile * len(ordered)))]
    floor = ordered[0]
    res = [iid for iid, c in costs.items() if c >= cut and c > floor]
    singletons = [ids[0] for ids in comp.groups.values() if len(ids) == 1]
    return sorted(set(res) | set(singletons))


def expand_mechanical(state: State, comp: Compression | None, k: int = 6) -> list[str]:
    """EXPAND (P12 combine), biased toward the residue: cross residue tokens
    with corpus tokens to phrase frontier probes. Mechanical stand-in for a
    model probing the unexplained; deterministic (no RNG) by construction."""
    seeds = state.residue or list(state.corpus)
    res_tokens: list[str] = []
    for iid in seeds:
        res_tokens.extend(sorted(tokens(state.corpus[iid].text)))
    pool: list[str] = []
    for iid in state.corpus:
        pool.extend(sorted(tokens(state.corpus[iid].text)))
    seen = {it.text for it in state.corpus.values()}
    out: list[str] = []
    for i, a in enumerate(res_tokens):
        for b in pool[i::max(1, len(res_tokens))]:
            if a == b:
                continue
            text = f"{a} {b}"
            if text not in seen and text not in out:
                out.append(text)
            if len(out) >= k:
                return out
    return out


def judge_mechanical(state: State, candidates: list[str]) -> list[str]:
    """JUDGE/FILTER (P18): drop candidates that duplicate or are near-subsets
    of existing corpus items."""
    existing = [tokens(it.text) for it in state.corpus.values()]
    kept: list[str] = []
    for text in candidates:
        toks = tokens(text)
        if not toks:
            continue
        if any(toks <= e or len(toks & e) / (len(toks | e) or 1) >= 0.9 for e in existing):
            continue
        kept.append(text)
    return kept


# ------------------------------------------------------------- the breath
Expand = Callable[[State, Optional[Compression], int], list]
Judge = Callable[[State, list], list]
Compress = Callable[[State], Compression]


def breath(state: State, *, expand: Expand = expand_mechanical,
           judge: Judge = judge_mechanical, compress: Compress = compress_mechanical,
           k: int = 6) -> dict[str, Any]:
    """One expand->judge->compress->measure->residue breath, with MDL ratchet.

    The expansion is accepted only if it does not worsen the two-part code
    length; on regression the new items are rolled back and the breath is
    recorded as a failed expansion (logged, never hidden).
    """
    state.cycle += 1
    prev_comp = state.compression
    prev_len = codelen(state, prev_comp) if prev_comp else 0.0
    prev_ratio = (raw_bits(state) / prev_len) if prev_len else 1.0
    snapshot = set(state.corpus)

    # breathe in
    candidates = expand(state, prev_comp, k)
    kept = judge(state, candidates)
    for text in kept:
        state.add(text, source=f"expand:c{state.cycle}")

    # breathe out
    comp = compress(state)
    new_len = codelen(state, comp)
    new_ratio = raw_bits(state) / new_len if new_len else 0.0

    # Ratchet on the compression RATIO, not absolute codelen: adding items
    # always raises absolute bits, so the scale-correct test is whether the
    # corpus still compresses at least as well — i.e. the new items were on
    # the frontier (joined the structure) rather than noise (inflated residue).
    accepted = prev_comp is None or new_ratio >= prev_ratio - 1e-9
    if not accepted:
        # roll back the expansion; keep the prior compression (P32).
        for iid in list(state.corpus):
            if iid not in snapshot:
                del state.corpus[iid]
        comp = compress(state)
        new_len = codelen(state, comp)

    state.compression = comp
    state.residue = residue_extract(state, comp)
    rec = {
        "cycle": state.cycle,
        "items": len(state.corpus),
        "added": len(kept) if accepted else 0,
        "groups": len(comp.groups),
        "codelen": round(new_len, 2),
        "raw": round(raw_bits(state), 2),
        "ratio": round(raw_bits(state) / new_len, 3) if new_len else 0.0,
        "residue": len(state.residue),
        "expansion": "accepted" if accepted else "reverted",
    }
    state.history.append(rec)
    return rec


def run(state: State, cycles: int = 5, **kw: Any) -> State:
    """Breathe until the budget is spent or compression plateaus (P30/P32)."""
    stale = 0
    for _ in range(cycles):
        prev = state.history[-1]["codelen"] if state.history else None
        rec = breath(state, **kw)
        if prev is not None and abs(rec["codelen"] - prev) < 0.5 and rec["added"] == 0:
            stale += 1
            if stale >= 2:
                break
        else:
            stale = 0
    return state


def seed(texts: list[str]) -> State:
    s = State(corpus={})
    for t in texts:
        s.add(t, source="seed")
    return s
