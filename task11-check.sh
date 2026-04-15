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

collect_task11_candidates() {
    local script

    while IFS= read -r script; do
        if ! is_user_script_candidate "$script"; then
            continue
        fi

        if ! [ -r "$script" ] || ! grep -Iq . "$script" 2>/dev/null; then
            continue
        fi

        if head -n 1 "$script" 2>/dev/null | grep -Eiq '^#!.*/(ba)?sh' || \
           grep -Eiq '(systemctl|stat[[:space:]]+-c[[:space:]]*%a|is-active|\-f[[:space:]])' "$script"; then
            printf '%s\n' "$script"
        fi
    done < <(find "$HOME" \
        \( -path '*/.copilot/*' -o -path '*/.cache/*' -o -path '*/.config/*' -o -path '*/node_modules/*' -o -path '*/.git/*' \) -prune -o \
        -maxdepth 5 -type f \( -name '*.sh' -o -name 'yl11*' -o -name '*teenus*' -o -name '*oigus*' \) -print 2>/dev/null)
}

has_comment_block() {
    local file="$1"
    local comments

    comments=$(grep -Ec '^[[:space:]]*#' "$file" || true)
    [ "$comments" -ge 3 ]
}

has_service_check_logic() {
    local file="$1"

    grep -Eiq '(systemctl[[:space:]]+is-active|systemctl[[:space:]]+status|service[[:space:]].*status|is-active)' "$file"
}

has_permission_check_logic() {
    local file="$1"

    grep -Eiq '(stat[[:space:]]+-c[[:space:]]*%a|stat[[:space:]]+--format[=[:space:]]*%a|ls[[:space:]]+-l)' "$file" && \
    grep -Eiq '(oigused|peaksid olema|fail|perm|permission)' "$file"
}

has_file_type_check_logic() {
    local file="$1"

    grep -Eiq '(^|[[:space:]])(if[[:space:]]+\[|\[\[|test[[:space:]]+).*-f' "$file"
}

has_args_for_permissions() {
    local file="$1"

    (grep -Eiq '(\$1|\$\{1\})' "$file" && \
     grep -Eiq '(\$2|\$\{2\})' "$file") || \
    grep -Eiq '(getopts|case[[:space:]]+\$[[:alnum:]_]+[[:space:]]+in|for[[:space:]]+[[:alnum:]_]+[[:space:]]+in[[:space:]]+"\$@")' "$file"
}

echo "Task 11: kontrollin, kas vajalikud tegevused on labi tehtud"

history -a 2>/dev/null || true

if [ -f "$HISTORY_FILE" ]; then
    ok "Bash ajaloo fail on olemas"
else
    all_missing=$((all_missing + 1))
    fail "Bash ajaloo faili ei leitud"
    echo "  Vihje: tee terminalis vajalikud tegevused ja salvesta ajalugu."
fi

mapfile -t candidate_scripts < <(collect_task11_candidates)

if [ "${#candidate_scripts[@]}" -gt 0 ]; then
    ok "Ylesande 11 skript(id) on leitud"
else
    all_missing=$((all_missing + 1))
    fail "Ylesande 11 skripti ei leitud"
    echo "  Vihje: tee bash skript teenuste ja failioiguste kontrolliks."
fi

comments_ok=0
service_ok=0
perm_ok=0
file_type_ok=0
args_ok=0

for script in "${candidate_scripts[@]}"; do
    if has_comment_block "$script"; then
        comments_ok=1
    fi

    if has_service_check_logic "$script"; then
        service_ok=1
    fi

    if has_permission_check_logic "$script"; then
        perm_ok=1
    fi

    if has_file_type_check_logic "$script"; then
        file_type_ok=1
    fi

    if has_args_for_permissions "$script"; then
        args_ok=1
    fi
done

if [ "$comments_ok" -eq 1 ]; then
    ok "Skriptis on kommentaarid olemas"
else
    all_missing=$((all_missing + 1))
    fail "Kommentaare ei leitud piisavalt"
    echo "  Vihje: lisa skripti kommentaarid, mis selgitavad samme."
fi

if [ "$service_ok" -eq 1 ]; then
    ok "Teenuste kontrolli loogika on tuvastatud"
else
    all_missing=$((all_missing + 1))
    fail "Teenuste kontrolli loogikat ei leitud"
    echo "  Vihje: kasuta teenuse oleku kontrolliks systemctl kaesku."
fi

if [ "$perm_ok" -eq 1 ]; then
    ok "Failioiguste kontroll (stat -c %a) on tuvastatud"
else
    all_missing=$((all_missing + 1))
    fail "Failioiguste kontrolli ei leitud"
    echo "  Vihje: kasuta numbriliste oiguste lugemiseks stat -c %a."
fi

if [ "$file_type_ok" -eq 1 ]; then
    ok "Failityybi kontroll (-f) on tuvastatud"
else
    all_missing=$((all_missing + 1))
    fail "Failityybi kontrolli ei leitud"
    echo "  Vihje: kontrolli enne oigusi, kas etteantud tee on fail."
fi

if [ "$args_ok" -eq 1 ]; then
    ok "Kasurea argumentide kasutus (fail + oigus) on tuvastatud"
else
    all_missing=$((all_missing + 1))
    fail "Kasurea argumentide kasutust ei leitud"
    echo "  Vihje: kasuta oiguste kontrollis vahemalt kahte argumenti (fail ja oigus)."
fi

if history_has '(^|[[:space:]])(systemctl|stat)([[:space:]]|$)'; then
    ok "Oluliste kaeskude kasutus on ajaloost tuvastatud"
else
    info "Kaeskude ajaloo kontroll jaeti vahele"
fi

echo
echo "Puuduvate kohustuslike tingimuste arv: $mandatory_fails"

if [ "$all_missing" -ge 7 ]; then
    echo
    echo "Vihje: voimalik, et shelli ajalugu pole veel faili kirjutatud."
    echo "Jooksuta enne kontrolli: history -a"
fi

if [ "$mandatory_fails" -eq 0 ]; then
    printf '%b\n' "${GREEN_BOLD}Task 11: ARVESTATUD${RESET}"
    send_result 11
else
    printf '%b\n' "${RED_BOLD}Task 11: MITTE ARVESTATUD${RESET}"
    exit 1
fi
