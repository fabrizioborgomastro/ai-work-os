#!/bin/sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
errors=0
required='README.md
ROADMAP.md
AGENTS.md
INSTALL.md
install.ps1
install.sh
LICENSE
THIRD_PARTY_NOTICES.md
GETTING_STARTED.md
ARCHITECTURE.md
core/WORKFLOW.md
core/TRACKERS.md
core/ROUTING.md
core/GATES.md
core/BUDGETS.md
core/PORTABILITY.md
core/COMPATIBILITY.md
core/DISPATCH.md
templates/PROJECT.example.md
templates/EVIDENCE_PACKAGE.md
adapters/README.md
adapters/codex/README.md
adapters/claude/README.md
adapters/compatibility.tsv
adapters/omniroute/combos.json
skills/ai-work-os/SKILL.md
scripts/bootstrap.ps1
scripts/bootstrap.sh
scripts/manage.ps1
scripts/manage.sh
scripts/verify_distribution.ps1
scripts/verify_distribution.sh
scripts/test_compatibility.ps1
scripts/test_compatibility.sh'

printf '%s\n' "$required" | while IFS= read -r relative; do
    [ -f "$root/$relative" ] || { echo "missing: $relative" >&2; exit 1; }
done || errors=1

for name in PROJECT.md .ai-work-os .kilo .wayfinder node_modules __pycache__; do
    if [ -e "$root/$name" ]; then echo "runtime artifact in distribution root: $name" >&2; errors=1; fi
done

core_count=$(find "$root/core/agents" -maxdepth 1 -type f -name '*.md' | wc -l | tr -d ' ')
adapter_count=$(find "$root/adapters/markdown-agents/agents" -maxdepth 1 -type f -name '*.md' | wc -l | tr -d ' ')
[ "$core_count" -eq 7 ] || { echo "core agent count mismatch: $core_count" >&2; errors=1; }
[ "$adapter_count" -eq 8 ] || { echo "adapter agent count mismatch: $adapter_count" >&2; errors=1; }
grep -q '^mode: primary$' "$root/adapters/markdown-agents/agents/ai-work-os.md" || { echo "dispatcher is not primary" >&2; errors=1; }
for name in business-wayfinder business-engineer light-planner light-builder; do
    grep -q '^mode: subagent$' "$root/adapters/markdown-agents/agents/$name.md" || { echo "internal role is visible as primary: $name" >&2; errors=1; }
done
grep -q '^description: .*riprendi.*Code/Build' "$root/skills/ai-work-os/SKILL.md" || { echo "skill resume trigger missing" >&2; errors=1; }
grep -q 'apply the same dispatch table' "$root/skills/ai-work-os/SKILL.md" || { echo "skill generic dispatch missing" >&2; errors=1; }
if find "$root" -type f -name '*.py' | grep -q .; then echo "Python file present in Python-free distribution" >&2; errors=1; fi

for route in business-engineering business-review light-engineering light-review; do
    grep -q "\"$route\"" "$root/adapters/omniroute/combos.json" || { echo "missing route: $route" >&2; errors=1; }
done

[ "$errors" -eq 0 ] || { echo "AI Work OS distribution: FAIL"; exit 1; }
echo "AI Work OS distribution: OK"
echo "Root: $root"
echo "Core roles: 7"
echo "Markdown agents: 8"
echo "Routes: 4"
