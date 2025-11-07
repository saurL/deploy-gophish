#!/usr/bin/env bash
set -euo pipefail

# Usage: ./init.sh NEW_DOMAIN EMAIL
# Example: ./init.sh smort-rh.com admin@example.com
# Replaces ADMIN_DOMAIN, WWW_DOMAIN, ROOT_DOMAIN in the listed files.
# Does NOT create .bak files. Use git to be able to revert easily if needed.

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 NEW_DOMAIN EMAIL"
  exit 2
fi

DOMAIN_NEW="$1"
EMAIL="$2"
ADMIN_NEW="admin.${DOMAIN_NEW}"
WWW_NEW="www.${DOMAIN_NEW}"

# files to modify (adjust if needed)
GOPHISH_CONF="./gophish/config.json"
NGINX_CONF="./nginx/conf.d/gophish.conf"
GOPHISH_DIR="./gophish"
NGINX_DIR="./nginx"

echo "New domain     : $DOMAIN_NEW"
echo "Admin host     : $ADMIN_NEW"
echo "WWW host       : $WWW_NEW"
echo "Certbot email  : $EMAIL"
echo

# Function: replace placeholders in a file using awk + temporary file
# Replaces literal ADMIN_DOMAIN, WWW_DOMAIN, ROOT_DOMAIN
replace_placeholders_with_awk() {
  local file="$1"
  echo "Processing: $file"
  # create a secure tmp file
  tmp=$(mktemp "${TMPDIR:-/tmp}/replace.XXXXXX") || { echo "Unable to create temporary file"; exit 4; }
  awk -v admin="$ADMIN_NEW" -v www="$WWW_NEW" -v root="$DOMAIN_NEW" \
    '{ gsub(/ADMIN_DOMAIN/, admin); gsub(/WWW_DOMAIN/, www); gsub(/ROOT_DOMAIN/, root); print }' "$file" > "$tmp"
  # atomic move
  mv "$tmp" "$file"
}

read -r -p "Confirm replacing placeholders with the values below? [y/N]
  ADMIN_DOMAIN -> $ADMIN_NEW
  WWW_DOMAIN   -> $WWW_NEW
  ROOT_DOMAIN  -> $DOMAIN_NEW
> " confirm
case "$confirm" in
  [Yy]|[Yy][Ee][Ss]) ;;
  *) echo "Aborted."; exit 0 ;;
esac

# Apply replacements (no .bak)
replace_placeholders_with_awk "$GOPHISH_CONF"
replace_placeholders_with_awk "$NGINX_CONF"

read -r -p "Continue to obtain certificates? [y/N] " cont
case "$cont" in
  [Yy]|[Yy][Ee][Ss]) ;;
  *) echo "Done (operations stopped)."; exit 0 ;;
esac


# Check port 80 is free
echo "Checking port 80..."
if command -v ss >/dev/null 2>&1; then
  if ss -ltn | awk '$4 ~ /:80$/ {exit 1}'; then
    echo "Port 80 is free."
  else
    echo "Error: port 80 appears to be in use. Free it before running certbot."
    ss -ltnp | grep ':80' || true
    exit 5
  fi
elif command -v netstat >/dev/null 2>&1; then
  if netstat -ltn | awk '$4 ~ /:80$/ {exit 1}'; then
    echo "Port 80 is free."
  else
    echo "Error: port 80 appears to be in use. Free it before running certbot."
    netstat -ltnp | grep ':80' || true
    exit 5
  fi
else
  echo "Unable to automatically check port 80 (ss/netstat not found). Make sure it is free."
fi

# Run certbot (standalone)
echo "Requesting Let's Encrypt certificates for: $ADMIN_NEW, $WWW_NEW, $DOMAIN_NEW"
if ! sudo certbot certonly --standalone \
  -d "$ADMIN_NEW" -d "$WWW_NEW" -d "$DOMAIN_NEW" \
  --preferred-challenges http \
  --agree-tos --non-interactive -m "$EMAIL"
then
  echo "Error: certbot failed. Aborting. Fix the issue and re-run the script."
  exit 6
fi

echo "Certificates successfully obtained."

# Decide which docker-compose command to use
DOCKER_CMD=""
if command -v "docker" >/dev/null 2>&1 && docker help compose >/dev/null 2>&1; then
  DOCKER_CMD="docker compose"
elif command -v docker-compose >/dev/null 2>&1; then
  DOCKER_CMD="docker-compose"
else
  echo "Error: neither 'docker compose' nor 'docker-compose' found. Start containers manually."
  exit 7
fi

# Start containers (detached)
echo "Starting containers with: $DOCKER_CMD up -d"
$DOCKER_CMD up -d

echo
echo "=== Done ==="
echo "Containers started. You can check the status with:"
echo "  $DOCKER_CMD ps"
echo "Check certificates at: /etc/letsencrypt/live/$DOMAIN_NEW/"
echo "Access your services:"
echo " - Admin UI: https://$ADMIN_NEW"
echo " - Landing pages: https://$DOMAIN_NEW or https://$WWW_NEW"
