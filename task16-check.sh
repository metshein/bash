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
    elif command -v rpm >/dev/null 2>&1; then
        rpm -q "$pkg" >/dev/null 2>&1
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

find_web_root() {
    local candidate

    for candidate in /var/www/html /usr/share/nginx/html; do
        if [ -d "$candidate" ]; then
            printf '%s\n' "$candidate"
            return 0
        fi
    done

    return 1
}

find_php_test_file() {
    local root="$1"
    find "$root" -maxdepth 2 -type f -name '*.php' 2>/dev/null | head -n 1 || true
}

html_has_css_link() {
    local html_file="$1"
    grep -Eiq '<link[^>]+\.css' "$html_file"
}

css_file_from_html_exists() {
    local html_file="$1"
    local root="$2"
    local css_rel

    css_rel=$(grep -Eio '<link[^>]+href=["\x27][^"\x27]+\.css["\x27]' "$html_file" | head -n 1 | sed -E 's/.*href=["\x27]([^"\x27]+)["\x27].*/\1/' || true)
    if [ -z "$css_rel" ]; then
        return 1
    fi

    if [[ "$css_rel" = /* ]]; then
        [ -f "$css_rel" ] || [ -f "$root$css_rel" ]
    else
        [ -f "$root/$css_rel" ] || [ -f "$(dirname "$html_file")/$css_rel" ]
    fi
}

nginx_has_php_fpm_conf() {
    grep -R -Eiq 'location[[:space:]]+~[[:space:]]+\\\.php|fastcgi_pass[[:space:]]+.*php.*fpm|include[[:space:]]+fastcgi_params' /etc/nginx 2>/dev/null
}

nginx_has_ssl_conf() {
    grep -R -Eiq 'listen[[:space:]]+443([[:space:]]+ssl|;)|ssl_certificate[[:space:]]+|ssl_certificate_key[[:space:]]+' /etc/nginx 2>/dev/null
}

ssl_cert_present() {
    find /etc/ssl -maxdepth 5 -type f \( -name '*.crt' -o -name '*.pem' \) 2>/dev/null | grep -q .
}

localhost_http_ok() {
    curl -sS -I --max-time 5 http://127.0.0.1 2>/dev/null | grep -Eq 'HTTP/[0-9.]+[[:space:]]+(200|301|302)'
}

localhost_https_ok() {
    curl -k -sS -I --max-time 5 https://127.0.0.1 2>/dev/null | grep -Eq 'HTTP/[0-9.]+[[:space:]]+(200|301|302)'
}

php_fpm_service_active() {
    if command -v systemctl >/dev/null 2>&1; then
        systemctl list-units --type=service --all 2>/dev/null | grep -Eiq 'php.*fpm.*running|php.*fpm\.service'
    else
        return 1
    fi
}

db_service_active() {
    service_active mariadb || service_active mysql || service_active postgresql
}

db_gui_installed() {
    [ -d /usr/share/phpmyadmin ] || [ -d /etc/phpmyadmin ] || [ -f /usr/share/adminer/adminer.php ] || [ -f /var/www/html/adminer.php ]
}

echo "Task 16: kontrollin, kas vajalikud tegevused on labi tehtud"

history -a 2>/dev/null || true

if [ -f "$HISTORY_FILE" ]; then
    ok "Bash ajaloo fail on olemas"
else
    all_missing=$((all_missing + 1))
    fail "Bash ajaloo faili ei leitud"
    echo "  Vihje: tee terminalis vajalikud tegevused ja salvesta ajalugu."
fi

if pkg_installed nginx || command -v nginx >/dev/null 2>&1; then
    ok "Nginx on paigaldatud"
else
    all_missing=$((all_missing + 1))
    fail "Nginx paigaldust ei tuvastatud"
    echo "  Vihje: paigalda nginx."
fi

if service_active nginx; then
    ok "Nginx teenus on aktiivne"
else
    all_missing=$((all_missing + 1))
    fail "Nginx teenus ei ole aktiivne"
    echo "  Vihje: kaivita teenus systemctl kasuga."
fi

web_root=""
if web_root=$(find_web_root); then
    ok "Veebi juurkaust on leitud: $web_root"
else
    all_missing=$((all_missing + 1))
    fail "Nginx veebikausta ei leitud"
    echo "  Vihje: kontrolli nginx dokumentjuurt."
fi

index_html=""
if [ -n "$web_root" ] && [ -f "$web_root/index.html" ]; then
    index_html="$web_root/index.html"
    ok "index.html on olemas"
else
    all_missing=$((all_missing + 1))
    fail "index.html faili ei leitud"
    echo "  Vihje: loo ja salvesta lihtne HTML indeksfail."
fi

if [ -n "$index_html" ] && grep -Eiq '<html|<!doctype html' "$index_html"; then
    ok "index.html sisaldab HTML struktuuri"
elif [ -n "$index_html" ]; then
    all_missing=$((all_missing + 1))
    fail "index.html ei paista olevat korrektne HTML"
    echo "  Vihje: lisa faili HTML struktuur."
fi

if [ -n "$index_html" ] && html_has_css_link "$index_html"; then
    ok "HTML fail viitab CSS failile"
else
    all_missing=$((all_missing + 1))
    fail "HTML failis puudub CSS viide"
    echo "  Vihje: lisa <link ... .css> HTML faili."
fi

if [ -n "$index_html" ] && [ -n "$web_root" ] && css_file_from_html_exists "$index_html" "$web_root"; then
    ok "CSS fail on olemas"
else
    all_missing=$((all_missing + 1))
    fail "CSS faili ei leitud"
    echo "  Vihje: loo viidatud CSS fail ja salvesta see veebikausta."
fi

if localhost_http_ok; then
    ok "Nginx HTTP kattesaatavus on tuvastatud"
else
    all_missing=$((all_missing + 1))
    fail "Nginx HTTP kattesaatavust ei tuvastatud"
    echo "  Vihje: testi brauseris voi curl kasuga http://127.0.0.1."
fi

if pkg_installed php-fpm || php_fpm_service_active || command -v php-fpm >/dev/null 2>&1; then
    ok "PHP-FPM on paigaldatud"
else
    all_missing=$((all_missing + 1))
    fail "PHP-FPM paigaldust ei tuvastatud"
    echo "  Vihje: paigalda php-fpm."
fi

if php_fpm_service_active; then
    ok "PHP-FPM teenus on tuvastatud"
else
    info "PHP-FPM teenuse kontroll jaeti vahele"
fi

if nginx_has_php_fpm_conf; then
    ok "Nginx PHP-FPM konfiguratsioon on tuvastatud"
else
    all_missing=$((all_missing + 1))
    fail "Nginx PHP-FPM konfiguratsiooni ei leitud"
    echo "  Vihje: lisa php location + fastcgi_pass seadistus."
fi

php_test_file=""
if [ -n "$web_root" ]; then
    php_test_file=$(find_php_test_file "$web_root")
fi

if [ -n "$php_test_file" ]; then
    ok "PHP testfail on leitud: $(basename "$php_test_file")"
else
    all_missing=$((all_missing + 1))
    fail "PHP testfaili ei leitud"
    echo "  Vihje: loo veebikausta test .php fail."
fi

if history_has '(phpinfo|\.php|curl[[:space:]].*127\.0\.0\.1.*php|wget[[:space:]].*127\.0\.0\.1.*php)'; then
    ok "PHP toe testimise tegevus on tuvastatud"
else
    all_missing=$((all_missing + 1))
    fail "PHP toe testimise tegevust ei leitud"
    echo "  Vihje: testi PHP faili kaesitletavust nginx kaudu."
fi

if db_service_active || pkg_installed mariadb-server || pkg_installed mysql-server || pkg_installed postgresql; then
    ok "Andmebaasi paigaldus/teenus on tuvastatud"
else
    all_missing=$((all_missing + 1))
    fail "Andmebaasi paigaldust ei tuvastatud"
    echo "  Vihje: paigalda ja kaivita andmebaas."
fi

if db_gui_installed || pkg_installed phpmyadmin; then
    ok "Andmebaasi graafiline liides on tuvastatud"
else
    all_missing=$((all_missing + 1))
    fail "Andmebaasi graafilise liidese paigaldust ei tuvastatud"
    echo "  Vihje: paigalda phpMyAdmin voi muu GUI lahendus."
fi

if nginx_has_ssl_conf && ssl_cert_present; then
    ok "HTTPS (SSL konfiguratsioon + sertifikaat) on tuvastatud"
else
    all_missing=$((all_missing + 1))
    fail "HTTPS aktiveerimist ei tuvastatud"
    echo "  Vihje: lisa nginx SSL seadistus ja sertifikaat."
fi

if localhost_https_ok; then
    ok "HTTPS kattesaatavus on tuvastatud"
else
    all_missing=$((all_missing + 1))
    fail "HTTPS kattesaatavust ei tuvastatud"
    echo "  Vihje: testi brauseris voi curl -k kasuga https://127.0.0.1."
fi

if history_has '(^|[[:space:]])(apt|apt-get|systemctl|nginx|php-fpm|mysql|mariadb)([[:space:]]|$)'; then
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
    printf '%b\n' "${GREEN_BOLD}Task 16: ARVESTATUD${RESET}"
    send_result 16
else
    printf '%b\n' "${RED_BOLD}Task 16: MITTE ARVESTATUD${RESET}"
    exit 1
fi
