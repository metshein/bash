#!/usr/bin/env bash

set -u -o pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"

tasks=(
    task01-check.sh
    task02-check.sh
    task03-check.sh
    task04-check.sh
    task05-check.sh
    task06-check.sh
    task07-check.sh
    task08-check.sh
    task09-check.sh
    task10-check.sh
    task11-check.sh
    task12-check.sh
    task13-check.sh
    task14-check.sh
    task15-check.sh
    task16-check.sh
    task17-check.sh
)

passed=0
failed=0

for task in "${tasks[@]}"; do
    task_path="$script_dir/$task"

    if [ ! -x "$task_path" ]; then
        chmod +x "$task_path" 2>/dev/null || true
    fi

    if [ ! -f "$task_path" ]; then
        printf '[PUUDU] %s\n' "$task"
        failed=$((failed + 1))
        continue
    fi

    printf '\n=== %s ===\n' "$task"
    if "$task_path"; then
        passed=$((passed + 1))
    else
        failed=$((failed + 1))
    fi
done

printf '\nKokkuv\u00f5te: %d korras, %d ebaonnestus\n' "$passed" "$failed"

if [ "$failed" -eq 0 ]; then
    exit 0
fi

exit 1