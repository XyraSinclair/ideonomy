#!/bin/sh
# Install the ideonomy premier skills into an agent's personal skills dir.
#
#   ./install.sh                 # -> ~/.claude/skills/<skill-name>/
#   SKILLS_DIR=/path ./install.sh
#
# Claude Code users can instead install as a plugin (see README):
#   /plugin marketplace add XyraSinclair/ideonomy
#
# Idempotent: re-running updates existing copies in place.

set -eu

here=$(cd "$(dirname "$0")" && pwd)
dest="${SKILLS_DIR:-$HOME/.claude/skills}"

mkdir -p "$dest"
n=0
for d in "$here"/skills/*/; do
    name=$(basename "$d")
    mkdir -p "$dest/$name"
    cp "$d/SKILL.md" "$dest/$name/SKILL.md"
    n=$((n + 1))
done

echo "installed $n skills -> $dest"
echo "start with: route-to-the-right-move (the dispatcher), or the top three:"
echo "  triangulate-without-oracle, build-the-oracle-before-the-answer, reframe-until-it-dissolves"
