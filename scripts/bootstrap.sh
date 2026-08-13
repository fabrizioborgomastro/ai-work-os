#!/bin/sh
set -eu

usage() {
    echo "Usage: $0 [--target CLIENT] [--host HOST] [--analyze] [--apply] [--skill-path PATH]" >&2
    echo "          [--workflow-capability LEVEL] [--routing-capability LEVEL]" >&2
    echo "          [--accept-limited-compatibility] [--accept-unverified]" >&2
}

target="" host=auto skill_path="" workflow_claim=unknown routing_claim=unknown
apply=${AI_WORK_OS_INSTALL_DEFAULT:-0}
accept_limited=0 accept_unverified=0
while [ "$#" -gt 0 ]; do
    case "$1" in
        --target|--client) target=${2-}; shift 2 ;;
        --host) host=${2-}; shift 2 ;;
        --skill-path) skill_path=${2-}; shift 2 ;;
        --workflow-capability) workflow_claim=${2-}; shift 2 ;;
        --routing-capability) routing_claim=${2-}; shift 2 ;;
        --analyze|--dry-run) apply=0; shift ;;
        --apply) apply=1; shift ;;
        --accept-limited-compatibility) accept_limited=1; shift ;;
        --accept-unverified) accept_unverified=1; shift ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Unknown argument: $1" >&2; usage; exit 2 ;;
    esac
done
case "$workflow_claim" in unknown|native|adapted|skill-only|unsupported) ;; *) echo "Invalid workflow capability" >&2; exit 2 ;; esac
case "$routing_claim" in unknown|native-combo|external-manual|unsupported) ;; *) echo "Invalid routing capability" >&2; exit 2 ;; esac

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
catalog="$root/adapters/compatibility.tsv"
state="$HOME/.ai-work-os"
ledger="$state/managed-files.tsv"
old_ledger=""
stamp=$(date -u +%Y%m%dT%H%M%SZ)

catalog_row() { awk -F '|' -v id="$1" '$1==id && $2=="runtime" { print; exit }' "$catalog"; }
field() { printf '%s\n' "$1" | awk -F '|' -v n="$2" '{ print $n }'; }

detected=""
while IFS='|' read -r id kind display command rest; do
    [ "$kind" = runtime ] || continue
    [ -n "$command" ] || continue
    if command -v "$command" >/dev/null 2>&1; then detected="${detected}${detected:+, }$id"; fi
done < "$catalog"

if [ -z "$target" ] && [ -n "${AI_WORK_OS_TARGET:-}" ]; then target=$AI_WORK_OS_TARGET; fi
if [ -z "$target" ]; then
    case "$detected" in
        "") echo "The target runtime is ambiguous; detected: none. Use --target <runtime>." >&2; exit 2 ;;
        *,*) echo "The target runtime is ambiguous; detected: $detected. Use --target <runtime>." >&2; exit 2 ;;
        *) target=$detected ;;
    esac
fi
target=$(printf '%s' "$target" | tr '[:upper:]' '[:lower:]')

if [ "$host" = auto ]; then
    if [ -n "${CURSOR_TRACE_ID:-}" ] || [ "${TERM_PROGRAM:-}" = cursor ]; then host=cursor
    elif [ -n "${ANTIGRAVITY_HOME:-}" ] || [ -n "${ANTIGRAVITY_SESSION:-}" ]; then host=antigravity
    elif [ -n "${VSCODE_PID:-}" ] || [ "${TERM_PROGRAM:-}" = vscode ]; then host=vscode
    else host=terminal
    fi
fi

row=$(catalog_row "$target")
verified=0
if [ -n "$row" ] && [ "$target" != generic ]; then
    verified=1
    adapter=$(field "$row" 5)
    workflow=$(field "$row" 6)
    routing=$(field "$row" 7)
    limitation=$(field "$row" 9)
    recommendation=$(field "$row" 10)
    verified_at=$(field "$row" 11)
    evidence=$(field "$row" 12)
else
    adapter=generic-explicit workflow=$workflow_claim routing=$routing_claim
    limitation="Runtime non catalogato: percorso e capacita non sono verificati automaticamente."
    recommendation="Fornire --skill-path e verificare la documentazione ufficiale del runtime."
    verified_at="" evidence="UNKNOWN: runtime non presente nel catalogo locale"
fi

case "$routing" in
    native-combo)
        routing_status="CAPABLE - configuration not verified"
        combo_status="Available only after the runtime combos and providers are configured and tested"
        routing_action="Verify the four routes in core/ROUTING.md; the installer does not create provider or combo configuration" ;;
    external-manual)
        routing_status="NOT CONFIGURED"
        combo_status="Unavailable until a compatible routing layer is configured"
        routing_action="Configure OmniRoute, an equivalent external router, or a supported manual runtime mapping" ;;
    unsupported)
        routing_status="UNSUPPORTED" combo_status="Unavailable"
        routing_action="Use a runtime or router that can implement the four logical routes" ;;
    *)
        routing_status="UNKNOWN" combo_status="Not verified"
        routing_action="Verify routing capabilities before relying on combos, fallbacks or review panels" ;;
esac

echo ""
echo "Compatibility preflight"
echo "Host/editor: $host (informational only)"
echo "Target runtime: $target"
echo "Adapter: $adapter"
echo "Workflow compatibility: $workflow"
echo "Routing compatibility: $routing"
echo "Multiprovider routing: $routing_status"
echo "Combo support: $combo_status"
echo "Routing action: $routing_action"
if [ "$verified" -eq 1 ]; then echo "Catalog status: VERIFIED"; else echo "Catalog status: UNVERIFIED"; fi
echo "Limitation: $limitation"
echo "Recommendation: $recommendation"

if [ "$verified" -eq 0 ]; then
    echo "Minimum audit:"
    if command -v "$target" >/dev/null 2>&1; then echo "- Executable: VERIFIED: command found on PATH"; else echo "- Executable: UNKNOWN: command not found on PATH"; fi
    if [ -n "$skill_path" ]; then echo "- Skill destination: INFERRED: user supplied skill path $skill_path"; else echo "- Skill destination: UNKNOWN: no skill destination supplied"; fi
    echo "- Workflow claim: INFERRED ($workflow_claim)"
    echo "- Routing claim: INFERRED ($routing_claim)"
fi

if [ "$apply" -eq 1 ] && [ "$verified" -eq 0 ]; then
    [ -n "$skill_path" ] || { echo "Unverified target blocked: provide --skill-path. No files were changed." >&2; exit 1; }
    [ "$accept_unverified" -eq 1 ] || { echo "Unverified target blocked: add --accept-unverified after reviewing the audit. No files were changed." >&2; exit 1; }
    [ "$workflow_claim" != unsupported ] || { echo "The declared workflow capability is unsupported. No files were changed." >&2; exit 1; }
fi
if [ "$apply" -eq 1 ] && [ "$verified" -eq 1 ] && [ "$workflow" != native ] && [ "$accept_limited" -ne 1 ]; then
    echo "Compatibility is $workflow. Add --accept-limited-compatibility after reviewing the limitations. No files were changed." >&2
    exit 1
fi

skill_base() {
    if [ "$verified" -eq 0 ]; then printf '%s' "$skill_path"; return; fi
    case "$target" in
        kilo) printf '%s' "$HOME/.kilo/skills" ;;
        opencode) printf '%s' "$HOME/.config/opencode/skills" ;;
        pi) printf '%s' "$HOME/.pi/agent/skills" ;;
        codex) printf '%s' "$HOME/.codex/skills" ;;
        claude) printf '%s' "$HOME/.claude/skills" ;;
    esac
}

show_targets() {
    case "$target" in kilo) echo "- $HOME/.config/kilo/agents" ;; opencode) echo "- $HOME/.config/opencode/agents" ;; esac
    base=$(skill_base)
    echo "- $base/ai-work-os"
    echo "- $base/wayfinder"
    [ "$target" = pi ] && echo "- $HOME/.pi/agent/prompts"
    echo "- $state/manage.sh"
    echo "- $state/SETUP-REPORT.md"
    echo "- $state/install.json"
    echo "- $ledger"
}

echo "Planned targets:"
if [ "$verified" -eq 1 ] || [ -n "$skill_path" ]; then show_targets; else echo "- BLOCKED until an explicit skill destination is supplied"; fi
if [ "$apply" -eq 0 ]; then echo "Analysis complete: no files changed."; exit 0; fi

hash_file() {
    if command -v sha256sum >/dev/null 2>&1; then sha256sum "$1" | awk '{print $1}'
    else shasum -a 256 "$1" | awk '{print $1}'; fi
}

mkdir -p "$state"
if [ -f "$ledger" ]; then old_ledger=$(mktemp "${TMPDIR:-/tmp}/ai-work-os-old.XXXXXX"); cp "$ledger" "$old_ledger"; fi
new_ledger=$(mktemp "${TMPDIR:-/tmp}/ai-work-os-new.XXXXXX")
printf '%s\n' 'path|installedHash|preExisting|backupPath' > "$new_ledger"
rendered=""
cleanup() { rm -f "${old_ledger:-}" "${new_ledger:-}" "${rendered:-}"; }
trap cleanup EXIT HUP INT TERM

record_file() {
    path=$1 pre=$2 backup=$3
    case "$path" in *'|'*) echo "Managed paths cannot contain pipes: $path" >&2; exit 1 ;; esac
    if [ -n "$old_ledger" ]; then
        prior=$(awk -F '|' -v p="$path" '$1==p { print $3 "|" $4; exit }' "$old_ledger")
        if [ -n "$prior" ]; then pre=${prior%%|*}; prior_backup=${prior#*|}; [ -n "$backup" ] || backup=$prior_backup; fi
    fi
    printf '%s|%s|%s|%s\n' "$path" "$(hash_file "$path")" "$pre" "$backup" >> "$new_ledger"
}

install_file() {
    source=$1 destination=$2
    mkdir -p "$(dirname -- "$destination")"
    pre=0 backup=""
    if [ -f "$destination" ]; then
        pre=1
        if ! cmp -s "$source" "$destination"; then backup="$destination.backup-$stamp"; cp -p "$destination" "$backup"; fi
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
        agent) sed -e "s|\`core/|\`$escaped_root/core/|g" -e "s|\`templates/|\`$escaped_root/templates/|g" "$source" > "$rendered" ;;
    esac
    install_file "$rendered" "$destination"
    rm -f "$rendered"; rendered=""
}

base=$(skill_base)
install_rendered "$root/skills/ai-work-os/SKILL.md" "$base/ai-work-os/SKILL.md" skill
for name in SKILL.md LICENSE README.md; do install_file "$root/third_party/mattpocock-wayfinder/$name" "$base/wayfinder/$name"; done

if [ "$target" = kilo ] || [ "$target" = opencode ]; then
    if [ "$target" = kilo ]; then agent_target="$HOME/.config/kilo/agents"; else agent_target="$HOME/.config/opencode/agents"; fi
    for source in "$root"/adapters/markdown-agents/agents/*.md; do install_rendered "$source" "$agent_target/$(basename "$source")" agent; done
fi

if [ "$target" = pi ]; then
    for role in business-wayfinder business-engineer business-architect business-reviewer light-planner light-builder light-reviewer; do
        rendered=$(mktemp "${TMPDIR:-/tmp}/ai-work-os-prompt.XXXXXX")
        printf 'Activate the AI Work OS `%s` role for the project in the current working directory.\n\nRead and follow `%s/core/agents/%s.md` and the shared policies under `%s/core/`. Treat `%s` as read-only. Persist all operational artifacts and handoffs in the actual project.\n' "$role" "$root" "$role" "$root" "$root" > "$rendered"
        install_file "$rendered" "$HOME/.pi/agent/prompts/ai-$role.md"
        rm -f "$rendered"; rendered=""
    done
fi

install_file "$root/scripts/manage.sh" "$state/manage.sh"
chmod +x "$state/manage.sh"

rendered=$(mktemp "${TMPDIR:-/tmp}/ai-work-os-report.XXXXXX")
cat > "$rendered" <<EOF
# AI Work OS setup report

- Status: **APPLIED**
- Host/editor: \`$host\` (informational; no files installed in the host)
- Target runtime: \`$target\`
- Adapter: \`$adapter\`
- Workflow compatibility: **$workflow**
- Routing compatibility: **$routing**
- Multiprovider routing: **$routing_status**
- Combo support: **$combo_status**
- Catalog verification: **$verified**
- Runtimes detected on PATH: ${detected:-none}
- Installation scope: only \`$target\`
- Canonical core: \`$root\`

## What was installed

$(show_targets)

## What was not installed or configured

- No files for other agentic clients or host editors.
- No provider, credential, plugin, MCP, combo, fallback, privacy control or spending limit.
- Routing action required: $routing_action.
- Limitation: $limitation
- Recommendation: $recommendation
- Evidence: $evidence${verified_at:+ (verified $verified_at)}

## Lifecycle commands

- \`$state/manage.sh status\`
- \`$state/manage.sh compatibility\`
- \`$state/manage.sh doctor\`
- \`$state/manage.sh update --dry-run\`
- \`$state/manage.sh uninstall --dry-run\`

## First use

$(if [ "$target" = kilo ] || [ "$target" = opencode ]; then printf 'Close any chat opened before this install/update: existing sessions retain their original permissions. Create a new session, select the `ai-work-os` agent, open the real project directory and type `riprendi`. Keep the dispatcher selected; it invokes the specialized role from persisted project state.'; else printf 'Open the real project directory, activate the AI Work OS skill and type `riprendi`. The skill selects the role from persisted project state using the capabilities available in this runtime.'; fi)

Configure credentials through the runtime's secure flow. Verify privacy, provider and budget policies before sending real project data.
EOF
install_file "$rendered" "$state/SETUP-REPORT.md"
rm -f "$rendered"; rendered=""

mv "$new_ledger" "$ledger"; new_ledger=""
revision=unknown
if command -v git >/dev/null 2>&1; then revision=$(git -C "$root" rev-parse HEAD 2>/dev/null || printf unknown); fi
json_escape() { printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'; }
cat > "$state/install.json" <<EOF
{
  "schemaVersion": 2,
  "installedAt": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "client": "$(json_escape "$target")",
  "target": "$(json_escape "$target")",
  "host": "$(json_escape "$host")",
  "adapter": "$(json_escape "$adapter")",
  "workflowCompatibility": "$(json_escape "$workflow")",
  "routingCompatibility": "$(json_escape "$routing")",
  "compatibilityVerified": "$verified",
  "skillPath": "$(json_escape "$skill_path")",
  "root": "$(json_escape "$root")",
  "sourceRevision": "$(json_escape "$revision")",
  "report": "$(json_escape "$state/SETUP-REPORT.md")",
  "ledger": "$(json_escape "$ledger")",
  "installer": "shell"
}
EOF
echo "Installation complete."
echo "Manager: $state/manage.sh"
if [ "$target" = kilo ] || [ "$target" = opencode ]; then
    echo "Next: close chats opened before this install/update, create a new session, select ai-work-os and type 'riprendi'."
fi
