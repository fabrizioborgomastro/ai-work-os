"""Read-only structural verification for an AI Work OS distribution."""

from __future__ import annotations

import json
import hashlib
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
    "ROADMAP.md",
    "AGENTS.md",
    "INSTALL.md",
    "install.ps1",
    "LICENSE",
    "THIRD_PARTY_NOTICES.md",
    "third_party/mattpocock-wayfinder/SKILL.md",
    "third_party/mattpocock-wayfinder/LICENSE",
    "third_party/mattpocock-wayfinder/README.md",
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
WAYFINDER_SHA256 = "d33e2141f7c8bbfd137fef0213cbec465820e4680e67da5d0f0815d6742d26c2"


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

    wayfinder = ROOT / "third_party/mattpocock-wayfinder/SKILL.md"
    if wayfinder.is_file() and hashlib.sha256(wayfinder.read_bytes()).hexdigest() != WAYFINDER_SHA256:
        errors.append("vendored Wayfinder snapshot differs from the recorded upstream revision")

    wayfinder_license = ROOT / "third_party/mattpocock-wayfinder/LICENSE"
    if wayfinder_license.is_file():
        license_text = wayfinder_license.read_text(encoding="utf-8")
        if "Copyright (c) 2026 Matt Pocock" not in license_text or "MIT License" not in license_text:
            errors.append("vendored Wayfinder MIT attribution is incomplete")

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
