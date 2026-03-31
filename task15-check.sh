#!/usr/bin/env bash

set -euo pipefail

source "$(dirname "$0")/common.sh"

HISTORY_FILE="$HOME/.bash_history"

# värvid (kui terminal toetab)
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

# ------------------------
# Abifunktsioonid
# ------------------------

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

# Apache turvalisus (vastavalt juhendile)
apache_security_ok() {
    local found_sig=1
    local found_indexes=1

    grep -R -Eiq 'ServerSignature[[:space:]]+Off' /etc/apache2 2>/dev/null && found_sig=0
    grep -R -Eiq 'Options[[:space:]]+-Indexes' /etc/apache2 2>/dev/null && found_indexes=0

    [ $found_sig -eq 0 ] && [ $found_indexes -eq 0 ]
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

# SSL kontrollid
apache_has_ssl_support() {
    [ -f /etc/apache2/mods-enabled/ssl.load ] || [ -L /etc/apache2/mods-enabled/ssl.load ]
}

ssl_site_enabled() {
    [ -f /etc/apache2/sites-enabled/default-ssl.conf ] || [ -L /etc/apache2/sites-enabled/default-ssl.conf ]
}

ssl_cert_present() {
    find /etc/ssl -maxdepth 4 -type f \( -name '*.crt' -o -name '*.pem' \) 2>/dev/null | grep -q .
}

ssl_cert_configured() {
    grep -R -Eiq 'SSLCertificateFile[[:space:]]+/etc/ssl/' /etc/apache2 2>/dev/null && \
    grep -R -Eiq 'SSLCertificateKeyFile[[:space:]]+/etc/ssl/' /etc/apache2 2>/dev/null
}

# ------------------------
# Kontroll algab
# ------------------------

echo "Task 15: kontrollin, kas vajalikud tegevused on labi tehtud"

history -a 2>/dev/null || true

# Bash ajalugu
if [ -f "$HISTORY_FILE" ]; then
    ok "Bash ajaloo fail on olemas"
else
    all_missing=$((all_missing + 1))
    fail "Bash ajaloo faili ei leitud"
fi

# Apache paigaldus
if pkg_installed apache2 || command -v apache2 >/dev/null 2>&1; then
    ok "Apache2 on paigaldatud"
else
    all_missing=$((all_missing + 1))
    fail "Apache2 paigaldust ei tuvastatud"
fi

# Apache töötab
if service_active apache2; then
    ok "Apache2 teenus on aktiivne"
else
    all_missing=$((all_missing + 1))
    fail "Apache2 teenus ei ole aktiivne"
fi

# Apache turvalisus
if apache_security_ok; then
    ok "Apache turvalisuse seadistused on korras"
else
    all_missing=$((all_missing + 1))
    fail "Apache turvalisuse seadistusi ei tuvastatud"
    echo "  Vihje: ServerSignature Off ja Options -Indexes"
fi

# PHP tugi
if apache_has_php_support || pkg_installed php; then
    ok "PHP tugi Apachele on olemas"
else
    all_missing=$((all_missing + 1))
    fail "PHP toe lisamist ei tuvastatud"
fi

# MariaDB
if pkg_installed mariadb-server || pkg_installed mysql-server; then
    ok "MariaDB/MySQL on paigaldatud"
else
    all_missing=$((all_missing + 1))
    fail "Andmebaasi paigaldust ei tuvastatud"
fi

# MariaDB töötab
if service_active mariadb || service_active mysql; then
    ok "Andmebaasi teenus töötab"
else
    all_missing=$((all_missing + 1))
    fail "Andmebaasi teenus ei tööta"
fi

# phpMyAdmin
if pkg_installed phpmyadmin || [ -d /usr/share/phpmyadmin ]; then
    ok "phpMyAdmin on paigaldatud"
else
    all_missing=$((all_missing + 1))
    fail "phpMyAdmin paigaldust ei tuvastatud"
fi

# SSL kontroll (parandatud)
if ssl_cert_present && apache_has_ssl_support && ssl_site_enabled && ssl_cert_configured; then
    ok "SSL ja HTTPS seadistus on korras"
elif ssl_cert_present; then
    all_missing=$((all_missing + 1))
    fail "SSL failid olemas, aga Apache HTTPS seadistus puudulik"
    echo "  Vihje: a2enmod ssl, a2ensite default-ssl ja cert path"
else
    all_missing=$((all_missing + 1))
    fail "SSL sertifikaati ei leitud"
fi

# monitooring
if history_has 'server-status|status[[:space:]]+apache2'; then
    ok "Monitooringu tegevus tuvastatud"
else
    all_missing=$((all_missing + 1))
    fail "Monitooringut ei tuvastatud"
fi

# backup
if history_has 'tar.*backup|mysqldump'; then
    ok "Varukoopia tegemine tuvastatud"
else
    all_missing=$((all_missing + 1))
    fail "Varukoopia tegemist ei tuvastatud"
fi

echo
echo "Puuduvate tingimuste arv: $mandatory_fails"

if [ "$mandatory_fails" -eq 0 ]; then
    printf '%b\n' "${GREEN_BOLD}Task 15: ARVESTATUD${RESET}"
    send_result 15
else
    printf '%b\n' "${RED_BOLD}Task 15: MITTE ARVESTATUD${RESET}"
    exit 1
fi