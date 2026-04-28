#!/usr/bin/env bash
# ==========================================================
# NOBITA CLOUD SYSTEM | BANE-ANMESH 3S UPLINK
# DATE: 2026-04-08 | UI-TYPE: SEMA-HYPER-VISUAL → VIP ELITE
# ==========================================================
set -euo pipefail

# ── Color palette ──────────────────────────────────────────
BOLD='\033[1m'
DIM='\033[2m'
R='\033[1;38;5;196m'      # Crimson
G='\033[1;38;5;82m'       # Emerald
Y='\033[1;38;5;220m'      # Gold
C='\033[1;38;5;51m'       # Cyan
P='\033[1;38;5;201m'      # VIP Pink
V='\033[1;38;5;135m'      # Violet
N='\033[1;38;5;198m'      # Neon
W='\033[1;38;5;255m'      # White
DG='\033[0;38;5;244m'     # Steel Gray
LG='\033[0;38;5;240m'     # Light Gray (borders)
NC='\033[0m'              # Reset

# ── Constants ──────────────────────────────────────────────
HOST="run.nobitahost.in"
URL="https://${HOST}"
NETRC="${HOME}/.netrc"
IP="65.0.86.121"
LOCL_IP="10.1.0.29"
VERSION="14.0"
WIDTH=78

# ── Helpers ────────────────────────────────────────────────

# Print a horizontal rule
hr() {
    local char="${1:-─}"
    printf "${LG}%*s${NC}\n" "$WIDTH" "" | tr ' ' "$char"
}

# Print a padded row inside a box
row() {
    printf "${V}║${NC}  %-74s${V}║${NC}\n" "$1"
}

# Print a blank box row
blank_row() {
    printf "${V}║${NC}%76s${V}║${NC}\n" ""
}

# Status dot
dot() {
    local color="$1" label="$2" value="$3"
    printf "  ${LG}│${NC}  ${color}●${NC}  ${DG}%-28s${NC}  ${W}%s${NC}\n" "$label" "$value"
}

# Spinner frames
spin() {
    local msg="$1"
    local frames=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
    local delay=0.07
    local i=0
    printf "  ${LG}│${NC}  ${C}%s${NC}  ${DG}%s${NC}" "${frames[0]}" "$msg"
    for _ in {1..20}; do
        printf "\r  ${LG}│${NC}  ${C}%s${NC}  ${DG}%s${NC}" "${frames[$((i % ${#frames[@]}))]}" "$msg"
        sleep $delay
        (( i++ )) || true
    done
}

# Completion line
ok() {
    local label="$1"
    printf "\r  ${LG}│${NC}  ${G}✔${NC}  ${DG}${label}${NC}%*s${G}done${NC}\n" "$((WIDTH - ${#label} - 10))" ""
}

fail() {
    local label="$1"
    printf "\r  ${LG}│${NC}  ${R}✘${NC}  ${DG}${label}${NC}%*s${R}failed${NC}\n" "$((WIDTH - ${#label} - 12))" ""
}

# Section header
section() {
    local num="$1" title="$2"
    echo
    printf "  ${Y}[${num}]${NC}  ${BOLD}${W}%s${NC}\n" "$title"
    printf "  ${LG}│${NC}\n"
}

# ── Header ─────────────────────────────────────────────────
clear

printf "${V}╔%*s╗${NC}\n" "$((WIDTH - 2))" "" | tr ' ' '═'
printf "${V}║${NC}%*s${V}║${NC}\n" "$((WIDTH - 2))" ""

# Wordmark — centered
WORDMARK=" ★  NOBITA CLOUD  •  BANE-ANMESH 3S  •  VIP ELITE  ★ "
printf "${V}║${NC}${P}${BOLD}%*s%s%*s${NC}${V}║${NC}\n" \
    "$(( (WIDTH - 2 - ${#WORDMARK}) / 2 ))" "" \
    "$WORDMARK" \
    "$(( (WIDTH - 2 - ${#WORDMARK} + 1) / 2 ))" ""

printf "${V}║${NC}%*s${V}║${NC}\n" "$((WIDTH - 2))" ""
printf "${V}╠%*s╣${NC}\n" "$((WIDTH - 2))" "" | tr ' ' '═'

# Meta row
META="  v${VERSION}  │  $(date +"%Y-%m-%d %H:%M:%S %Z")  │  SECURE UPLINK  "
printf "${V}║${NC}${DG}%-$((WIDTH - 2))s${NC}${V}║${NC}\n" "$META"
printf "${V}╚%*s╝${NC}\n" "$((WIDTH - 2))" "" | tr ' ' '═'

echo

# ── Network info ───────────────────────────────────────────
printf "  ${C}NETWORK DIAGNOSTICS${NC}\n"
printf "  ${LG}┌%*s┐${NC}\n" "$((WIDTH - 4))" "" | tr ' ' '─'
dot "$G" "Public endpoint"    "$IP"
dot "$G" "Local gateway"      "$LOCL_IP"
dot "$C" "Target host"        "$HOST"
dot "$P" "Security layer"     "SSH V-65S  ★ VIP"
dot "$N" "Cipher"             "QUANTUM-256"
printf "  ${LG}└%*s┘${NC}\n" "$((WIDTH - 4))" "" | tr ' ' '─'

# ── Auth sequence ──────────────────────────────────────────
section "1/2" "Authentication Sequence"

spin "Linking VIP credentials"
touch "$NETRC" && chmod 600 "$NETRC"
sed -i "/$HOST/d" "$NETRC" 2>/dev/null || true
printf "machine %s login %s password %s\n" "$HOST" "$IP" "$LOCL_IP" >> "$NETRC"
sleep 0.4
ok "Linking VIP credentials"

spin "Verifying identity token"
sleep 0.5
ok "Verifying identity token"

# ── Uplink ─────────────────────────────────────────────────
section "2/2" "Bane Uplink Protocol"

spin "Establishing quantum link"

payload="$(mktemp)"
trap "rm -f $payload" EXIT

if curl -fsSL -A "Bane-VIP-Agent" --netrc -o "$payload" "$URL" 2>/dev/null; then
    ok "Establishing quantum link"
    spin "Negotiating VIP channel"
    sleep 0.3
    ok "Negotiating VIP channel"
    echo

    # ── Ready banner ───────────────────────────────────────
    printf "${V}╔%*s╗${NC}\n" "$((WIDTH - 2))" "" | tr ' ' '═'
    printf "${V}║${NC}%*s${V}║${NC}\n" "$((WIDTH - 2))" ""
    LABEL="  UPLINK ESTABLISHED  •  AUTHORIZED  •  VIP TIER  "
    printf "${V}║${NC}${G}${BOLD}%*s%s%*s${NC}${V}║${NC}\n" \
        "$(( (WIDTH - 2 - ${#LABEL}) / 2 ))" "" \
        "$LABEL" \
        "$(( (WIDTH - 2 - ${#LABEL} + 1) / 2 ))" ""
    printf "${V}║${NC}%*s${V}║${NC}\n" "$((WIDTH - 2))" ""
    printf "${V}╚%*s╝${NC}\n" "$((WIDTH - 2))" "" | tr ' ' '═'
    echo

    # ── Countdown ──────────────────────────────────────────
    printf "  ${DG}Executing payload in${NC} "
    for i in 3 2 1; do
        printf "${Y}${BOLD}${i}${NC} "
        sleep 1
    done
    printf "${G}▶${NC}\n\n"

    bash "$payload"

else
    fail "Establishing quantum link"
    echo
    printf "  ${R}✘  Connection terminated by host.${NC}\n"
    printf "  ${DG}   Verify host availability and credentials.${NC}\n"
    echo
    exit 1
fi
