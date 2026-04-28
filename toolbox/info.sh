#!/bin/bash
# ===========================================================
# OMNI-ADMIN v201 — TITAN EDITION
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

# ── Config ─────────────────────────────────────────────────
LOG_FILE="$HOME/omni_titan.log"
BACKUP_DIR="$HOME/omni_backups"
mkdir -p "$BACKUP_DIR"

WIDTH=66

# ── Helpers ────────────────────────────────────────────────
box_top()   { printf "\n  ${CYN}╔%*s╗${NC}\n"   "$((WIDTH-2))" "" | tr ' ' '═'; }
box_bot()   { printf   "  ${CYN}╚%*s╝${NC}\n"   "$((WIDTH-2))" "" | tr ' ' '═'; }
box_mid()   { printf   "  ${CYN}╠%*s╣${NC}\n"   "$((WIDTH-2))" "" | tr ' ' '═'; }
box_side()  { printf   "  ${CYN}╟%*s╢${NC}\n"   "$((WIDTH-2))" "" | tr ' ' '─'; }
box_blank() { printf   "  ${CYN}║${NC}%*s${CYN}║${NC}\n" "$((WIDTH-2))" ""; }

ok()      { printf "  ${GRN}✔${NC}  ${W}%s${NC}\n"   "$1"; }
err()     { printf "  ${RED}✘${NC}  ${RED}%s${NC}\n" "$1"; }
info()    { printf "  ${CYN}➜${NC}  ${DG}%s${NC}\n"  "$1"; }
warn()    { printf "  ${YLW}!${NC}  ${YLW}%s${NC}\n" "$1"; }
divider() { printf "  ${LG}%*s${NC}\n" "$WIDTH" "" | tr ' ' '─'; }

pause() {
    printf "\n  ${DG}Press Enter to return…${NC}"
    read -r
}

# Two-column menu row: NUM1 LABEL1 NUM2 LABEL2
menu_row() {
    printf "  ${CYN}║${NC}  ${DG}%3s${NC}  ${W}%-22s${NC}  ${DG}%3s${NC}  ${W}%-18s${NC}  ${CYN}║${NC}\n" \
        "$1." "$2" "$3." "$4"
}
menu_row_single() {
    printf "  ${CYN}║${NC}  ${DG}%3s${NC}  ${W}%-22s${NC}%*s  ${CYN}║${NC}\n" \
        "$1." "$2" "$((WIDTH-30))" ""
}

# ── Auto-install ────────────────────────────────────────────
auto_install() {
    local PKG="$1"
    if ! command -v "$PKG" &>/dev/null; then
        warn "Missing tool: ${PKG} — installing…"
        if   [ -f /etc/debian_version ];  then sudo apt-get install -y -qq "$PKG" >/dev/null 2>&1
        elif [ -f /etc/redhat-release ];   then sudo yum install -y -q  "$PKG" >/dev/null 2>&1
        elif [ -f /etc/arch-release ];     then sudo pacman -S --noconfirm "$PKG" >/dev/null 2>&1
        fi
    fi
}

# ── Metrics ────────────────────────────────────────────────
get_metrics() {
    CPU=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{printf "%.0f", 100-$1}' 2>/dev/null || echo "?")
    RAM=$(free -m 2>/dev/null | awk '/Mem/{printf "%.0f", $3/$2*100}' || echo "?")
    KERN=$(uname -r 2>/dev/null || echo "unknown")
    WHO="$(whoami)@$(hostname)"
}

# ── Header ─────────────────────────────────────────────────
draw_header() {
    get_metrics
    clear

    box_top
    box_blank
    printf "  ${CYN}║${NC}  ${CYN}${BOLD}OMNI-ADMIN v201${NC}  ${DG}│${NC}  ${YLW}TITAN EDITION${NC}  ${DG}│${NC}  ${MGN}%s${NC}%*s${CYN}║${NC}\n" \
        "$WHO" "$(( WIDTH - 2 - 16 - 3 - 13 - 3 - ${#WHO} - 2 ))" ""
    box_blank
    box_mid
    printf "  ${CYN}║${NC}  ${DG}CPU${NC}  ${GRN}%3s%%${NC}   ${DG}│${NC}   ${DG}RAM${NC}  ${GRN}%3s%%${NC}   ${DG}│${NC}   ${DG}Kernel${NC}  ${BLU}%s${NC}%*s${CYN}║${NC}\n" \
        "$CPU" "$RAM" "$KERN" "$(( WIDTH - 2 - 5 - 7 - 5 - 7 - 8 - ${#KERN} - 2 ))" ""
    box_blank
    box_bot
}

# ── Category header ────────────────────────────────────────
cat_header() {
    local color="$1" title="$2"
    printf "\n  ${color}${BOLD}%s${NC}\n" "$title"
    printf "  ${CYN}╔%*s╗${NC}\n" "$((WIDTH-2))" "" | tr ' ' '═'
    printf "  ${CYN}║${NC}%*s${CYN}║${NC}\n" "$((WIDTH-2))" ""
}
cat_footer() {
    printf "  ${CYN}║${NC}%*s${CYN}║${NC}\n" "$((WIDTH-2))" ""
    printf "  ${CYN}╟%*s╢${NC}\n" "$((WIDTH-2))" "" | tr ' ' '─'
    printf "  ${CYN}║${NC}  ${RED}  0${NC}  ${W}%-22s${NC}%*s${CYN}║${NC}\n" "Back to main menu" "$((WIDTH-30))" ""
    printf "  ${CYN}║${NC}%*s${CYN}║${NC}\n" "$((WIDTH-2))" ""
    printf "  ${CYN}╚%*s╝${NC}\n" "$((WIDTH-2))" "" | tr ' ' '═'
    printf "\n  ${CYN}λ${NC}  ${W}Select tool:${NC}  "
}

# ===========================================================
# CATEGORY 1 — SYSTEM & HARDWARE
# ===========================================================
menu_sys() {
    while true; do
        draw_header
        cat_header "$MGN" "  ◈  SYSTEM & HARDWARE  (Tools 1–20)"
        menu_row  " 1" "All Info (yabs)"       "11" "All Devices"
        menu_row  " 2" "OS Release"            "12" "USB Devices"
        menu_row  " 3" "Kernel Version"        "13" "Block Devices"
        menu_row  " 4" "CPU Architecture"      "14" "Disk Space"
        menu_row  " 5" "CPU Cores/Threads"     "15" "Disk Inodes"
        menu_row  " 6" "RAM Utilization"       "16" "Mount Points"
        menu_row  " 7" "Uptime Detail"         "17" "Hardware List"
        menu_row  " 8" "Load Average"          "18" "BIOS/Firmware"
        menu_row  " 9" "Hostname Info"         "19" "Sensor Temps"
        menu_row  "10" "Last Reboot"           "20" "Battery Status"
        cat_footer

        read -r opt
        case $opt in
            1)  curl -sL yabs.sh | bash ;;
            2)  cat /etc/*release ;;
            3)  uname -a ;;
            4)  lscpu | grep Architecture ;;
            5)  lscpu | grep -E '^Thread|^Core|^Socket' ;;
            6)  free -h ;;
            7)  uptime -p ;;
            8)  uptime ;;
            9)  hostnamectl ;;
            10) last reboot | head -5 ;;
            11) auto_install pciutils; lspci ;;
            12) lsusb ;;
            13) lsblk ;;
            14) df -hT --exclude-type=tmpfs ;;
            15) df -i ;;
            16) mount | column -t ;;
            17) auto_install lshw; sudo lshw -short ;;
            18) [ -d /sys/firmware/efi ] && echo "UEFI Boot" || echo "Legacy BIOS" ;;
            19) auto_install lm-sensors; sensors ;;
            20) acpi -bi 2>/dev/null || echo "No battery detected." ;;
            0)  return ;;
            *)  warn "Invalid option."; sleep 0.8; continue ;;
        esac
        pause
    done
}

# ===========================================================
# CATEGORY 2 — NETWORK
# ===========================================================
menu_net() {
    while true; do
        draw_header
        cat_header "$BLU" "  ◈  NETWORK & INTERNET  (Tools 21–40)"
        menu_row  "21" "IP Address (all)"      "31" "Ping Google"
        menu_row  "22" "Public IP"             "32" "Ping Custom"
        menu_row  "23" "DNS Lookup"            "33" "Traceroute"
        menu_row  "24" "Whois Domain"          "34" "MTR Live Trace"
        menu_row  "25" "Netstat Listening"     "35" "Speedtest CLI"
        menu_row  "26" "SS Active Conns"       "36" "Download File"
        menu_row  "27" "Route Table"           "37" "HTTP Headers"
        menu_row  "28" "ARP Table"             "38" "Scan Local Net"
        menu_row  "29" "Interface Stats"       "39" "Bandwidth (nload)"
        menu_row  "30" "Flush DNS Cache"       "40" "Wifi Signal"
        cat_footer

        read -r opt
        case $opt in
            21) ip a ;;
            22) curl -s ifconfig.me; echo ;;
            23) printf "  Domain: "; read -r d; auto_install dnsutils; dig "$d" +short ;;
            24) printf "  Domain: "; read -r d; auto_install whois; whois "$d" | head -20 ;;
            25) netstat -tulpn ;;
            26) ss -tuna ;;
            27) ip route ;;
            28) ip neigh ;;
            29) ip -s link ;;
            30) sudo systemd-resolve --flush-caches && ok "DNS cache flushed." ;;
            31) ping -c 4 google.com ;;
            32) printf "  Host: "; read -r h; ping -c 4 "$h" ;;
            33) printf "  Host: "; read -r h; traceroute "$h" ;;
            34) printf "  Host: "; read -r h; auto_install mtr; mtr "$h" ;;
            35) auto_install speedtest-cli; speedtest-cli --simple ;;
            36) printf "  URL: ";  read -r u; wget "$u" ;;
            37) printf "  URL: ";  read -r u; curl -I "$u" ;;
            38) auto_install nmap; nmap -sn 192.168.1.0/24 ;;
            39) auto_install nload; nload ;;
            40) nmcli dev wifi ;;
            0)  return ;;
            *)  warn "Invalid option."; sleep 0.8; continue ;;
        esac
        pause
    done
}

# ===========================================================
# CATEGORY 3 — SECURITY
# ===========================================================
menu_sec() {
    while true; do
        draw_header
        cat_header "$RED" "  ◈  SECURITY OPS  (Tools 41–60)"
        menu_row  "41" "Firewall Status"       "51" "Check Rootkits"
        menu_row  "42" "Fail2Ban Status"       "52" "Audit SSH Config"
        menu_row  "43" "Last Logins"           "53" "Check Sudo Users"
        menu_row  "44" "Failed Auth Logs"      "54" "Passwd File"
        menu_row  "45" "Current Users"         "55" "Open Ports (Nmap)"
        menu_row  "46" "Password Expiry"       "56" "File Permissions"
        menu_row  "47" "Lock User"             "57" "Lynis Audit"
        menu_row  "48" "Unlock User"           "58" "SELinux Status"
        menu_row  "49" "Kick User"             "59" "AppArmor Status"
        menu_row  "50" "Kill User Procs"       "60" "History Cleaner"
        cat_footer

        read -r opt
        case $opt in
            41) sudo ufw status 2>/dev/null || err "UFW not found." ;;
            42) sudo fail2ban-client status 2>/dev/null || err "Fail2ban not found." ;;
            43) last -n 10 ;;
            44) sudo grep "Failed" /var/log/auth.log 2>/dev/null | tail -10 ;;
            45) w ;;
            46) printf "  User: "; read -r u; sudo chage -l "$u" ;;
            47) printf "  User: "; read -r u; sudo passwd -l "$u" ;;
            48) printf "  User: "; read -r u; sudo passwd -u "$u" ;;
            49) printf "  User: "; read -r u; sudo pkill -u "$u" ;;
            50) printf "  User: "; read -r u; sudo killall -u "$u" ;;
            51) auto_install rkhunter; sudo rkhunter --check --sk ;;
            52) grep "^PermitRoot" /etc/ssh/sshd_config ;;
            53) grep sudo /etc/group ;;
            54) cat /etc/passwd ;;
            55) auto_install nmap; nmap -sT localhost ;;
            56) printf "  File: "; read -r f; ls -la "$f" ;;
            57) auto_install lynis; sudo lynis audit system --quick ;;
            58) sestatus 2>/dev/null || info "Not a SELinux system." ;;
            59) aa-status 2>/dev/null || info "Not an AppArmor system." ;;
            60) history -c; ok "Session history cleared." ;;
            0)  return ;;
            *)  warn "Invalid option."; sleep 0.8; continue ;;
        esac
        pause
    done
}

# ===========================================================
# CATEGORY 4 — MAINTENANCE
# ===========================================================
menu_maint() {
    while true; do
        draw_header
        cat_header "$YLW" "  ◈  MAINTENANCE & OPS  (Tools 61–80)"
        menu_row  "61" "Update System"         "71" "Edit Crontab"
        menu_row  "62" "Upgrade System"        "72" "List Crons"
        menu_row  "63" "Clean Packages"        "73" "Systemd Failed"
        menu_row  "64" "Empty Trash"           "74" "Journal Vacuum"
        menu_row  "65" "Clear Thumbnails"      "75" "List Services"
        menu_row  "66" "Restart Network"       "76" "Restart SSH"
        menu_row  "67" "Sync Time (NTP)"       "77" "Stop Service"
        menu_row  "68" "Backup Home"           "78" "Start Service"
        menu_row  "69" "Find Large Files"      "79" "Enable Service"
        menu_row  "70" "Memory Cache Drop"     "80" "Disable Service"
        cat_footer

        read -r opt
        case $opt in
            61) sudo apt update || sudo yum check-update ;;
            62) sudo apt upgrade -y || sudo yum update -y ;;
            63) sudo apt autoremove -y || sudo yum autoremove -y ;;
            64) rm -rf ~/.local/share/Trash/*; ok "Trash emptied." ;;
            65) rm -rf ~/.cache/thumbnails/*; ok "Thumbnails cleared." ;;
            66) sudo systemctl restart networking ;;
            67) sudo timedatectl set-ntp on; ok "NTP sync enabled." ;;
            68) tar -czf "$BACKUP_DIR/home_bkp_$(date +%F).tar.gz" /home/ && ok "Backup saved to $BACKUP_DIR" ;;
            69) sudo find / -type f -size +100M 2>/dev/null ;;
            70) sudo sh -c 'echo 3 > /proc/sys/vm/drop_caches'; ok "Memory cache dropped." ;;
            71) crontab -e ;;
            72) crontab -l ;;
            73) systemctl --failed ;;
            74) sudo journalctl --vacuum-time=2d ;;
            75) systemctl list-units --type=service ;;
            76) sudo systemctl restart ssh ;;
            77) printf "  Service: "; read -r s; sudo systemctl stop    "$s" ;;
            78) printf "  Service: "; read -r s; sudo systemctl start   "$s" ;;
            79) printf "  Service: "; read -r s; sudo systemctl enable  "$s" ;;
            80) printf "  Service: "; read -r s; sudo systemctl disable "$s" ;;
            0)  return ;;
            *)  warn "Invalid option."; sleep 0.8; continue ;;
        esac
        pause
    done
}

# ===========================================================
# CATEGORY 5 — DOCKER & WEB
# ===========================================================
menu_web() {
    while true; do
        draw_header
        cat_header "$CYN" "  ◈  DOCKER & WEB STACK  (Tools 81–100)"
        menu_row  " 81" "Docker Version"       " 91" "Nginx Status"
        menu_row  " 82" "List Containers"      " 92" "Apache Status"
        menu_row  " 83" "Running Containers"   " 93" "MySQL Status"
        menu_row  " 84" "Docker Images"        " 94" "PHP Version"
        menu_row  " 85" "System Prune"         " 95" "Node.js Version"
        menu_row  " 86" "Stop All Containers"  " 96" "Python Version"
        menu_row  " 87" "Kill All Containers"  " 97" "Check Site SSL"
        menu_row  " 88" "Container Logs"       " 98" "Access Logs"
        menu_row  " 89" "Docker Stats"         " 99" "Error Logs"
        menu_row  " 90" "Compose Up"           "100" "Certbot Renew"
        cat_footer

        read -r opt
        case $opt in
            81)  docker --version ;;
            82)  docker ps -a ;;
            83)  docker ps ;;
            84)  docker images ;;
            85)  docker system prune -f ;;
            86)  docker stop $(docker ps -q) 2>/dev/null || warn "No running containers." ;;
            87)  docker kill  $(docker ps -q) 2>/dev/null || warn "No running containers." ;;
            88)  printf "  Container ID: "; read -r i; docker logs "$i" ;;
            89)  docker stats --no-stream ;;
            90)  docker compose up -d 2>/dev/null || docker-compose up -d ;;
            91)  systemctl status nginx   --no-pager ;;
            92)  systemctl status apache2 --no-pager ;;
            93)  systemctl status mysql   --no-pager ;;
            94)  php -v ;;
            95)  node -v ;;
            96)  python3 --version ;;
            97)  printf "  Domain: "; read -r d; curl -vI "https://$d" 2>&1 | grep -i "expire" ;;
            98)  tail -n 20 /var/log/nginx/access.log 2>/dev/null || err "No Nginx access log found." ;;
            99)  tail -n 20 /var/log/nginx/error.log  2>/dev/null || err "No Nginx error log found." ;;
            100) sudo certbot renew --dry-run ;;
            0)   return ;;
            *)   warn "Invalid option."; sleep 0.8; continue ;;
        esac
        pause
    done
}

# ===========================================================
# MAIN MENU
# ===========================================================
while true; do
    draw_header

    printf "  ${CYN}╔%*s╗${NC}\n" "$((WIDTH-2))" "" | tr ' ' '═'
    printf "  ${CYN}║${NC}%*s${CYN}║${NC}\n" "$((WIDTH-2))" ""

    printf "  ${CYN}║${NC}  ${MGN}[1]${NC}  ${W}%-22s${NC}  ${DG}CPU, RAM, Disk, Info${NC}%*s${CYN}║${NC}\n" \
        "System & Hardware" "$(( WIDTH - 54 ))" ""
    printf "  ${CYN}║${NC}  ${BLU}[2]${NC}  ${W}%-22s${NC}  ${DG}IP, DNS, Speed, Scan${NC}%*s${CYN}║${NC}\n" \
        "Network & Internet" "$(( WIDTH - 54 ))" ""
    printf "  ${CYN}║${NC}  ${RED}[3]${NC}  ${W}%-22s${NC}  ${DG}Firewall, Users, Perms${NC}%*s${CYN}║${NC}\n" \
        "Security & Audit" "$(( WIDTH - 56 ))" ""
    printf "  ${CYN}║${NC}  ${YLW}[4]${NC}  ${W}%-22s${NC}  ${DG}Updates, Clean, Services${NC}%*s${CYN}║${NC}\n" \
        "Maintenance & Ops" "$(( WIDTH - 58 ))" ""
    printf "  ${CYN}║${NC}  ${CYN}[5]${NC}  ${W}%-22s${NC}  ${DG}Containers, Nginx, Logs${NC}%*s${CYN}║${NC}\n" \
        "Docker & Web Stack" "$(( WIDTH - 57 ))" ""

    printf "  ${CYN}║${NC}%*s${CYN}║${NC}\n" "$((WIDTH-2))" ""
    printf "  ${CYN}╟%*s╢${NC}\n" "$((WIDTH-2))" "" | tr ' ' '─'
    printf "  ${CYN}║${NC}  ${RED}[0]${NC}  ${W}%-22s${NC}%*s${CYN}║${NC}\n" \
        "Exit Titan Panel" "$(( WIDTH - 30 ))" ""
    printf "  ${CYN}║${NC}%*s${CYN}║${NC}\n" "$((WIDTH-2))" ""s
    printf "  ${CYN}╚%*s╝${NC}\n\n" "$((WIDTH-2))" "" | tr ' ' '═'

    printf "  ${CYN}root@omni${NC}${DG}:~#${NC}  "
    read -r main_opt

    case $main_opt in
        1) menu_sys ;;
        2) menu_net ;;
        3) menu_sec ;;
        4) menu_maint ;;
        5) menu_web ;;
        0) clear; printf "  ${DG}System halted. Goodbye.${NC}\n\n"; exit 0 ;;
        *) warn "Invalid — choose 0–5."; sleep 0.8 ;;
    esac
done
