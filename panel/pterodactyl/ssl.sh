#!/bin/bash
# ===========================================================
# PTERODACTYL — NGINX CONFIGURATOR
# ===========================================================

# ── Colors ─────────────────────────────────────────────────
BOLD='\033[1m'
CYN='\033[1;38;5;51m'
GRN='\033[1;38;5;82m'
YLW='\033[1;38;5;220m'
RED='\033[1;38;5;196m'
PUR='\033[1;38;5;141m'
W='\033[1;38;5;255m'
DG='\033[0;38;5;244m'
LG='\033[0;38;5;240m'
NC='\033[0m'

PHP_VERSION="8.3"
WIDTH=54

# ── Helpers ────────────────────────────────────────────────
box_top()    { printf "\n  ${LG}╔%*s╗${NC}\n" "$((WIDTH - 2))" "" | tr ' ' '═'; }
box_bot()    { printf "  ${LG}╚%*s╝${NC}\n\n" "$((WIDTH - 2))" "" | tr ' ' '═'; }
box_mid()    { printf "  ${LG}╠%*s╣${NC}\n" "$((WIDTH - 2))" "" | tr ' ' '═'; }
box_row()    { printf "  ${LG}║${NC}  %-$((WIDTH - 4))s${LG}║${NC}\n" "$1"; }
box_blank()  { printf "  ${LG}║${NC}%*s${LG}║${NC}\n" "$((WIDTH - 2))" ""; }

step()  { printf "\n  ${YLW}▸${NC}  ${DG}%s${NC}\n" "$1"; }
ok()    { printf "  ${GRN}✔${NC}  ${W}%s${NC}\n" "$1"; }
warn()  { printf "  ${YLW}!${NC}  ${YLW}%s${NC}\n" "$1"; }
err()   { printf "  ${RED}✘${NC}  ${RED}%s${NC}\n" "$1"; }
info()  { printf "  ${DG}    %s${NC}\n" "$1"; }

divider() { printf "  ${LG}%*s${NC}\n" "$WIDTH" "" | tr ' ' '─'; }

ask() {
    # ask VARNAME "Prompt text"
    local var="$1" prompt="$2"
    printf "\n  ${CYN}?${NC}  ${W}%s${NC}\n  ${LG}╰─▸${NC} " "$prompt"
    read -r "$var"
}

ask_yn() {
    # ask_yn VARNAME "Prompt text"  → stores y or n
    local var="$1" prompt="$2"
    printf "\n  ${CYN}?${NC}  ${W}%s${NC} ${DG}[y/n]${NC}\n  ${LG}╰─▸${NC} " "$prompt"
    read -r "$var"
}

# ── Header ─────────────────────────────────────────────────
clear

box_top
box_blank
box_row "$(printf "${CYN}${BOLD}  PTERODACTYL  •  NGINX CONFIGURATOR${NC}")"
box_blank
box_mid
box_row "$(printf "${DG}  PHP %-6s  │  Nginx auto-config tool${NC}" "${PHP_VERSION}")"
box_blank
box_bot

# ── Mode selection ─────────────────────────────────────────
printf "  ${W}${BOLD}Select configuration mode:${NC}\n\n"
printf "  ${LG}│${NC}  ${GRN}[1]${NC}  SSL / HTTPS          ${DG}Recommended${NC}\n"
printf "  ${LG}│${NC}  ${YLW}[2]${NC}  HTTP only            ${DG}No certificate${NC}\n"
printf "  ${LG}│${NC}  ${PUR}[3]${NC}  Auto SSL (Certbot)   ${DG}Issue & configure${NC}\n"
printf "\n"
printf "  ${LG}╰─▸${NC} "
read -r OPTION

# ── Domain input ───────────────────────────────────────────
ask DOMAIN "Enter your domain  (e.g. panel.example.com)"

# ── Prepare environment ────────────────────────────────────
step "Preparing environment"

if [ "$OPTION" != "3" ]; then
    cd /var/www/pterodactyl 2>/dev/null || {
        err "Pterodactyl directory not found at /var/www/pterodactyl"
        exit 1
    }
fi

rm -f /etc/nginx/sites-enabled/default
rm -f /etc/nginx/sites-available/pterodactyl.conf
ok "Old configs cleared"

# ===========================================================
# OPTION 1 — SSL / HTTPS
# ===========================================================
if [ "$OPTION" == "1" ]; then

    printf "\n  ${W}Certificate source:${NC}\n"
    printf "  ${LG}│${NC}  ${GRN}[y]${NC}  Let's Encrypt   ${DG}/etc/letsencrypt/live/…${NC}\n"
    printf "  ${LG}│${NC}  ${YLW}[n]${NC}  Custom path     ${DG}/etc/certs/panel${NC}\n\n"
    printf "  ${LG}╰─▸${NC} "
    read -r SSLTYPE

    if [ "$SSLTYPE" == "y" ]; then
        FULLCHAIN="/etc/letsencrypt/live/${DOMAIN}/fullchain.pem"
        PRIVKEY="/etc/letsencrypt/live/${DOMAIN}/privkey.pem"
    else
        FULLCHAIN="/etc/certs/panel/fullchain.pem"
        PRIVKEY="/etc/certs/panel/privkey.pem"
    fi

    step "Writing APP_URL → https://${DOMAIN}"
    sed -i "s|APP_URL=.*|APP_URL=https://${DOMAIN}|g" .env
    ok "APP_URL updated"

    step "Writing Nginx SSL config"
    cat > /etc/nginx/sites-available/pterodactyl.conf <<EOF
server {
    listen 80;
    server_name ${DOMAIN};
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name ${DOMAIN};

    root /var/www/pterodactyl/public;
    index index.php;

    ssl_certificate ${FULLCHAIN};
    ssl_certificate_key ${PRIVKEY};

    client_max_body_size 100m;
    client_body_timeout 120s;
    sendfile off;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php\$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)\$;
        fastcgi_pass unix:/run/php/php${PHP_VERSION}-fpm.sock;
        fastcgi_index index.php;
        include /etc/nginx/fastcgi_params;
        fastcgi_param PHP_VALUE "upload_max_filesize=100M \n post_max_size=100M";
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param HTTP_PROXY "";
        fastcgi_intercept_errors off;
        fastcgi_buffer_size 16k;
        fastcgi_buffers 4 16k;
        fastcgi_connect_timeout 300;
        fastcgi_send_timeout 300;
        fastcgi_read_timeout 300;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF
    ok "Config written"

# ===========================================================
# OPTION 2 — HTTP only
# ===========================================================
elif [ "$OPTION" == "2" ]; then

    step "Writing APP_URL → http://${DOMAIN}"
    sed -i "s|APP_URL=.*|APP_URL=http://${DOMAIN}|g" .env
    ok "APP_URL updated"

    step "Writing Nginx HTTP config"
    cat > /etc/nginx/sites-available/pterodactyl.conf <<EOF
server {
    listen 80;
    server_name ${DOMAIN};

    root /var/www/pterodactyl/public;
    index index.php;
    charset utf-8;

    client_max_body_size 100m;
    client_body_timeout 120s;
    sendfile off;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php\$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)\$;
        fastcgi_pass unix:/run/php/php${PHP_VERSION}-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param PHP_VALUE "upload_max_filesize=100M \n post_max_size=100M";
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF
    ok "Config written"

# ===========================================================
# OPTION 3 — Auto SSL via Certbot
# ===========================================================
elif [ "$OPTION" == "3" ]; then

    clear
    box_top
    box_blank
    box_row "$(printf "${PUR}${BOLD}  AUTO SSL GENERATOR  •  Certbot${NC}")"
    box_blank
    box_bot

    EMAIL="ssl$(tr -dc a-z0-9 </dev/urandom | head -c6)@nobita.com"
    info "Using email: ${EMAIL}"

    step "Updating system repositories"
    apt update -y &>/dev/null
    ok "Repositories updated"

    step "Installing Certbot + Nginx plugin"
    apt install certbot python3-certbot-nginx -y &>/dev/null
    ok "Certbot installed"

    step "Requesting SSL certificate for ${DOMAIN}"
    certbot --nginx -d "${DOMAIN}" --non-interactive --agree-tos \
        -m "${EMAIL}" --redirect

    if [ $? -eq 0 ]; then
        printf "\n"
        divider
        ok "SSL certificate issued successfully"
        ok "HTTPS redirect configured"
        printf "\n"
        printf "  ${W}Panel URL:${NC}  ${GRN}${BOLD}https://${DOMAIN}${NC}\n"
        divider
        printf "\n"
    else
        printf "\n"
        err "SSL generation failed"
        warn "Verify your domain's DNS points to this server's IP."
    fi
    exit 0

else
    err "Invalid option — please run again and choose 1, 2, or 3."
    exit 1
fi

# ── Enable & test config (options 1 & 2) ──────────────────
step "Enabling site config"
ln -sf /etc/nginx/sites-available/pterodactyl.conf \
       /etc/nginx/sites-enabled/pterodactyl.conf
ok "Symlink created"

step "Testing Nginx configuration"
nginx -t

if [ $? -eq 0 ]; then
    step "Restarting Nginx"
    systemctl restart nginx
    ok "Nginx restarted"

    SCHEME="http"
    [ "$OPTION" == "1" ] && SCHEME="https"

    printf "\n"
    divider
    ok "Setup completed successfully"
    printf "\n"
    printf "  ${W}Panel URL:${NC}  ${GRN}${BOLD}${SCHEME}://${DOMAIN}${NC}\n"
    divider
    printf "\n"
else
    printf "\n"
    err "Nginx config test failed — review errors above."
fi
