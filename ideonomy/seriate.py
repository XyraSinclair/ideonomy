"""Seriation: the order of a list as its own object of study.

Gunkel seriated lists by hand; gwern seriates by embedding-TSP. Here the
algebra is pure and the meaning is bound elsewhere: these operators take a
similarity matrix (from any source — embeddings, model judgments, counts)
and return orders and scores. A named axis is a *claim* about what the
order means; naming belongs to the caller (a model, a person), measuring
belongs here.

Three operators and one objective:

  spectral_order(sim)  — Fiedler-vector seriation: the second eigenvector
                         of the graph Laplacian, the classic archaeology
                         ordering; global, gap-revealing
  greedy_chain(sim)    — nearest-neighbor chaining from the loneliest
                         endpoint; local, fast, gwern-style
  smoothness(sim, o)   — mean adjacent similarity: lets orders compete
                         (a model-named axis order can be scored against
                         the spectral order on equal terms)
  best_order(sim)      — the smoothest of spectral, greedy, and reversal

Stdlib-pure by design (the package has no dependencies); n^2 power
iteration is ample for list-sized n.
"""
import math
import random


def cosine(u, v) -> float:
    dot = sum(a * b for a, b in zip(u, v))
    nu = math.sqrt(sum(a * a for a in u)) or 1.0
    nv = math.sqrt(sum(b * b for b in v)) or 1.0
    return dot / (nu * nv)


def sim_matrix(vectors) -> list:
    n = len(vectors)
    sim = [[0.0] * n for _ in range(n)]
    for i in range(n):
        sim[i][i] = 1.0
        for j in range(i + 1, n):
            sim[i][j] = sim[j][i] = cosine(vectors[i], vectors[j])
    return sim


def spectral_order(sim, iters: int = 500) -> list:
    """Order items by the Fiedler vector of the similarity graph's Laplacian.

    Power-iterates M = cI - L (which reverses L's spectrum), deflating the
    constant vector (L's trivial kernel), so the dominant remaining
    direction is the Fiedler vector. Deterministic."""
    n = len(sim)
    if n <= 2:
        return list(range(n))
    deg = [sum(row) - sim[i][i] for i, row in enumerate(sim)]
    c = 2.0 * max(deg) + 1.0
    rng = random.Random(4)                      # fixed seed: reproducible orders
    v = [rng.uniform(-1, 1) for _ in range(n)]
    for _ in range(iters):
        mean = sum(v) / n                       # deflate the constant vector
        v = [x - mean for x in v]
        norm = math.sqrt(sum(x * x for x in v)) or 1.0
        v = [x / norm for x in v]
        # w = M v, with (Lv)_i = deg_i v_i - sum_j sim_ij v_j  (off-diagonal)
        w = []
        for i in range(n):
            lv = deg[i] * v[i] - sum(sim[i][j] * v[j] for j in range(n) if j != i)
            w.append(c * v[i] - lv)
        v = w
    return sorted(range(n), key=lambda i: v[i])


def greedy_chain(sim) -> list:
    """Chain from the loneliest item (a natural endpoint) by nearest neighbor."""
    n = len(sim)
    if n == 0:
        return []
    start = min(range(n), key=lambda i: sum(sim[i]))
    order, used = [start], {start}
    while len(order) < n:
        last = order[-1]
        nxt = max((i for i in range(n) if i not in used), key=lambda i: sim[last][i])
        order.append(nxt)
        used.add(nxt)
    return order


def smoothness(sim, order) -> float:
    """Mean similarity of adjacent pairs — the objective all orders compete on."""
    if len(order) < 2:
        return 1.0
    return sum(sim[a][b] for a, b in zip(order, order[1:])) / (len(order) - 1)


def best_order(sim) -> tuple:
    """(order, method, smoothness): smoothest of spectral and greedy chains."""
    candidates = [(spectral_order(sim), "spectral"), (greedy_chain(sim), "greedy")]
    order, method = max(candidates, key=lambda c: smoothness(sim, c[0]))
    return order, method, smoothness(sim, order)
