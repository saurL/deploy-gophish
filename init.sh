#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<EOF
Usage: $0 [-y] NEW_DOMAIN EMAIL
  -y   answer yes to all prompts (non-interactive)
Example:
  $0 smort-rh.com admin@example.com
  $0 smort-rh.com admin@example.com -y
EOF
  exit 2
}

# Parse arguments: detect -y anywhere
AUTO_YES=false
POSITIONAL=()
for arg in "$@"; do
  case "$arg" in
    -y|--yes) AUTO_YES=true ;;
    *) POSITIONAL+=("$arg") ;;
  esac
done
set -- "${POSITIONAL[@]}"

# Expect exactly 2 positional args
if [ "$#" -ne 2 ]; then
  usage
fi

DOMAIN_NEW="$1"
EMAIL="$2"
ADMIN_NEW="admin.${DOMAIN_NEW}"
WWW_NEW="www.${DOMAIN_NEW}"

# Files to modify
GOPHISH_CONF="./gophish/config.json"
NGINX_CONF="./nginx/conf.d/gophish.conf"

echo "New domain     : $DOMAIN_NEW"
echo "Admin host     : $ADMIN_NEW"
echo "WWW host       : $WWW_NEW"
echo "Certbot email  : $EMAIL"
echo

# Helper: ask question, default Yes. returns 0 for yes, 1 for no
ask_yes_default_yes() {
  local prompt="$1"
  if [ "$AUTO_YES" = true ]; then return 0; fi
  local ans
  read -r -p "$prompt [Y/n] (default: Y) " ans
  ans="${ans:-y}"
  case "${ans,,}" in
    y|yes) return 0 ;;
    *) return 1 ;;
  esac
}

# Function: replace placeholders in a file
replace_placeholders_with_awk() {
  local file="$1"
  echo "Processing: $file"
  [ -f "$file" ] || { echo "Skipped $file (not found)"; return; }
  tmp=$(mktemp "${TMPDIR:-/tmp}/replace.XXXXXX") || { echo "Unable to create tmp"; exit 4; }
  awk -v admin="$ADMIN_NEW" -v www="$WWW_NEW" -v root="$DOMAIN_NEW" \
    '{ gsub(/ADMIN_DOMAIN/, admin); gsub(/WWW_DOMAIN/, www); gsub(/ROOT_DOMAIN/, root); print }' "$file" > "$tmp"
  mv "$tmp" "$file"
}

# Replace placeholders
if ask_yes_default_yes "Replace placeholders ADMIN_DOMAIN / WWW_DOMAIN / ROOT_DOMAIN in files?"; then
  replace_placeholders_with_awk "$GOPHISH_CONF"
  replace_placeholders_with_awk "$NGINX_CONF"
  echo "Placeholder replacement: done."
else
  echo "Placeholder replacement: skipped."
fi

# Certbot
DO_CERTBOT=false
if ask_yes_default_yes "Obtain Let's Encrypt certificates using certbot?"; then
  DO_CERTBOT=true
else
  echo "Certificate issuance: skipped."
fi

if [ "$DO_CERTBOT" = true ]; then
  echo "Checking port 80..."
  if command -v ss >/dev/null 2>&1; then
    if ss -ltn | awk '$4 ~ /:80$/ {exit 1}'; then echo "Port 80 free."; else echo "Port 80 busy."; ss -ltnp | grep ':80' || true; exit 5; fi
  elif command -v netstat >/dev/null 2>&1; then
    if netstat -ltn | awk '$4 ~ /:80$/ {exit 1}'; then echo "Port 80 free."; else echo "Port 80 busy."; netstat -ltnp | grep ':80' || true; exit 5; fi
  else
    echo "Cannot check port 80 automatically."
  fi

  echo "Requesting Let's Encrypt certificates for: $ADMIN_NEW, $WWW_NEW, $DOMAIN_NEW"
  if ! sudo certbot certonly --standalone -d "$ADMIN_NEW" --preferred-challenges http --agree-tos --non-interactive -m "$EMAIL"; then
    echo "Certbot failed. Aborting."
    exit 6
    fi
  if ! sudo certbot certonly --standalone -d "$WWW_NEW"  --preferred-challenges http --agree-tos --non-interactive -m "$EMAIL"; then
  echo "Certbot failed. Aborting."
  exit 6
  fi
  if ! sudo certbot certonly --standalone  -d "$DOMAIN_NEW" --preferred-challenges http --agree-tos --non-interactive -m "$EMAIL"; then
  echo "Certbot failed. Aborting."
  exit 6
  fi
  echo "Certificates obtained."
fi

# Determine docker command
DOCKER_CMD=""
if command -v docker >/dev/null 2>&1 && docker help compose >/dev/null 2>&1; then
  DOCKER_CMD="docker compose"
elif command -v docker-compose >/dev/null 2>&1; then
  DOCKER_CMD="docker-compose"
else
  echo "Warning: docker not found, containers must be started manually."
fi

# Start containers
if [ -n "$DOCKER_CMD" ]; then
  if ask_yes_default_yes "Start containers now with '$DOCKER_CMD up -d'?"; then
    echo "Starting containers..."
    $DOCKER_CMD up -d
    echo "Containers started."
  else
    echo "Container startup: skipped."
  fi
fi

echo
echo "=== Done ==="
[ -n "$DOCKER_CMD" ] && echo "Check containers: $DOCKER_CMD ps"
[ "$DO_CERTBOT" = true ] && echo "Certificates: /etc/letsencrypt/live/$DOMAIN_NEW/"
echo "Service URLs (if containers & certificates are set up):"
echo " - Admin UI: https://$ADMIN_NEW"
echo " - Landing pages: https://$DOMAIN_NEW or https://$WWW_NEW"
