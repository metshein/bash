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

collect_task12_candidates() {
    local script

    while IFS= read -r script; do
        if ! is_user_script_candidate "$script"; then
            continue
        fi

        if ! [ -r "$script" ] || ! grep -Iq . "$script" 2>/dev/null; then
            continue
        fi

        if head -n 1 "$script" 2>/dev/null | grep -Eiq '^#!.*/(ba)?sh' || \
           grep -Eiq '(/etc/passwd|nimekiri\.txt|useradd|sha256sum|stat[[:space:]]+-c[[:space:]]*%a)' "$script"; then
            printf '%s\n' "$script"
        fi
    done < <(find "$HOME" \
        \( -path '*/.copilot/*' -o -path '*/.cache/*' -o -path '*/.config/*' -o -path '*/node_modules/*' -o -path '*/.git/*' \) -prune -o \
        -maxdepth 5 -type f \( -name '*.sh' -o -name 'yl12*' -o -name '*nimekiri*' -o -name '*kasutaja*' \) -print 2>/dev/null)
}

find_nimekiri_file() {
    local candidate

    for candidate in \
        "$HOME/nimekiri.txt" \
        "$HOME/Documents/nimekiri.txt" \
        "$HOME/Desktop/nimekiri.txt" \
        "$PWD/nimekiri.txt"
    do
        if [ -f "$candidate" ]; then
            printf '%s\n' "$candidate"
            return 0
        fi
    done

    local found
    found=$(find "$HOME" -maxdepth 5 -type f -name 'nimekiri.txt' 2>/dev/null | head -n 1 || true)
    if [ -n "$found" ]; then
        printf '%s\n' "$found"
        return 0
    fi

    return 1
}

has_comments() {
    local file="$1"
    local count

    count=$(grep -Ec '^[[:space:]]*#' "$file" || true)
    [ "$count" -ge 3 ]
}

has_passwd_user_list_logic() {
    local file="$1"

    grep -Eiq '/etc/passwd' "$file" && \
    grep -Eiq '(awk[[:space:]].*\$1|cut[[:space:]].*-d:[[:space:]]*-f1|getent[[:space:]]+passwd.*awk|while[[:space:]]+IFS=:)' "$file"
}

has_list_file_check_logic() {
    local file="$1"

    grep -Eiq '(^|[[:space:]])(if[[:space:]]+\[|\[\[).*-f' "$file" && \
    grep -Eiq '(pole fail|ei ole fail|nimekiri\.txt)' "$file"
}

has_lowercase_logic() {
    local file="$1"

    grep -Eiq '(tolower\(|tr[[:space:]].*(\[:upper:\]|A-Z).*(\[:lower:\]|a-z))' "$file" || \
    (grep -Eiq 'eesnimi[[:space:]]*=[[:space:]]*\$\{eesnimi,,\}' "$file" && \
     grep -Eiq 'perenimi[[:space:]]*=[[:space:]]*\$\{perenimi,,\}' "$file")
}

has_diacritic_replace_logic() {
    local file="$1"

    grep -Eiq '(tr[[:space:]].*[õÕüÜäÄöÖ].*[oOuUaAoO]|sed[[:space:]].*s/[õÕ].*/o/g|sed[[:space:]].*s/[üÜ].*/u/g|sed[[:space:]].*s/[äÄ].*/a/g|sed[[:space:]].*s/[öÖ].*/o/g|sed[[:space:]].*y/õüäöÕÜÄÖ/ouaoOUAO/|sed[[:space:]].*y/ÕÜÄÖõüäö/OUAOouao/)' "$file"
}

has_username_dot_logic() {
    local file="$1"

    grep -Eiq '(\$\{?[[:alnum:]_]+\}?\.\$\{?[[:alnum:]_]+\}?|printf[[:space:]].*%s\.%s|echo[[:space:]].*\.)' "$file"
}

has_password_generation_logic() {
    local file="$1"

    grep -Eiq '(sha256sum|openssl[[:space:]]+rand)' "$file" && \
    grep -Eiq '(head[[:space:]]+-c[[:space:]]*12|cut[[:space:]]+-c[[:space:]]*1-12|\{RANDOM\}|date[[:space:]]*\+%s%N)' "$file"
}

has_bulk_user_create_logic() {
    local file="$1"

    grep -Eiq '(while[[:space:]]+read|for[[:space:]].*in)' "$file" && \
    grep -Eiq '(useradd|adduser)' "$file"
}

has_output_user_pass_logic() {
    local file="$1"

    grep -Eiq '(echo|printf)' "$file" && \
    grep -Eiq '(parool|password|\$parool|\$password|\$kasutajanimi|\$username)' "$file"
}

echo "Task 12: kontrollin, kas vajalikud tegevused on labi tehtud"

history -a 2>/dev/null || true

if [ -f "$HISTORY_FILE" ]; then
    ok "Bash ajaloo fail on olemas"
else
    all_missing=$((all_missing + 1))
    fail "Bash ajaloo faili ei leitud"
    echo "  Vihje: tee terminalis vajalikud tegevused ja salvesta ajalugu."
fi

mapfile -t candidate_scripts < <(collect_task12_candidates)

if [ "${#candidate_scripts[@]}" -gt 0 ]; then
    ok "Ylesande 12 skript(id) on leitud"
else
    all_missing=$((all_missing + 1))
    fail "Ylesande 12 skripti ei leitud"
    echo "  Vihje: loo skriptid osadele 12.1 ja 12.2."
fi

nimekiri_file=""
if nimekiri_file=$(find_nimekiri_file); then
    ok "nimekiri.txt on leitud: $nimekiri_file"
else
    all_missing=$((all_missing + 1))
    fail "nimekiri.txt faili ei leitud"
    echo "  Vihje: loo nimekiri.txt etteantud nimedega."
fi

if [ -n "$nimekiri_file" ]; then
    line_count=$(grep -Ec '.' "$nimekiri_file" || true)
    if [ "$line_count" -ge 15 ]; then
        ok "nimekiri.txt sisaldab vahemalt 15 nime"
    else
        all_missing=$((all_missing + 1))
        fail "nimekiri.txt ei sisalda piisavalt ridu"
        echo "  Vihje: lisa nimekirja koik nouutud nimed."
    fi
fi

comments_ok=0
passwd_ok=0
file_check_ok=0
lower_ok=0
diacritic_ok=0
username_ok=0
password_ok=0
bulk_add_ok=0
output_ok=0

for script in "${candidate_scripts[@]}"; do
    if has_comments "$script"; then
        comments_ok=1
    fi

    if has_passwd_user_list_logic "$script"; then
        passwd_ok=1
    fi

    if has_list_file_check_logic "$script"; then
        file_check_ok=1
    fi

    if has_lowercase_logic "$script"; then
        lower_ok=1
    fi

    if has_diacritic_replace_logic "$script"; then
        diacritic_ok=1
    fi

    if has_username_dot_logic "$script"; then
        username_ok=1
    fi

    if has_password_generation_logic "$script"; then
        password_ok=1
    fi

    if has_bulk_user_create_logic "$script"; then
        bulk_add_ok=1
    fi

    if has_output_user_pass_logic "$script"; then
        output_ok=1
    fi
done

if [ "$comments_ok" -eq 1 ]; then
    ok "Kommentaarid on skriptides olemas"
else
    all_missing=$((all_missing + 1))
    fail "Kommentaare ei leitud piisavalt"
    echo "  Vihje: kommenteeri olulised solmed."
fi

if [ "$passwd_ok" -eq 1 ] || history_has '/etc/passwd'; then
    ok "12.1 /etc/passwd kasutajate kuvamise loogika on tuvastatud"
else
    all_missing=$((all_missing + 1))
    fail "12.1 /etc/passwd kasutajate kuvamise loogikat ei leitud"
    echo "  Vihje: kuva failist /etc/passwd ainult kasutajanimed."
fi

if [ "$file_check_ok" -eq 1 ]; then
    ok "Nimekirja failikontroll (-f) on tuvastatud"
else
    all_missing=$((all_missing + 1))
    fail "Nimekirja failikontrolli ei leitud"
    echo "  Vihje: kontrolli enne tootlemist, et etteantud tee oleks fail."
fi

if [ "$lower_ok" -eq 1 ]; then
    ok "Nimede vaiketahteks muutmine on tuvastatud"
else
    all_missing=$((all_missing + 1))
    fail "Nimede vaiketahteks muutmist ei leitud"
    echo "  Vihje: muuda nimed vaiketahteks (tolower voi tr)."
fi

if [ "$diacritic_ok" -eq 1 ]; then
    ok "Tapitahtede asendamise loogika on tuvastatud"
else
    all_missing=$((all_missing + 1))
    fail "Tapitahtede asendamist ei leitud"
    echo "  Vihje: asenda ouao tapitahed vastavalt noudele."
fi

if [ "$username_ok" -eq 1 ]; then
    ok "Kasutajanime eesnimi.perenimi loogika on tuvastatud"
else
    all_missing=$((all_missing + 1))
    fail "eesnimi.perenimi kasutajanime loogikat ei leitud"
    echo "  Vihje: liida eesnimi ja perenimi punktiga."
fi

if [ "$password_ok" -eq 1 ]; then
    ok "12 margi parooli loomise loogika on tuvastatud"
else
    all_missing=$((all_missing + 1))
    fail "12 margi parooli loomise loogikat ei leitud"
    echo "  Vihje: kasuta parooli loomiseks juhuslikku allikat ja piira pikkus 12 margini."
fi

if [ "$bulk_add_ok" -eq 1 ]; then
    ok "Nimekirjast kasutajate lisamise loogika on tuvastatud"
else
    all_missing=$((all_missing + 1))
    fail "Nimekirjast kasutajate lisamise loogikat ei leitud"
    echo "  Vihje: loe nimekiri sisse ja lisa kasutajad tsukliga."
fi

if [ "$output_ok" -eq 1 ]; then
    ok "Kasutajanimi + parool valjastamise loogika on tuvastatud"
else
    all_missing=$((all_missing + 1))
    fail "Kasutajanimi + parool valjastamist ei leitud"
    echo "  Vihje: valjasta eesnimi.perenimi ja parool ekraanile voi faili."
fi

if history_has '(^|[[:space:]])(systemctl|stat|useradd|adduser|awk|cut)([[:space:]]|$)'; then
    ok "Oluliste kaeskude kasutus on ajaloost tuvastatud"
else
    info "Kaeskude ajaloo kontroll jaeti vahele"
fi

echo
echo "Puuduvate kohustuslike tingimuste arv: $mandatory_fails"

if [ "$all_missing" -ge 9 ]; then
    echo
    echo "Vihje: voimalik, et shelli ajalugu pole veel faili kirjutatud."
    echo "Jooksuta enne kontrolli: history -a"
fi

if [ "$mandatory_fails" -eq 0 ]; then
    printf '%b\n' "${GREEN_BOLD}Task 12: ARVESTATUD${RESET}"
    send_result 12
else
    printf '%b\n' "${RED_BOLD}Task 12: MITTE ARVESTATUD${RESET}"
    exit 1
fi
