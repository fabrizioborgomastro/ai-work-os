#!/bin/sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
bootstrap="$root/scripts/bootstrap.sh"
test_home=$(mktemp -d "${TMPDIR:-/tmp}/ai-work-os-test.XXXXXX")
cleanup() { rm -rf "$test_home"; }
trap cleanup EXIT HUP INT TERM

cursor_claude=$(HOME="$test_home" sh "$bootstrap" --target claude --host cursor --analyze)
printf '%s\n' "$cursor_claude" | grep -q 'Host/editor: cursor'
printf '%s\n' "$cursor_claude" | grep -q 'Workflow compatibility: skill-only'
if printf '%s\n' "$cursor_claude" | grep -q '/.config/kilo'; then echo "Cursor/Claude planned Kilo files" >&2; exit 1; fi

antigravity_kilo=$(HOME="$test_home" sh "$bootstrap" --target kilo --host antigravity --analyze)
printf '%s\n' "$antigravity_kilo" | grep -q 'Routing compatibility: native-combo'

unknown=$(HOME="$test_home" sh "$bootstrap" --target unknown-test-runtime --analyze)
printf '%s\n' "$unknown" | grep -q 'Catalog status: UNVERIFIED'
printf '%s\n' "$unknown" | grep -q 'BLOCKED until an explicit skill destination'

if HOME="$test_home" sh "$bootstrap" --target claude --host cursor --apply >/dev/null 2>&1; then
    echo "Limited compatibility apply did not require acknowledgement" >&2; exit 1
fi
if HOME="$test_home" sh "$bootstrap" --target unknown-test-runtime --apply >/dev/null 2>&1; then
    echo "Unknown runtime apply did not require a skill path" >&2; exit 1
fi
[ ! -e "$test_home/.ai-work-os" ] || { echo "Blocked tests wrote installation state" >&2; exit 1; }

echo "Compatibility tests: OK"
echo "Cases: Cursor/Claude, Antigravity/Kilo, unknown runtime, acknowledgement gates"
