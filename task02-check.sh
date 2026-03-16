#!/usr/bin/env bash

set -euo pipefail

source "$(dirname "$0")/common.sh"

HISTORY_FILE="$HOME/.bash_history"

mandatory_fails=0

ok() {
    echo "[KORRAS] $1"
}

fail() {
    echo "[PUUDU] $1"
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
    fail "Abi/manual tegevus puudub"
    echo "  Vihje: vaata ping kasu kirjeldust kas man voi help kaudu."
fi

if history_has 'ping([^#\n]*)127\.0\.0\.1'; then
    ok "Loopback aadressi kontroll leitud"
else
    fail "Loopback aadressi kontroll puudub"
    echo "  Vihje: testi kohalikku aadressi, mitte valisvorku."
fi

if history_has 'ping([^#\n]*)192\.168\.1\.14'; then
    ok "Lokaalvorgu IP kontroll leitud"
else
    fail "Lokaalvorgu IP kontroll puudub"
    echo "  Vihje: kasuta etteantud privaatvorgu aadressi."
fi

if history_has 'ping([^#\n]*)metshein\.com([^#\n]*)(-i[[:space:]]*3|--interval[=[:space:]]*3)([^#\n]*)(-c[[:space:]]*3|--count[=[:space:]]*3)([^#\n]*)-a([^#\n]*)(-s[[:space:]]*1024|--size[=[:space:]]*1024)'; then
    ok "Domeeni kontroll koigi nouetud tingimustega leitud"
else
    fail "Domeeni kontrolli tingimused ei ole koik taidetud"
    echo "  Vihje: tee yks ping-kask, kus on korraga intervall, pakettide arv, helisignaal ja paketi suurus."
fi

echo
echo "Puuduvate kohustuslike tingimuste arv: $mandatory_fails"

if [ "$mandatory_fails" -eq 0 ]; then
    echo "Task 02: ARVESTATUD"
    send_result 2
else
    echo "Task 02: MITTE ARVESTATUD"
    exit 1
fi
