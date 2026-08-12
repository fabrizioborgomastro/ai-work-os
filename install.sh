#!/bin/sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
echo "AI Work OS root: $root"
echo "Installer engine: POSIX shell (Python is not required)"
AI_WORK_OS_INSTALL_DEFAULT=1; export AI_WORK_OS_INSTALL_DEFAULT
exec sh "$root/scripts/bootstrap.sh" "$@"
