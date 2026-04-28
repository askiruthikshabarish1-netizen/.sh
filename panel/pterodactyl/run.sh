#!/bin/bash
# ===========================================================
# PTERODACTYL CONTROL CENTER — v2.1
# ===========================================================

# ── Colors ─────────────────────────────────────────────────
BOLD='\033[1m'
PUR='\033[1;38;5;141m'
CYN='\033[1;38;5;51m'
GRN='\033[1;38;5;82m'
YLW='\033[1;38;5;220m'
RED='\033[1;38;5;196m'
W='\033[1;38;5;255m'
DG='\033[0;38;5;244m'
LG='\033[0;38;5;240m'
NC='\033[0m'

WIDTH=58

# ── Helpers ────────────────────────────────────────────────
box_top()   { printf "\n  ${PUR}╔%*s╗${NC}\n"   "$((WIDTH-2))" "" | tr ' ' '═'; }
box_bot()   { printf   "  ${PUR}╚%*s╝${NC}\n\n" "$((WIDTH-2))" "" | tr ' ' '═'; }
box_mid()   { printf   "  ${PUR}╠%*s╣${NC}\n"   "$((WIDTH-2))" "" | tr ' ' '═'; }
box_side()  { printf   "  ${PUR}╟%*s╢${NC}\n"   "$((WIDTH-2))" "" | tr ' ' '─'; }
box_blank() { printf   "  ${PUR}║${NC}%*s${PUR}║${NC}\n" "$((WIDTH-2))" ""; }
box_row()   { printf   "  ${PUR}║${NC}  %-$((WIDTH-4))s${PUR}║${NC}\n" "$1"; }

step()  { printf "\n  ${YLW}▸${NC}  ${DG}%s${NC}\n"  "$1"; }
ok()    { printf   "  ${GRN}✔${NC}  ${W}%s${NC}\n"   "$1"; }
err()   { printf   "  ${RED}✘${NC}  ${RED}%s${NC}\n" "$1"; }
info()  { printf   "  ${CYN}➜${NC}  ${DG}%s${NC}\n"  "$1"; }
warn()  { printf   "  ${YLW}!${NC}  ${YLW}%s${NC}\n" "$1"; }

divider() { printf "  ${LG}%*s${NC}\n" "$WIDTH" "" | tr ' ' '─'; }

pause() {
    printf "\n  ${DG}Press Enter to return to main menu…${NC}"
    read -r
}

# ── Header ─────────────────────────────────────────────────
show_header() {
    clear
    box_top
    box_blank
    box_row "$(printf "${PUR}${BOLD}  PTERODACTYL  •  SERVER MANAGEMENT${NC}")"
    box_blank
    box_mid
    box_row "$(printf "${DG}  Module: ${W}%s${NC}" "$1")"
    box_blank
    box_bot
}

# ── Panel status badge ─────────────────────────────────────
panel_status() {
    if [ -d "/var/www/pterodactyl" ]; then
        printf "${GRN}${BOLD}INSTALLED ✔${NC}"
    else
        printf "${RED}${BOLD}NOT INSTALLED ✘${NC}"
    fi
}

# ===========================================================
# INSTALL
# ===========================================================
install_ptero() {
    show_header "Panel Installation"
    info "Fetching installation script…"
    sleep 0.6
    bash <(curl -s https://raw.githubusercontent.com/nobita329/Nobita-Cloud/refs/heads/main/panel/pterodactyl/install.sh)
    printf "\n"
    ok "Installation sequence complete."
    pause
}

# ===========================================================
# CREATE USER
# ===========================================================
create_user() {
    show_header "User Management"

    if [ ! -d /var/www/pterodactyl ]; then
        err "Panel not found at /var/www/pterodactyl"
        err "Install the panel first."
        pause
        return
    fi

    printf "\n  ${W}User creation mode:${NC}\n\n"
    printf "  ${LG}│${NC}  ${GRN}[1]${NC}  Custom user    ${DG}(interactive)${NC}\n"
    printf "  ${LG}│${NC}  ${CYN}[2]${NC}  Auto admin     ${DG}(random credentials)${NC}\n"
    printf "\n  ${LG}╰─▸${NC} "
    read -r choice

    cd /var/www/pterodactyl || exit 1

    case $choice in
        1)
            step "Launching interactive user creation"
            php artisan p:user:make
            ;;
        2)
            step "Generating random admin credentials"
            USERNAME="user$(openssl rand -hex 2)"
            PASSWORD="$(openssl rand -base64 10)"
            EMAIL="$(openssl rand -base64 4 | tr -dc 'a-z0-9' | head -c8)@email.com"
            FIRST="$(openssl rand -base64 6 | tr -dc 'a-zA-Z' | head -c6)"
            LAST="$(openssl rand -base64 4 | tr -dc 'a-zA-Z' | head -c4)"

            php artisan p:user:make -n \
                --email="${EMAIL}" \
                --username="${USERNAME}" \
                --password="${PASSWORD}" \
                --admin=1 \
                --name-first="${FIRST}" \
                --name-last="${LAST}"

            printf "\n"
            divider
            ok "Admin user created"
            printf "\n"
            printf "  ${DG}Username :${NC}  ${W}%s${NC}\n" "$USERNAME"
            printf "  ${DG}Password :${NC}  ${W}%s${NC}\n" "$PASSWORD"
            printf "  ${DG}Email    :${NC}  ${W}%s${NC}\n" "$EMAIL"
            divider
            ;;
        *)
            err "Invalid option."
            ;;
    esac

    pause
}

# ===========================================================
# UNINSTALL
# ===========================================================
uninstall_logic() {
    step "Stopping panel services"
    systemctl stop pteroq.service    2>/dev/null || true
    systemctl disable pteroq.service 2>/dev/null || true
    rm -f /etc/systemd/system/pteroq.service
    systemctl daemon-reload
    ok "Services stopped"

    step "Removing cron jobs"
    crontab -l 2>/dev/null \
        | grep -v 'php /var/www/pterodactyl/artisan schedule:run' \
        | crontab - || true
    ok "Cron entries removed"

    step "Deleting panel files"
    rm -rf /var/www/pterodactyl
    ok "Files deleted"

    step "Dropping database"
    mysql -u root -e "DROP DATABASE IF EXISTS panel;"
    mysql -u root -e "DROP USER IF EXISTS 'pterodactyl'@'127.0.0.1';"
    mysql -u root -e "FLUSH PRIVILEGES;"
    ok "Database dropped"

    step "Cleaning Nginx configs"
    rm -f /etc/nginx/sites-enabled/pterodactyl.conf
    rm -f /etc/nginx/sites-available/pterodactyl.conf
    systemctl reload nginx || true
    ok "Nginx config removed"
}

uninstall_ptero() {
    show_header "Uninstallation"

    warn "This will permanently delete ALL panel data and databases."
    printf "\n  ${LG}╰─▸${NC} Proceed? ${DG}[y/N]${NC}  "
    read -r confirm

    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        info "Uninstallation cancelled."
        pause
        return
    fi

    printf "\n"
    uninstall_logic
    printf "\n"
    ok "Panel removed. Wings installation left untouched."
    pause
}

# ===========================================================
# UPDATE
# ===========================================================
update_panel() {
    show_header "System Update"

    if [ ! -d /var/www/pterodactyl ]; then
        err "Panel not found at /var/www/pterodactyl"
        pause
        return
    fi

    cd /var/www/pterodactyl || exit 1

    step "Enabling maintenance mode"
    php artisan down
    ok "Maintenance mode on"

    step "Removing old files"
    rm -rf /var/www/pterodactyl/*
    ok "Old files cleared"

    step "Downloading latest release"
    curl -Lo panel.tar.gz \
        https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz
    tar -xzvf panel.tar.gz
    ok "Release extracted"

    step "Setting permissions"
    chmod -R 755 storage/* bootstrap/cache/
    ok "Permissions set"

    step "Updating Composer dependencies"
    COMPOSER_ALLOW_SUPERUSER=1 composer install --no-dev --optimize-autoloader
    ok "Dependencies updated"

    step "Running migrations & clearing cache"
    php artisan view:clear
    php artisan config:clear
    php artisan migrate --seed --force
    chown -R www-data:www-data /var/www/pterodactyl/*
    ok "Migrations complete"

    step "Restarting queue workers"
    php artisan queue:restart
    php artisan up
    ok "Panel back online"

    printf "\n"
    divider
    ok "Panel updated successfully."
    divider
    pause
}

# ===========================================================
# MAIN MENU
# ===========================================================
while true; do
    clear

    # ── Banner ──
    printf "\n"
    printf "  ${PUR}${BOLD} ____  _                     _            _         _ ${NC}\n"
    printf "  ${PUR}${BOLD}|  _ \\| |_ ___ _ __ ___   __| | __ _  ___| |_ _   _| |${NC}\n"
    printf "  ${PUR}${BOLD}| |_) | __/ _ \\ '__/ _ \\ / _\` |/ _\` |/ __| __| | | | |${NC}\n"
    printf "  ${PUR}${BOLD}|  __/| ||  __/ | | (_) | (_| | (_| | (__| |_| |_| | |${NC}\n"
    printf "  ${PUR}${BOLD}|_|    \\__\\___|_|  \\___/ \\__,_|\\__,_|\\___|\\__|\\__, |_|${NC}\n"
    printf "  ${PUR}${BOLD}                                               |___/   ${NC}\n"
    printf "\n"

    # ── Status & menu box ──
    STATUS="$(panel_status)"

    printf "  ${PUR}╔%*s╗${NC}\n" "$((WIDTH-2))" "" | tr ' ' '═'
    printf "  ${PUR}║${NC}  ${DG}Panel status:${NC}  %-$((WIDTH-18))b${PUR}║${NC}\n" "$STATUS"
    printf "  ${PUR}╠%*s╣${NC}\n" "$((WIDTH-2))" "" | tr ' ' '═'
    printf "  ${PUR}║${NC}%*s${PUR}║${NC}\n" "$((WIDTH-2))" ""

    printf "  ${PUR}║${NC}  ${GRN}[1]${NC}  %-20s${DG}Fresh install${NC}%*s${PUR}║${NC}\n"    "Install"    "$(( WIDTH - 42 ))" ""
    printf "  ${PUR}║${NC}  ${GRN}[2]${NC}  %-20s${DG}Add admin / user${NC}%*s${PUR}║${NC}\n" "User"       "$(( WIDTH - 46 ))" ""
    printf "  ${PUR}║${NC}  ${YLW}[3]${NC}  %-20s${DG}Latest release${NC}%*s${PUR}║${NC}\n"   "Update"     "$(( WIDTH - 44 ))" ""
    printf "  ${PUR}║${NC}  ${YLW}[4]${NC}  %-20s${DG}Change domain / SSL${NC}%*s${PUR}║${NC}\n" "Domain"  "$(( WIDTH - 49 ))" ""
    printf "  ${PUR}║${NC}  ${RED}[5]${NC}  %-20s${DG}Remove all data${NC}%*s${PUR}║${NC}\n"   "Uninstall"  "$(( WIDTH - 45 ))" ""

    printf "  ${PUR}║${NC}%*s${PUR}║${NC}\n" "$((WIDTH-2))" ""
    printf "  ${PUR}╟%*s╢${NC}\n" "$((WIDTH-2))" "" | tr ' ' '─'
    printf "  ${PUR}║${NC}  ${W}[0]${NC}  %-20s%*s${PUR}║${NC}\n" "Exit" "$(( WIDTH - 26 ))" ""
    printf "  ${PUR}║${NC}%*s${PUR}║${NC}\n" "$((WIDTH-2))" ""
    printf "  ${PUR}╚%*s╝${NC}\n" "$((WIDTH-2))" "" | tr ' ' '═'

    printf "\n  ${PUR}root@ptero${NC}${DG}:~#${NC}  "
    read -r choice

    case $choice in
        1) install_ptero ;;
        2) create_user ;;
        3) update_panel ;;
        4) bash <(curl -fsSL https://raw.githubusercontent.com/nobita329/Nobita-Cloud/refs/heads/main/panel/pterodactyl/ssl.sh) ;;
        5) uninstall_ptero ;;
        0) clear; exit 0 ;;
        *) warn "Invalid option — choose 0–5."; sleep 0.8 ;;
    esac
done
