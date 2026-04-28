#!/bin/bash
# ===========================================================
# MACK CONTROL PANEL — v3.5  |  Server Automation
# ===========================================================

# ── Colors ─────────────────────────────────────────────────
BOLD='\033[1m'
CYN='\033[1;38;5;51m'
PUR='\033[1;38;5;141m'
GRN='\033[1;38;5;82m'
YLW='\033[1;38;5;220m'
RED='\033[1;38;5;196m'
BLU='\033[1;38;5;75m'
MGN='\033[1;38;5;201m'
W='\033[1;38;5;255m'
DG='\033[0;38;5;244m'
LG='\033[0;38;5;240m'
NC='\033[0m'

WIDTH=60

# ── Helpers ────────────────────────────────────────────────
box_top()   { printf "\n  ${BLU}╔%*s╗${NC}\n"   "$((WIDTH-2))" "" | tr ' ' '═'; }
box_bot()   { printf   "  ${BLU}╚%*s╝${NC}\n"   "$((WIDTH-2))" "" | tr ' ' '═'; }
box_mid()   { printf   "  ${BLU}╠%*s╣${NC}\n"   "$((WIDTH-2))" "" | tr ' ' '═'; }
box_side()  { printf   "  ${BLU}╟%*s╢${NC}\n"   "$((WIDTH-2))" "" | tr ' ' '─'; }
box_blank() { printf   "  ${BLU}║${NC}%*s${BLU}║${NC}\n" "$((WIDTH-2))" ""; }

ok()      { printf "  ${GRN}✔${NC}  ${W}%s${NC}\n"   "$1"; }
err()     { printf "  ${RED}✘${NC}  ${RED}%s${NC}\n" "$1"; }
info()    { printf "  ${CYN}➜${NC}  ${DG}%s${NC}\n"  "$1"; }
warn()    { printf "  ${YLW}!${NC}  ${YLW}%s${NC}\n" "$1"; }
step()    { printf "\n  ${YLW}▸${NC}  ${DG}%s${NC}\n" "$1"; }
divider() { printf "  ${LG}%*s${NC}\n" "$WIDTH" "" | tr ' ' '─'; }

launching() { printf "\n  ${CYN}▶${NC}  ${W}Launching${NC} ${DG}%s${NC}…\n\n" "$1"; }

pause() {
    printf "\n  ${DG}Press Enter to return to menu…${NC}"
    read -r
}

# ── System detection ───────────────────────────────────────
detect_system() {
    printf "  ${DG}Detecting system…${NC}\r"

    if [ -f /etc/os-release ]; then
        # shellcheck source=/dev/null
        . /etc/os-release
        OS_NAME="${PRETTY_NAME:-$(uname -s)}"
    else
        OS_NAME=$(uname -s)
    fi

    PUBLIC_IP=$(curl -s --max-time 3 https://ipinfo.io/ip 2>/dev/null || echo "unavailable")
    LOCAL_IP=$(hostname -I 2>/dev/null | awk '{print $1}' || echo "unavailable")

    if command -v free >/dev/null 2>&1; then
        RAM_USED=$(free -h | awk '/^Mem:/{print $3 "/" $2}')
    else
        RAM_USED="N/A"
    fi

    printf "  %*s\r" "$WIDTH" ""   # clear the detecting line
}

# ── Header ─────────────────────────────────────────────────
header() {
    clear

    box_top
    box_blank
    printf "  ${BLU}║${NC}  ${BLU}${BOLD}⚡ MACK CONTROL PANEL${NC}  ${DG}v3.5${NC}  ${DG}│${NC}  ${CYN}Server Automation${NC}%*s${BLU}║${NC}\n" \
        "$((WIDTH - 2 - 22 - 4 - 3 - 17 - 2))" ""
    box_blank
    box_mid

    # Truncate OS name if too long
    local os_short="${OS_NAME:0:22}"
    printf "  ${BLU}║${NC}  ${DG}OS   ${NC}  ${W}%-22s${NC}  ${DG}WAN${NC}  ${W}%-14s${NC}  ${BLU}║${NC}\n" \
        "$os_short" "$PUBLIC_IP"
    printf "  ${BLU}║${NC}  ${DG}RAM  ${NC}  ${W}%-22s${NC}  ${DG}LAN${NC}  ${W}%-14s${NC}  ${BLU}║${NC}\n" \
        "$RAM_USED" "$LOCAL_IP"
    box_blank
    box_bot
}

# ── Main menu ──────────────────────────────────────────────
show_menu() {
    printf "  ${BLU}╔%*s╗${NC}\n" "$((WIDTH-2))" "" | tr ' ' '═'
    printf "  ${BLU}║${NC}%*s${BLU}║${NC}\n" "$((WIDTH-2))" ""

    printf "  ${BLU}║${NC}  ${CYN}[1]${NC}  %-22s${DG}Certbot / Nginx${NC}%*s${BLU}║${NC}\n" \
        "SSL Configuration" "$((WIDTH-45))" ""
    printf "  ${BLU}║${NC}  ${GRN}[2]${NC}  %-22s${DG}Nobita script${NC}%*s${BLU}║${NC}\n"    \
        "Install Wings"     "$((WIDTH-43))" ""
    printf "  ${BLU}║${NC}  ${YLW}[3]${NC}  %-22s${DG}Wings manager${NC}%*s${BLU}║${NC}\n"    \
        "Manager"           "$((WIDTH-43))" ""
    printf "  ${BLU}║${NC}  ${MGN}[4]${NC}  %-22s${DG}MySQL / MariaDB${NC}%*s${BLU}║${NC}\n"  \
        "Database Manager"  "$((WIDTH-45))" ""
    printf "  ${BLU}║${NC}  ${RED}[5]${NC}  %-22s${DG}Remove Wings${NC}%*s${BLU}║${NC}\n"     \
        "Uninstall"         "$((WIDTH-42))" ""

    printf "  ${BLU}║${NC}%*s${BLU}║${NC}\n" "$((WIDTH-2))" ""
    printf "  ${BLU}╟%*s╢${NC}\n" "$((WIDTH-2))" "" | tr ' ' '─'
    printf "  ${BLU}║${NC}  ${W}[0]${NC}  %-22s%*s${BLU}║${NC}\n" \
        "Exit" "$((WIDTH-28))" ""
    printf "  ${BLU}║${NC}%*s${BLU}║${NC}\n" "$((WIDTH-2))" ""
    printf "  ${BLU}╚%*s╝${NC}\n\n" "$((WIDTH-2))" "" | tr ' ' '═'

    printf "  ${BLU}root@mack${NC}${DG}:~#${NC}  "
}

# ===========================================================
# SSL SETUP
# ===========================================================
ssl_setup() {
    header

    printf "  ${BLU}╔%*s╗${NC}\n" "$((WIDTH-2))" "" | tr ' ' '═'
    printf "  ${BLU}║${NC}  ${CYN}${BOLD}SSL CONFIGURATION${NC}%*s${BLU}║${NC}\n" "$((WIDTH-20))" ""
    printf "  ${BLU}╟%*s╢${NC}\n" "$((WIDTH-2))" "" | tr ' ' '─'
    printf "  ${BLU}║${NC}  ${DG}Auto-detected IP:${NC}  ${GRN}%-$((WIDTH-22))s${BLU}║${NC}\n" "$PUBLIC_IP"
    printf "  ${BLU}╚%*s╝${NC}\n\n" "$((WIDTH-2))" "" | tr ' ' '═'

    printf "  ${BLU}?${NC}  ${W}Enter domain${NC} ${DG}(e.g. node.host.com)${NC}\n  ${LG}╰─▸${NC} "
    read -r DOMAIN

    if [[ -z "$DOMAIN" ]]; then
        err "No domain entered — setup aborted."
        sleep 1; return
    fi

    printf "\n"
    step "Installing dependencies"
    apt update -y >/dev/null 2>&1
    apt install -y certbot python3-certbot-nginx >/dev/null 2>&1
    ok "Certbot installed"

    step "Cleaning existing certificate for ${DOMAIN}"
    rm -rf "/etc/letsencrypt/live/$DOMAIN" \
           "/etc/letsencrypt/archive/$DOMAIN" \
           "/etc/letsencrypt/renewal/$DOMAIN.conf"
    ok "Old cert cleared"

    step "Requesting SSL certificate for ${DOMAIN}"
    local email="ssl$(tr -dc a-z0-9 </dev/urandom | head -c6)@${DOMAIN}"
    certbot certonly --nginx -d "$DOMAIN" \
        --non-interactive --agree-tos --email "$email"

    printf "\n"
    divider
    ok "SSL setup complete for ${DOMAIN}"
    divider
    pause
}

# ===========================================================
# UNINSTALL
# ===========================================================
uninstall_menu() {
    header

    printf "  ${RED}╔%*s╗${NC}\n" "$((WIDTH-2))" "" | tr ' ' '═'
    printf "  ${RED}║${NC}  ${RED}${BOLD}⚠  DANGER ZONE — UNINSTALL${NC}%*s${RED}║${NC}\n" "$((WIDTH-30))" ""
    printf "  ${RED}╟%*s╢${NC}\n" "$((WIDTH-2))" "" | tr ' ' '─'
    printf "  ${RED}║${NC}  ${DG}Removes Wings, Docker configs.${NC}%*s${RED}║${NC}\n" "$((WIDTH-34))" ""
    printf "  ${RED}║${NC}  ${DG}Panel files remain untouched.${NC}%*s${RED}║${NC}\n"  "$((WIDTH-33))" ""
    printf "  ${RED}╚%*s╝${NC}\n\n" "$((WIDTH-2))" "" | tr ' ' '═'

    printf "  ${LG}╰─▸${NC} Proceed? ${DG}[y/N]${NC}  "
    read -r CONFIRM
    [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]] && { info "Cancelled."; sleep 1; return; }

    printf "\n"
    step "Stopping Wings service"
    systemctl disable --now wings 2>/dev/null || true
    ok "Wings stopped"

    step "Removing Wings files"
    rm -f /etc/systemd/system/wings.service
    rm -rf /etc/pterodactyl /var/lib/pterodactyl /usr/local/bin/wings
    systemctl daemon-reload
    ok "Wings files removed"

    step "Pruning Docker"
    docker system prune -a -f 2>/dev/null || warn "Docker not found or prune failed."
    ok "Docker cleaned"

    printf "\n  ${LG}╰─▸${NC} Delete database too? ${DG}[y/N]${NC}  "
    read -r DEL_DB
    if [[ "$DEL_DB" == "y" || "$DEL_DB" == "Y" ]]; then
        printf "  ${DG}DB name:${NC}  "; read -r DBN
        printf "  ${DG}DB user:${NC}  "; read -r DBU
        mysql -e "DROP DATABASE IF EXISTS \`${DBN}\`; DROP USER IF EXISTS '${DBU}'@'127.0.0.1';" 2>/dev/null \
            && ok "Database '${DBN}' and user '${DBU}' removed." \
            || err "MySQL command failed — check credentials."
    fi

    printf "\n"
    divider
    ok "Uninstallation complete."
    divider
    sleep 2
}

# ===========================================================
# MAIN LOOP
# ===========================================================
detect_system

while true; do
    header
    show_menu
    read -r opt

    case $opt in
        1) ssl_setup ;;
        2) launching "Wings Installer"
           bash <(curl -fsSL https://raw.githubusercontent.com/nobita329/Nobita-Cloud/refs/heads/main/wings/install.sh) ;;
        3) launching "Wings Manager"
           bash <(curl -fsSL https://raw.githubusercontent.com/nobita329/Nobita-Cloud/refs/heads/main/wings/mang.sh) ;;
        4) launching "Database Manager"
           bash <(curl -fsSL https://raw.githubusercontent.com/nobita329/ptero/refs/heads/main/ptero/wings/db.sh) ;;
        5) uninstall_menu ;;
        0) printf "\n  ${DG}Goodbye.${NC}\n\n"; exit 0 ;;
        *) warn "Invalid option — choose 0–5."; sleep 0.8 ;;
    esac
done
