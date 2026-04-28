#!/bin/bash
# ===========================================================
# CODING HUB — OBSIDIAN NEXT GEN (v12.0 — Nobita Edition)
# ===========================================================

# ── Color palette ──────────────────────────────────────────
BOLD='\033[1m'
BLU='\033[1;38;5;33m'
CYN='\033[1;38;5;51m'
PUR='\033[1;38;5;141m'
GRN='\033[1;38;5;82m'
RED='\033[1;38;5;196m'
GLD='\033[38;5;220m'
W='\033[1;38;5;255m'
DG='\033[0;38;5;244m'
LG='\033[0;38;5;240m'
NC='\033[0m'

WIDTH=76

# ── Helpers ────────────────────────────────────────────────
pill() {
    # pill COLOR LABEL VALUE
    local c="$1" lbl="$2" val="$3"
    printf "${LG}[${NC} ${c}${lbl}${NC} ${W}${val}${NC} ${LG}]${NC}"
}

metric_bar() {
    local val="$1" width=16
    local filled=$(( val * width / 100 ))
    local empty=$(( width - filled ))
    printf "${GRN}"
    printf '%0.s█' $(seq 1 $filled 2>/dev/null) 2>/dev/null || printf '%*s' "$filled" "" | tr ' ' '█'
    printf "${LG}"
    printf '%0.s░' $(seq 1 $empty 2>/dev/null) 2>/dev/null || printf '%*s' "$empty" "" | tr ' ' '░'
    printf "${NC}"
}

menu_item() {
    local key="$1" label="$2" pad="$3"
    printf "  ${LG}│${NC}  ${BLU}[${W}${key}${BLU}]${NC}  %-${pad}s" "$label"
}

section_hdr() {
    local icon="$1" title="$2"
    printf "\n  ${CYN}${icon}  ${BOLD}${W}%s${NC}\n" "$title"
    printf "  ${LG}┌%*s┐${NC}\n" "$((WIDTH - 4))" "" | tr ' ' '─'
}

section_end() {
    printf "  ${LG}└%*s┘${NC}\n" "$((WIDTH - 4))" "" | tr ' ' '─'
}

# ── Metrics ────────────────────────────────────────────────
get_metrics() {
    CPU=$(top -bn1 | grep "Cpu(s)" | awk '{printf "%.0f", $2+$4}' 2>/dev/null || echo "??")
    RAM=$(free | grep Mem | awk '{printf "%.0f", $3*100/$2}' 2>/dev/null || echo "??")
    UPT=$(uptime -p | sed 's/up //' 2>/dev/null || echo "unknown")
    DISK=$(df -h / | awk 'NR==2 {print $5}' 2>/dev/null || echo "??")
    HOST_=$(hostname 2>/dev/null || echo "localhost")
    NET="ONLINE"
    ping -c1 -W1 8.8.8.8 &>/dev/null || NET="OFFLINE"
}

# ── Main UI ────────────────────────────────────────────────
render_ui() {
    clear
    get_metrics

    # ── Top bar ──
    printf "\n"
    printf "  "
    pill "$BLU"  "HOST"   "$HOST_"
    printf "  "
    pill "$PUR"  "UPTIME" "$UPT"
    printf "  "
    pill "$GLD"  "DISK"   "$DISK"
    printf "  "
    [[ "$NET" == "ONLINE" ]] && pill "$GRN" "NET" "● ONLINE" || pill "$RED" "NET" "✘ OFFLINE"
    printf "\n\n"

    # ── Banner ──
    printf "  ${CYN}${BOLD}  ██████╗ ██████╗ ██████╗ ██╗███╗   ██╗ ██████╗${NC}\n"
    printf "  ${CYN}${BOLD} ██╔════╝██╔═══██╗██╔══██╗██║████╗  ██║██╔════╝${NC}\n"
    printf "  ${PUR}${BOLD} ██║     ██║   ██║██║  ██║██║██╔██╗ ██║██║  ███╗${NC}\n"
    printf "  ${PUR}${BOLD} ██║     ██║   ██║██║  ██║██║██║╚██╗██║██║   ██║${NC}\n"
    printf "  ${GLD}${BOLD} ╚██████╗╚██████╔╝██████╔╝██║██║ ╚████║╚██████╔╝${NC}\n"
    printf "  ${GLD}${BOLD}  ╚═════╝ ╚═════╝ ╚═════╝ ╚═╝╚═╝  ╚═══╝ ╚═════╝${NC}\n"
    printf "  ${DG}               HUB  •  OBSIDIAN NEXT GEN  •  NOBITA EDITION${NC}\n"

    printf "\n  ${LG}%*s${NC}\n" "$WIDTH" "" | tr ' ' '─'

    # ── System health ──
    section_hdr "◉" "SYSTEM HEALTH"
    printf "  ${LG}│${NC}  ${DG}CPU${NC}  $(metric_bar ${CPU//??/0})  ${CYN}${CPU}%%${NC}       ${DG}RAM${NC}  $(metric_bar ${RAM//??/0})  ${PUR}${RAM}%%${NC}\n"
    section_end

    # ── Deployment menu ──
    section_hdr "▸" "DEPLOYMENT & SERVICES"
    printf "  ${LG}│${NC}\n"
    printf "$(menu_item 1 'VPS Deploy'    22)$(menu_item 5 'Themes'     0)\n"
    printf "$(menu_item 2 'Panel'         22)$(menu_item 6 'System'     0)\n"
    printf "$(menu_item 3 'Wings'         22)$(menu_item 7 'Container'  0)\n"
    printf "$(menu_item 8 "${GRN}New Module${NC}"  22)\n"
    printf "  ${LG}│${NC}\n"
    section_end

    # ── Tools menu ──
    section_hdr "▸" "MAINTENANCE & TOOLS"
    printf "  ${LG}│${NC}\n"
    printf "$(menu_item 4 'Toolbox'    22)$(menu_item 9 'Extras'     0)\n"
    printf "  ${LG}│${NC}\n"
    printf "  ${LG}│${NC}  ${RED}[0]${NC}  ${W}Shutdown / Exit${NC}\n"
    printf "  ${LG}│${NC}\n"
    section_end

    printf "\n  ${LG}%*s${NC}\n\n" "$WIDTH" "" | tr ' ' '─'
    printf "  ${CYN}➜${NC}  ${W}Select option${NC} ${DG}[0–9]:${NC}  "
}

# ── Feedback helpers ───────────────────────────────────────
launching() {
    printf "\n  ${CYN}▶${NC}  ${W}Launching${NC} ${DG}%s${NC}…\n\n" "$1"
}

# ── Main loop ──────────────────────────────────────────────
while true; do
    render_ui
    read -r opt

    case $opt in
        1) launching "VPS Deploy"
           bash <(curl -s https://raw.githubusercontent.com/nobita329/hub/refs/heads/main/Codinghub/VM/menu.sh) ;;
        2) launching "Panel"
           bash <(curl -s https://raw.githubusercontent.com/nobita329/Nobita-Cloud/refs/heads/main/panel/1.sh) ;;
        3) launching "Wings"
           bash <(curl -s https://raw.githubusercontent.com/nobita329/Nobita-Cloud/refs/heads/main/wings/run.sh) ;;
        4) launching "Toolbox"
           bash <(curl -s https://raw.githubusercontent.com/nobita329/ptero/refs/heads/main/ptero/tools/run.sh) ;;
        5) launching "Themes"
           bash <(curl -s https://raw.githubusercontent.com/nobita329/Nobita-Cloud/refs/heads/main/thame/run.sh) ;;
        6) launching "System"
           bash <(curl -s https://raw.githubusercontent.com/nobita329/The-Coding-Hub/refs/heads/main/srv/menu/System1.sh) ;;
        7) launching "Container"
           bash <(curl -s https://raw.githubusercontent.com/nobita329/ptero/refs/heads/main/ptero/no-kvm/run.sh) ;;
        8) launching "New Module"
           printf "  ${DG}(Add your script or command here.)${NC}\n"
           sleep 1.8 ;;
        9) launching "Extra Tools"
           bash <(curl -s https://raw.githubusercontent.com/nobita329/Nobita-Cloud/refs/heads/main/Extras/run.sh)
           sleep 1.5 ;;
        0|exit|quit)
           printf "\n  ${RED}●${NC}  ${DG}Session ended. Goodbye, Nobita.${NC}\n\n"
           exit 0 ;;
        *)
           printf "\n  ${RED}✘${NC}  ${DG}Invalid option — please choose 0–9.${NC}\n"
           sleep 0.8 ;;
    esac
done
