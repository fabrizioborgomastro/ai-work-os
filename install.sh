#!/bin/sh
set -eu

usage() {
    echo "Usage: ./install.sh --client kilo|opencode|pi|codex|claude|generic [--dry-run]"
}

client=""
dry_run=0
while [ "$#" -gt 0 ]; do
    case "$1" in
        --client) client=${2-}; shift 2 ;;
        --dry-run) dry_run=1; shift ;;
        *) usage; exit 2 ;;
    esac
done

case "$client" in
    kilo|opencode|pi|codex|claude|generic) ;;
    *) usage; exit 2 ;;
esac

root=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
echo "AI Work OS root: $root"
echo "Selected client: $client"
echo "Installer engine: POSIX shell (Python is not required)"
if [ "$dry_run" -eq 1 ]; then
    exec sh "$root/scripts/bootstrap.sh" --client "$client"
fi
exec sh "$root/scripts/bootstrap.sh" --client "$client" --apply
