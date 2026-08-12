#!/bin/sh
set -eu

client=""
apply=0
while [ "$#" -gt 0 ]; do
    case "$1" in
        --client) client=${2-}; shift 2 ;;
        --apply) apply=1; shift ;;
        *) echo "Unknown argument: $1" >&2; exit 2 ;;
    esac
done
case "$client" in kilo|opencode|pi|codex|claude|generic) ;; *) echo "Explicit --client is required" >&2; exit 2 ;; esac

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
state="$HOME/.ai-work-os"
ledger="$state/managed-files.tsv"
old_ledger=""
stamp=$(date -u +%Y%m%dT%H%M%SZ)

hash_file() {
    if command -v sha256sum >/dev/null 2>&1; then sha256sum "$1" | awk '{print $1}';
    else shasum -a 256 "$1" | awk '{print $1}'; fi
}

skill_base() {
    case "$client" in
        kilo) printf '%s' "$HOME/.kilo/skills" ;;
        opencode) printf '%s' "$HOME/.config/opencode/skills" ;;
        pi) printf '%s' "$HOME/.pi/agent/skills" ;;
        codex) printf '%s' "$HOME/.codex/skills" ;;
        claude) printf '%s' "$HOME/.claude/skills" ;;
        generic) printf '%s' "$HOME/.agents/skills" ;;
    esac
}

show_targets() {
    case "$client" in
        kilo) echo "- $HOME/.config/kilo/agents" ;;
        opencode) echo "- $HOME/.config/opencode/agents" ;;
    esac
    base=$(skill_base)
    echo "- $base/ai-work-os"
    echo "- $base/wayfinder"
    [ "$client" = pi ] && echo "- $HOME/.pi/agent/prompts"
    echo "- $state/manage.sh"
    echo "- $state/SETUP-REPORT.md"
    echo "- $state/install.json"
    echo "- $ledger"
}

echo "AI Work OS: $root"
echo "Selected adapter: $client"
echo "Installation scope: only $client"
echo "Planned targets:"
show_targets
if [ "$apply" -eq 0 ]; then
    echo "Dry run: no files changed."
    exit 0
fi

mkdir -p "$state"
if [ -f "$ledger" ]; then
    old_ledger=$(mktemp "${TMPDIR:-/tmp}/ai-work-os-old.XXXXXX")
    cp "$ledger" "$old_ledger"
fi
new_ledger=$(mktemp "${TMPDIR:-/tmp}/ai-work-os-new.XXXXXX")
printf '%s\n' 'path|installedHash|preExisting|backupPath' > "$new_ledger"
cleanup() { rm -f "${old_ledger:-}" "${new_ledger:-}" "${rendered:-}"; }
trap cleanup EXIT HUP INT TERM

record_file() {
    path=$1 pre=$2 backup=$3
    case "$path" in *'|'*) echo "Managed paths cannot contain pipes: $path" >&2; exit 1 ;; esac
    if [ "$(printf '%s' "$path" | wc -l | tr -d ' ')" -ne 0 ]; then
        echo "Managed paths cannot contain newlines: $path" >&2; exit 1
    fi
    if [ -n "$old_ledger" ]; then
        prior=$(awk -F '|' -v p="$path" '$1==p { print $3 "|" $4; exit }' "$old_ledger")
        if [ -n "$prior" ]; then
            pre=${prior%%|*}
            prior_backup=${prior#*|}
            [ -n "$backup" ] || backup=$prior_backup
        fi
    fi
    printf '%s|%s|%s|%s\n' "$path" "$(hash_file "$path")" "$pre" "$backup" >> "$new_ledger"
}

install_file() {
    source=$1 destination=$2
    mkdir -p "$(dirname -- "$destination")"
    pre=0 backup=""
    if [ -f "$destination" ]; then
        pre=1
        if ! cmp -s "$source" "$destination"; then
            backup="$destination.backup-$stamp"
            cp -p "$destination" "$backup"
        fi
    fi
    cp "$source" "$destination"
    record_file "$destination" "$pre" "$backup"
}

install_rendered() {
    source=$1 destination=$2 mode=$3
    rendered=$(mktemp "${TMPDIR:-/tmp}/ai-work-os-render.XXXXXX")
    escaped_root=$(printf '%s' "$root" | sed 's/[&|]/\\&/g')
    case "$mode" in
        skill) sed "s|{{AI_WORK_OS_HOME}}|$escaped_root|g" "$source" > "$rendered" ;;
        agent)
            sed -e "s|\`core/|\`$escaped_root/core/|g" -e "s|\`templates/|\`$escaped_root/templates/|g" "$source" > "$rendered" ;;
    esac
    install_file "$rendered" "$destination"
    rm -f "$rendered"; rendered=""
}

base=$(skill_base)
install_rendered "$root/skills/ai-work-os/SKILL.md" "$base/ai-work-os/SKILL.md" skill
for name in SKILL.md LICENSE README.md; do install_file "$root/third_party/mattpocock-wayfinder/$name" "$base/wayfinder/$name"; done

if [ "$client" = kilo ] || [ "$client" = opencode ]; then
    if [ "$client" = kilo ]; then agent_target="$HOME/.config/kilo/agents"; else agent_target="$HOME/.config/opencode/agents"; fi
    for source in "$root"/adapters/markdown-agents/agents/*.md; do install_rendered "$source" "$agent_target/$(basename "$source")" agent; done
fi

if [ "$client" = pi ]; then
    mkdir -p "$HOME/.pi/agent/prompts"
    for role in business-wayfinder business-engineer business-architect business-reviewer light-planner light-builder light-reviewer; do
        rendered=$(mktemp "${TMPDIR:-/tmp}/ai-work-os-prompt.XXXXXX")
        printf 'Activate the AI Work OS `%s` role for the project in the current working directory.\n\nRead and follow `%s/core/agents/%s.md` and the shared policies under `%s/core/`. Treat `%s` as read-only. Persist all operational artifacts and handoffs in the actual project.\n' "$role" "$root" "$role" "$root" "$root" > "$rendered"
        install_file "$rendered" "$HOME/.pi/agent/prompts/ai-$role.md"
        rm -f "$rendered"; rendered=""
    done
fi

install_file "$root/scripts/manage.sh" "$state/manage.sh"
chmod +x "$state/manage.sh"
# Re-record after chmod because permissions do not affect SHA-256 content.

rendered=$(mktemp "${TMPDIR:-/tmp}/ai-work-os-report.XXXXXX")
cat > "$rendered" <<EOF
# AI Work OS setup report

- Status: **APPLIED**
- Client selected: \`$client\`
- Installation scope: only the selected client
- Canonical core: \`$root\`

Run lifecycle commands from any directory:

- \`$state/manage.sh status\`
- \`$state/manage.sh doctor\`
- \`$state/manage.sh update --dry-run\`
- \`$state/manage.sh uninstall --dry-run\`

Provider credentials, routes, privacy controls, budgets and external integrations remain manual.
EOF
install_file "$rendered" "$state/SETUP-REPORT.md"
rm -f "$rendered"; rendered=""

mv "$new_ledger" "$ledger"; new_ledger=""
revision=unknown
if command -v git >/dev/null 2>&1; then revision=$(git -C "$root" rev-parse HEAD 2>/dev/null || printf unknown); fi
json_escape() { printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'; }
cat > "$state/install.json" <<EOF
{
  "schemaVersion": 1,
  "installedAt": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "client": "$(json_escape "$client")",
  "root": "$(json_escape "$root")",
  "sourceRevision": "$(json_escape "$revision")",
  "report": "$(json_escape "$state/SETUP-REPORT.md")",
  "ledger": "$(json_escape "$ledger")",
  "installer": "shell"
}
EOF
echo "Installation complete."
echo "Manager: $state/manage.sh"
