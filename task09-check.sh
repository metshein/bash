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

find_skriptid_dir() {
    local candidate

    for candidate in \
        "$HOME/skriptid" \
        "$HOME/Documents/skriptid" \
        "$HOME/Desktop/skriptid"
    do
        if [ -d "$candidate" ]; then
            printf '%s\n' "$candidate"
            return 0
        fi
    done

    local found
    found=$(find "$HOME" -maxdepth 5 -type d -name skriptid 2>/dev/null | head -n 1 || true)
    if [ -n "$found" ]; then
        printf '%s\n' "$found"
        return 0
    fi

    return 1
}

path_has_dir() {
    local target="$1"
    local element

    IFS=':' read -r -a _path_parts <<< "$PATH"
    for element in "${_path_parts[@]}"; do
        if [ "$element" = "$target" ]; then
            return 0
        fi
    done

    return 1
}

path_config_has_skriptid() {
    grep -Eiq 'PATH=.*skriptid' "$HOME/.bashrc" 2>/dev/null || \
    grep -Eiq 'PATH=.*skriptid' "$HOME/.profile" 2>/dev/null || \
    grep -Eiq 'PATH=.*skriptid' "$HOME/.bash_profile" 2>/dev/null
}

script_prints_name_and_course() {
    local file="$1"

    grep -Eiq '^[[:space:]]*(echo|printf)\b' "$file"
}

echo "Task 09: kontrollin, kas vajalikud tegevused on labi tehtud"

history -a 2>/dev/null || true

resolved_cmd_path="$(command -v yl9_kuva_nimi 2>/dev/null || true)"

if [ -f "$HISTORY_FILE" ]; then
    ok "Bash ajaloo fail on olemas"
else
    all_missing=$((all_missing + 1))
    fail "Bash ajaloo faili ei leitud"
    echo "  Vihje: tee terminalis vajalikud tegevused ja salvesta ajalugu."
fi

skriptid_dir=""
if skriptid_dir=$(find_skriptid_dir); then
    ok "Kaust skriptid on leitud: $skriptid_dir"
elif [ -n "$resolved_cmd_path" ] && [ -f "$resolved_cmd_path" ]; then
    skriptid_dir="$(dirname "$resolved_cmd_path")"
    ok "Skriptide kaust on tuvastatud: $skriptid_dir"
    if [ "$(basename "$skriptid_dir")" != "skriptid" ]; then
        info "Kausta nimi pole tapselt skriptid, aga skript on tuvastatud ja kaivitatav"
    fi
else
    all_missing=$((all_missing + 1))
    fail "Kausta skriptid ei leitud"
    echo "  Vihje: loo oma skriptide jaoks kaust nimega skriptid."
fi

if [ -n "$skriptid_dir" ] && path_has_dir "$skriptid_dir"; then
    ok "skriptid kaust on aktiivses PATH keskkonnamuutujas"
elif path_config_has_skriptid; then
    ok "PATH seadistus skriptid kaustale on shelli konfiguratsioonis olemas"
else
    all_missing=$((all_missing + 1))
    fail "skriptid kausta ei leitud PATH keskkonnamuutujast"
    echo "  Vihje: lisa skriptid kaust PATH muutujasse (nt .bashrc kaudu)."
fi

if history_has '(^|[[:space:]])(export[[:space:]]+PATH=|echo[[:space:]].*PATH|nano[[:space:]].*\.bashrc|vi[[:space:]].*\.bashrc|vim[[:space:]].*\.bashrc)' && \
   history_has 'skriptid'; then
    ok "PATH muutmise tegevus on ajaloost tuvastatud"
else
    info "PATH muutmise ajaloo kontroll jaeti vahele"
fi

script_file=""
if [ -n "$skriptid_dir" ] && [ -f "$skriptid_dir/yl9_kuva_nimi" ]; then
    script_file="$skriptid_dir/yl9_kuva_nimi"
    ok "Skriptifail yl9_kuva_nimi on olemas"
elif [ -n "$resolved_cmd_path" ] && [ -f "$resolved_cmd_path" ]; then
    script_file="$resolved_cmd_path"
    ok "Skriptifail yl9_kuva_nimi on olemas"
else
    all_missing=$((all_missing + 1))
    fail "Skriptifaili yl9_kuva_nimi (ilma laiendita) ei leitud"
    echo "  Vihje: loo fail nimega yl9_kuva_nimi ilma .sh laiendita."
fi

if [ -n "$script_file" ]; then
    script_name="$(basename "$script_file")"
    if [[ "$script_name" == "yl9_kuva_nimi" ]]; then
        ok "Skriptifaili nimi on oige (ilma laiendita)"
    else
        all_missing=$((all_missing + 1))
        fail "Skriptifaili nimi pole nouutud kujul"
        echo "  Vihje: nimi peab olema yl9_kuva_nimi ilma laiendita."
    fi
fi

if [ -n "$script_file" ] && [ -x "$script_file" ]; then
    ok "Skriptifail on kaivitatav"
elif [ -n "$script_file" ]; then
    all_missing=$((all_missing + 1))
    fail "Skriptifail pole kaivitatav"
    echo "  Vihje: lisa failile kaivitusoigus (chmod +x)."
fi

if [ -n "$script_file" ] && script_prints_name_and_course "$script_file"; then
    ok "Skriptis on nime ja kursuse valjastamise loogika tuvastatud"
elif [ -n "$script_file" ]; then
    all_missing=$((all_missing + 1))
    fail "Skriptist ei tuvasta nime ja kursuse valjastamist"
    echo "  Vihje: skript peab valjastama sinu nime ja kursuse."
fi

if command -v yl9_kuva_nimi >/dev/null 2>&1; then
    ok "Skripti saab kaivitada soltumata asukohast (command -v tuvastas)"
elif [ -n "$script_file" ] && history_has '(^|[[:space:]])yl9_kuva_nimi([[:space:]]|$)'; then
    ok "Skripti valjakutse on ajaloost tuvastatud"
else
    all_missing=$((all_missing + 1))
    fail "Skripti kaivitust soltumata asukohast ei tuvastatud"
    echo "  Vihje: lisa skript PATH-i ja kaivita lihtsalt nimega yl9_kuva_nimi."
fi

if [ -n "$script_file" ]; then
    script_output="$($script_file 2>/dev/null || true)"
    if [ -n "$script_output" ]; then
        ok "Skript valjastab teksti"
    else
        all_missing=$((all_missing + 1))
        fail "Skripti valjund on tyhi"
        echo "  Vihje: lisa skripti echo/printf valjund nime ja kursusega."
    fi
fi

if history_has '(^|[[:space:]])(scrot|gnome-screenshot|spectacle|flameshot|import)([[:space:]]|$)' || \
   find "$HOME" -maxdepth 3 -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' \) 2>/dev/null | grep -q .; then
    ok "Ekraanitommise toend on osaliselt tuvastatud"
else
    info "Ekraanitommise kontroll jaeti vahele (toend voib olla valjaspool masinat)"
fi

echo
echo "Puuduvate kohustuslike tingimuste arv: $mandatory_fails"

if [ "$all_missing" -ge 8 ]; then
    echo
    echo "Vihje: voimalik, et shelli ajalugu pole veel faili kirjutatud."
    echo "Jooksuta enne kontrolli: history -a"
fi

if [ "$mandatory_fails" -eq 0 ]; then
    printf '%b\n' "${GREEN_BOLD}Task 09: ARVESTATUD${RESET}"
    send_result 9
else
    printf '%b\n' "${RED_BOLD}Task 09: MITTE ARVESTATUD${RESET}"
    exit 1
fi
