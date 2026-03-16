#!/usr/bin/env bash

set -euo pipefail

SERVER="${SERVER_URL:-http://10.10.10.139/skripti_kontroll/api/submit.php}"
HOST="$(hostname)"
OS="$(grep PRETTY_NAME /etc/os-release | cut -d '"' -f2 2>/dev/null || uname -s)"

send_result() {
    local task="$1"

    curl -sS -X POST "$SERVER" \
        -d "hostname=$HOST" \
        -d "task=$task" \
        -d "os=$OS"

    echo
    echo "Result sent for task $task"
}
