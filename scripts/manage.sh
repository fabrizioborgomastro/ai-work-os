#!/bin/sh
set -eu

command_name=${1:-status}
shift || true
dry_run=0
if [ "${1:-}" = "--dry-run" ]; then dry_run=1; shift; fi
[ "$#" -eq 0 ] || { echo "Unexpected arguments" >&2; exit 2; }

state=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
manifest="$state/install.json"
ledger="$state/managed-files.tsv"
[ -f "$manifest" ] || { echo "Installation manifest not found: $manifest" >&2; exit 1; }
[ -f "$ledger" ] || { echo "Managed-files ledger not found: $ledger" >&2; exit 1; }

json_value() { sed -n 's/^[[:space:]]*"'"$1"'": "\(.*\)",\{0,1\}$/\1/p' "$manifest" | sed 's/\\"/"/g; s/\\\\/\\/g'; }
client=$(json_value client)
root=$(json_value root)
revision=$(json_value sourceRevision)

hash_file() {
    if command -v sha256sum >/dev/null 2>&1; then sha256sum "$1" | awk '{print $1}';
    else shasum -a 256 "$1" | awk '{print $1}'; fi
}
file_state() {
    path=$1 expected=$2
    [ -f "$path" ] || { printf missing; return; }
    [ "$(hash_file "$path")" = "$expected" ] && printf unchanged || printf modified
}

show_status() {
    detailed=$1 unchanged=0 modified=0 missing=0 total=0
    while IFS='|' read -r path expected pre backup; do
        [ "$path" = path ] && continue
        total=$((total + 1)); result=$(file_state "$path" "$expected")
        case "$result" in
            unchanged) unchanged=$((unchanged + 1)) ;;
            modified) modified=$((modified + 1)); [ "$detailed" -eq 1 ] && echo "[MODIFIED] $path" ;;
            missing) missing=$((missing + 1)); [ "$detailed" -eq 1 ] && echo "[MISSING] $path" ;;
        esac
    done < "$ledger"
    if [ -d "$root" ]; then root_state=present; else root_state=missing; fi
    echo "Client: $client"
    echo "Source: $root ($root_state)"
    echo "Revision: $revision"
    echo "Managed files: $total"
    echo "Unchanged: $unchanged; modified: $modified; missing: $missing"
    if [ "$root_state" = present ] && [ "$modified" -eq 0 ] && [ "$missing" -eq 0 ]; then echo "State: OK"; return 0; fi
    echo "State: ACTION REQUIRED"
    return 1
}

uninstall_files() {
    preserved=0
    while IFS='|' read -r path expected pre backup; do
        [ "$path" = path ] && continue
        [ "$path" = "$state/manage.sh" ] && continue
        [ "$path" = "$state/SETUP-REPORT.md" ] && continue
        result=$(file_state "$path" "$expected")
        [ "$result" = missing ] && continue
        if [ "$result" = modified ]; then echo "PRESERVE modified: $path"; preserved=$((preserved + 1)); continue; fi
        if [ "$pre" = 1 ] && [ -n "$backup" ] && [ -f "$backup" ]; then
            echo "RESTORE: $backup -> $path"
            if [ "$dry_run" -eq 0 ]; then cp -p "$backup" "$path"; rm -f "$backup"; fi
        elif [ "$pre" = 1 ]; then
            echo "PRESERVE pre-existing (no backup recorded): $path"; preserved=$((preserved + 1))
        else
            echo "REMOVE: $path"; [ "$dry_run" -eq 1 ] || rm -f "$path"
        fi
    done < "$ledger"
    if [ "$dry_run" -eq 1 ]; then
        echo "REMOVE OR RESTORE AFTER VALIDATION: $state/SETUP-REPORT.md"
        echo "REMOVE OR RESTORE AFTER VALIDATION: $state/manage.sh"
        echo "Dry run complete; no files changed."
        return
    fi
    if [ "$preserved" -gt 0 ]; then echo "Uninstall incomplete: $preserved file(s) preserved. Manager and state retained."; return; fi
    for deferred_path in "$state/SETUP-REPORT.md" "$state/manage.sh"; do
        line=$(awk -F '|' -v p="$deferred_path" '$1==p { print; exit }' "$ledger")
        [ -n "$line" ] || continue
        path=${line%%|*}; rest=${line#*|}; expected=${rest%%|*}; rest=${rest#*|}; pre=${rest%%|*}; backup=${rest#*|}
        result=$(file_state "$path" "$expected")
        if [ "$result" = modified ]; then echo "PRESERVE modified lifecycle file: $path"; echo "State retained."; return; fi
        if [ "$result" = unchanged ] && [ "$pre" = 1 ] && [ -n "$backup" ] && [ -f "$backup" ]; then cp -p "$backup" "$path"; rm -f "$backup"
        elif [ "$result" = unchanged ] && [ "$pre" = 0 ]; then rm -f "$path"
        elif [ "$result" = unchanged ]; then echo "PRESERVE pre-existing lifecycle file: $path"; echo "State retained."; return
        fi
    done
    rm -f "$ledger" "$manifest"
    echo "AI Work OS uninstalled. Empty parent directories may remain."
}

case "$command_name" in
    status) show_status 0 ;;
    doctor) show_status 1 ;;
    update)
        [ -f "$root/install.sh" ] || { echo "Source installer not found: $root/install.sh" >&2; exit 1; }
        if [ "$dry_run" -eq 1 ]; then sh "$root/install.sh" --client "$client" --dry-run; else sh "$root/install.sh" --client "$client"; fi ;;
    uninstall) uninstall_files ;;
    *) echo "Usage: $0 status|doctor|update|uninstall [--dry-run]" >&2; exit 2 ;;
esac
