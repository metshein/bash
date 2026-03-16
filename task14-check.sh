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

collect_task14_candidates() {
    local script

    while IFS= read -r script; do
        if ! is_user_script_candidate "$script"; then
            continue
        fi

        if ! [ -r "$script" ] || ! grep -Iq . "$script" 2>/dev/null; then
            continue
        fi

        if head -n 1 "$script" 2>/dev/null | grep -Eiq '^#!.*/(ba)?sh' || \
           grep -Eiq '(apache2|apt|apt-get|menu|select|case.*\$|systemctl)' "$script"; then
            printf '%s\n' "$script"
        fi
    done < <(find "$HOME" \
        \( -path '*/.copilot/*' -o -path '*/.cache/*' -o -path '*/.config/*' -o -path '*/node_modules/*' -o -path '*/.git/*' \) -prune -o \
        -maxdepth 5 -type f \( -name '*.sh' -o -name 'yl14*' -o -name '*menu*' -o -name '*apache*' \) -print 2>/dev/null)
}

has_comments() {
    local file="$1"
    local count

    count=$(grep -Ec '^[[:space:]]*#' "$file" || true)
    [ "$count" -ge 3 ]
}

has_menu_logic() {
    local file="$1"

    grep -Eiq '(while[[:space:]]+true|until[[:space:]]+|select[[:space:]]+|read[[:space:]].*valik|case[[:space:]]+\$)' "$file"
}

has_update_logic() {
    local file="$1"

    grep -Eiq '(apt-get|apt)[[:space:]]+update' "$file" && \
    grep -Eiq '(apt-get|apt)[[:space:]].*(upgrade|full-upgrade)' "$file"
}

has_default_yes_logic() {
    local file="$1"

    grep -Eiq '(^|[[:space:]])yes[[:space:]]*\|' "$file" || \
    grep -Eiq '(apt-get|apt)[[:space:]].*-[[:alpha:]]*y[[:alpha:]]*' "$file"
}

has_apache_install_check_logic() {
    local file="$1"

    grep -Eiq '(dpkg[[:space:]]+-s[[:space:]]+apache2|command[[:space:]]+-v[[:space:]]+apache2|systemctl[[:space:]]+status[[:space:]]+apache2)' "$file" && \
    grep -Eiq '(apt-get|apt)[[:space:]]+install[[:space:]].*apache2' "$file"
}

has_apache_start_logic() {
    local file="$1"

    grep -Eiq 'systemctl[[:space:]]+(start|enable[[:space:]]+--now)[[:space:]]+apache2' "$file"
}

has_apache_remove_logic() {
    local file="$1"

    grep -Eiq 'systemctl[[:space:]]+(stop|disable)[[:space:]]+apache2' "$file" && \
    grep -Eiq '(apt-get|apt)[[:space:]]+(remove|purge)[[:space:]].*apache2' "$file"
}

has_related_package_cleanup_logic() {
    local file="$1"

    grep -Eiq '(autoremove|purge|--purge)' "$file"
}

has_exit_option_logic() {
    local file="$1"

    grep -Eiq '(exit|break)' "$file" && \
    grep -Eiq '(valju|exit|lopeta)' "$file"
}

has_invalid_option_message_logic() {
    local file="$1"

    grep -Eiq '(\*\)|default|invalid|vigane|pole olemas)' "$file"
}

has_success_failure_messages_logic() {
    local file="$1"

    grep -Eiq '(onnestus|ebaonnestus|success|error|viga|hoiatus)' "$file"
}

echo "Task 14: kontrollin, kas vajalikud tegevused on labi tehtud"

history -a 2>/dev/null || true

if [ -f "$HISTORY_FILE" ]; then
    ok "Bash ajaloo fail on olemas"
else
    all_missing=$((all_missing + 1))
    fail "Bash ajaloo faili ei leitud"
    echo "  Vihje: tee terminalis vajalikud tegevused ja salvesta ajalugu."
fi

mapfile -t candidate_scripts < <(collect_task14_candidates)

if [ "${#candidate_scripts[@]}" -gt 0 ]; then
    ok "Ylesande 14 skript(id) on leitud"
else
    all_missing=$((all_missing + 1))
    fail "Ylesande 14 skripti ei leitud"
    echo "  Vihje: loo menyyga bash skript apache2 haldamiseks."
fi

comments_ok=0
menu_ok=0
update_ok=0
yes_ok=0
install_check_ok=0
start_ok=0
remove_ok=0
cleanup_ok=0
exit_ok=0
invalid_ok=0
messages_ok=0

for script in "${candidate_scripts[@]}"; do
    if has_comments "$script"; then
        comments_ok=1
    fi

    if has_menu_logic "$script"; then
        menu_ok=1
    fi

    if has_update_logic "$script"; then
        update_ok=1
    fi

    if has_default_yes_logic "$script"; then
        yes_ok=1
    fi

    if has_apache_install_check_logic "$script"; then
        install_check_ok=1
    fi

    if has_apache_start_logic "$script"; then
        start_ok=1
    fi

    if has_apache_remove_logic "$script"; then
        remove_ok=1
    fi

    if has_related_package_cleanup_logic "$script"; then
        cleanup_ok=1
    fi

    if has_exit_option_logic "$script"; then
        exit_ok=1
    fi

    if has_invalid_option_message_logic "$script"; then
        invalid_ok=1
    fi

    if has_success_failure_messages_logic "$script"; then
        messages_ok=1
    fi
done

if [ "$comments_ok" -eq 1 ]; then
    ok "Kommentaarid on skriptis olemas"
else
    all_missing=$((all_missing + 1))
    fail "Kommentaare ei leitud piisavalt"
    echo "  Vihje: lisa skripti kommentaarid."
fi

if [ "$menu_ok" -eq 1 ]; then
    ok "Menyy loogika on tuvastatud"
else
    all_missing=$((all_missing + 1))
    fail "Menyy loogikat ei leitud"
    echo "  Vihje: kasuta while/select/case loogikat valikute jaoks."
fi

if [ "$update_ok" -eq 1 ]; then
    ok "Pakettide uuenduse loogika on tuvastatud"
else
    all_missing=$((all_missing + 1))
    fail "Pakettide uuenduse loogikat ei leitud"
    echo "  Vihje: lisa update + upgrade tegevus."
fi

if [ "$yes_ok" -eq 1 ]; then
    ok "Vaikimisi yes loogika on tuvastatud"
else
    all_missing=$((all_missing + 1))
    fail "Vaikimisi yes loogikat ei leitud"
    echo "  Vihje: kasuta -y voi yes | kaeske."
fi

if [ "$install_check_ok" -eq 1 ]; then
    ok "Apache2 olemasolu kontroll + paigaldus loogika on tuvastatud"
else
    all_missing=$((all_missing + 1))
    fail "Apache2 paigalduse eelkontrolli loogikat ei leitud"
    echo "  Vihje: kontrolli enne installi, kas apache2 on juba olemas."
fi

if [ "$start_ok" -eq 1 ]; then
    ok "Apache2 teenuse kaivitamise loogika on tuvastatud"
else
    all_missing=$((all_missing + 1))
    fail "Apache2 teenuse kaivitamise loogikat ei leitud"
    echo "  Vihje: paigaldamise jarel kaivita teenus systemctl kasuga."
fi

if [ "$remove_ok" -eq 1 ]; then
    ok "Apache2 eemaldamise loogika on tuvastatud"
else
    all_missing=$((all_missing + 1))
    fail "Apache2 eemaldamise loogikat ei leitud"
    echo "  Vihje: peata teenus ja eemalda apache2."
fi

if [ "$cleanup_ok" -eq 1 ]; then
    ok "Seotud pakettide puhastuse loogika on tuvastatud"
else
    all_missing=$((all_missing + 1))
    fail "Seotud pakettide puhastuse loogikat ei leitud"
    echo "  Vihje: kasuta purge/autoremove tegevust."
fi

if [ "$exit_ok" -eq 1 ]; then
    ok "Valik menyyust valjumiseks on tuvastatud"
else
    all_missing=$((all_missing + 1))
    fail "Valjumise valikut ei leitud"
    echo "  Vihje: lisa menyy valik valjumiseks."
fi

if [ "$invalid_ok" -eq 1 ]; then
    ok "Vigase valiku teavitus on tuvastatud"
else
    all_missing=$((all_missing + 1))
    fail "Vigase valiku teavitust ei leitud"
    echo "  Vihje: anna teada, kui valikut pole olemas."
fi

if [ "$messages_ok" -eq 1 ]; then
    ok "Onnestumise/ebaonnestumise teadete loogika on tuvastatud"
else
    all_missing=$((all_missing + 1))
    fail "Onnestumise/ebaonnestumise teadete loogikat ei leitud"
    echo "  Vihje: valjasta teated, kas tegevus onnestus voi ebaonnestus."
fi

if history_has '(^|[[:space:]])(apt|apt-get|systemctl)([[:space:]]|$)'; then
    ok "Oluliste kaeskude kasutus on ajaloost tuvastatud"
else
    info "Kaeskude ajaloo kontroll jaeti vahele"
fi

echo
echo "Puuduvate kohustuslike tingimuste arv: $mandatory_fails"

if [ "$all_missing" -ge 10 ]; then
    echo
    echo "Vihje: voimalik, et shelli ajalugu pole veel faili kirjutatud."
    echo "Jooksuta enne kontrolli: history -a"
fi

if [ "$mandatory_fails" -eq 0 ]; then
    printf '%b\n' "${GREEN_BOLD}Task 14: ARVESTATUD${RESET}"
    send_result 14
else
    printf '%b\n' "${RED_BOLD}Task 14: MITTE ARVESTATUD${RESET}"
    exit 1
fi
