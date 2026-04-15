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

collect_task13_candidates() {
    local script

    while IFS= read -r script; do
        if ! is_user_script_candidate "$script"; then
            continue
        fi

        if ! [ -r "$script" ] || ! grep -Iq . "$script" 2>/dev/null; then
            continue
        fi

        if head -n 1 "$script" 2>/dev/null | grep -Eiq '^#!.*/(ba)?sh' || \
           grep -Eiq '(varunda\s*\(|function[[:space:]]+varunda|backup|date\s*\+)' "$script"; then
            printf '%s\n' "$script"
        fi
    done < <(find "$HOME" \
        \( -path '*/.copilot/*' -o -path '*/.cache/*' -o -path '*/.config/*' -o -path '*/node_modules/*' -o -path '*/.git/*' \) -prune -o \
        -maxdepth 5 -type f \( -name '*.sh' -o -name 'yl13*' -o -name '*varund*' -o -name '*backup*' \) -print 2>/dev/null)
}

has_comments() {
    local file="$1"
    local count

    count=$(grep -Ec '^[[:space:]]*#' "$file" || true)
    [ "$count" -ge 2 ]
}

has_varunda_function() {
    local file="$1"

    grep -Eiq '(^|[[:space:]])function[[:space:]]+varunda([[:space:]]*\{|[[:space:]]*$)|(^|[[:space:]])varunda[[:space:]]*\(\)[[:space:]]*\{' "$file"
}

has_argument_usage() {
    local file="$1"

    grep -Eiq '(\$1|\$\{1\})' "$file"
}

has_backup_dir_logic() {
    local file="$1"

    grep -Eiq 'mkdir([[:space:]]+-p)?[[:space:]].*backup' "$file" || \
    grep -Eiq '/backup/' "$file"
}

has_timestamp_logic() {
    local file="$1"

    grep -Eiq 'date[[:space:]]*\+.*(%Y|%F|%H|%M|%S|%T)' "$file"
}

has_backup_filename_logic() {
    local file="$1"

    (grep -Eiq '(basename|dirname|##\*/)' "$file" || grep -Eiq '(backup|varu|archive|cp[[:space:]].*\$1)' "$file") && \
    grep -Eiq '(\$\{?[[:alnum:]_]+\}?[_-]\$\{?[[:alnum:]_]+\}?|\$\{?[[:alnum:]_]+\}?\.[[:alnum:]]+|backup|varu|archive|date[[:space:]]*\+)' "$file"
}

has_copy_logic() {
    local file="$1"

    grep -Eiq '(^|[[:space:]])(cp|install|cat[[:space:]].*>)([[:space:]]|$)' "$file"
}

echo "Task 13: kontrollin, kas vajalikud tegevused on labi tehtud"

history -a 2>/dev/null || true

if [ -f "$HISTORY_FILE" ]; then
    ok "Bash ajaloo fail on olemas"
else
    all_missing=$((all_missing + 1))
    fail "Bash ajaloo faili ei leitud"
    echo "  Vihje: tee terminalis vajalikud tegevused ja salvesta ajalugu."
fi

mapfile -t candidate_scripts < <(collect_task13_candidates)

if [ "${#candidate_scripts[@]}" -gt 0 ]; then
    ok "Ylesande 13 skript(id) on leitud"
else
    all_missing=$((all_missing + 1))
    fail "Ylesande 13 skripti ei leitud"
    echo "  Vihje: loo skript, kus on funktsioon varunda."
fi

comments_ok=0
function_ok=0
arg_ok=0
backup_dir_ok=0
time_ok=0
name_ok=0
copy_ok=0

for script in "${candidate_scripts[@]}"; do
    if has_comments "$script"; then
        comments_ok=1
    fi

    if has_varunda_function "$script"; then
        function_ok=1
    fi

    if has_argument_usage "$script"; then
        arg_ok=1
    fi

    if has_backup_dir_logic "$script"; then
        backup_dir_ok=1
    fi

    if has_timestamp_logic "$script"; then
        time_ok=1
    fi

    if has_backup_filename_logic "$script"; then
        name_ok=1
    fi

    if has_copy_logic "$script"; then
        copy_ok=1
    fi
done

if [ "$comments_ok" -eq 1 ]; then
    ok "Kommentaarid on skriptis olemas"
else
    info "Kommentaaride kontroll jaeti vahele"
fi

if [ "$function_ok" -eq 1 ]; then
    ok "Funktsioon varunda on tuvastatud"
else
    all_missing=$((all_missing + 1))
    fail "Funktsiooni varunda ei leitud"
    echo "  Vihje: lisa skripti funktsioon nimega varunda."
fi

if [ "$arg_ok" -eq 1 ]; then
    ok "Funktsioon kasutab faili tee argumenti"
else
    all_missing=$((all_missing + 1))
    fail "Faili tee argumendi kasutust ei leitud"
    echo "  Vihje: kasuta varunda funktsioonis esimest argumenti (\$1)."
fi

if [ "$backup_dir_ok" -eq 1 ]; then
    ok "backup kausta loogika on tuvastatud"
else
    all_missing=$((all_missing + 1))
    fail "backup kausta loomise/asukoha loogikat ei leitud"
    echo "  Vihje: varufail peab minema kasutaja backup kausta."
fi

if [ "$time_ok" -eq 1 ]; then
    ok "Kuupaeva ja kellaaja lisamise loogika on tuvastatud"
else
    all_missing=$((all_missing + 1))
    fail "Kuupaeva/kellaaja loogikat ei leitud"
    echo "  Vihje: kasuta failinimes date valjundit."
fi

if [ "$name_ok" -eq 1 ]; then
    ok "Varufaili nime koostamise loogika on tuvastatud"
else
    all_missing=$((all_missing + 1))
    fail "Varufaili nime koostamise loogikat ei leitud"
    echo "  Vihje: kasuta algset failinime ja lisa ajatempel."
fi

if [ "$copy_ok" -eq 1 ]; then
    ok "Varundamise kask (cp/install/cat>) on tuvastatud"
else
    all_missing=$((all_missing + 1))
    fail "Varundamise kaske ei leitud"
    echo "  Vihje: kopeeri sisendfail backup faili."
fi

if history_has '(^|[[:space:]])(bash|sh|\.\/).*(varund|backup|yl13).*(\.sh)?' || \
   history_has '(^|[[:space:]])varunda([[:space:]]|$)'; then
    ok "Skripti voi funktsiooni testkaivitus on ajaloost tuvastatud"
else
    info "Testkaivituse ajaloo kontroll jaeti vahele"
fi

echo
echo "Puuduvate kohustuslike tingimuste arv: $mandatory_fails"

if [ "$all_missing" -ge 7 ]; then
    echo
    echo "Vihje: voimalik, et shelli ajalugu pole veel faili kirjutatud."
    echo "Jooksuta enne kontrolli: history -a"
fi

if [ "$mandatory_fails" -eq 0 ]; then
    printf '%b\n' "${GREEN_BOLD}Task 13: ARVESTATUD${RESET}"
    send_result 13
else
    printf '%b\n' "${RED_BOLD}Task 13: MITTE ARVESTATUD${RESET}"
    exit 1
fi
