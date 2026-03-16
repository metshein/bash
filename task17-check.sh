#!/usr/bin/env bash

set -euo pipefail

source "$(dirname "$0")/common.sh"

if [ -t 1 ]; then
    GREEN_BOLD='\033[1;32m'
    RED_BOLD='\033[1;31m'
    RESET='\033[0m'
else
    GREEN_BOLD=''
    RED_BOLD=''
    RESET=''
fi

mandatory_fails=0

ok() {
    printf '%b\n' "${GREEN_BOLD}[KORRAS]${RESET} $1"
}

fail() {
    printf '%b\n' "${RED_BOLD}[PUUDU]${RESET} $1"
    mandatory_fails=$((mandatory_fails + 1))
}

kuma_exists() {
    [ -d "$HOME/uptime-kuma" ] || \
    pm2 jlist 2>/dev/null | grep -Eiq 'uptime-kuma' || \
    pgrep -af 'uptime-kuma|server/server.js' >/dev/null 2>&1
}

port_3001_listening() {
    ss -lnt 2>/dev/null | grep -Eq '[:.]3001[[:space:]]' || \
    netstat -lnt 2>/dev/null | grep -Eq '[:.]3001[[:space:]]'
}

kuma_http_works() {
    curl -sS -I --max-time 5 http://127.0.0.1:3001 2>/dev/null | grep -Eq 'HTTP/[0-9.]+[[:space:]]+(200|301|302|401|403)'
}

echo "Task 17: kontrollin, kas Uptime Kuma on olemas ja tootab pordil 3001"

if kuma_exists; then
    ok "Uptime Kuma olemasolu on tuvastatud"
else
    fail "Uptime Kuma olemasolu ei tuvastatud"
    echo "  Vihje: paigalda Uptime Kuma (nt ~/uptime-kuma) voi kaivita see PM2 all."
fi

if port_3001_listening; then
    ok "Port 3001 kuulab"
else
    fail "Port 3001 ei kuula"
    echo "  Vihje: kaivita Uptime Kuma ja kontrolli, et teenus kuulaks pordil 3001."
fi

if kuma_http_works; then
    ok "Uptime Kuma vastab aadressil http://127.0.0.1:3001"
else
    fail "Uptime Kuma HTTP vastust pordilt 3001 ei tuvastatud"
    echo "  Vihje: testi brauseris voi curl kasuga http://127.0.0.1:3001."
fi

echo
echo "Puuduvate kohustuslike tingimuste arv: $mandatory_fails"

if [ "$mandatory_fails" -eq 0 ]; then
    printf '%b\n' "${GREEN_BOLD}Task 17: ARVESTATUD${RESET}"
    send_result 17
else
    printf '%b\n' "${RED_BOLD}Task 17: MITTE ARVESTATUD${RESET}"
    exit 1
fi
