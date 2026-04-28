#!/bin/bash
# ===========================================================
# CLOUDFLARE COMMANDER — v3.0
# ===========================================================

# ── Colors ─────────────────────────────────────────────────
BOLD='\033[1m'
CYN='\033[1;38;5;51m'
PUR='\033[1;38;5;141m'
GRN='\033[1;38;5;82m'
YLW='\033[1;38;5;220m'
RED='\033[1;38;5;196m'
ORG='\033[1;38;5;208m'   # Cloudflare orange
W='\033[1;38;5;255m'
DG='\033[0;38;5;244m'
LG='\033[0;38;5;240m'
NC='\033[0m'

WIDTH=60

# ── Helpers ────────────────────────────────────────────────
box_top()   { printf "\n  ${PUR}╔%*s╗${NC}\n"   "$((WIDTH-2))" "" | tr ' ' '═'; }
box_bot()   { printf   "  ${PUR}╚%*s╝${NC}\n"   "$((WIDTH-2))" "" | tr ' ' '═'; }
box_mid()   { printf   "  ${PUR}╠%*s╣${NC}\n"   "$((WIDTH-2))" "" | tr ' ' '═'; }
box_side()  { printf   "  ${PUR}╟%*s╢${NC}\n"   "$((WIDTH-2))" "" | tr ' ' '─'; }
box_blank() { printf   "  ${PUR}║${NC}%*s${PUR}║${NC}\n" "$((WIDTH-2))" ""; }

step()    { printf "\n  ${YLW}▸${NC}  ${DG}%s${NC}\n"     "$1"; }
ok()      { printf   "  ${GRN}✔${NC}  ${W}%s${NC}\n"      "$1"; }
err()     { printf   "  ${RED}✘${NC}  ${RED}%s${NC}\n"    "$1"; }
info()    { printf   "  ${CYN}➜${NC}  ${DG}%s${NC}\n"     "$1"; }
warn()    { printf   "  ${YLW}!${NC}  ${YLW}%s${NC}\n"    "$1"; }
divider() { printf   "  ${LG}%*s${NC}\n" "$WIDTH" "" | tr ' ' '─'; }

pause() {
    printf "\n  ${DG}Press Enter to return to menu…${NC}"
    read -r
}

progress_bar() {
    local total=24
    printf "  ${DG}["
    for _ in $(seq 1 $total); do
        printf "${ORG}█${NC}"
        sleep 0.07
    done
    printf "${DG}]${NC}\n"
}

# ── Service status ─────────────────────────────────────────
cf_status() {
    ARCH=$(dpkg --print-architecture 2>/dev/null || uname -m)

    if ! command -v cloudflared &>/dev/null; then
        CF_STATUS="${RED}NOT INSTALLED${NC}"
        CF_PID="${DG}—${NC}"
        CF_SINCE="${DG}—${NC}"
        return
    fi

    if systemctl is-active --quiet cloudflared 2>/dev/null; then
        CF_STATUS="${GRN}${BOLD}ACTIVE ● RUNNING${NC}"
        CF_PID="${W}$(pgrep -x cloudflared | head -1)${NC}"
        CF_SINCE="${CYN}$(systemctl show -p ActiveEnterTimestamp cloudflared \
            | cut -d'=' -f2 | cut -d' ' -f2-3)${NC}"
    else
        CF_STATUS="${RED}INACTIVE ● STOPPED${NC}"
        CF_PID="${DG}—${NC}"
        CF_SINCE="${DG}—${NC}"
    fi
}

# ── Header ─────────────────────────────────────────────────
show_header() {
    cf_status
    clear

    box_top
    box_blank
    printf "  ${PUR}║${NC}  ${ORG}${BOLD}☁  CLOUDFLARE TUNNEL MANAGER${NC}  ${DG}v3.0${NC}%*s${PUR}║${NC}\n" \
        "$((WIDTH - 34))" ""
    box_blank
    box_mid
    printf "  ${PUR}║${NC}  ${DG}Arch    ${NC}  ${W}%-$((WIDTH-14))s${PUR}║${NC}\n" "$ARCH"
    printf "  ${PUR}║${NC}  ${DG}Status  ${NC}  %-$((WIDTH-5))b${PUR}║${NC}\n"      "$CF_STATUS"
    printf "  ${PUR}║${NC}  ${DG}PID     ${NC}  %-$((WIDTH-5))b${PUR}║${NC}\n"      "$CF_PID"
    printf "  ${PUR}║${NC}  ${DG}Since   ${NC}  %-$((WIDTH-5))b${PUR}║${NC}\n"      "$CF_SINCE"
    box_blank
    box_bot
}

# ===========================================================
# INSTALL
# ===========================================================
install_cf() {
    show_header

    printf "  ${W}${BOLD}INSTALLATION SEQUENCE${NC}\n"
    divider

    # 1. Repository
    step "Configuring Cloudflare repository"
    sudo mkdir -p --mode=0755 /usr/share/keyrings
    curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg \
        | sudo tee /usr/share/keyrings/cloudflare-main.gpg >/dev/null
    echo 'deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared any main' \
        | sudo tee /etc/apt/sources.list.d/cloudflared.list >/dev/null
    ok "Repository added"

    # 2. Install binary
    step "Updating APT & installing binary"
    sudo apt-get update -qq >/dev/null
    sudo apt-get install -y cloudflared -qq >/dev/null 2>&1

    if command -v cloudflared &>/dev/null; then
        ok "Cloudflared binary installed"
    else
        err "Binary installation failed"
        pause; return
    fi

    # 3. Clean old service
    if systemctl list-units --type=service 2>/dev/null | grep -q cloudflared; then
        step "Removing conflicting service"
        sudo cloudflared service uninstall >/dev/null 2>&1
        ok "Old service removed"
    fi

    # 4. Token input
    printf "\n"
    printf "  ${PUR}╔%*s╗${NC}\n" "$((WIDTH-2))" "" | tr ' ' '═'
    printf "  ${PUR}║${NC}  ${YLW}${BOLD}ACTION REQUIRED${NC}%*s${PUR}║${NC}\n" "$((WIDTH-18))" ""
    printf "  ${PUR}╟%*s╢${NC}\n" "$((WIDTH-2))" "" | tr ' ' '─'
    printf "  ${PUR}║${NC}  ${DG}Paste your tunnel token below.${NC}%*s${PUR}║${NC}\n" "$((WIDTH-34))" ""
    printf "  ${PUR}║${NC}  ${DG}You may paste the full 'sudo cloudflared…' cmd.${NC}%*s${PUR}║${NC}\n" "$((WIDTH-51))" ""
    printf "  ${PUR}╚%*s╝${NC}\n\n" "$((WIDTH-2))" "" | tr ' ' '═'
    printf "  ${PUR}➤${NC}  ${W}Token:${NC}  "
    read -r USER_TOKEN

    CLEAN_TOKEN=$(echo "$USER_TOKEN" \
        | sed 's/sudo cloudflared service install //g' \
        | sed 's/cloudflared service install //g' \
        | xargs)

    if [[ -z "$CLEAN_TOKEN" ]]; then
        err "Token cannot be empty."
        pause; return
    fi

    # 5. Register & start
    step "Registering tunnel service"
    sudo cloudflared service uninstall >/dev/null 2>&1
    sudo cloudflared service install "$CLEAN_TOKEN"

    printf "\n  ${DG}Waiting for service to initialize…${NC}\n  "
    progress_bar
    printf "\n"

    if systemctl is-active --quiet cloudflared; then
        divider
        ok  "Tunnel is online and stable."
        divider
    else
        divider
        err "Service failed to start."
        info "Debug: sudo journalctl -u cloudflared -f"
        divider
    fi

    pause
}

# ===========================================================
# UNINSTALL
# ===========================================================
uninstall_cf() {
    show_header

    warn "This will remove the tunnel service and the binary."
    printf "\n  ${LG}╰─▸${NC} Proceed? ${DG}[y/N]${NC}  "
    read -r confirm

    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        info "Operation cancelled."
        sleep 1; return
    fi

    printf "\n"
    step "Stopping and uninstalling service"
    sudo cloudflared service uninstall >/dev/null 2>&1
    ok "Service removed"

    step "Removing binary"
    sudo apt-get remove -y cloudflared -qq >/dev/null 2>&1
    ok "Binary removed"

    step "Cleaning repository config"
    sudo rm -f /etc/apt/sources.list.d/cloudflared.list
    sudo rm -f /usr/share/keyrings/cloudflare-main.gpg
    ok "Config cleaned"

    printf "\n"
    divider
    ok "Cloudflared completely removed."
    divider
    sleep 2
}

# ===========================================================
# MAIN MENU
# ===========================================================
while true; do
    show_header

    printf "  ${PUR}╔%*s╗${NC}\n" "$((WIDTH-2))" "" | tr ' ' '═'
    printf "  ${PUR}║${NC}%*s${PUR}║${NC}\n" "$((WIDTH-2))" ""
    printf "  ${PUR}║${NC}  ${GRN}[1]${NC}  %-20s${DG}Auto-fix install${NC}%*s${PUR}║${NC}\n" \
        "Install"   "$((WIDTH-42))" ""
    printf "  ${PUR}║${NC}  ${RED}[2]${NC}  %-20s${DG}Remove all${NC}%*s${PUR}║${NC}\n"       \
        "Uninstall" "$((WIDTH-36))" ""
    printf "  ${PUR}║${NC}%*s${PUR}║${NC}\n" "$((WIDTH-2))" ""
    printf "  ${PUR}╟%*s╢${NC}\n" "$((WIDTH-2))" "" | tr ' ' '─'
    printf "  ${PUR}║${NC}  ${W}[0]${NC}  %-20s%*s${PUR}║${NC}\n" \
        "Exit" "$((WIDTH-26))" ""
    printf "  ${PUR}║${NC}%*s${PUR}║${NC}\n" "$((WIDTH-2))" ""
    printf "  ${PUR}╚%*s╝${NC}\n\n" "$((WIDTH-2))" "" | tr ' ' '═'

    printf "  ${ORG}root@cloudflared${NC}${DG}:~#${NC}  "
    read -r choice

    case $choice in
        1) install_cf ;;
        2) uninstall_cf ;;
        0) clear; exit 0 ;;
        *) warn "Invalid option — choose 0, 1, or 2."; sleep 0.8 ;;
    esac
done
