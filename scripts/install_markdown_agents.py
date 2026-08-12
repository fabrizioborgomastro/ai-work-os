"""Install AI Work OS Markdown agents for a supported client.

This copies only adapter files. The canonical core stays in this distribution
directory and is referenced through its resolved absolute path.
"""

from __future__ import annotations

import argparse
import shutil
from datetime import datetime, timezone
from pathlib import Path


CLIENT_DIRS = {
    "kilo": Path(".config/kilo/agents"),
    "opencode": Path(".config/opencode/agents"),
}


def render(text: str, root: Path) -> str:
    portable = root.resolve().as_posix()
    return (
        text.replace("`core/", f"`{portable}/core/")
        .replace("`templates/", f"`{portable}/templates/")
    )


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--client", choices=sorted(CLIENT_DIRS), required=True)
    parser.add_argument("--target", type=Path, help="Override the global agents directory")
    args = parser.parse_args()

    root = Path(__file__).resolve().parents[1]
    source = root / "adapters" / "markdown-agents" / "agents"
    target = args.target.expanduser().resolve() if args.target else (Path.home() / CLIENT_DIRS[args.client]).resolve()
    target.mkdir(parents=True, exist_ok=True)

    stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    installed: list[str] = []
    for src in sorted(source.glob("*.md")):
        dst = target / src.name
        if dst.exists():
            shutil.copy2(dst, target / f"{src.name}.backup-{stamp}")
        dst.write_text(render(src.read_text(encoding="utf-8"), root), encoding="utf-8")
        installed.append(src.stem)

    print(f"Client: {args.client}")
    print(f"Core: {root}")
    print(f"Target: {target}")
    print(f"Installed: {', '.join(installed)}")
    print("Next: map the four route names from core/ROUTING.md in the client/provider configuration.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
