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

find_oigused_dir() {
    local candidate

    for candidate in \
        "$HOME/oigused" \
        "$HOME/Documents/oigused" \
        "$HOME/Desktop/oigused" \
        "$PWD/oigused"
    do
        if [ -d "$candidate" ]; then
            printf '%s\n' "$candidate"
            return 0
        fi
    done

    local found
    found=$(find "$HOME" -maxdepth 4 -type d -name oigused 2>/dev/null | head -n 1 || true)
    if [ -n "$found" ]; then
        printf '%s\n' "$found"
        return 0
    fi

    return 1
}

dir_mode_octal() {
    local path="$1"
    stat -c '%a' "$path"
}

dir_mode_symbolic() {
    local path="$1"
    stat -c '%A' "$path"
}

file_mode_symbolic() {
    local path="$1"
    stat -c '%A' "$path"
}

echo "Task 06: kontrollin, kas vajalikud tegevused on labi tehtud"

history -a 2>/dev/null || true

if [ -f "$HISTORY_FILE" ]; then
    ok "Bash ajaloo fail on olemas"
else
    all_missing=$((all_missing + 1))
    fail "Bash ajaloo faili ei leitud"
    echo "  Vihje: tee terminalis vajalikud tegevused ja salvesta ajalugu."
fi

oigused_dir=""
if oigused_dir=$(find_oigused_dir); then
    ok "Kaust oigused on leitud: $oigused_dir"
else
    all_missing=$((all_missing + 1))
    fail "Kausta oigused ei leitud"
    echo "  Vihje: loo kaust nimega oigused oma valitud asukohta."
fi

important_file=""
if [ -n "$oigused_dir" ] && [ -f "$oigused_dir/oluline_fail.txt" ]; then
    important_file="$oigused_dir/oluline_fail.txt"
    ok "Fail oluline_fail.txt on olemas"
else
    all_missing=$((all_missing + 1))
    fail "Faili oluline_fail.txt ei leitud kaustast oigused"
    echo "  Vihje: loo fail kaustas oigused kasuga who > oluline_fail.txt."
fi

if [ -n "$important_file" ] && [ -s "$important_file" ]; then
    ok "Fail oluline_fail.txt ei ole tyhi"
elif [ -n "$important_file" ]; then
    all_missing=$((all_missing + 1))
    fail "Fail oluline_fail.txt on tyhi"
    echo "  Vihje: faili sisu peab tulema who valjundist."
fi

if grep -qE '^who' "$HISTORY_FILE" 2>/dev/null; then
    ok "who kask on leitud"
else
    all_missing=$((all_missing + 1))
    fail "who kasku ei leitud"
    echo "  Vihje: suuna who valjund faili oluline_fail.txt."
fi

if grep -qE '^ls([[:space:]]|$|-[a-zA-Z])' "$HISTORY_FILE" 2>/dev/null; then
    ok "ls kask on leitud"
else
    all_missing=$((all_missing + 1))
    fail "ls kasku ei leitud"
    echo "  Vihje: kuva faili oigused kasuga ls -l."
fi

if [ -n "$important_file" ]; then
    file_perm=$(file_mode_symbolic "$important_file")
    ok "Faili praegused oigused: $file_perm"
fi

if history_has '(^|[[:space:]])chmod([[:space:]].*)oluline_fail\.txt'; then
    ok "Faili oiguste muutmise tegevus on leitud"
else
    all_missing=$((all_missing + 1))
    fail "Faili oiguste muutmise tegevust ei leitud"
    echo "  Vihje: kasuta faili puhul chmod kaske."
fi

if history_has '(^|[[:space:]])chmod([[:space:]].*)(o-|o=|a-r|0[0-7][0-7][0-7]|[0-7][0-7][0-7]).*oluline_fail\.txt'; then
    ok "Teiste kasutajate oiguste eemaldamine faililt on leitud"
else
    all_missing=$((all_missing + 1))
    fail "Teiste kasutajate oiguste eemaldamise tegevust ei leitud"
    echo "  Vihje: eemalda faililt koik other/o oigused (nt chmod o-rwx oluline_fail.txt)."
fi

if history_has '(^|[[:space:]])chmod([[:space:]].*)(u-r|a-r|0[0-2][0-7][0-7]|[0-2][0-7][0-7]).*oluline_fail\.txt'; then
    ok "Omaniku lugemisoiguse eemaldamise tegevus on leitud"
else
    all_missing=$((all_missing + 1))
    fail "Omaniku lugemisoiguse eemaldamise tegevust ei leitud"
    echo "  Vihje: eemalda faililt omaniku lugemisoigus (nt chmod u-r oluline_fail.txt)."
fi

if history_has '(^|[[:space:]])(cat|head|tail|less|more)([[:space:]].*)?oluline_fail\.txt' || \
   ( [ -n "$important_file" ] && ! [ -r "$important_file" ] ); then
    ok "Faili lugemise kontroll on tehtud (lugemisoigus puudub)"
else
    all_missing=$((all_missing + 1))
    fail "Faili lugemise kontrolli ei leitud"
    echo "  Vihje: parast lugemisoiguse eemaldamist proovi faili lugeda (cat oluline_fail.txt)."
fi

if history_has '(^|[[:space:]])(sudo[[:space:]]+)?(cat|head|tail|less|more)([[:space:]].*)oluline_fail\.txt'; then
    ok "Root/privileegitud lugemise kontrolli tegevus on leitud"
else
    ok "Root lugemise history kontroll jaeti vahele (sudo kasud voivad puududa ajaloost)"
fi

if [ -n "$oigused_dir" ]; then
    dir_perm_octal=$(dir_mode_octal "$oigused_dir")

    if history_has '(^|[[:space:]])chmod([[:space:]].*)(777|0777)([[:space:]]|$)' || \
       [ "$dir_perm_octal" = "777" ]; then
        ok "Kaustale on seatud oigused 0777"
    else
        all_missing=$((all_missing + 1))
        fail "Kaustale pole seatud oiguseid 0777"
        echo "  Vihje: sea kaustale oigused 0777 (chmod 0777 oigused)."
    fi

    if [ -r "$oigused_dir" ] && [ -x "$oigused_dir" ]; then
        ok "Omanik saab kausta sisu naha ja kausta siseneda"
    else
        all_missing=$((all_missing + 1))
        fail "Omanik ei saa kausta sisu naha voi kausta siseneda"
        echo "  Vihje: kontrolli kausta lugemis- ja kaivitusoigust."
    fi
fi

if history_has '(^|[[:space:]])(rm|unlink)([[:space:]].*)oluline_fail\.txt'; then
    ok "Faili kustutamise tegevus on leitud"
else
    ok "Faili kustutamise history kontroll jaeti vahele"
fi

echo
echo "Puuduvate kohustuslike tingimuste arv: $mandatory_fails"

if [ "$all_missing" -ge 8 ]; then
    echo
    echo "Vihje: voimalik, et shelli ajalugu pole veel faili kirjutatud."
    echo "Jooksuta enne kontrolli: history -a"
fi

if [ "$mandatory_fails" -eq 0 ]; then
    printf '%b\n' "${GREEN_BOLD}Task 06: ARVESTATUD${RESET}"
    send_result 6
else
    printf '%b\n' "${RED_BOLD}Task 06: MITTE ARVESTATUD${RESET}"
    exit 1
fi
