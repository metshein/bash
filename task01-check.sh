#!/usr/bin/env bash

set -euo pipefail

source "$(dirname "$0")/common.sh"

echo "Checking system and network..."
uname -a

network_ok=0

# ICMP can be blocked on some networks; accept other successful probes too.
if ping -c 1 -W 2 metshein.com >/dev/null 2>&1 || \
   ping -c 1 -W 2 1.1.1.1 >/dev/null 2>&1; then
    network_ok=1
fi

if [ "$network_ok" -eq 0 ] && command -v curl >/dev/null 2>&1; then
    if curl -fsS --connect-timeout 3 https://metshein.com >/dev/null 2>&1 || \
       curl -fsS --connect-timeout 3 https://github.com >/dev/null 2>&1; then
        network_ok=1
    fi
fi

if [ "$network_ok" -eq 0 ] && command -v getent >/dev/null 2>&1; then
    if getent hosts metshein.com >/dev/null 2>&1; then
        network_ok=1
    fi
fi

if [ "$network_ok" -eq 1 ]; then
    echo "Network OK"
    send_result 1
else
    echo "Network FAIL"
    exit 1
fi
