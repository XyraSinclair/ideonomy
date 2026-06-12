"""The organon, machine-readable.

Canonical prose form: ORGANON.md at the repo root. Keep the two in sync;
the catalog applies to itself (P11 gap-find, P35 self-modify).
"""

from __future__ import annotations

from dataclasses import dataclass, field

PHASES = ("SENSE", "ORIENT", "GENERATE", "JUDGE", "ACT", "PERSIST")


@dataclass(frozen=True)
class Primitive:
    key: str
    name: str
    phase: str
    gloss: str
    signature: str
    metabolizes: str = ""
    provenance: tuple[str, ...] = field(default_factory=tuple)


P = Primitive

PRIMITIVES: list[Primitive] = [
    # ------------------------------------------------------------- SENSE
    P("P1", "enumerate", "SENSE",
      "Collect instances of the thing before theorizing about it.",
      "subject -> [instances]",
      "vagueness -> evidence",
      ("Gunkel progressive lists", "HiExpan", "Clio facet extraction")),
    P("P2", "detector-bank", "SENSE",
      "Many small deterministic sensors feeding one queue; model judgment "
      "reserved for what rules cannot express.",
      "artifact -> [findings(detector, location, confidence)]",
      "ambient unease -> located, typed findings",
      ("desloppify", "aislop", "Semgrep", "ruff")),
    P("P3", "fault-model", "SENSE",
      "Define the defect/possibility class explicitly before searching for "
      "instances.",
      "domain -> class definitions -> targeted search",
      "unfalsifiable taste -> testable class membership",
      ("ACH mutants", "CodeMender vuln classes", "Gunkel divisions")),
    P("P4", "external-signal", "SENSE",
      "Wire the loop to event streams so it runs continuously.",
      "event stream -> triggered cycle",
      "staleness -> liveness",
      ("SapFix/Sapienz", "CodeMender/OSS-Fuzz", "gh-aw cron")),
    P("P37", "residue-seed", "SENSE",
      "Extract what resists the current structure — anomalies, misfits, "
      "cross-model disagreement — and make it the next expansion's seed. The "
      "heartbeat of the respiratory loop: residue is fuel, not error.",
      "(structure, corpus) -> [resisting items] -> next seed",
      "tension swept under the rug -> tension fed forward as the next question",
      ("CYCLES.md", "MDL residual term", "Gunkel anomalies/Xenology")),
    P("P5", "dimensionalize", "SENSE",
      "Identify the axes/facets along which the thing varies.",
      "[instances] -> [dimensions(name, range)]",
      "blob -> coordinate system",
      ("Gunkel Usiology", "Zwicky morphological box", "Clio facets",
       "TaxoAdapt")),
    # ------------------------------------------------------------ ORIENT
    P("P6", "cluster", "ORIENT",
      "Group instances by similarity before naming anything.",
      "[instances] -> [[instances]]",
      provenance=("Gunkel Botryology/MDS", "BERTopic", "Clio")),
    P("P7", "typify", "ORIENT",
      "Isolate types from clusters: the move from extension to intension.",
      "[[instances]] -> [types(intension, members)]",
      provenance=("Gunkel Typology", "LLMs4OL term typing", "TnT-LLM")),
    P("P8", "name", "ORIENT",
      "Bind a precise label and one-sentence definition to each type.",
      "type -> (label, definition)",
      "diffuse grasp -> compressed handle",
      ("Gunkel binomens", "TopicGPT/Clio titling")),
    P("P9", "hierarchize", "ORIENT",
      "Arrange types into levels with consistent granularity per level.",
      "[types] -> tree",
      provenance=("Gunkel Climology", "Chain-of-Layer", "Clio hierarchy")),
    P("P10", "map", "ORIENT",
      "Build a cheap navigable structural index of the territory.",
      "territory -> index",
      "token-expensive groping -> indexed retrieval",
      ("aider repo map", "AutoCodeRover AST search", "Moderne LST")),
    P("P11", "gap-find", "ORIENT",
      "Run the structure back over the instances; ask what should exist but "
      "doesn't (the missing cell).",
      "(structure, [instances]) -> [absences]",
      "complacent coverage -> named residual gaps",
      ("Gunkel loop step 3", "Mendeleev", "Qodo Cover")),
    P("P36", "distill", "ORIENT",
      "Compress the whole structure to the minimal generative rule that would "
      "regenerate it — the invariant, not a per-type label. Naming (P8) "
      "compresses one type; distillation compresses the structure.",
      "structure -> generative rule",
      "an enumerable structure -> a regenerable one",
      ("Gunkel 'proof is a tree'", "MDL two-part codes", "Clio describe")),
    # ---------------------------------------------------------- GENERATE
    P("P12", "combine", "GENERATE",
      "Cartesian product of lists phrased for coherent combination; read the "
      "product for live cells (ideocombinatorics).",
      "(list_a, list_b, template) -> [composites]",
      "exhausted single lists -> combinatorial frontier",
      ("Gunkel shapes x orders = 17,020",)),
    P("P13", "analogize", "GENERATE",
      "Transfer structure across domains; mine the unmapped remainder.",
      "(source structure, target domain) -> mapping + candidates",
      provenance=("Gunkel Icelology", "CoRel relation transfer")),
    P("P14", "transpose", "GENERATE",
      "Re-apply one domain's organizing scheme wholesale to another.",
      "(scheme, new domain) -> reorganized domain",
      provenance=("Gunkel projections",)),
    P("P15", "vary", "GENERATE",
      "Systematic variation: negate, invert, extremize, permute, relax.",
      "idea -> [variants by named operator]",
      provenance=("Gunkel Negations/Inversions", "mutation testing")),
    P("P16", "lump-split", "GENERATE",
      "Generalize and specialize as paired, reversible moves.",
      "type <-> (supertype | [subtypes])",
      provenance=("TopicGPT merge/refine",)),
    P("P17", "sample-many", "GENERATE",
      "Generate N independent candidates cheaply; selection is the product.",
      "prompt -> [candidate_1 .. candidate_n]",
      provenance=("Agentless", "Codeflash", "CodeMonkeys")),
    # ------------------------------------------------------------- JUDGE
    P("P18", "filter", "JUDGE",
      "Cheap mechanical winnow before expensive judgment.",
      "[candidates] -> [survivors]"),
    P("P19", "oracle", "JUDGE",
      "Get or make an executable truth signal; generate the oracle before "
      "the fix.",
      "claim -> executable check",
      "plausibility -> ground truth",
      ("AlphaCodium", "Agentless repro tests", "Codeflash")),
    P("P20", "self-verify", "JUDGE",
      "Re-run the sensor that found the tension against the resolution.",
      "(finding, resolution) -> still-fires?",
      provenance=("Semgrep autofix re-scan", "Debian Janitor rebuild")),
    P("P21", "judge-panel", "JUDGE",
      "N model critics with distinct lenses, not N identical voters.",
      "candidate -> [verdict(lens)]",
      provenance=("CriticGPT", "CodeMender judge stage")),
    P("P22", "adversarial-refute", "JUDGE",
      "Skeptics prompted to destroy the candidate, refuted-by-default.",
      "claim -> survives?",
      "plausible-but-wrong -> killed early",
      ("ACH mutation-as-adversary", "CodeMender re-fuzzing")),
    P("P23", "tournament", "JUDGE",
      "Selection as its own agentic subproblem; on ties, generate new "
      "discriminating tests.",
      "[candidates] -> winner + reasons",
      provenance=("CodeMonkeys selection state machine",)),
    P("P24", "multi-oracle-gate", "JUDGE",
      "Ship only on the conjunction of independent oracles.",
      "candidate -> all-of([oracles])",
      provenance=("Codeflash correct AND faster", "TestGen-LLM filters")),
    P("P25", "rubric-first", "JUDGE",
      "Draft the rubric before judging; refine once; apply repeatedly; "
      "write the score LAST.",
      "task -> rubric -> repeated judgment",
      "anchoring -> grounded judgment",
      ("desloppify observe->judge split", "rubric-HITL judging")),
    # --------------------------------------------------------------- ACT
    P("P26", "constrained-actuator", "ACT",
      "Effects flow only through guardrailed interfaces that reject "
      "malformed actions instantly.",
      "intent -> validated action | rejection",
      provenance=("SWE-agent linted editor", "OpenRewrite recipes")),
    P("P27", "atomic-rollback", "ACT",
      "Backup -> apply -> check -> auto-revert on red.",
      "action -> committed | reverted",
      provenance=("git", "Ai_Slop_Cleaner", "moatless commit trees")),
    P("P28", "minimal-diff", "ACT",
      "The smallest change that resolves the tension.",
      "resolution -> minimized resolution"),
    P("P29", "safety-classes", "ACT",
      "Explicit applicability labels per action class, conservative by "
      "default, promotable by config.",
      "action class -> safety label -> default behavior",
      provenance=("ruff fix safety", "Copilot Autofix suppression")),
    # ------------------------------------------------------------ PERSIST
    P("P30", "ledger", "PERSIST",
      "A persistent score that must ratchet, with dual strict/lenient "
      "reading so accepted debt stays visible.",
      "state -> score(strict, lenient) over time",
      "one-shot digestion -> metabolism",
      ("desloppify strict-vs-lenient gap",)),
    P("P31", "episodic-memory", "PERSIST",
      "Lessons from failures stored in natural language, scoped, retrieved "
      "by applicability.",
      "failure -> lesson -> retrieved-when-relevant",
      provenance=("Reflexion", "CodeRabbit learnings")),
    P("P32", "variant-archive", "PERSIST",
      "Keep a population of attempts including stepping stones, not a "
      "single greedy lineage.",
      "attempts -> archive -> recombination substrate",
      provenance=("Darwin Godel Machine", "CodeMonkeys ensembles")),
    P("P33", "scheduler", "PERSIST",
      "Continuity comes from boring loop drivers: cron, queues, labels.",
      "work -> queued, prioritized, resumed",
      provenance=("Debian Janitor", "gh-aw")),
    P("P34", "policy-file", "PERSIST",
      "A standing constitution versioned with the work it governs.",
      "norms -> versioned artifact -> loaded each cycle",
      provenance=("AGENTS.md", ".openhands_instructions")),
    P("P35", "self-modify", "PERSIST",
      "The loop edits its own prompts, rubrics, detectors, tools; keeps an "
      "edit only if measured utility improves.",
      "loop -> candidate self-edit -> utility-gated adoption",
      "fixed competence -> compounding competence",
      ("SICA", "Darwin Godel Machine")),
]

MULTI_MODEL_PATTERNS: dict[str, str] = {
    "M1 generator/critic split":
        "The model that makes is never the only model that judges.",
    "M2 diversity over redundancy":
        "Distinct lenses, models, prompts; identical voters share blind spots.",
    "M3 blind review":
        "Strip scores, authorship, prior verdicts before judging.",
    "M4 cross-model triangulation":
        "Disagreement between strong models is a high-value tension signal; "
        "investigate, don't average.",
    "M5 ensemble selection":
        "Selection over a multi-model pool beats the best single member; "
        "invest compute in the selector.",
    "M6 human-gate-last":
        "Machine senses, generates, verifies; the human adjudicates only "
        "verified survivors.",
}

# The respiratory axis (CYCLES.md): orthogonal to the six phases, like the
# multi-model axis. Every phase can run in an expanding or compressing register;
# what carries structure across breaths is the residue, ratcheted on MDL.
RESPIRATORY_AXIS: dict[str, str] = {
    "R1 expand":
        "Diverge: raise cardinality and entropy (enumerate, combine, vary, "
        "analogize, sample-many, gap-find, transpose). Breathe in.",
    "R2 compress":
        "Converge: raise structure, lower entropy (cluster, typify, name, "
        "hierarchize, distill). Breathe out.",
    "R3 distill":
        "Compression taken to its limit: the minimal generative rule (P36).",
    "R4 residue-as-seed":
        "What resists the compression seeds the next expansion (P37). Tension "
        "fed forward, not minimized away.",
    "R5 MDL-ratchet":
        "Keep a breath iff the corpus still compresses at least as well: "
        "L(structure)+L(corpus|structure) earns its keep. Catches expansion "
        "runaway and premature compression alike.",
    "R6 breath":
        "The cycle, not either half, is the unit of work. Metabolism = each "
        "breath explains more of its corpus with a smaller structure.",
}

BY_KEY: dict[str, Primitive] = {p.key: p for p in PRIMITIVES}
BY_NAME: dict[str, Primitive] = {p.name: p for p in PRIMITIVES}


def by_phase(phase: str) -> list[Primitive]:
    return [p for p in PRIMITIVES if p.phase == phase]
