"""Bootstrap AI Work OS into a supported agentic client.

Dry-run is the default. Use --apply to write outside the distribution.
Credentials, provider accounts and paid model calls are never touched.
"""

from __future__ import annotations

import argparse
import json
import shutil
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path


CLIENT_COMMANDS = {
    "kilo": "kilo",
    "opencode": "opencode",
    "pi": "pi",
    "codex": "codex",
    "claude": "claude",
}
ROLES = (
    "business-wayfinder",
    "business-engineer",
    "business-architect",
    "business-reviewer",
    "light-planner",
    "light-builder",
    "light-reviewer",
)
ROUTES = (
    "business-engineering",
    "business-review",
    "light-engineering",
    "light-review",
)


def detect_clients() -> list[str]:
    return [name for name, command in CLIENT_COMMANDS.items() if shutil.which(command)]


def resolve_client(requested: str) -> tuple[str, list[str]]:
    detected = detect_clients()
    if requested != "auto":
        return requested, detected
    if len(detected) == 1:
        return detected[0], detected
    return "generic", detected


def client_targets(client: str) -> list[Path]:
    home = Path.home()
    skill_base = home / (f".{client}/skills" if client in {"codex", "claude"} else ".agents/skills")
    if client == "kilo":
        return [home / ".config/kilo/agents", skill_base / "ai-work-os", skill_base / "wayfinder"]
    if client == "opencode":
        return [home / ".config/opencode/agents", skill_base / "ai-work-os", skill_base / "wayfinder"]
    if client == "pi":
        return [skill_base / "ai-work-os", skill_base / "wayfinder", home / ".pi/agent/prompts"]
    return [skill_base / "ai-work-os", skill_base / "wayfinder"]


def backup_and_write(path: Path, content: str, stamp: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    if path.exists() and path.read_text(encoding="utf-8") != content:
        shutil.copy2(path, path.with_name(f"{path.name}.backup-{stamp}"))
    path.write_text(content, encoding="utf-8", newline="\n")


def render_ai_work_os_skill(root: Path) -> str:
    source = root / "skills/ai-work-os/SKILL.md"
    return source.read_text(encoding="utf-8").replace("{{AI_WORK_OS_HOME}}", root.as_posix())


def install_skills(root: Path, client: str, stamp: str) -> None:
    home = Path.home()
    base = home / (f".{client}/skills" if client in {"codex", "claude"} else ".agents/skills")
    backup_and_write(base / "ai-work-os/SKILL.md", render_ai_work_os_skill(root), stamp)

    wayfinder_source = root / "third_party/mattpocock-wayfinder"
    for name in ("SKILL.md", "LICENSE", "README.md"):
        backup_and_write(
            base / "wayfinder" / name,
            (wayfinder_source / name).read_text(encoding="utf-8"),
            stamp,
        )


def install_markdown_agents(root: Path, client: str) -> None:
    subprocess.run(
        [sys.executable, str(root / "scripts/install_markdown_agents.py"), "--client", client],
        check=True,
    )


def install_pi_prompts(root: Path, stamp: str) -> None:
    target = Path.home() / ".pi/agent/prompts"
    policies = "WORKFLOW.md, TRACKERS.md, ROUTING.md, GATES.md and BUDGETS.md"
    for role in ROLES:
        content = (
            f"Activate the AI Work OS `{role}` role for the project in the current working directory.\n\n"
            f"Read and follow `{root.as_posix()}/core/agents/{role}.md` and the shared policies "
            f"under `{root.as_posix()}/core/` ({policies}). Treat `{root.as_posix()}` as read-only. "
            "Persist all operational artifacts and handoffs in the actual project.\n"
        )
        backup_and_write(target / f"ai-{role}.md", content, stamp)


def config_text_for(client: str) -> str:
    home = Path.home()
    candidates = {
        "kilo": [home / ".config/kilo/kilo.jsonc"],
        "opencode": [home / ".config/opencode/opencode.json", home / ".config/opencode/opencode.jsonc"],
        "pi": [home / ".pi/agent/models.json"],
    }.get(client, [])
    chunks: list[str] = []
    for path in candidates:
        if path.is_file():
            chunks.append(path.read_text(encoding="utf-8", errors="replace"))
    return "\n".join(chunks)


def build_report(root: Path, client: str, detected: list[str], applied: bool) -> str:
    config = config_text_for(client)
    missing_routes = [route for route in ROUTES if route not in config]
    status = "APPLIED" if applied else "DRY RUN — no files changed"
    targets = "\n".join(f"- `{path}`" for path in client_targets(client))
    missing = "\n".join(f"- `{route}`" for route in missing_routes) or "- none detected"
    return f"""# AI Work OS setup report

- Status: **{status}**
- Client selected: `{client}`
- Clients detected on PATH: {', '.join(detected) if detected else 'none'}
- Canonical core: `{root}`

## Installation targets

{targets}

## Route names not found in the inspected client configuration

{missing}

Configure or verify all four routes according to `{root / 'core/ROUTING.md'}`. A route may live in an external router and therefore not appear in the client config; verify it there instead.

## Manual checklist

1. Configure model/provider credentials using the client's secure credential flow.
2. For Business, verify no free endpoints, ZDR/no-training, allowlist and spending cap.
3. For Light, set the project spending cap and never provide sensitive material to free endpoints.
4. Reload the client and confirm the installed roles and both skills are visible.
5. If GitHub Issues is selected later, approve an official integration and authentication method.
6. Open a synthetic project and test planning -> handoff -> build without paid calls where possible.

## Bundled third-party component

- Wayfinder by Matt Pocock, revision `84fdeffd12f2ee307994d1eb6feb48173b6e0502`.
- License: MIT; the copyright notice and license are installed beside the skill.
- See `{root / 'THIRD_PARTY_NOTICES.md'}` for provenance and attribution.

## First use

- Business: start with `business-wayfinder` unless decisions are already mature.
- Light: start with `light-planner` unless the task is already small and fully specified.
"""


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--client", choices=["auto", *CLIENT_COMMANDS, "generic"], default="auto")
    parser.add_argument("--apply", action="store_true", help="Write installation files")
    args = parser.parse_args()

    root = Path(__file__).resolve().parents[1]
    client, detected = resolve_client(args.client)
    stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")

    print(f"AI Work OS: {root}")
    print(f"Requested client: {args.client}")
    print(f"Detected clients: {', '.join(detected) if detected else 'none'}")
    print(f"Selected adapter: {client}")
    print("Planned targets:")
    for target in client_targets(client):
        print(f"- {target}")

    if args.client == "auto" and len(detected) != 1:
        print("Auto-detection is ambiguous; generic skill selected. Re-run with an explicit --client for a native adapter.")

    if args.apply:
        if client in {"kilo", "opencode"}:
            install_markdown_agents(root, client)
            install_skills(root, client, stamp)
        elif client == "pi":
            install_skills(root, client, stamp)
            install_pi_prompts(root, stamp)
        else:
            install_skills(root, client, stamp)

    report = build_report(root, client, detected, args.apply)
    if args.apply:
        report_path = Path.home() / ".ai-work-os/SETUP-REPORT.md"
        report_path.parent.mkdir(parents=True, exist_ok=True)
        report_path.write_text(report, encoding="utf-8")
        metadata = {
            "installedAt": datetime.now(timezone.utc).isoformat(),
            "client": client,
            "root": str(root),
            "report": str(report_path),
            "thirdParty": {
                "wayfinder": {
                    "revision": "84fdeffd12f2ee307994d1eb6feb48173b6e0502",
                    "license": "MIT",
                }
            },
        }
        (report_path.parent / "install.json").write_text(json.dumps(metadata, indent=2), encoding="utf-8")
        print(f"Report: {report_path}")
    else:
        print("\n" + report)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
