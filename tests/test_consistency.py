"""Doc <-> code consistency, machine-enforced.

The catalog applies to itself (P20 self-verify, P30 ledger): every count and
cross-reference the prose asserts is checked here against the machine-readable
source. Staleness of the class "docs describe an earlier repo" fails the
suite instead of waiting for a careful reader.
"""

from __future__ import annotations

import re
import unittest
from pathlib import Path

from ideonomy import divisions, primitives

ROOT = Path(__file__).resolve().parent.parent
SKILLS = ROOT / "skills"


def read(rel: str) -> str:
    return (ROOT / rel).read_text()


def skill_dirs() -> list[Path]:
    return sorted(p for p in SKILLS.iterdir() if p.is_dir())


def frontmatter(text: str) -> dict[str, str]:
    m = re.match(r"^---\n(.*?)\n---\n", text, re.S)
    if not m:
        return {}
    body = m.group(1)
    out: dict[str, str] = {}
    key = None
    buf: list[str] = []
    for line in body.splitlines():
        km = re.match(r"^([a-zA-Z-]+):\s*(.*)$", line)
        if km:
            if key:
                out[key] = " ".join(buf).strip()
            key = km.group(1)
            first = km.group(2).strip()
            buf = [] if first in (">-", ">", "|", "|-") else [first]
        elif key:
            buf.append(line.strip())
    if key:
        out[key] = " ".join(buf).strip()
    return out


class TestOrganonSync(unittest.TestCase):
    """ORGANON.md and primitives.py must agree exactly."""

    def test_every_primitive_appears_in_organon_with_its_name(self):
        organon = read("ORGANON.md")
        for p in primitives.PRIMITIVES:
            pat = rf"\*\*{re.escape(p.key)}\.\s+{re.escape(p.name)}\*\*"
            self.assertRegex(organon, pat,
                             f"{p.key} ({p.name}) missing or renamed in ORGANON.md")

    def test_organon_has_no_primitive_missing_from_code(self):
        organon = read("ORGANON.md")
        doc_keys = set(re.findall(r"\*\*(P\d+)\.", organon))
        code_keys = {p.key for p in primitives.PRIMITIVES}
        self.assertEqual(doc_keys, code_keys)

    def test_multi_model_patterns_match(self):
        organon = read("ORGANON.md")
        doc_ms = set(re.findall(r"\*\*(M\d+)\.", organon))
        code_ms = {k.split()[0] for k in primitives.MULTI_MODEL_PATTERNS}
        self.assertEqual(doc_ms, code_ms)

    def test_phases_match(self):
        organon = read("ORGANON.md")
        for phase in primitives.PHASES:
            self.assertIn(f"— {phase}", organon)


class TestProseCounts(unittest.TestCase):
    """Numbers asserted in prose match the machine-readable source."""

    N = len(primitives.PRIMITIVES)

    def test_readme_primitive_count(self):
        self.assertIn(f"{self.N} inference-time", read("README.md"))

    def test_organon_primitive_count(self):
        self.assertIn(f"same {self.N} primitives", read("ORGANON.md"))

    def test_cycles_primitive_count(self):
        self.assertIn(f"{self.N} primitives", read("CYCLES.md"))

    def test_skill_count_claims(self):
        n = len(skill_dirs())
        for doc in ("AFFORDANCE.md", "README.md"):
            text = read(doc)
            for claim in re.findall(r"(\d+)\s+(?:premier\s+)?(?:agent\s+)?skills", text):
                self.assertEqual(int(claim), n,
                                 f"{doc} claims {claim} skills; {n} exist")

    def test_division_count(self):
        n = len(divisions.DIVISIONS)
        self.assertEqual(n, 236)
        self.assertIn(f"({n} recovered)", read("README.md"))

    def test_no_hardcoded_primitive_count_in_code(self):
        """Prose inside .py files must not carry a hardcoded primitive count."""
        for py in (ROOT / "ideonomy").glob("*.py"):
            for bad in ("35 primitive", "36 primitive"):
                self.assertNotIn(bad, py.read_text(),
                                 f"{py.name} carries a stale primitive count")


class TestVersionSync(unittest.TestCase):
    """pyproject, plugin.json, and marketplace.json carry one version."""

    def test_versions_agree(self):
        import json
        pv = re.search(r'^version = "([^"]+)"', read("pyproject.toml"), re.M).group(1)
        plugin = json.loads(read(".claude-plugin/plugin.json"))
        market = json.loads(read(".claude-plugin/marketplace.json"))
        self.assertEqual(plugin["version"], pv)
        self.assertEqual(market["plugins"][0]["version"], pv)


class TestLinks(unittest.TestCase):
    """Every relative markdown link in every tracked .md file resolves."""

    def test_intra_repo_links_resolve(self):
        md_files = [p for p in ROOT.rglob("*.md")
                    if ".git" not in p.parts and ".residue" not in p.parts]
        broken: list[str] = []
        for md in md_files:
            for target in re.findall(r"\]\(([^)]+)\)", md.read_text()):
                if target.startswith(("http://", "https://", "mailto:", "#")):
                    continue
                path = target.split("#", 1)[0]
                if not path:
                    continue
                if not (md.parent / path).exists():
                    broken.append(f"{md.relative_to(ROOT)} -> {target}")
        self.assertEqual(broken, [], f"broken links: {broken}")


class TestSkillFiles(unittest.TestCase):
    """skills/ satisfies the agent-skill contract."""

    def test_every_skill_dir_has_skill_md(self):
        for d in skill_dirs():
            self.assertTrue((d / "SKILL.md").exists(), d.name)

    def test_frontmatter_name_matches_dir_and_spec(self):
        for d in skill_dirs():
            fm = frontmatter((d / "SKILL.md").read_text())
            self.assertEqual(fm.get("name"), d.name)
            self.assertRegex(fm["name"], r"^[a-z0-9]+(-[a-z0-9]+)*$")
            self.assertLessEqual(len(fm["name"]), 64)

    def test_frontmatter_description_present_and_bounded(self):
        for d in skill_dirs():
            fm = frontmatter((d / "SKILL.md").read_text())
            desc = fm.get("description", "")
            self.assertTrue(desc, f"{d.name}: empty description")
            self.assertLessEqual(len(desc), 1024,
                                 f"{d.name}: description {len(desc)} chars")

    def test_skills_readme_lists_every_skill(self):
        text = read("skills/README.md")
        for d in skill_dirs():
            self.assertIn(f"({d.name}/SKILL.md)", text,
                          f"skills/README.md missing {d.name}")

    def test_router_routes_only_to_real_skills(self):
        text = (SKILLS / "route-to-the-right-move" / "SKILL.md").read_text()
        names = {d.name for d in skill_dirs()}
        for ref in re.findall(r"`([a-z0-9-]{8,})`", text):
            if "-" in ref and not ref.startswith(("ideonomy", "python")):
                self.assertIn(ref, names, f"router references unknown skill {ref}")


if __name__ == "__main__":
    unittest.main()
