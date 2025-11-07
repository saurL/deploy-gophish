#!/usr/bin/env bash
set -euo pipefail

# Usage: ./setup-domain.sh example.com admin@example.com
# Argument 1 : DOMAIN (ex: smort-rh.com)
# Argument 2 : EMAIL pour certbot (obligatoire pour Let's Encrypt)
# Le script crée des .bak des fichiers modifiés.

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 DOMAIN EMAIL"
  echo "Ex: $0 smort-rh.com admin@exemple.com"
  exit 2
fi

DOMAIN="$1"
EMAIL="$2"
ADMIN="admin.${DOMAIN}"
WWW="www.${DOMAIN}"

# Fichiers attendus (adapter si nécessaire)
GOPHISH_CONF="./gophish/config.json"
NGINX_CONF_DIR="./nginx/conf.d"
NGINX_CONF="${NGINX_CONF_DIR}/gophish.conf"
NGINX_STATIC="./nginx/static"
DOCKER_COMPOSE="./docker-compose.yml"

echo "Domain   : $DOMAIN"
echo "Admin    : $ADMIN"
echo "WWW      : $WWW"
echo "Email    : $EMAIL"
echo

# 0) Vérifications de base
if [ ! -f "$GOPHISH_CONF" ]; then
  echo "Erreur: fichier $GOPHISH_CONF introuvable. Vérifie le chemin."
  exit 3
fi
if [ ! -d "$NGINX_CONF_DIR" ]; then
  echo "Erreur: dossier $NGINX_CONF_DIR introuvable."
  exit 3
fi
if [ ! -f "$NGINX_CONF" ]; then
  echo "Erreur: fichier $NGINX_CONF introuvable."
  exit 3
fi
if [ ! -d "$NGINX_STATIC" ]; then
  echo "Info: $NGINX_STATIC introuvable. Le dossier sera créé."
  mkdir -p "$NGINX_STATIC"
fi

# Fonction utilitaire : sed in-place portable (mac/linux)
sed_i() {
  local expr="$1"; shift
  local file="$1"; shift
  if sed --version >/dev/null 2>&1; then
    sed -i.bak -E "$expr" "$file"
  else
    # macOS BSD sed
    sed -i '' -E "$expr" "$file"
    # create a .bak because mac sed -i'' doesn't create one; we create manually
    cp "$file" "$file.bak"
  fi
}

# 2) Remplacement des domaines (ordre important: admin, www, root)
echo "Sauvegarde des fichiers originaux (*.bak créé automatiquement)."
# backup copies already created by sed_i (or will exist as .bak)

# Replace admin.* occurrences
echo "Remplacement de l'ancien admin.* par $ADMIN"
sed_i "s/(admin\\.[a-z0-9.-]+)/$ADMIN/gI" "$NGINX_CONF" || true
sed_i "s/admin\\.[a-z0-9.-]+/$ADMIN/gI" "$GOPHISH_CONF" || true


# Replace www.* occurrences
echo "Remplacement de l'ancien www.* par $WWW"
sed_i "s/(www\\.[a-z0-9.-]+)/$WWW/gI" "$NGINX_CONF" || true
sed_i "s/www\\.[a-z0-9.-]+/$WWW/gI" "$GOPHISH_CONF" || true





# NOTE: les sed ci-dessus essayent d'être permissifs. Vérifie toujours les fichiers après exécution.
echo "Remplacements effectués. Copies .bak créées."

# 3) Afficher un rappel pour vérifier manuellement (sécurité)
echo
echo ">>> IMPORTANT : ouvre et vérifie rapidement :"
echo "    - $GOPHISH_CONF"
echo "    - $NGINX_CONF"
echo "Assure-toi que les remplacements correspondent à ce que tu veux."
echo

# 5) Obtenir les certificats avec certbot (standalone)
echo
echo "Obtention des certificats Let's Encrypt pour : $ADMIN, $WWW, $DOMAIN"
echo "Vérification que port 80 est libre..."
if ss -ltn | grep -q ':80'; then
  echo "Attention : le port 80 semble occupé sur l'hôte. Arrête nginx s'il tourne ou libère le port 80."
  echo "Processus écoutant sur :"
  ss -ltnp | grep ':80' || true
  echo "Sortie."
  exit 5
fi

# lancer certbot (standalone) - requires sudo
echo "Lancement de certbot (standalone). Tu peux être invité à entrer sudo..."
sudo certbot certonly --standalone \
  -d "$ADMIN" -d "$WWW" -d "$DOMAIN" \
  --preferred-challenges http \
  --agree-tos --non-interactive -m "$EMAIL"

echo "Certificats obtenus (si aucune erreur)."


echo
echo "=== Terminé ==="
echo "Vérifie :"
echo " - docker-compose ps"
echo " - /etc/letsencrypt/live/$DOMAIN/ (doit contenir les certificats)"
echo " - l'accès web : https://$DOMAIN , https://$WWW , https://$ADMIN"
echo
echo "Si nginx ne démarre pas : regarde les logs : docker-compose -f $DOCKER_COMPOSE logs nginx"
echo "Si certbot échoue, vérifie que les DNS pointent vers ce serveur et que le port 80 est libre."
