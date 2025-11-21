#!/usr/bin/env bash
set -euo pipefail

# Cargar variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/.env"

echo "Descargando WordPress en ${WP_PATH} con locale ${WP_LOCALE}..."
sudo -u "${WWW_USER}" wp core download \
  --path="${WP_PATH}" \
  --locale="${WP_LOCALE}" \
  --allow-root

echo "Creando wp-config.php..."
sudo -u "${WWW_USER}" wp config create \
  --dbname="${DB_NAME}" \
  --dbuser="${DB_USER}" \
  --dbpass="${DB_PASS}" \
  --dbhost="${DB_HOST}" \
  --path="${WP_PATH}" \
  --allow-root

echo "Instalando WordPress..."
sudo -u "${WWW_USER}" wp core install \
  --url="${SITE_URL}" \
  --title="${SITE_TITLE}" \
  --admin_user="${ADMIN_USER}" \
  --admin_password="${ADMIN_PASS}" \
  --admin_email="${ADMIN_EMAIL}" \
  --path="${WP_PATH}" \
  --allow-root

echo "Ajustando permisos del directorio..."
sudo chown -R "${WWW_USER}:${WWW_GROUP}" "${WP_PATH}"

echo "Configurando estructura de enlaces permanentes: ${WP_PERMALINK_STRUCTURE}"
sudo -u "${WWW_USER}" wp rewrite structure "${WP_PERMALINK_STRUCTURE}" \
  --path="${WP_PATH}" \
  --allow-root

echo "Forzando escritura de reglas de reescritura..."
sudo -u "${WWW_USER}" wp rewrite flush \
  --hard \
  --path="${WP_PATH}" \
  --allow-root

echo "Actualizando plugins y temas..."
sudo -u "${WWW_USER}" wp plugin update --all --path="${WP_PATH}" --allow-root
sudo -u "${WWW_USER}" wp theme update --all --path="${WP_PATH}" --allow-root

echo "[✓] WordPress desplegado y configurado."
