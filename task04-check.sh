#!/usr/bin/env bash

set -euo pipefail

source "$(dirname "$0")/common.sh"

HISTORY_FILE="$HOME/.bash_history"
DOCS_DIR="$HOME/Documents"
ALT_DOCS_DIR="$HOME/Dokumendid"

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

echo "Task 04: kontrollin, kas vajalikud tegevused on labi tehtud"

history -a 2>/dev/null || true

if [ -f "$HISTORY_FILE" ]; then
    ok "Bash ajaloo fail on olemas"
else
    all_missing=$((all_missing + 1))
    fail "Bash ajaloo faili ei leitud"
    echo "  Vihje: tee terminalis paar kasku ja lopeta shell korrektselt."
fi

if history_has '(^|[[:space:]])(find|locate)([[:space:]].*)?\.bash_history'; then
    ok "Ajaloo faili otsimise kask on leitud"
else
    all_missing=$((all_missing + 1))
    fail "Ajaloo faili otsimise kasku ei leitud"
    echo "  Vihje: kasuta faili leidmiseks vastavat otsingukasku."
fi

if history_has '(^|[[:space:]])(grep|awk|sed|rg)([[:space:]].*)sudo'; then
    ok "sudo ridade otsimine on leitud"
else
    all_missing=$((all_missing + 1))
    fail "sudo ridade otsimise kasku ei leitud"
    echo "  Vihje: filtreeri failist read, mis sisaldavad sona sudo."
fi

if history_has '(^|[[:space:]])(sort|tac)([[:space:]]|$)' ; then
    ok "Ridade jarjestamise tegevus on leitud"
else
    all_missing=$((all_missing + 1))
    fail "Ridade jarjestamise tegevust ei leitud"
    echo "  Vihje: kuva viimased kirjed ettepoole sobivas jarjekorras."
fi

if [ -d "$DOCS_DIR" ] || [ -d "$ALT_DOCS_DIR" ] || [ -d "$HOME/Desktop" ]; then
    ok "Documents kaust on olemas"
else
    all_missing=$((all_missing + 1))
    fail "Documents kausta ei leitud"
    echo "  Vihje: salvesta valjund kodukataloogi Documents kausta."
fi

report_file=""
for search_dir in "$DOCS_DIR" "$ALT_DOCS_DIR" "$HOME/Desktop" "$HOME"; do
    [ -d "$search_dir" ] || continue

    shopt -s nullglob
    report_candidates=("$search_dir"/*_ylesanne04.txt)
    shopt -u nullglob

    if [ "${#report_candidates[@]}" -gt 0 ]; then
        report_file="${report_candidates[0]}"
        ok "Ylesanne 04 faili nimekujuga fail on leitud"
        break
    fi
done

if [ -z "$report_file" ]; then
    all_missing=$((all_missing + 1))
    fail "Ylesanne 04 faili nimekujuga faili ei leitud"
    echo "  Vihje: faili nimi peab loppema kujul _ylesanne04.txt."
fi

if [ -n "$report_file" ] && [ -s "$report_file" ]; then
    ok "Valjundfail ei ole tyhi"
elif [ -n "$report_file" ]; then
    all_missing=$((all_missing + 1))
    fail "Valjundfail on tyhi"
    echo "  Vihje: failis peavad olema leitud sudo read."
fi

if [ -n "$report_file" ] && grep -Eq 'sudo' "$report_file"; then
    ok "Valjundfailis on sudo read olemas"
elif [ -n "$report_file" ]; then
    all_missing=$((all_missing + 1))
    fail "Valjundfailis puuduvad sudo read"
    echo "  Vihje: kontrolli, et failis oleksid ainult vastavad leiud."
fi

if [ -n "$report_file" ]; then
    first_line="$(head -n 1 "$report_file" | tr -d '\r')"
    if printf '%s\n' "$first_line" | grep -Eq '[[:alpha:]]' && \
       printf '%s\n' "$first_line" | grep -Eq '([0-3]?[0-9][./-][01]?[0-9][./-][12][0-9]{3}|[12][0-9]{3}-[01][0-9]-[0-3][0-9])'; then
        ok "Faili alguses on nimi ja kuupaev"
    else
        all_missing=$((all_missing + 1))
        fail "Faili alguses puudub nimi voi kuupaev"
        echo "  Vihje: lisa faili ette rida oma nime ja kuupaevaga."
    fi
fi

if history_has '(^|[[:space:]])(nano|vim|vi|nvim|code|micro|gedit)([[:space:]].*)_ylesanne04\.txt'; then
    ok "Tekstiredaktori kasutus on leitud"
else
    all_missing=$((all_missing + 1))
    fail "Tekstiredaktori kasutust ei leitud"
    echo "  Vihje: ava valjundfail tekstiredaktoris ja salvesta muudatused."
fi

echo
echo "Puuduvate kohustuslike tingimuste arv: $mandatory_fails"

if [ "$all_missing" -ge 6 ]; then
    echo
    echo "Vihje: voimalik, et shelli ajalugu pole veel faili kirjutatud."
    echo "Jooksuta enne kontrolli: history -a"
fi

if [ "$mandatory_fails" -eq 0 ]; then
    echo "Task 04: ARVESTATUD"
    send_result 4
else
    printf '%b\n' "${RED_BOLD}Task 04: MITTE ARVESTATUD${RESET}"
    exit 1
fi