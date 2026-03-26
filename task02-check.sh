#!/usr/bin/env bash

set -euo pipefail

source "$(dirname "$0")/common.sh"

HISTORY_FILE="$HOME/.bash_history"

if [ -t 1 ]; then
    RED_BOLD='\033[1;31m'
    RESET='\033[0m'
else
    RED_BOLD=''
    RESET=''
fi

mandatory_fails=0
all_missing=0

ok() {
    echo "[KORRAS] $1"
}

fail() {
    printf '%b\n' "${RED_BOLD}[PUUDU]${RESET} $1"
    mandatory_fails=$((mandatory_fails + 1))
}

history_has() {
    local pattern="$1"
    grep -Eq "$pattern" "$HISTORY_FILE"
}

echo "Task 02: kontrollin, kas vajalikud tegevused on labi tehtud"

if [ ! -f "$HISTORY_FILE" ]; then
    fail "Bash ajalugu ei leitud: $HISTORY_FILE"
    echo
    echo "Vihje: tee terminalis vajalikud tegevused ara ja proovi seejärel uuesti."
    exit 1
fi

# Flush interactive shell history when possible.
history -a 2>/dev/null || true

# Nouded kontrollitakse ajaloo pohjal.
if history_has '(^|[[:space:]])(man[[:space:]]+ping|ping[[:space:]]+(-h|--help))([[:space:]]|$)'; then
    ok "Abi/manual kasutus leitud"
else
    all_missing=$((all_missing + 1))
    fail "Abi/manual tegevus puudub"
    echo "  Vihje: vaata ping kasu kirjeldust kas man voi help kaudu."
fi

if history_has 'ping([^#\n]*)127\.0\.0\.1'; then
    ok "Loopback aadressi kontroll leitud"
else
    all_missing=$((all_missing + 1))
    fail "Loopback aadressi kontroll puudub"
    echo "  Vihje: testi kohalikku aadressi, mitte valisvorku."
fi

if history_has 'ping([^#\n]*)192\.168\.1\.14'; then
    ok "Lokaalvorgu IP kontroll leitud"
else
    all_missing=$((all_missing + 1))
    fail "Lokaalvorgu IP kontroll puudub"
    echo "  Vihje: kasuta etteantud privaatvorgu aadressi."
fi

domain_line=$(grep -E 'ping.*(www\.)?metshein\.com' "$HISTORY_FILE" | tail -1 || true)

if [ -n "$domain_line" ] && \
   echo "$domain_line" | grep -Eq '(-i[[:space:]]*3|--interval[=[:space:]]*3)' && \
   echo "$domain_line" | grep -Eq '(-c[[:space:]]*3|--count[=[:space:]]*3)' && \
   echo "$domain_line" | grep -Eq '(^|[[:space:]])-a([[:space:]]|$)' && \
   echo "$domain_line" | grep -Eq '(-s[[:space:]]*1024|--size[=[:space:]]*1024)'; then

    ok "Domeeni kontroll koigi nouetud tingimustega leitud"

else
    all_missing=$((all_missing + 1))
    fail "Domeeni kontrolli tingimused ei ole koik taidetud"
fi

echo
echo "Puuduvate kohustuslike tingimuste arv: $mandatory_fails"

if [ "$all_missing" -eq 4 ]; then
    echo
    echo "Vihje: voimalik, et shelli ajalugu pole veel faili kirjutatud."
    echo "Jooksuta enne kontrolli: history -a"
fi

if [ "$mandatory_fails" -eq 0 ]; then
    echo "Task 02: ARVESTATUD"
    send_result 2
else
    printf '%b\n' "${RED_BOLD}Task 02: MITTE ARVESTATUD${RESET}"
    exit 1
fi
