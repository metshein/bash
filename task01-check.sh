#!/usr/bin/env bash

set -euo pipefail

source "$(dirname "$0")/common.sh"

echo "Checking system and network..."
uname -a

if ping -c 1 metshein.com >/dev/null 2>&1; then
    echo "Network OK"
    send_result 1
else
    echo "Network FAIL"
    exit 1
fi
