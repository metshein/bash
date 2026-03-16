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

pkg_installed() {
    local pkg="$1"

    if command -v dpkg >/dev/null 2>&1; then
        dpkg -s "$pkg" >/dev/null 2>&1
    else
        return 1
    fi
}

service_active() {
    local svc="$1"

    if command -v systemctl >/dev/null 2>&1; then
        systemctl is-active --quiet "$svc"
    else
        return 1
    fi
}

apache_security_ok() {
    if [ -f /etc/apache2/conf-available/security.conf ]; then
        grep -Eiq 'ServerTokens[[:space:]]+Prod' /etc/apache2/conf-available/security.conf && \
        grep -Eiq 'ServerSignature[[:space:]]+Off' /etc/apache2/conf-available/security.conf
    else
        return 1
    fi
}

apache_has_php_support() {
    if command -v apache2ctl >/dev/null 2>&1; then
        apache2ctl -M 2>/dev/null | grep -Eiq 'php(_module)?'
    elif pkg_installed libapache2-mod-php; then
        return 0
    else
        return 1
    fi
}

apache_has_ssl_support() {
    if command -v apache2ctl >/dev/null 2>&1 && apache2ctl -M 2>/dev/null | grep -Eiq 'ssl_module'; then
        return 0
    fi

    if [ -L /etc/apache2/mods-enabled/ssl.load ] || [ -f /etc/apache2/mods-enabled/ssl.load ]; then
        return 0
    fi

    history_has '(^|[[:space:]])a2enmod([[:space:]]+.*)?[[:space:]]ssl([[:space:]]|$)'
}

ssl_cert_present() {
    find /etc/ssl -maxdepth 4 -type f \( -name '*.crt' -o -name '*.pem' \) 2>/dev/null | grep -q .
}

echo "Task 15: kontrollin, kas vajalikud tegevused on labi tehtud"

history -a 2>/dev/null || true

if [ -f "$HISTORY_FILE" ]; then
    ok "Bash ajaloo fail on olemas"
else
    all_missing=$((all_missing + 1))
    fail "Bash ajaloo faili ei leitud"
    echo "  Vihje: tee terminalis vajalikud tegevused ja salvesta ajalugu."
fi

if pkg_installed apache2 || command -v apache2 >/dev/null 2>&1; then
    ok "Apache2 on paigaldatud"
else
    all_missing=$((all_missing + 1))
    fail "Apache2 paigaldust ei tuvastatud"
    echo "  Vihje: paigalda apache2."
fi

if service_active apache2; then
    ok "Apache2 teenus on aktiivne"
else
    all_missing=$((all_missing + 1))
    fail "Apache2 teenus ei ole aktiivne"
    echo "  Vihje: kaivita teenus systemctl kasuga."
fi

if apache_security_ok || history_has 'ServerTokens|ServerSignature|security\.conf'; then
    ok "Apache turvalisuse konfiguratsiooni loogika on tuvastatud"
else
    all_missing=$((all_missing + 1))
    fail "Apache turvalisuse konfiguratsiooni ei tuvastatud"
    echo "  Vihje: sea ServerTokens Prod ja ServerSignature Off."
fi

if apache_has_php_support || pkg_installed php || pkg_installed libapache2-mod-php; then
    ok "PHP tugi Apachele on olemas"
else
    all_missing=$((all_missing + 1))
    fail "PHP toe lisamist Apachele ei tuvastatud"
    echo "  Vihje: paigalda php ja Apache PHP moodul."
fi

if pkg_installed mariadb-server || pkg_installed mysql-server || command -v mariadbd >/dev/null 2>&1; then
    ok "MariaDB/MySQL on paigaldatud"
else
    all_missing=$((all_missing + 1))
    fail "MariaDB/MySQL paigaldust ei tuvastatud"
    echo "  Vihje: paigalda mariadb-server (voi mysql-server)."
fi

if service_active mariadb || service_active mysql; then
    ok "MariaDB/MySQL teenus on aktiivne"
else
    all_missing=$((all_missing + 1))
    fail "MariaDB/MySQL teenus ei ole aktiivne"
    echo "  Vihje: kaivita andmebaasi teenus."
fi

if pkg_installed phpmyadmin || [ -d /etc/phpmyadmin ] || [ -d /usr/share/phpmyadmin ]; then
    ok "phpMyAdmin on paigaldatud"
else
    all_missing=$((all_missing + 1))
    fail "phpMyAdmin paigaldust ei tuvastatud"
    echo "  Vihje: paigalda phpmyadmin."
fi

if ssl_cert_present && apache_has_ssl_support; then
    ok "SSL sertifikaat ja Apache SSL tugi on tuvastatud"
elif ssl_cert_present; then
    all_missing=$((all_missing + 1))
    fail "SSL sertifikaat on olemas, aga Apache SSL tugi puudub"
    echo "  Vihje: luba ssl moodul (a2enmod ssl) ja taaskaivita Apache."
else
    all_missing=$((all_missing + 1))
    fail "SSL sertifikaadi paigaldust ei tuvastatud"
    echo "  Vihje: paigalda sertifikaat /etc/ssl alla ja luba SSL veebiserveris."
fi

if history_has 'server-status|status[[:space:]]+apache2|apache2ctl[[:space:]]+status|systemctl[[:space:]]+status[[:space:]]+apache2'; then
    ok "Veebiserveri monitoorimise tegevus on tuvastatud"
else
    all_missing=$((all_missing + 1))
    fail "Veebiserveri monitoorimise tegevust ei leitud"
    echo "  Vihje: kuva serveri staatus/monitooringu vaade."
fi

if history_has '(^|[[:space:]])(apt|apt-get|systemctl|a2enmod)([[:space:]]|$)'; then
    ok "Oluliste kaeskude kasutus on ajaloost tuvastatud"
else
    info "Kaeskude ajaloo kontroll jaeti vahele"
fi

echo
echo "Puuduvate kohustuslike tingimuste arv: $mandatory_fails"

if [ "$all_missing" -ge 8 ]; then
    echo
    echo "Vihje: voimalik, et shelli ajalugu pole veel faili kirjutatud."
    echo "Jooksuta enne kontrolli: history -a"
fi

if [ "$mandatory_fails" -eq 0 ]; then
    printf '%b\n' "${GREEN_BOLD}Task 15: ARVESTATUD${RESET}"
    send_result 15
else
    printf '%b\n' "${RED_BOLD}Task 15: MITTE ARVESTATUD${RESET}"
    exit 1
fi
