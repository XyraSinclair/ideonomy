"""Model adapters: any callable str -> str is a model.

Multi-model work is the point (M1-M5), so the abstraction is deliberately
minimal: a Model is `(prompt: str) -> str`. CommandModel shells out to any
CLI (claude, codex, ollama, llm, ...), which is how heterogeneous panels are
assembled on a workstation without SDK lock-in.
"""

from __future__ import annotations

import concurrent.futures
import re
import shlex
import subprocess
from collections.abc import Callable, Sequence
from dataclasses import dataclass

Model = Callable[[str], str]


@dataclass(frozen=True)
class CommandModel:
    """A model backed by a shell command.

    The command template either contains '{prompt}' (substituted, shell-safe)
    or the prompt is passed on stdin.

    Examples:
        CommandModel("claude -p {prompt}")
        CommandModel("codex exec --full-auto {prompt}")
        CommandModel("ollama run llama3.3", via_stdin=True)
    """

    command: str
    via_stdin: bool = False
    timeout: float = 600.0
    name: str = ""

    def __call__(self, prompt: str) -> str:
        if self.via_stdin or "{prompt}" not in self.command:
            proc = subprocess.run(
                self.command, shell=True, input=prompt, capture_output=True,
                text=True, timeout=self.timeout,
            )
        else:
            # replace, not str.format: command templates may carry literal
            # braces (jq filters, JSON payloads) that are not placeholders.
            cmd = self.command.replace("{prompt}", shlex.quote(prompt))
            proc = subprocess.run(
                cmd, shell=True, capture_output=True, text=True,
                timeout=self.timeout,
            )
        if proc.returncode != 0:
            raise RuntimeError(
                f"model command failed ({self.name or self.command!r}): "
                f"{proc.stderr.strip()[:500]}"
            )
        return proc.stdout.strip()


def panel(models: Sequence[Model], prompt: str,
          prompts: Sequence[str] | None = None) -> list[str | Exception]:
    """Run a panel of models concurrently (P21).

    If `prompts` is given it must match `models` in length — distinct lenses
    per judge (M2). A failed model yields its Exception rather than sinking
    the panel.
    """
    if not models:
        return []
    ps = list(prompts) if prompts is not None else [prompt] * len(models)
    if len(ps) != len(models):
        raise ValueError("prompts must match models in length")
    results: list[str | Exception] = [Exception("not run")] * len(models)
    with concurrent.futures.ThreadPoolExecutor(max_workers=len(models)) as ex:
        futs = {ex.submit(m, p): i for i, (m, p) in enumerate(zip(models, ps))}
        for fut in concurrent.futures.as_completed(futs):
            i = futs[fut]
            try:
                results[i] = fut.result()
            except Exception as exc:  # noqa: BLE001 - panel isolates failures
                results[i] = exc
    return results


def refute(models: Sequence[Model], claim: str, context: str = "") -> bool:
    """P22 adversarial-refute: claim survives iff a majority of refuters fail.

    Refuters are prompted to destroy the claim and to default to REFUTED when
    uncertain. Returns True iff the claim survives.
    """
    prompt = (
        "You are a motivated skeptic. Try to REFUTE the claim below: find a "
        "concrete counterexample, a hidden false assumption, or a reason it "
        "is vacuous. If you cannot decisively refute it but remain uncertain, "
        "default to REFUTED. End your reply with exactly one line: "
        "VERDICT: REFUTED or VERDICT: SURVIVES.\n\n"
        f"Claim: {claim}\n"
    )
    if context:
        prompt += f"\nContext:\n{context}\n"
    votes = panel(models, prompt)
    survives = sum(
        1 for v in votes if isinstance(v, str) and _survives(v)
    )
    return survives > len(models) / 2


def _survives(reply: str) -> bool:
    """Parse the LAST verdict line; refuted-by-default when unparseable.

    A bare substring test would count a model that echoes its instructions
    (which contain both verdict strings) as a survival vote — inverting the
    gate's safety default.
    """
    for ln in reversed([ln.strip() for ln in reply.splitlines() if ln.strip()]):
        m = re.match(r"VERDICT:\s*(REFUTED|SURVIVES)\b", ln, re.IGNORECASE)
        if m:
            return m.group(1).upper() == "SURVIVES"
    return False
