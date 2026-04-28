#!/bin/bash
# ===========================================================
# SERVER PANEL MANAGER — v15.0
# ===========================================================

# ── Colors ─────────────────────────────────────────────────
BOLD='\033[1m'
CYN='\033[1;38;5;51m'
PUR='\033[1;38;5;141m'
GRN='\033[1;38;5;82m'
RED='\033[1;38;5;196m'
GLD='\033[38;5;220m'
W='\033[1;38;5;255m'
DG='\033[0;38;5;244m'
LG='\033[0;38;5;240m'
NC='\033[0m'

WIDTH=62

# ── Helpers ────────────────────────────────────────────────
box_top()   { printf "\n  ${PUR}╔%*s╗${NC}\n"   "$((WIDTH-2))" "" | tr ' ' '═'; }
box_bot()   { printf   "  ${PUR}╚%*s╝${NC}\n"   "$((WIDTH-2))" "" | tr ' ' '═'; }
box_mid()   { printf   "  ${PUR}╠%*s╣${NC}\n"   "$((WIDTH-2))" "" | tr ' ' '═'; }
box_side()  { printf   "  ${PUR}╟%*s╢${NC}\n"   "$((WIDTH-2))" "" | tr ' ' '─'; }
box_blank() { printf   "  ${PUR}║${NC}%*s${PUR}║${NC}\n" "$((WIDTH-2))" ""; }

# A single row inside the box — left-padded, right-padded
box_row() {
    # box_row "pre-colored string" visible_length
    local str="$1" vlen="${2:-0}"
    local pad=$(( WIDTH - 2 - vlen - 2 ))
    printf "  ${PUR}║${NC}  %b%*s${PUR}║${NC}\n" "$str" "$pad" ""
}

# Two-column grid row inside the box
# grid_row KEY1 LABEL1 STATUS1 KEY2 LABEL2 STATUS2
grid_row() {
    local k1="$1" l1="$2" s1="$3"
    local k2="$4" l2="$5" s2="$6"
    local col=28   # column width each side

    # key+label visible length: [N] = 3 + 2 spaces + label
    printf "  ${PUR}║${NC}  ${PUR}[${W}%s${PUR}]${NC}  %-16s${DG}%-6s${NC}" "$k1" "$l1" "$s1"
    if [ -n "$k2" ]; then
        printf "  ${PUR}[${W}%s${PUR}]${NC}  %-14s${DG}%-4s${NC}" "$k2" "$l2" "$s2"
    else
        printf "%*s" "22" ""
    fi
    printf "  ${PUR}║${NC}\n"
}

info()  { printf "  ${CYN}➜${NC}  ${DG}%s${NC}\n"  "$1"; }
ok()    { printf "  ${GRN}✔${NC}  ${W}%s${NC}\n"   "$1"; }
err()   { printf "  ${RED}✘${NC}  ${RED}%s${NC}\n" "$1"; }
warn()  { printf "  ${GLD}!${NC}  ${GLD}%s${NC}\n" "$1"; }

launching() {
    printf "\n  ${CYN}▶${NC}  ${W}Launching${NC} ${DG}%s${NC}…\n\n" "$1"
}

not_configured() {
    warn "Script not yet configured for this module."
    sleep 1.2
}

pause() {
    printf "\n  ${DG}Press any key to return to menu…${NC}"
    read -n1 -s -r
}

# ── Metrics ────────────────────────────────────────────────
get_metrics() {
    UPT=$(uptime -p 2>/dev/null | sed 's/up //' || echo "unknown")
    LOAD=$(uptime 2>/dev/null | awk -F'load average:' '{print $2}' | cut -d, -f1 | xargs || echo "?")
    MEM=$(free 2>/dev/null | awk '/Mem/{printf "%.0f%%", $3*100/$2}' || echo "?")
}

# ── Header ─────────────────────────────────────────────────
show_header() {
    get_metrics
    clear

    box_top
    box_blank
    box_row "$(printf "${PUR}${BOLD}  SERVER PANEL MANAGER${NC}  ${DG}v15.0${NC}  ${LG}$(date +"%H:%M %Z")${NC}")" 40
    box_blank
    box_mid
    printf "  ${PUR}║${NC}  ${DG}Uptime${NC}  ${W}%-20s${NC}  ${DG}Load${NC}  ${W}%-8s${NC}  ${DG}RAM${NC}  ${W}%s${NC}%*s${PUR}║${NC}\n" \
        "$UPT" "$LOAD" "$MEM" "$(( WIDTH - 2 - 20 - 10 - 10 - ${#MEM} - 14 ))" ""
    box_blank
    box_bot
}

# ── Menu ───────────────────────────────────────────────────
panel_menu() {
    while true; do
        show_header

        printf "  ${GLD}${BOLD}  AVAILABLE DEPLOYMENTS${NC}\n\n"

        # ── Grid ──
        printf "  ${PUR}╔%*s╗${NC}\n" "$((WIDTH-2))" "" | tr ' ' '═'
        printf "  ${PUR}║${NC}%*s${PUR}║${NC}\n" "$((WIDTH-2))" ""

        grid_row  "1"  "Pterodactyl"  "●"   "7"  "Convoy"       "●"
        grid_row  "2"  "Jexactyl"     "…"   "8"  "FeatherPanel" "…"
        grid_row  "3"  "JexPanel"     "…"   "9"  "Mythicaldash" "●"
        grid_row  "4"  "Reviactyl"    "…"   "10" "Mythical v3"  "…"
        grid_row  "5"  "CtrlPanel"    "…"   "11" "VPS Panel"    "…"
        grid_row  "6"  "Paymenter"    "●"   ""   ""             ""

        printf "  ${PUR}║${NC}%*s${PUR}║${NC}\n" "$((WIDTH-2))" ""
        printf "  ${PUR}╟%*s╢${NC}\n" "$((WIDTH-2))" "" | tr ' ' '─'
        printf "  ${PUR}║${NC}  ${RED}[0]${NC}  %-20s%*s${PUR}║${NC}\n" "Exit" "$((WIDTH-26))" ""
        printf "  ${PUR}║${NC}%*s${PUR}║${NC}\n" "$((WIDTH-2))" ""
        printf "  ${PUR}╚%*s╝${NC}\n" "$((WIDTH-2))" "" | tr ' ' '═'

        printf "\n  ${DG}● configured  … pending${NC}\n"
        printf "\n  ${PUR}λ${NC}  ${W}Select module${NC} ${DG}[0–11]:${NC}  "
        read -r p

        case $p in
            1)  launching "Pterodactyl"
                bash <(curl -s https://raw.githubusercontent.com/nobita329/Nobita-Cloud/refs/heads/main/panel/pterodactyl/run.sh)
                pause ;;
            2)  launching "Jexactyl";    not_configured ;;
            3)  launching "JexPanel";    not_configured ;;
            4)  launching "Reviactyl";   not_configured ;;
            5)  launching "CtrlPanel";   not_configured ;;
            6)  launching "Paymenter"
                bash <(curl -s https://raw.githubusercontent.com/nobita329/Nobita-Cloud/refs/heads/main/panel/paymenter/run.sh)
                pause ;;
            7)  launching "Convoy"
                bash <(curl -s https://raw.githubusercontent.com/nobita329/hub/refs/heads/main/Codinghub/panel/convoy/run.sh)
                pause ;;
            8)  launching "FeatherPanel"; not_configured ;;
            9)  launching "Mythicaldash"
                bash <(curl -s https://raw.githubusercontent.com/nobita329/Nobita-Cloud/refs/heads/main/panel/mythical/run.sh)
                pause ;;
            10) launching "Mythical v3";  not_configured ;;
            11) launching "VPS Panel";    not_configured ;;
            0)
                printf "\n  ${RED}●${NC}  ${DG}Uplink closed. Goodbye.${NC}\n\n"
                exit 0 ;;
            *)
                warn "Invalid selection — choose 0–11."
                sleep 0.8 ;;
        esac
    done
}

panel_menu
