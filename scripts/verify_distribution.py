"""Read-only structural verification for an AI Work OS distribution."""

from __future__ import annotations

import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
AGENTS = {
    "business-wayfinder",
    "business-engineer",
    "business-architect",
    "business-reviewer",
    "light-planner",
    "light-builder",
    "light-reviewer",
}
REQUIRED = {
    "README.md",
    "AGENTS.md",
    "INSTALL.md",
    "install.ps1",
    "GETTING_STARTED.md",
    "ARCHITECTURE.md",
    "core/WORKFLOW.md",
    "core/TRACKERS.md",
    "core/ROUTING.md",
    "core/GATES.md",
    "core/BUDGETS.md",
    "core/PORTABILITY.md",
    "templates/PROJECT.example.md",
    "templates/EVIDENCE_PACKAGE.md",
    "adapters/README.md",
    "adapters/omniroute/combos.json",
    "skills/ai-work-os/SKILL.md",
    "scripts/bootstrap.py",
}
FORBIDDEN_ROOT = {"PROJECT.md", ".kilo", ".wayfinder", "node_modules", "__pycache__"}
FORBIDDEN_TEXT = ("C:\\Users\\", "E:/Lavoro/", "E:\\Lavoro\\", "Struttura di lavoro")


def main() -> int:
    errors: list[str] = []
    for relative in sorted(REQUIRED):
        if not (ROOT / relative).is_file():
            errors.append(f"missing: {relative}")

    for name in sorted(FORBIDDEN_ROOT):
        if (ROOT / name).exists():
            errors.append(f"distribution root contains runtime artifact: {name}")

    core_agents = {p.stem for p in (ROOT / "core/agents").glob("*.md")}
    markdown_agents = {p.stem for p in (ROOT / "adapters/markdown-agents/agents").glob("*.md")}
    if core_agents != AGENTS:
        errors.append(f"core agent set mismatch: {sorted(core_agents ^ AGENTS)}")
    if markdown_agents != AGENTS:
        errors.append(f"Markdown adapter agent set mismatch: {sorted(markdown_agents ^ AGENTS)}")

    manifest = json.loads((ROOT / "adapters/omniroute/combos.json").read_text(encoding="utf-8"))
    expected_routes = {"business-engineering", "business-review", "light-engineering", "light-review"}
    if set(manifest.get("combos", {})) != expected_routes:
        errors.append("routing manifest does not contain exactly the four canonical routes")

    for path in ROOT.rglob("*"):
        if path.resolve() == Path(__file__).resolve():
            continue
        if path.is_dir() and path.name in {"__pycache__", "node_modules"}:
            errors.append(f"generated directory present: {path.relative_to(ROOT)}")
        if path.is_file() and path.suffix.lower() in {".md", ".json", ".py", ".txt"}:
            text = path.read_text(encoding="utf-8")
            for marker in FORBIDDEN_TEXT:
                if marker in text:
                    errors.append(f"personal/legacy path in {path.relative_to(ROOT)}: {marker}")

    if errors:
        print("AI Work OS distribution: FAIL")
        for error in errors:
            print(f"- {error}")
        return 1

    print("AI Work OS distribution: OK")
    print(f"Root: {ROOT}")
    print(f"Agents: {len(AGENTS)}")
    print(f"Routes: {len(expected_routes)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
