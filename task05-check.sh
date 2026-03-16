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

    if [ ! -f "$HISTORY_FILE" ]; then
        return 1
    fi

    grep -Eq "$pattern" "$HISTORY_FILE"
}

history_reverse_stream() {
    if command -v tac >/dev/null 2>&1; then
        tac "$HISTORY_FILE"
    else
        awk '{a[NR]=$0} END {for (i=NR; i>=1; i--) print a[i]}' "$HISTORY_FILE"
    fi
}

collect_created_users() {
    getent passwd | awk -F: '$1 ~ /^user[0-9]+$/ {print $1}' | sort -V
}

echo "Task 05: kontrollin, kas vajalikud tegevused on labi tehtud"

history -a 2>/dev/null || true

if [ -f "$HISTORY_FILE" ]; then
    ok "Bash ajaloo fail on olemas"
else
    all_missing=$((all_missing + 1))
    fail "Bash ajaloo faili ei leitud"
    echo "  Vihje: tee terminalis vajalikud tegevused ja salvesta ajalugu."
fi

mapfile -t created_users < <(collect_created_users)

if [ "${#created_users[@]}" -ge 3 ]; then
    ok "Vahemalt 3 loodud kasutajat on systeemis olemas"
elif [ "${#created_users[@]}" -ge 1 ]; then
    ok "Kasutajaid on olemas (leitud: ${created_users[*]})"
else
    all_missing=$((all_missing + 1))
    fail "Kolme kasutaja ei leitud systeemist"
    echo "  Vihje: kontrolli, kas lood testkasutajad nimedega user1, user2 ja user3."
fi

existing_count=0
for user_name in "${created_users[@]}"; do
    if id "$user_name" >/dev/null 2>&1; then
        existing_count=$((existing_count + 1))
    fi
done

if [ "$existing_count" -ge 3 ]; then
    ok "Loodud kasutajad on systeemis olemas"
else
    all_missing=$((all_missing + 1))
    fail "Mone loodud kasutaja konto puudub"
    echo "  Vihje: kontrolli, kas kasutajad said edukalt loodud."
fi

if getent group harj5 >/dev/null 2>&1; then
    ok "Grupp harj5 on systeemis olemas"
    ok "Grupi loomine on arvestatud lopptulemuse pohjal"
else
    all_missing=$((all_missing + 1))
    fail "Gruppi harj5 ei leitud"
    echo "  Vihje: kontrolli grupi loomist ja nime muutmist."
fi

if getent group harjutus5 >/dev/null 2>&1; then
    all_missing=$((all_missing + 1))
    fail "Grupp harjutus5 on endiselt alles"
    echo "  Vihje: peale umbernimetamist ei tohiks vana nimi alles olla."
else
    ok "Vana grupinimi ei ole enam aktiivne"
    ok "Grupi umbernimetamine on arvestatud lopptulemuse pohjal"
fi

users_in_group=0
for user_name in "${created_users[@]}"; do
    if id -nG "$user_name" 2>/dev/null | grep -qw 'harj5'; then
        users_in_group=$((users_in_group + 1))
    fi
done

if [ "$users_in_group" -ge 3 ]; then
    ok "Loodud kasutajad kuuluvad gruppi harj5"
else
    all_missing=$((all_missing + 1))
    fail "Koik loodud kasutajad ei kuulu gruppi harj5"
    echo "  Vihje: lisa iga loodud kasutaja noutud gruppi."
fi

if history_has '(^|[[:space:]])(getent[[:space:]]+passwd|cat[[:space:]]+/etc/passwd|compgen[[:space:]]+-u)([[:space:]]|$)'; then
    ok "Kasutajate nimekirja kuvamine on leitud"
else
    all_missing=$((all_missing + 1))
    fail "Kasutajate nimekirja kuvamist ei leitud"
    echo "  Vihje: kuva kasutajate nimekiri terminalis."
fi

if history_has '(^|[[:space:]])(last|lastlog|who|w)([[:space:]]|$)'; then
    ok "Sisselogimiste kuvamise tegevus on leitud"
else
    ok "Sisselogimiste kuvamise history kontroll jaeti vahele"
fi

if history_has '(^|[[:space:]])(journalctl([[:space:]]+-b)?[[:space:]]*\|[[:space:]]*grep|grep[[:space:]]+.*(Failed password|/var/log/auth\.log|/var/log/secure)|cat[[:space:]]+/var/log/auth\.log|cat[[:space:]]+/var/log/secure)'; then
    ok "Logide kontrolli tegevus on leitud"
else
    ok "Logide kontrolli history kontroll jaeti vahele (voib olla tehtud sudo kasuga)"
fi

echo
echo "Puuduvate kohustuslike tingimuste arv: $mandatory_fails"

if [ "$all_missing" -ge 8 ]; then
    echo
    echo "Vihje: voimalik, et shelli ajalugu pole veel faili kirjutatud."
    echo "Jooksuta enne kontrolli: history -a"
fi

if [ "$mandatory_fails" -eq 0 ]; then
    echo "Task 05: ARVESTATUD"
    send_result 5
else
    printf '%b\n' "${RED_BOLD}Task 05: MITTE ARVESTATUD${RESET}"
    exit 1
fi