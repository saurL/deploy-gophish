#!/usr/bin/env bash
set -euo pipefail

# Usage: ./setup-domain.sh NEW_DOMAIN EMAIL
# Exemple: ./setup-domain.sh smort-rh.com admin@example.com
# Remplace ADMIN_DOMAIN, WWW_DOMAIN, ROOT_DOMAIN dans les fichiers listés.
# Ne crée pas de .bak. Vérifie avec git avant exécution si tu veux revert facilement.

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 NEW_DOMAIN EMAIL"
  exit 2
fi

DOMAIN_NEW="$1"
EMAIL="$2"
ADMIN_NEW="admin.${DOMAIN_NEW}"
WWW_NEW="www.${DOMAIN_NEW}"

# fichiers à modifier (adapte si besoin)
GOPHISH_CONF="./gophish/config.json"
NGINX_CONF="./nginx/conf.d/gophish.conf"
GOPHISH_DIR="./gophish"
NGINX_DIR="./nginx"

echo "Nouveau domaine : $DOMAIN_NEW"
echo "Admin           : $ADMIN_NEW"
echo "WWW             : $WWW_NEW"
echo "Email certbot   : $EMAIL"
echo



# Fonction : remplacer placeholders dans un fichier en utilisant awk + fichier temporaire
# Remplace littéralement ADMIN_DOMAIN, WWW_DOMAIN, ROOT_DOMAIN
replace_placeholders_with_awk() {
  local file="$1"
  echo "Traitement : $file"
  # créer un tmp file de manière sécurisée
  tmp=$(mktemp "${TMPDIR:-/tmp}/replace.XXXXXX") || { echo "Impossible de créer un tmp"; exit 4; }
  awk -v admin="$ADMIN_NEW" -v www="$WWW_NEW" -v root="$DOMAIN_NEW" \
    '{ gsub(/ADMIN_DOMAIN/, admin); gsub(/WWW_DOMAIN/, www); gsub(/ROOT_DOMAIN/, root); print }' "$file" > "$tmp"
  # mv atomique
  mv "$tmp" "$file"
}

# Détecter si au moins un des placeholders est présent (simple check)
check_placeholders_present() {
  local file="$1"
  if grep -q 'ADMIN_DOMAIN\|WWW_DOMAIN\|ROOT_DOMAIN' "$file"; then
    return 0
  else
    return 1
  fi
}



read -r -p "Confirmer le remplacement des placeholders par les valeurs ci‑dessous ? [y/N]
  ADMIN_DOMAIN -> $ADMIN_NEW
  WWW_DOMAIN   -> $WWW_NEW
  ROOT_DOMAIN  -> $DOMAIN_NEW
> " confirm
case "$confirm" in
  [Yy]|[Yy][Ee][Ss]) ;;
  *) echo "Abandon."; exit 0 ;;
esac

# Appliquer remplacements (sans .bak)
replace_placeholders_with_awk "$GOPHISH_CONF"
replace_placeholders_with_awk "$NGINX_CONF"

read -r -p "Continuer et démarrer gophish + obtenir certificats ? [y/N] " cont
case "$cont" in
  [Yy]|[Yy][Ee][Ss]) ;;
  *) echo "Terminé (opérations arrêtées)."; exit 0 ;;
esac


# Vérifier port 80 libre
echo "Vérification du port 80..."
if command -v ss >/dev/null 2>&1; then
  if ss -ltn | awk '$4 ~ /:80$/ {exit 1}'; then
    echo "Port 80 libre."
  else
    echo "Erreur : le port 80 est occupé. Libère-le avant d'exécuter certbot."
    ss -ltnp | grep ':80' || true
    exit 5
  fi
elif command -v netstat >/dev/null 2>&1; then
  if netstat -ltn | awk '$4 ~ /:80$/ {exit 1}'; then
    echo "Port 80 libre."
  else
    echo "Erreur : le port 80 est occupé. Libère-le avant d'exécuter certbot."
    netstat -ltnp | grep ':80' || true
    exit 5
  fi
else
  echo "Impossible de vérifier automatiquement le port 80 (ss/netstat non trouvés). Assure-toi qu'il soit libre."
fi

# Lancer certbot (standalone)
echo "Obtention des certificats Let's Encrypt pour : $ADMIN_NEW, $WWW_NEW, $DOMAIN_NEW"
sudo certbot certonly --standalone \
  -d "$ADMIN_NEW" -d "$WWW_NEW" -d "$DOMAIN_NEW" \
  --preferred-challenges http \
  --agree-tos --non-interactive -m "$EMAIL"



echo
echo "=== Terminé ==="
echo "Vérifie :"
echo " - docker-compose ps"
echo " - /etc/letsencrypt/live/$DOMAIN_NEW/"
echo " - accès web : https://$DOMAIN_NEW , https://$WWW_NEW , https://$ADMIN_NEW"
