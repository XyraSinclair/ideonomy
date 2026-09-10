-- | The organon, machine-readable.
--
-- Canonical prose form: @ORGANON.md@ at the repo root. Keep the two in
-- sync; the catalog applies to itself (P11 gap-find, P35 self-modify).
--
-- Thirty-seven primitives across six phases, plus two axes orthogonal to
-- the phases: the multi-model patterns (who judges whom) and the
-- respiratory axis (expand, compress, distill, seed the next breath).
module Ideonomy.Primitives
  ( Phase (..), phases, phaseName
  , Primitive (..), primitives, byPhase, byKey, byName
  , multiModelPatterns, respiratoryAxis
  ) where

data Phase = Sense | Orient | Generate | Judge | Act | Persist
  deriving (Eq, Ord, Show, Enum, Bounded)

-- | The six phases, in loop order.
phases :: [Phase]
phases = [minBound .. maxBound]

phaseName :: Phase -> String
phaseName = \case
  Sense -> "SENSE"
  Orient -> "ORIENT"
  Generate -> "GENERATE"
  Judge -> "JUDGE"
  Act -> "ACT"
  Persist -> "PERSIST"

data Primitive = Primitive
  { key :: String
  , name :: String
  , phase :: Phase
  , gloss :: String
  , signature :: String
  , metabolizes :: String    -- ^ what it turns into what; empty for pure mechanisms
  , provenance :: [String]
  } deriving (Eq, Show)

byPhase :: Phase -> [Primitive]
byPhase ph = [p | p <- primitives, p.phase == ph]

byKey :: String -> Maybe Primitive
byKey k = lookup k [(p.key, p) | p <- primitives]

byName :: String -> Maybe Primitive
byName n = lookup n [(p.name, p) | p <- primitives]

primitives :: [Primitive]
primitives =
  [ Primitive "P1" "enumerate" Sense
      "Collect instances of the thing before theorizing about it."
      "subject -> [instances]"
      "vagueness -> evidence"
      ["Gunkel progressive lists", "HiExpan", "Clio facet extraction"]
  , Primitive "P2" "detector-bank" Sense
      "Many small deterministic sensors feeding one queue; model judgment reserved for what rules cannot express."
      "artifact -> [findings(detector, location, confidence)]"
      "ambient unease -> located, typed findings"
      ["desloppify", "aislop", "Semgrep", "ruff"]
  , Primitive "P3" "fault-model" Sense
      "Define the defect/possibility class explicitly before searching for instances."
      "domain -> class definitions -> targeted search"
      "unfalsifiable taste -> testable class membership"
      ["ACH mutants", "CodeMender vuln classes", "Gunkel divisions"]
  , Primitive "P4" "external-signal" Sense
      "Wire the loop to event streams so it runs continuously."
      "event stream -> triggered cycle"
      "staleness -> liveness"
      ["SapFix/Sapienz", "CodeMender/OSS-Fuzz", "gh-aw cron"]
  , Primitive "P37" "residue-seed" Sense
      "Extract what resists the current structure — anomalies, misfits, cross-model disagreement — and make it the next expansion's seed. The heartbeat of the respiratory loop: residue is fuel, not error."
      "(structure, corpus) -> [resisting items] -> next seed"
      "tension swept under the rug -> tension fed forward as the next question"
      ["CYCLES.md", "MDL residual term", "Gunkel anomalies/Xenology"]
  , Primitive "P5" "dimensionalize" Sense
      "Identify the axes/facets along which the thing varies."
      "[instances] -> [dimensions(name, range)]"
      "blob -> coordinate system"
      ["Gunkel Usiology", "Zwicky morphological box", "Clio facets", "TaxoAdapt"]
  , Primitive "P6" "cluster" Orient
      "Group instances by similarity before naming anything."
      "[instances] -> [[instances]]"
      ""
      ["Gunkel Botryology/MDS", "BERTopic", "Clio"]
  , Primitive "P7" "typify" Orient
      "Isolate types from clusters: the move from extension to intension."
      "[[instances]] -> [types(intension, members)]"
      ""
      ["Gunkel Typology", "LLMs4OL term typing", "TnT-LLM"]
  , Primitive "P8" "name" Orient
      "Bind a precise label and one-sentence definition to each type."
      "type -> (label, definition)"
      "diffuse grasp -> compressed handle"
      ["Gunkel binomens", "TopicGPT/Clio titling"]
  , Primitive "P9" "hierarchize" Orient
      "Arrange types into levels with consistent granularity per level."
      "[types] -> tree"
      ""
      ["Gunkel Climology", "Chain-of-Layer", "Clio hierarchy"]
  , Primitive "P10" "map" Orient
      "Build a cheap navigable structural index of the territory."
      "territory -> index"
      "token-expensive groping -> indexed retrieval"
      ["aider repo map", "AutoCodeRover AST search", "Moderne LST"]
  , Primitive "P11" "gap-find" Orient
      "Run the structure back over the instances; ask what should exist but doesn't (the missing cell)."
      "(structure, [instances]) -> [absences]"
      "complacent coverage -> named residual gaps"
      ["Gunkel loop step 3", "Mendeleev", "Qodo Cover"]
  , Primitive "P36" "distill" Orient
      "Compress the whole structure to the minimal generative rule that would regenerate it — the invariant, not a per-type label. Naming (P8) compresses one type; distillation compresses the structure."
      "structure -> generative rule"
      "an enumerable structure -> a regenerable one"
      ["Gunkel 'proof is a tree'", "MDL two-part codes", "Clio describe"]
  , Primitive "P12" "combine" Generate
      "Cartesian product of lists phrased for coherent combination; read the product for live cells (ideocombinatorics)."
      "(list_a, list_b, template) -> [composites]"
      "exhausted single lists -> combinatorial frontier"
      ["Gunkel shapes x orders = 17,020"]
  , Primitive "P13" "analogize" Generate
      "Transfer structure across domains; mine the unmapped remainder."
      "(source structure, target domain) -> mapping + candidates"
      ""
      ["Gunkel Icelology", "CoRel relation transfer"]
  , Primitive "P14" "transpose" Generate
      "Re-apply one domain's organizing scheme wholesale to another."
      "(scheme, new domain) -> reorganized domain"
      ""
      ["Gunkel projections"]
  , Primitive "P15" "vary" Generate
      "Systematic variation: negate, invert, extremize, permute, relax."
      "idea -> [variants by named operator]"
      ""
      ["Gunkel Negations/Inversions", "mutation testing"]
  , Primitive "P16" "lump-split" Generate
      "Generalize and specialize as paired, reversible moves."
      "type <-> (supertype | [subtypes])"
      ""
      ["TopicGPT merge/refine"]
  , Primitive "P17" "sample-many" Generate
      "Generate N independent candidates cheaply; selection is the product."
      "prompt -> [candidate_1 .. candidate_n]"
      ""
      ["Agentless", "Codeflash", "CodeMonkeys"]
  , Primitive "P18" "filter" Judge
      "Cheap mechanical winnow before expensive judgment."
      "[candidates] -> [survivors]"
      ""
      []
  , Primitive "P19" "oracle" Judge
      "Get or make an executable truth signal; generate the oracle before the fix."
      "claim -> executable check"
      "plausibility -> ground truth"
      ["AlphaCodium", "Agentless repro tests", "Codeflash"]
  , Primitive "P20" "self-verify" Judge
      "Re-run the sensor that found the tension against the resolution."
      "(finding, resolution) -> still-fires?"
      ""
      ["Semgrep autofix re-scan", "Debian Janitor rebuild"]
  , Primitive "P21" "judge-panel" Judge
      "N model critics with distinct lenses, not N identical voters."
      "candidate -> [verdict(lens)]"
      ""
      ["CriticGPT", "CodeMender judge stage"]
  , Primitive "P22" "adversarial-refute" Judge
      "Skeptics prompted to destroy the candidate, refuted-by-default."
      "claim -> survives?"
      "plausible-but-wrong -> killed early"
      ["ACH mutation-as-adversary", "CodeMender re-fuzzing"]
  , Primitive "P23" "tournament" Judge
      "Selection as its own agentic subproblem; on ties, generate new discriminating tests."
      "[candidates] -> winner + reasons"
      ""
      ["CodeMonkeys selection state machine"]
  , Primitive "P24" "multi-oracle-gate" Judge
      "Ship only on the conjunction of independent oracles."
      "candidate -> all-of([oracles])"
      ""
      ["Codeflash correct AND faster", "TestGen-LLM filters"]
  , Primitive "P25" "rubric-first" Judge
      "Draft the rubric before judging; refine once; apply repeatedly; write the score LAST."
      "task -> rubric -> repeated judgment"
      "anchoring -> grounded judgment"
      ["desloppify observe->judge split", "rubric-HITL judging"]
  , Primitive "P26" "constrained-actuator" Act
      "Effects flow only through guardrailed interfaces that reject malformed actions instantly."
      "intent -> validated action | rejection"
      ""
      ["SWE-agent linted editor", "OpenRewrite recipes"]
  , Primitive "P27" "atomic-rollback" Act
      "Backup -> apply -> check -> auto-revert on red."
      "action -> committed | reverted"
      ""
      ["git", "Ai_Slop_Cleaner", "moatless commit trees"]
  , Primitive "P28" "minimal-diff" Act
      "The smallest change that resolves the tension."
      "resolution -> minimized resolution"
      ""
      []
  , Primitive "P29" "safety-classes" Act
      "Explicit applicability labels per action class, conservative by default, promotable by config."
      "action class -> safety label -> default behavior"
      ""
      ["ruff fix safety", "Copilot Autofix suppression"]
  , Primitive "P30" "ledger" Persist
      "A persistent score that must ratchet, with dual strict/lenient reading so accepted debt stays visible."
      "state -> score(strict, lenient) over time"
      "one-shot digestion -> metabolism"
      ["desloppify strict-vs-lenient gap"]
  , Primitive "P31" "episodic-memory" Persist
      "Lessons from failures stored in natural language, scoped, retrieved by applicability."
      "failure -> lesson -> retrieved-when-relevant"
      ""
      ["Reflexion", "CodeRabbit learnings"]
  , Primitive "P32" "variant-archive" Persist
      "Keep a population of attempts including stepping stones, not a single greedy lineage."
      "attempts -> archive -> recombination substrate"
      ""
      ["Darwin Godel Machine", "CodeMonkeys ensembles"]
  , Primitive "P33" "scheduler" Persist
      "Continuity comes from boring loop drivers: cron, queues, labels."
      "work -> queued, prioritized, resumed"
      ""
      ["Debian Janitor", "gh-aw"]
  , Primitive "P34" "policy-file" Persist
      "A standing constitution versioned with the work it governs."
      "norms -> versioned artifact -> loaded each cycle"
      ""
      ["AGENTS.md", ".openhands_instructions"]
  , Primitive "P35" "self-modify" Persist
      "The loop edits its own prompts, rubrics, detectors, tools; keeps an edit only if measured utility improves."
      "loop -> candidate self-edit -> utility-gated adoption"
      "fixed competence -> compounding competence"
      ["SICA", "Darwin Godel Machine"]
  ]

multiModelPatterns :: [(String, String)]
multiModelPatterns =
  [ ("M1 generator/critic split", "The model that makes is never the only model that judges.")
  , ("M2 diversity over redundancy", "Distinct lenses, models, prompts; identical voters share blind spots.")
  , ("M3 blind review", "Strip scores, authorship, prior verdicts before judging.")
  , ("M4 cross-model triangulation", "Disagreement between strong models is a high-value tension signal; investigate, don't average.")
  , ("M5 ensemble selection", "Selection over a multi-model pool beats the best single member; invest compute in the selector.")
  , ("M6 human-gate-last", "Machine senses, generates, verifies; the human adjudicates only verified survivors.")
  ]

respiratoryAxis :: [(String, String)]
respiratoryAxis =
  [ ("R1 expand", "Diverge: raise cardinality and entropy (enumerate, combine, vary, analogize, sample-many, gap-find, transpose). Breathe in.")
  , ("R2 compress", "Converge: raise structure, lower entropy (cluster, typify, name, hierarchize, distill). Breathe out.")
  , ("R3 distill", "Compression taken to its limit: the minimal generative rule (P36).")
  , ("R4 residue-as-seed", "What resists the compression seeds the next expansion (P37). Tension fed forward, not minimized away.")
  , ("R5 MDL-ratchet", "Keep a breath iff the corpus still compresses at least as well: L(structure)+L(corpus|structure) earns its keep. Catches expansion runaway and premature compression alike.")
  , ("R6 breath", "The cycle, not either half, is the unit of work. Metabolism = each breath explains more of its corpus with a smaller structure.")
  ]
