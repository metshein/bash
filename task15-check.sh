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

cron_has_backup_script() {
    # Lubame nii konkreetse skripti nime kui ka tüüpilised varukoopia mustrid.
    local pattern='veebiserveri_konf|apache_conf_|php_conf_|ssl_conf_|/etc/apache2|/etc/php|/etc/ssl'

    if command -v crontab >/dev/null 2>&1; then
        if crontab -l 2>/dev/null | grep -Eiq "$pattern"; then
            return 0
        fi
    fi

    grep -R -Eiq "$pattern" /etc/crontab /etc/cron.d /etc/cron.daily /etc/cron.weekly /etc/cron.hourly 2>/dev/null
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
apache_server_signature_off() {
    grep -R -Eiq 'ServerSignature[[:space:]]+Off' /etc/apache2 2>/dev/null
}

apache_options_no_indexes() {
    grep -R -Eiq 'Options[[:space:]]+-Indexes' /etc/apache2 2>/dev/null
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

# HTTPS kontrollid
apache_ssl_module_enabled() {
    if command -v apache2ctl >/dev/null 2>&1; then
        apache2ctl -M 2>/dev/null | grep -Eiq 'ssl_module'
    else
        [ -f /etc/apache2/mods-enabled/ssl.load ] || [ -L /etc/apache2/mods-enabled/ssl.load ]
    fi
}

apache_default_ssl_site_enabled() {
    [ -f /etc/apache2/sites-enabled/default-ssl.conf ] || [ -L /etc/apache2/sites-enabled/default-ssl.conf ]
}

apache_https_config_present() {
    grep -R -Eiq '<VirtualHost[[:space:]]+\*:443>|Listen[[:space:]]+443|SSLEngine[[:space:]]+on' /etc/apache2 2>/dev/null
}

apache_ssl_cert_directives_present() {
    grep -R -Eiq 'SSLCertificateFile[[:space:]]+' /etc/apache2 2>/dev/null && \
    grep -R -Eiq 'SSLCertificateKeyFile[[:space:]]+' /etc/apache2 2>/dev/null
}

apache_ssl_cert_files_exist() {
    local cert_file
    local key_file

    cert_file=$(grep -R -Ei '^[[:space:]]*SSLCertificateFile[[:space:]]+' /etc/apache2 2>/dev/null | head -n1 | sed -E 's/.*SSLCertificateFile[[:space:]]+//I')
    key_file=$(grep -R -Ei '^[[:space:]]*SSLCertificateKeyFile[[:space:]]+' /etc/apache2 2>/dev/null | head -n1 | sed -E 's/.*SSLCertificateKeyFile[[:space:]]+//I')

    [ -n "$cert_file" ] && [ -n "$key_file" ] && [ -f "$cert_file" ] && [ -f "$key_file" ]
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
apache_security_missing=0

if apache_server_signature_off; then
    ok "ServerSignature Off on seadistatud"
else
    apache_security_missing=1
    fail "ServerSignature Off seadistust ei tuvastatud"
fi

if apache_options_no_indexes; then
    ok "Options -Indexes on seadistatud"
else
    apache_security_missing=1
    fail "Options -Indexes seadistust ei tuvastatud"
fi

if [ "$apache_security_missing" -eq 0 ]; then
    ok "Apache turvalisuse seadistused on korras"
else
    all_missing=$((all_missing + 1))
    echo "  Vihje: kontrolli Apache conf failides ridu ServerSignature Off ja Options -Indexes"
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

# HTTPS kontroll
https_missing=0

if apache_ssl_module_enabled; then
    ok "Apache ssl moodul on aktiivne"
else
    https_missing=1
    fail "Apache ssl moodulit ei tuvastatud"
fi

if apache_default_ssl_site_enabled; then
    ok "default-ssl sait on lubatud"
else
    https_missing=1
    fail "default-ssl saiti ei tuvastatud"
fi

if apache_https_config_present; then
    ok "Apache HTTPS konfiguratsioon on olemas"
else
    https_missing=1
    fail "Apache HTTPS konfiguratsiooni ei tuvastatud"
fi

if apache_ssl_cert_directives_present && apache_ssl_cert_files_exist; then
    ok "Sertifikaadi failid on Apache konfiguratsioonis ja olemas"
else
    https_missing=1
    fail "Sertifikaadi failide seadistus on puudu või failid puuduvad"
fi

if [ "$https_missing" -ne 0 ]; then
    all_missing=$((all_missing + 1))
    echo "  Vihje: a2enmod ssl, a2ensite default-ssl ja kontrolli SSLCertificateFile/SSLCertificateKeyFile"
fi

# monitooring
if history_has 'server-status|status[[:space:]]+apache2'; then
    ok "Monitooringu tegevus tuvastatud"
else
    all_missing=$((all_missing + 1))
    fail "Monitooringut ei tuvastatud"
fi

# backup
if history_has 'tar.*backup|mysqldump|apache_conf_|php_conf_|ssl_conf_' || cron_has_backup_script; then
    ok "Varukoopia tegemine tuvastatud (ajaloost voi cronist)"
else
    all_missing=$((all_missing + 1))
    fail "Varukoopia tegemist ei tuvastatud"
    echo "  Vihje: lisa cron'i varukoopia skript (nt 0 0 * * * ~/skriptid/veebiserveri_konf)"
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