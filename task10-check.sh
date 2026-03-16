#!/usr/bin/env bash

set -euo pipefail

source "$(dirname "$0")/common.sh"

HISTORY_FILE="$HOME/.bash_history"

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
all_missing=0

ok() {
    printf '%b\n' "${GREEN_BOLD}[KORRAS]${RESET} $1"
}

info() {
    echo "[INFO] $1"
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

is_user_script_candidate() {
    local script_path="$1"
    local script_name

    script_name="$(basename "$script_path")"

    case "$script_name" in
        task*-check.sh|common.sh)
            return 1
            ;;
    esac

    return 0
}

find_task10_script() {
    local script

    while IFS= read -r script; do
        if ! is_user_script_candidate "$script"; then
            continue
        fi

        # Skip binary files and unreadable paths.
        if ! [ -r "$script" ] || ! grep -Iq . "$script" 2>/dev/null; then
            continue
        fi

        if grep -Eiq '(useradd|adduser)' "$script" && \
           grep -Eiq '(read[[:space:]].*(kasutaja|user)|kasutaja|username)' "$script"; then
            printf '%s\n' "$script"
            return 0
        fi
    done < <(find "$HOME" -maxdepth 5 -type f \( -name '*.sh' -o -name 'yl10*' -o -name '*kasutaja*' -o -name 'muutujad' -o -perm -u+x \) 2>/dev/null)

    return 1
}

comment_ratio_ok() {
    local file="$1"
    local comment_lines
    comment_lines=$(grep -Ec '^[[:space:]]*#' "$file" || true)

    # Leebe kontroll: kui kommentaare on vahemalt 3, loeme tingimuse taitetuks.
    [ "$comment_lines" -ge 3 ]
}

has_username_var_logic() {
    local file="$1"

    grep -Eiq 'read([[:space:]]+-[rpns]+)*[[:space:]].*(username|kasutaja_nimi|kasutajanimi|user_name|kasutaja)' "$file" || \
    grep -Eiq '^(username|kasutaja_nimi|kasutajanimi|user_name|kasutaja)=' "$file"
}

has_password_hidden_logic() {
    local file="$1"

    grep -Eiq '^[[:space:]]*read[[:space:]].*-[[:alpha:]]*s[[:alpha:]]*' "$file" || \
    grep -Eiq '^[[:space:]]*read[[:space:]]+-s([[:space:]]|$)|^[[:space:]]*read[[:space:]]+-sp([[:space:]]|$)|^[[:space:]]*read[[:space:]]+-ps([[:space:]]|$)' "$file"
}

has_user_create_logic() {
    local file="$1"

    grep -Eiq '(useradd|adduser)' "$file"
}

has_welcome_file_logic() {
    local file="$1"

    # Variant 1: koik teeosad on samal real.
    if grep -Eiq '/home/\$\{?[[:alnum:]_]+\}?/teretulemast_' "$file" || \
       grep -Eiq 'teretulemast_.*\$\{?[[:alnum:]_]+\}?[^[:space:]]*\.txt' "$file"; then
        return 0
    fi

    # Variant 2: tee pannakse kokku muutujate kaudu (HOME_DIR -> FILE).
    grep -Eiq 'HOME_DIR=.*/home/\$\{?[[:alnum:]_]+\}?' "$file" && \
    grep -Eiq 'FILE=.*/teretulemast_\$\{?[[:alnum:]_]+\}?[^[:space:]]*\.txt|FILE=.*\$\{?HOME_DIR\}?/teretulemast_\$\{?[[:alnum:]_]+\}?[^[:space:]]*\.txt' "$file"
}

has_group_argument_logic() {
    local file="$1"

    grep -Eiq '(\$1|\$\{1\}|group)' "$file" && \
    grep -Eiq '(usermod[[:space:]].*-aG|adduser[[:space:]].*[[:space:]]+\$\{?[[:alnum:]_]+\}?|gpasswd[[:space:]].*-a)' "$file"
}

find_welcome_files() {
    find /home -maxdepth 3 -type f -name 'teretulemast_*.txt' 2>/dev/null | head -n 3
}

echo "Task 10: kontrollin, kas vajalikud tegevused on labi tehtud"

history -a 2>/dev/null || true

if [ -f "$HISTORY_FILE" ]; then
    ok "Bash ajaloo fail on olemas"
else
    all_missing=$((all_missing + 1))
    fail "Bash ajaloo faili ei leitud"
    echo "  Vihje: tee terminalis vajalikud tegevused ja salvesta ajalugu."
fi

user_script=""
if user_script=$(find_task10_script); then
    ok "Ylesande skript on leitud: $user_script"
else
    all_missing=$((all_missing + 1))
    fail "Noutud kasutaja loomise skripti ei leitud"
    echo "  Vihje: tee eraldi bash skript, kus on kasutaja loomise loogika."
fi

if [ -n "$user_script" ] && [ -x "$user_script" ]; then
    ok "Skriptifail on kaivitatav"
elif [ -n "$user_script" ]; then
    all_missing=$((all_missing + 1))
    fail "Skriptifail pole kaivitatav"
    echo "  Vihje: lisa failile kaivitusoigus (chmod +x)."
fi

if [ -n "$user_script" ] && comment_ratio_ok "$user_script"; then
    ok "Skriptis on piisavalt kommentaare"
elif [ -n "$user_script" ]; then
    all_missing=$((all_missing + 1))
    fail "Skriptis on kommentaare liiga vahe"
    echo "  Vihje: kommenteeri skripti sammud loetavalt lahti."
fi

if [ -n "$user_script" ] && has_username_var_logic "$user_script"; then
    ok "Kasutajanime muutuja loogika on tuvastatud"
elif [ -n "$user_script" ]; then
    all_missing=$((all_missing + 1))
    fail "Kasutajanime muutuja loogikat ei leitud"
    echo "  Vihje: loe kasutajanimi muutujasse read kasuga."
fi

if [ -n "$user_script" ] && has_password_hidden_logic "$user_script"; then
    ok "Parool loetakse varjatult (read -s)"
elif [ -n "$user_script" ]; then
    all_missing=$((all_missing + 1))
    fail "Parooli varjatud sisestust ei leitud"
    echo "  Vihje: kasuta parooli lugemiseks read -s."
fi

if [ -n "$user_script" ] && has_user_create_logic "$user_script"; then
    ok "Kasutaja loomise kask on skriptis olemas"
elif [ -n "$user_script" ]; then
    all_missing=$((all_missing + 1))
    fail "Kasutaja loomise kaske ei leitud"
    echo "  Vihje: kasuta useradd voi adduser kaske."
fi

if [ -n "$user_script" ] && has_welcome_file_logic "$user_script"; then
    ok "Kataloogi ja teretulemast faili loomise loogika on tuvastatud"
elif [ -n "$user_script" ]; then
    all_missing=$((all_missing + 1))
    fail "Kataloogi/teretulemast faili loomise loogikat ei leitud"
    echo "  Vihje: loo /home/kasutajanimi/teretulemast_kasutajanimi.txt."
fi

if [ -n "$user_script" ] && has_group_argument_logic "$user_script"; then
    ok "Grupi argumendi ja gruppi lisamise loogika on tuvastatud"
elif [ -n "$user_script" ]; then
    all_missing=$((all_missing + 1))
    fail "Grupi argumendi tugi voi gruppi lisamine puudub"
    echo "  Vihje: kasuta skriptis esimest argumenti grupi jaoks ja lisa kasutaja gruppi."
fi

if [ -n "$user_script" ] && history_has "$(basename "$user_script")"; then
    ok "Skripti kaivitamise tegevus on ajaloost tuvastatud"
else
    info "Skripti kaivitamise ajaloo kontroll jaeti vahele"
fi

welcome_found="$(find_welcome_files || true)"
if [ -n "$welcome_found" ]; then
    ok "Teretulemast fail on loodud kasutaja kodukataloogi"
else
    info "Teretulemast faili lopptulemuse kontroll jaeti vahele (vajab root oigusi voi testkasutajat)"
fi

echo
echo "Puuduvate kohustuslike tingimuste arv: $mandatory_fails"

if [ "$all_missing" -ge 8 ]; then
    echo
    echo "Vihje: voimalik, et shelli ajalugu pole veel faili kirjutatud."
    echo "Jooksuta enne kontrolli: history -a"
fi

if [ "$mandatory_fails" -eq 0 ]; then
    printf '%b\n' "${GREEN_BOLD}Task 10: ARVESTATUD${RESET}"
    send_result 10
else
    printf '%b\n' "${RED_BOLD}Task 10: MITTE ARVESTATUD${RESET}"
    exit 1
fi
