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

find_wlan_file() {
    local candidate

    for candidate in \
        "$HOME/wlan.txt" \
        "$HOME/Documents/wlan.txt" \
        "$HOME/Desktop/wlan.txt" \
        "$PWD/wlan.txt"
    do
        if [ -f "$candidate" ]; then
            printf '%s\n' "$candidate"
            return 0
        fi
    done

    local found
    found=$(find "$HOME" -maxdepth 4 -type f -name wlan.txt 2>/dev/null | head -n 1 || true)
    if [ -n "$found" ]; then
        printf '%s\n' "$found"
        return 0
    fi

    return 1
}

find_download_dir() {
    local candidate

    for candidate in "$HOME/Download" "$HOME/Downloads"; do
        if [ -d "$candidate" ]; then
            printf '%s\n' "$candidate"
            return 0
        fi
    done

    return 1
}

find_uploaded_image() {
    local dir="$1"

    find "$dir" -maxdepth 1 -type f \
        \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.bmp' -o -iname '*.webp' \) \
        2>/dev/null | head -n 1 || true
}

looks_like_wlan_dump() {
    local file="$1"

    grep -Eqi 'wlan0|wlan|wireless|inet[[:space:]]|link/ether|mtu' "$file"
}

has_remote_login_trace() {
    last -n 30 2>/dev/null | grep -Eiq '([0-9]{1,3}\.){3}[0-9]{1,3}|pts/'
}

echo "Task 07: kontrollin, kas vajalikud tegevused on labi tehtud"

history -a 2>/dev/null || true

if [ -f "$HISTORY_FILE" ]; then
    ok "Bash ajaloo fail on olemas"
else
    all_missing=$((all_missing + 1))
    fail "Bash ajaloo faili ei leitud"
    echo "  Vihje: tee terminalis vajalikud tegevused ja salvesta ajalugu."
fi

wlan_file=""
if wlan_file=$(find_wlan_file); then
    ok "wlan.txt on leitud: $wlan_file"
else
    all_missing=$((all_missing + 1))
    fail "wlan.txt faili ei leitud"
    echo "  Vihje: salvesta wlan seaded faili wlan.txt."
fi

if [ -n "$wlan_file" ] && [ -s "$wlan_file" ]; then
    ok "wlan.txt ei ole tyhi"
elif [ -n "$wlan_file" ]; then
    all_missing=$((all_missing + 1))
    fail "wlan.txt on tyhi"
    echo "  Vihje: faili sisu peab tulema wlan liidese seadete kuvamisest."
fi

if [ -n "$wlan_file" ] && looks_like_wlan_dump "$wlan_file"; then
    ok "wlan.txt sisu naeb valja nagu wlan liidese valjund"
elif [ -n "$wlan_file" ]; then
    all_missing=$((all_missing + 1))
    fail "wlan.txt sisust ei tuvasta wlan liidese infot"
    echo "  Vihje: kasuta wlan liidese kuvamiseks ip voi ifconfig kaske."
fi

if history_has 'wlan\.txt' || { [ -n "$wlan_file" ] && looks_like_wlan_dump "$wlan_file"; }; then
    ok "wlan seadetest faili tegemise tegevus on leitud"
else
    all_missing=$((all_missing + 1))
    fail "wlan seadetest wlan.txt tegemist ei leitud"
    echo "  Vihje: kuva liidese seaded ja suuna valjund faili wlan.txt."
fi

if history_has '(^|[[:space:]])(scp|sftp|rsync|python[[:space:]]+-m[[:space:]]+http\.server|wget|curl)([[:space:]]|$)' || \
   history_has 'wlan\.txt'; then
    ok "wlan.txt edasi liigutamise tegevus on osaliselt tuvastatud"
else
    ok "wlan.txt Windows allalaadimise kontroll jaeti pehmemaks"
fi

download_dir=""
if download_dir=$(find_download_dir); then
    ok "Download/Downloads kaust on leitud: $download_dir"
else
    all_missing=$((all_missing + 1))
    fail "Download voi Downloads kausta ei leitud"
    echo "  Vihje: lae ekraanitommis Raspberry Pi Download(s) kausta."
fi

uploaded_image=""
if [ -n "$download_dir" ]; then
    uploaded_image=$(find_uploaded_image "$download_dir")
    if [ -n "$uploaded_image" ]; then
        ok "Download(s) kaustas on pildifail: $(basename "$uploaded_image")"
    else
        all_missing=$((all_missing + 1))
        fail "Download(s) kaustas pildifaili ei leitud"
        echo "  Vihje: lae ekraanitommis Raspberry Pi Download(s) kausta."
    fi
fi

if [ -n "$uploaded_image" ] && has_remote_login_trace; then
    ok "Kaudne toend faili uleslaadimisest on olemas (remote login + pildifail)"
elif [ -n "$uploaded_image" ]; then
    ok "Pildifail on olemas, kuid remote login jalg voib olla puhastatud"
else
    ok "Uhenduse toendit ei saanud kinnitada ilma pildifailita"
fi

if history_has '(^|[[:space:]])ls([[:space:]].*)(Download|Downloads)' || \
   history_has '(^|[[:space:]])ls([[:space:]]|$)'; then
    ok "Kataloogi loendi kuvamine on leitud"
else
    all_missing=$((all_missing + 1))
    fail "Kataloogi loendi kuvamist ei leitud"
    echo "  Vihje: kuva Download(s) kausta sisu kasuga ls -l."
fi

echo
echo "Puuduvate kohustuslike tingimuste arv: $mandatory_fails"

if [ "$all_missing" -ge 7 ]; then
    echo
    echo "Vihje: voimalik, et shelli ajalugu pole veel faili kirjutatud."
    echo "Jooksuta enne kontrolli: history -a"
fi

if [ "$mandatory_fails" -eq 0 ]; then
    printf '%b\n' "${GREEN_BOLD}Task 07: ARVESTATUD${RESET}"
    send_result 7
else
    printf '%b\n' "${RED_BOLD}Task 07: MITTE ARVESTATUD${RESET}"
    exit 1
fi
