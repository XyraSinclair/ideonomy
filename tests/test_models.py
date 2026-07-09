"""Offline tests for model adapters: panels and refutation with fake callables."""

from __future__ import annotations

import unittest

from ideonomy import models as M


def says(reply: str):
    return lambda prompt: reply


class PanelTests(unittest.TestCase):
    def test_results_preserve_model_order(self) -> None:
        out = M.panel([says("one"), says("two"), says("three")], "p")
        self.assertEqual(out, ["one", "two", "three"])

    def test_failed_model_yields_exception_not_sunk_panel(self) -> None:
        def boom(prompt: str) -> str:
            raise RuntimeError("down")
        out = M.panel([says("ok"), boom], "p")
        self.assertEqual(out[0], "ok")
        self.assertIsInstance(out[1], RuntimeError)

    def test_distinct_prompts_reach_their_judges(self) -> None:
        echo = lambda prompt: prompt
        self.assertEqual(M.panel([echo, echo], "unused", prompts=["a", "b"]),
                         ["a", "b"])

    def test_prompts_length_mismatch_raises(self) -> None:
        with self.assertRaises(ValueError):
            M.panel([says("x")], "p", prompts=["a", "b"])

    def test_empty_panel_returns_empty(self) -> None:
        self.assertEqual(M.panel([], "p"), [])


class RefuteTests(unittest.TestCase):
    def test_majority_survives_and_majority_refuted(self) -> None:
        s = says("reasoning...\nVERDICT: SURVIVES")
        r = says("counterexample!\nVERDICT: REFUTED")
        self.assertTrue(M.refute([s, s, r], "claim"))
        self.assertFalse(M.refute([s, r, r], "claim"))

    def test_prompt_echo_is_not_a_survival_vote(self) -> None:
        # The refuter prompt itself contains "VERDICT: SURVIVES"; a model that
        # quotes its instructions and votes REFUTED must count as REFUTED.
        def echoer(prompt: str) -> str:
            return prompt + "\nVERDICT: REFUTED"
        self.assertFalse(M.refute([echoer, echoer, echoer], "the moon is cheese"))

    def test_unparseable_reply_is_refuted_by_default(self) -> None:
        self.assertFalse(M.refute([says("hmm, hard to say")] * 3, "c"))

    def test_erroring_refuters_count_against_survival(self) -> None:
        def boom(prompt: str) -> str:
            raise RuntimeError("down")
        self.assertFalse(M.refute([says("VERDICT: SURVIVES"), boom, boom], "c"))


class CommandModelTests(unittest.TestCase):
    def test_stdin_mode(self) -> None:
        self.assertEqual(M.CommandModel("cat", via_stdin=True)("hello"), "hello")

    def test_template_substitution_is_shell_safe(self) -> None:
        m = M.CommandModel("printf '%s' {prompt}")
        self.assertEqual(m("a; echo pwned"), "a; echo pwned")

    def test_literal_braces_in_command_survive(self) -> None:
        # jq/JSON-style commands carry braces that are not placeholders.
        m = M.CommandModel("printf '%s' {prompt} '{\"k\":1}'")
        self.assertEqual(m("x"), 'x{"k":1}')

    def test_nonzero_exit_raises(self) -> None:
        with self.assertRaises(RuntimeError):
            M.CommandModel("false", via_stdin=True, name="f")("p")


if __name__ == "__main__":
    unittest.main()
