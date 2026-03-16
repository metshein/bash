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
    getent passwd | awk -F: '$3 >= 1000 {print $1}' | head -n 5
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
    echo "  Vihje: kontrolli, kas lood testkasutajad (user1, user2, user3) nimega."
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

if [ "${#created_users[@]}" -ge 3 ]; then
    users_with_password=0
    for user_name in "${created_users[@]}"; do
        user_shadow=$(getent shadow "$user_name" 2>/dev/null || true)
        if [ -n "$user_shadow" ]; then
            password_field=$(echo "$user_shadow" | cut -d: -f2)
            if [ -n "$password_field" ] && [ "$password_field" != "!" ] && [ "$password_field" != "*" ] && [ "$password_field" != "!!" ]; then
                users_with_password=$((users_with_password + 1))
            fi
        fi
    done

    if [ "$users_with_password" -ge 3 ]; then
        ok "Koik kolm kasutajat omavad kehtivat parooli"
    else
        all_missing=$((all_missing + 1))
        fail "Mone kasutaja parool ei ole seadistatud"
        echo "  Vihje: kontrolli, et isal loodud kasutajal oleks kehtiv parool."
    fi
else
    if [ "${#created_users[@]}" -ge 1 ]; then
        users_with_password=0
        for user_name in "${created_users[@]}"; do
            user_shadow=$(getent shadow "$user_name" 2>/dev/null || true)
            if [ -n "$user_shadow" ]; then
                password_field=$(echo "$user_shadow" | cut -d: -f2)
                if [ -n "$password_field" ] && [ "$password_field" != "!" ] && [ "$password_field" != "*" ] && [ "$password_field" != "!!" ]; then
                    users_with_password=$((users_with_password + 1))
                fi
            fi
        done

        if [ "$users_with_password" -gt 0 ]; then
            ok "Loodud kasutajatel on paroolid"
        else
            all_missing=$((all_missing + 1))
            fail "Loodud kasutajatel ei ole paroolidest"
            echo "  Vihje: sea paroolid neile kasutajatele."
        fi
    fi
fi

if history_has '(^|[[:space:]])(groupadd|addgroup)' && history_has 'harjutus5'; then
    ok "Grupi harjutus5 loomine on leitud"
else
    all_missing=$((all_missing + 1))
    fail "Grupi harjutus5 loomist ei leitud"
    echo "  Vihje: loo nouutud grupp groupadd voi addgroup kaesuga."
fi

if history_has '(^|[[:space:]])groupmod([[:space:]].*)-n[[:space:]]+harj5([[:space:]].*)harjutus5([[:space:]]|$)'; then
    ok "Grupi umbernimetamise tegevus on leitud"
else
    all_missing=$((all_missing + 1))
    fail "Grupi umbernimetamise tegevust ei leitud"
    echo "  Vihje: muuda grupi nimi nouutud kujule."
fi

if getent group harj5 >/dev/null 2>&1; then
    ok "Grupp harj5 on systeemis olemas"
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
    echo "  Vihje: lisa iga loodud kasutaja nouutud gruppi."
fi

if history_has '(^|[[:space:]])(getent[[:space:]]+passwd|cat[[:space:]]+/etc/passwd|compgen[[:space:]]+-u)([[:space:]]|$)'; then
    ok "Kasutajate nimekirja kuvamine on leitud"
else
    all_missing=$((all_missing + 1))
    fail "Kasutajate nimekirja kuvamist ei leitud"
    echo "  Vihje: kuva kasutajate nimekiri terminalis."
fi

login_try_found=0
for user_name in "${created_users[@]}"; do
    if history_has "(^|[[:space:]])(su|login|ssh)([[:space:]-].*)${user_name}([[:space:]]|$)"; then
        login_try_found=1
        break
    fi
done

if [ "$login_try_found" -eq 1 ]; then
    ok "Testkasutajaga sisselogimise proov on leitud"
else
    all_missing=$((all_missing + 1))
    fail "Testkasutajaga sisselogimise proov puudub"
    echo "  Vihje: proovi uhe loodud kasutajaga sisse logida."
fi

if history_has '(^|[[:space:]])(last|lastlog|who|w)([[:space:]]|$)'; then
    ok "Sisselogimiste kuvamise tegevus on leitud"
else
    all_missing=$((all_missing + 1))
    fail "Sisselogimiste kuvamise tegevust ei leitud"
    echo "  Vihje: kuva kasutajate sisse- ja valjalogimiste info."
fi

if history_has '(^|[[:space:]])(journalctl([[:space:]]+-b)?[[:space:]]*\|[[:space:]]*grep|grep[[:space:]]+.*(Failed password|/var/log/auth\.log|/var/log/secure)|cat[[:space:]]+/var/log/auth\.log|cat[[:space:]]+/var/log/secure)'; then
    ok "Logide kontrolli tegevus on leitud"
else
    all_missing=$((all_missing + 1))
    fail "Logide kontrolli tegevust ei leitud"
    echo "  Vihje: kasuta journali voi auth logisid sisselogimiste uurimiseks."
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