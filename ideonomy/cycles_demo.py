"""Demonstration of the respiratory engine, in two honest parts.

    python3 -m ideonomy.cycles_demo

Part 1 — a corpus with genuine latent structure. The breath compresses it,
the MDL ratchet accepts improving breaths and reverts worsening ones, and the
residue is extracted as the next frontier. This proves the rhythm and that
the ratchet has teeth.

Part 2 — the reflexive run: the engine breathes over the organon's own
primitive glosses. These are lexically token-disjoint one-liners, so mechanical (no
model) compression correctly bottoms out — the ratchet refuses to pretend a
pile of singletons is structure, and the run reports that this corpus needs
the model hook to be compressed by meaning rather than by shared tokens.
That refusal is the conscientious result, not a failure.
"""

from __future__ import annotations

from . import cycles, primitives


def _bar(label: str, history: list[dict]) -> None:
    print(f"\n{label}")
    print(f"  {'cyc':>3} {'items':>5} {'add':>3} {'grp':>3} "
          f"{'codelen':>8} {'raw':>6} {'ratio':>6} {'resid':>5}  expansion")
    for r in history:
        print(f"  {r['cycle']:>3} {r['items']:>5} {r['added']:>3} {r['groups']:>3} "
              f"{r['codelen']:>8} {r['raw']:>6} {r['ratio']:>6} {r['residue']:>5}  "
              f"{r['expansion']}")


_FRONTIER = ["adam", "dropout", "quantize", "sharding", "replica", "cdn",
             "prefetch", "mmap", "etag", "backoff", "warmup", "pruning"]


def frontier_expand(state: cycles.State, comp, k: int) -> list:
    """A stand-in for a *good* (model) expansion: probe each cluster's frontier
    by extending its distilled rule with a fresh token — coherent items that
    join the structure. (The generic default crosses residue tokens instead and
    mostly produces noise the ratchet reverts; both behaviours are real.)"""
    if comp is None:
        return []
    out: list = []
    i = state.cycle
    for rule in comp.rule.values():
        if not rule:
            continue
        text = f"{' '.join(sorted(rule))} {_FRONTIER[i % len(_FRONTIER)]}"
        i += 1
        out.append(text)
        if len(out) >= k:
            break
    return out


def part1() -> None:
    # three clusters, each item = shared core + one unique token (the kind of
    # latent structure real corpora carry).
    cores = {
        "neural network training": ["convergence", "regularization", "checkpoint", "scheduler"],
        "database query index": ["btree", "planner", "vacuum", "lookup"],
        "http request caching": ["header", "policy", "routing", "revalidation"],
    }
    texts = [f"{core} {tail}" for core, tails in cores.items() for tail in tails]
    state = cycles.seed(texts)
    c0 = cycles.compress_mechanical(state)
    state.compression = c0
    state.residue = cycles.residue_extract(state, c0)
    print("PART 1 — corpus with latent structure")
    print(f"  seed: {len(state.corpus)} items, "
          f"initial compression {len(c0.groups)} groups, "
          f"ratio={cycles.raw_bits(state)/cycles.codelen(state, c0):.3f}")
    cycles.run(state, cycles=4, expand=frontier_expand)
    _bar("breath log (frontier expansion: items that join the structure are "
         "accepted; the ratchet holds the compression ratio):", state.history)


def part2() -> None:
    texts = [f"{p.name}: {p.gloss}" for p in primitives.PRIMITIVES]
    state = cycles.seed(texts)
    c0 = cycles.compress_mechanical(state)
    state.compression = c0
    state.residue = cycles.residue_extract(state, c0)
    ratio = cycles.raw_bits(state) / cycles.codelen(state, c0)
    singletons = sum(1 for ids in c0.groups.values() if len(ids) == 1)
    print(f"\n\nPART 2 — reflexive run over the organon's own "
          f"{len(primitives.PRIMITIVES)} primitives")
    print(f"  groups={len(c0.groups)} ({singletons} singletons), "
          f"ratio={ratio:.3f}, residue={len(state.residue)}")
    cycles.run(state, cycles=3)
    _bar("breath log:", state.history)
    verdict = ("lexical compression bottoms out (ratio <= 1): the glosses share "
               "almost no surface tokens, so the ratchet correctly refuses to "
               "claim structure. Wire a model expand/compress to compress these "
               "by meaning."
               if state.history[-1]["ratio"] <= 1.0 else
               "lexical compression found surface structure.")
    print(f"\n  verdict: {verdict}")


def main() -> None:
    part1()
    part2()


if __name__ == "__main__":
    main()
