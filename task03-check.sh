#!/usr/bin/env bash

set -euo pipefail

source "$(dirname "$0")/common.sh"

HISTORY_FILE="$HOME/.bash_history"
TARGET_DIR=""

if [ -d "/Documents/ylesanne03" ]; then
    TARGET_DIR="/Documents/ylesanne03"
elif [ -d "$HOME/Documents/ylesanne03" ]; then
    TARGET_DIR="$HOME/Documents/ylesanne03"
elif [ -d "$HOME/ylesanne03" ]; then
    TARGET_DIR="$HOME/ylesanne03"
else
    found_dir=$(find "$HOME" -maxdepth 4 -type d -name 'ylesanne03' 2>/dev/null | head -n 1 || true)
    if [ -n "$found_dir" ]; then
        TARGET_DIR="$found_dir"
    fi
fi

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

ls_with_flags_found() {
    if [ ! -f "$HISTORY_FILE" ]; then
        return 1
    fi

    while IFS= read -r line; do
        case "$line" in
            ls*)
                if printf '%s\n' "$line" | grep -Eq '(^|[[:space:]])ls([[:space:]]|$)' && \
                   (printf '%s\n' "$line" | grep -Eq '(^|[[:space:]])-[A-Za-z]*F[A-Za-z]*([[:space:]]|$)|(^|[[:space:]])--classify([[:space:]]|$)') && \
                   (printf '%s\n' "$line" | grep -Eq '(^|[[:space:]])-[A-Za-z]*l[A-Za-z]*([[:space:]]|$)|(^|[[:space:]])--format=long([[:space:]]|$)') && \
                   (printf '%s\n' "$line" | grep -Eq '(^|[[:space:]])-[A-Za-z]*h[A-Za-z]*([[:space:]]|$)|(^|[[:space:]])--human-readable([[:space:]]|$)'); then
                    return 0
                fi
                ;;
        esac
    done < "$HISTORY_FILE"

    return 1
}

echo "Task 03: kontrollin, kas vajalikud tegevused on labi tehtud"

history -a 2>/dev/null || true

if [ -z "$TARGET_DIR" ]; then
    all_missing=$((all_missing + 1))
    fail "Ylesanne 03 kausta ei leitud"
    echo "  Vihje: kontrolli, kas tegid too Documents kausta alla."
else
    ok "Ylesanne 03 kaust leitud"
fi

if [ -n "$TARGET_DIR" ]; then
    missing_main_dirs=0

    for number in $(seq 1 50); do
        if [ "$number" -eq 3 ]; then
            continue
        fi

        if [ ! -d "$TARGET_DIR/kaust$number" ]; then
            missing_main_dirs=1
            break
        fi
    done

    if [ "$missing_main_dirs" -eq 0 ]; then
        ok "Noutud pohikaustad on olemas"
    else
        all_missing=$((all_missing + 1))
        fail "Mone pohikausta struktuur on puudu"
        echo "  Vihje: kontrolli kaustade nimetusi ja arvu."
    fi

    top_level_count=$(find "$TARGET_DIR" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')
    if [ "$top_level_count" -ge 49 ]; then
        ok "Ylemise taseme kaustade arv sobib"
    else
        all_missing=$((all_missing + 1))
        fail "Ylemise taseme kaustade arv ei klapi"
        echo "  Vihje: parast kustutamist peaks ylemisel tasemel olema yks kaust vahem."
    fi

    missing_subdirs=0
    for number in $(seq 1 50); do
        if [ "$number" -eq 3 ]; then
            continue
        fi

        for subdir in alamkaust1 alamkaust2 alamkaust3; do
            if [ ! -d "$TARGET_DIR/kaust$number/$subdir" ]; then
                missing_subdirs=1
                break 2
            fi
        done
    done

    if [ "$missing_subdirs" -eq 0 ]; then
        ok "Alamkaustade struktuur on olemas"
    else
        all_missing=$((all_missing + 1))
        fail "Mones kaustas puuduvad alamkaustad"
        echo "  Vihje: kontrolli, et igas nouutud kaustas oleks kolm alamkausta."
    fi

    if [ ! -d "$TARGET_DIR/kaust3" ]; then
        ok "Kaust3 on eemaldatud"
    else
        all_missing=$((all_missing + 1))
        fail "Kaust3 on veel alles"
        echo "  Vihje: kontrolli, milline kaust tuli eemaldada."
    fi

    shopt -s nullglob
    copied_dirs=("$TARGET_DIR"/kaust1/kaust5 "$TARGET_DIR"/kaust1/kaust5_*)
    shopt -u nullglob

    valid_copy_found=0
    for copied_dir in "${copied_dirs[@]}"; do
        if [ -d "$copied_dir" ] && [ -d "$copied_dir/alamkaust1" ] && [ -d "$copied_dir/alamkaust2" ] && [ -d "$copied_dir/alamkaust3" ]; then
            valid_copy_found=1
            break
        fi
    done

    if [ "$valid_copy_found" -eq 1 ]; then
        ok "Kaust5 koopia on kaust1 sees olemas"
    else
        all_missing=$((all_missing + 1))
        fail "Kaust5 koopiat ei leitud oigest asukohast"
        echo "  Vihje: kontrolli koopia nimekuju ja asukohta."
    fi
fi

if [ -f "$HISTORY_FILE" ]; then
    ok "Bash ajalugu leitud"
else
    all_missing=$((all_missing + 1))
    fail "Bash ajalugu ei leitud"
    echo "  Vihje: tee vajalikud tegevused terminalis ja salvesta need ajalukku."
fi

if history_has '(^|[[:space:]])ls([[:space:]]|$)'; then
    ok "ls kasutus leitud"
else
    all_missing=$((all_missing + 1))
    fail "ls kasutus puudub"
    echo "  Vihje: kuva kaustade sisu vastava kaesuga."
fi

if history_has '(^|[[:space:]])(tree|find)([[:space:]]|$)'; then
    ok "tree kasutus leitud"
else
    all_missing=$((all_missing + 1))
    fail "tree kasutus puudub"
    echo "  Vihje: kuva kaustade puustruktuur vastava kaesuga."
fi

if history_has '(^|[[:space:]])(man[[:space:]]+ls|ls[[:space:]]+--help)([[:space:]]|$)'; then
    ok "man ls kasutus leitud"
else
    all_missing=$((all_missing + 1))
    fail "man ls kasutus puudub"
    echo "  Vihje: uuri ls kasu juhendit."
fi

if ls_with_flags_found; then
    ok "ls lipud F, l ja h on kasutatud"
else
    all_missing=$((all_missing + 1))
    fail "ls lippe F, l ja h ei leitud koos"
    echo "  Vihje: kuva sisu uuesti ls kaesuga, kasutades koiki kolme lippu."
fi

if history_has '(^|[[:space:]])mkdir([[:space:]]|$)'; then
    ok "Kaustade loomise kaesud on leitud"
else
    all_missing=$((all_missing + 1))
    fail "Kaustade loomise kaeske ei leitud"
    echo "  Vihje: kontrolli, kuidas kaustu terminalis luuakse."
fi

if history_has '(^|[[:space:]])(rm|rmdir)([[:space:]]|$)'; then
    ok "Kustutamise kaesk on leitud"
else
    all_missing=$((all_missing + 1))
    fail "Kustutamise kaesku ei leitud"
    echo "  Vihje: kontrolli, kuidas kataloogi eemaldatakse."
fi

if history_has '(^|[[:space:]])cp([[:space:]]|$)'; then
    ok "Kopeerimise kaesk on leitud"
else
    all_missing=$((all_missing + 1))
    fail "Kopeerimise kaesku ei leitud"
    echo "  Vihje: kontrolli, kuidas kataloogist koopiat teha."
fi

if history_has '(^|[[:space:]])mv([[:space:]]|$)'; then
    ok "Liigutamise kaesk on leitud"
else
    all_missing=$((all_missing + 1))
    fail "Liigutamise kaesku ei leitud"
    echo "  Vihje: kontrolli, kuidas kataloogi asukohta muuta."
fi

echo
echo "Puuduvate kohustuslike tingimuste arv: $mandatory_fails"

if [ "$all_missing" -ge 8 ]; then
    echo
    echo "Vihje: voimalik, et shelli ajalugu pole veel faili kirjutatud."
    echo "Jooksuta enne kontrolli: history -a"
fi

if [ "$mandatory_fails" -eq 0 ]; then
    echo "Task 03: ARVESTATUD"
    send_result 3
else
    printf '%b\n' "${RED_BOLD}Task 03: MITTE ARVESTATUD${RESET}"
    exit 1
fi