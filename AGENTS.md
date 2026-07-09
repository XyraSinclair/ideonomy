# For agents working on this repo

Run `python3 -m unittest discover tests` before and after any change. The
suite is offline, dependency-free, and fast; it also machine-enforces the
invariants below (`tests/test_consistency.py`), so a green run is the gate.

## Invariants

- **ORGANON.md ↔ `ideonomy/primitives.py` are one catalog in two forms.**
  Change one, change the other, same commit.
- **Prose counts are derived, never asserted.** If you add a primitive, a
  skill, or a division, the tests will name every doc that carries the count.
  Do not hardcode catalog counts inside `.py` prose.
- **Skill dirs are self-contained**: `skills/<name>/SKILL.md`, frontmatter
  `name` equal to the directory name, `description` carrying both the move
  and its trigger. Every skill appears in `skills/README.md`; the router
  (`route-to-the-right-move`) may only reference skills that exist.
- **Every relative markdown link must resolve.** No links to private or
  sibling repos.

## Doctrine

- **Gates are the product.** A new skill without an anti-fool-yourself gate
  is copy, not a skill. A new engine feature without an offline test is a
  claim, not a feature.
- **Promote down, not up.** Grow the catalog by adding primitives/operators/
  divisions, not by adding compound recipes; compounds live only in
  `skills/` and must name the primitives they compose.
- **The catalog applies to itself.** Substantive changes should say which
  primitives they exercised (P11 gap-find, P22 refute, P35 self-modify) and
  honest failures are recorded, not hidden (`PREMIER_SKILLS.md` shows the
  form).
- **Stdlib only** in `ideonomy/`. Any model dependency stays behind
  `models.CommandModel` (any CLI is a model).

## Release

`pyproject.toml` version == `.claude-plugin/plugin.json` version ==
`.claude-plugin/marketplace.json` plugin version. `claude plugin validate .`
must pass. Tag releases `vX.Y.Z`.
