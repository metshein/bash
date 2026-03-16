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

find_pack_script() {
    local script

    while IFS= read -r script; do
        if ! is_user_script_candidate "$script"; then
            continue
        fi

        if grep -Eiq '(tar|zip)' "$script" && grep -Eiq 'Documents' "$script"; then
            printf '%s\n' "$script"
            return 0
        fi
    done < <(find "$HOME" -maxdepth 5 -type f -name '*.sh' 2>/dev/null)

    return 1
}

find_send_script() {
    local script

    while IFS= read -r script; do
        if ! is_user_script_candidate "$script"; then
            continue
        fi

        if grep -Eiq '(scp|sftp|rsync|lftp|ftp|curl)' "$script"; then
            printf '%s\n' "$script"
            return 0
        fi
    done < <(find "$HOME" -maxdepth 5 -type f -name '*.sh' 2>/dev/null)

    return 1
}

find_backup_archive() {
    local archive
    local base_name

    while IFS= read -r archive; do
        base_name="$(basename "$archive")"
        if printf '%s\n' "$base_name" | grep -Eiq 'documents|varukoopia|backup' && \
           printf '%s\n' "$base_name" | grep -Eq '([12][0-9]{3}[-_][01][0-9][-_][0-3][0-9]|[0-3][0-9][-_][01][0-9][-_][12][0-9]{3}|[12][0-9]{7})'; then
            printf '%s\n' "$archive"
            return 0
        fi
    done < <(find "$HOME" -maxdepth 5 -type f \
        \( -name '*.tar' -o -name '*.tar.gz' -o -name '*.tgz' -o -name '*.zip' \) \
        2>/dev/null)

    return 1
}

cron_has_daily_2000() {
    local cron_content="$1"

    printf '%s\n' "$cron_content" | grep -Eq '^[[:space:]]*0[[:space:]]+20[[:space:]]+\*[[:space:]]+\*[[:space:]]+\*[[:space:]]+'
}

cron_daily_does_pack() {
    local cron_content="$1"

    printf '%s\n' "$cron_content" | grep -Ei '^[[:space:]]*0[[:space:]]+20[[:space:]]+\*[[:space:]]+\*[[:space:]]+\*[[:space:]]+' | \
        grep -Eiq '(tar|zip|backup|varukoopia|documents|\.sh)'
}

cron_has_weekly() {
    local cron_content="$1"

    printf '%s\n' "$cron_content" | grep -Eq '^[[:space:]]*([0-9*/,-]+)[[:space:]]+([0-9*/,-]+)[[:space:]]+([0-9*/,-]+)[[:space:]]+([0-9*/,-]+)[[:space:]]+([0-7]|sun|mon|tue|wed|thu|fri|sat)[[:space:]]+' || \
    printf '%s\n' "$cron_content" | grep -Eq '^[[:space:]]*@weekly[[:space:]]+'
}

cron_weekly_does_send() {
    local cron_content="$1"

    {
        printf '%s\n' "$cron_content" | grep -Ei '^[[:space:]]*([0-9*/,-]+)[[:space:]]+([0-9*/,-]+)[[:space:]]+([0-9*/,-]+)[[:space:]]+([0-9*/,-]+)[[:space:]]+([0-7]|sun|mon|tue|wed|thu|fri|sat)[[:space:]]+'
        printf '%s\n' "$cron_content" | grep -Ei '^[[:space:]]*@weekly[[:space:]]+'
    } | grep -Eiq '(scp|sftp|rsync|lftp|curl|ftp|sshpass|varukoopiad|liivakast|\.sh)'
}

echo "Task 08: kontrollin, kas vajalikud tegevused on labi tehtud"

history -a 2>/dev/null || true

if [ -f "$HISTORY_FILE" ]; then
    ok "Bash ajaloo fail on olemas"
else
    all_missing=$((all_missing + 1))
    fail "Bash ajaloo faili ei leitud"
    echo "  Vihje: tee terminalis vajalikud tegevused ja salvesta ajalugu."
fi

pack_script=""
if pack_script=$(find_pack_script); then
    ok "Kokkupakkimise skript on leitud: $pack_script"
else
    pack_script=""
    info "Kokkupakkimise skripti ei leitud (see pole kohustuslik, kui tegevus on muul viisil toendatud)"
fi

send_script=""
if send_script=$(find_send_script); then
    ok "Serverisse saatmise skript on leitud: $send_script"
else
    send_script=""
    info "Serverisse saatmise skripti ei leitud (see pole kohustuslik, kui tegevus on muul viisil toendatud)"
fi

if [ -n "$send_script" ] && grep -Eiq 'varukoopiad' "$send_script"; then
    ok "Saatmisskriptis on sihtkaust varukoopiad tuvastatud"
elif history_has 'varukoopiad'; then
    ok "Sihtkausta varukoopiad kasutus on ajaloost tuvastatud"
elif [ -n "$send_script" ]; then
    all_missing=$((all_missing + 1))
    fail "Saatmisskriptist ei leia varukoopiad sihtkausta"
    echo "  Vihje: suuna fail serveris kausta nimega varukoopiad."
else
    all_missing=$((all_missing + 1))
    fail "Serveri sihtkausta varukoopiad kasutust ei leitud"
    echo "  Vihje: kasuta serveris kausta varukoopiad."
fi

if [ -n "$send_script" ] && grep -Eiq '(sshpass|lftp|curl[[:space:]]+-u|ftp|sftp|scp|rsync)' "$send_script"; then
    ok "Saatmisskriptis on andmeedastuse kask tuvastatud"
elif history_has '(^|[[:space:]])(sshpass|lftp|curl|ftp|sftp|scp|rsync)([[:space:]]|$)'; then
    ok "Andmeedastuse kask on ajaloost tuvastatud"
elif [ -n "$send_script" ]; then
    all_missing=$((all_missing + 1))
    fail "Saatmisskriptis andmeedastuse kaske ei leitud"
    echo "  Vihje: kasuta faili saatmiseks sobivat kaske (scp/sftp/rsync/lftp/curl)."
else
    all_missing=$((all_missing + 1))
    fail "Andmeedastuse kaske ei leitud"
    echo "  Vihje: kasuta faili saatmiseks sobivat kaske (scp/sftp/rsync/lftp/curl)."
fi

backup_archive=""
if backup_archive=$(find_backup_archive); then
    ok "Kuupaevaga varukoopia fail on leitud: $(basename "$backup_archive")"
else
    backup_archive=""
    all_missing=$((all_missing + 1))
    fail "Kuupaevaga varukoopiafaili ei leitud"
    echo "  Vihje: faili nimi peab sisaldama loomise kuupaeva."
fi

cron_content="$(crontab -l 2>/dev/null || true)"
if [ -n "$cron_content" ]; then
    ok "Crontab kirjed on olemas"
else
    all_missing=$((all_missing + 1))
    fail "Crontab kirjeid ei leitud"
    echo "  Vihje: lisa crontabi nii paevane kui nadalane ajastus."
fi

if [ -n "$cron_content" ] && cron_has_daily_2000 "$cron_content"; then
    ok "Paevane ajastus 20:00 on crontabis olemas"
else
    all_missing=$((all_missing + 1))
    fail "Paevast 20:00 ajastust ei leitud"
    echo "  Vihje: lisa kirje kujul 0 20 * * * ..."
fi

if [ -n "$cron_content" ] && cron_daily_does_pack "$cron_content"; then
    ok "Paevane 20:00 crontab kirje kaivitab varunduse"
else
    all_missing=$((all_missing + 1))
    fail "Paevane 20:00 crontab kirje ei kaivita varundust"
    echo "  Vihje: pane 0 20 kirjesse tar/zip voi varundusskripti kaivitus."
fi

if [ -n "$cron_content" ] && cron_has_weekly "$cron_content"; then
    ok "Nadalane ajastus serverisse saatmiseks on olemas"
else
    all_missing=$((all_missing + 1))
    fail "Nadalast serverisse saatmise ajastust ei leitud"
    echo "  Vihje: lisa nadalane kirje (nt @weekly voi day-of-week cron)."
fi

if [ -n "$cron_content" ] && cron_weekly_does_send "$cron_content"; then
    ok "Nadalane crontab kirje kaivitab serverisse saatmise"
else
    all_missing=$((all_missing + 1))
    fail "Nadalane crontab kirje ei kaivita serverisse saatmist"
    echo "  Vihje: pane nadalasesse kirjesse scp/sftp/rsync voi saatmisskripti kaivitus."
fi

pack_script_name=""
if [ -n "$pack_script" ]; then
    pack_script_name="$(basename "$pack_script")"
fi

if [ -n "$pack_script_name" ] && \
   grep -Fqi "$pack_script_name" "$HISTORY_FILE" 2>/dev/null; then
    ok "Varukoopia skripti testkaivitus on tuvastatud"
elif history_has '(^|[[:space:]])(tar|zip)([[:space:]]|$)' && [ -n "$backup_archive" ]; then
    ok "Varukoopia loomise test on tuvastatud (tar/zip + varukoopiafail)"
else
    all_missing=$((all_missing + 1))
    fail "Varukoopia loomise testi ei leitud"
    echo "  Vihje: kaivita varundus (skript voi kask) ja kontrolli, et fail tekib."
fi

echo
echo "Puuduvate kohustuslike tingimuste arv: $mandatory_fails"

if [ "$all_missing" -ge 8 ]; then
    echo
    echo "Vihje: voimalik, et shelli ajalugu pole veel faili kirjutatud."
    echo "Jooksuta enne kontrolli: history -a"
fi

if [ "$mandatory_fails" -eq 0 ]; then
    printf '%b\n' "${GREEN_BOLD}Task 08: ARVESTATUD${RESET}"
    send_result 8
else
    printf '%b\n' "${RED_BOLD}Task 08: MITTE ARVESTATUD${RESET}"
    exit 1
fi
