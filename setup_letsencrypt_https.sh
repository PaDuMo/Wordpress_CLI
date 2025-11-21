#!/usr/bin/env bash
set -euo pipefail

# Cargar variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/.env"

echo "Instalando Certbot para Apache..."
sudo apt-get update -y
sudo apt-get install -y certbot python3-certbot-apache

echo "Solicitando y configurando certificado SSL/TLS..."
sudo certbot --apache \
  -d "${APACHE_VHOST_SERVER_NAME}" \
  -m "${LETSENCRYPT_EMAIL}" \
  --agree-tos \
  --non-interactive \
  --redirect

echo "Probando renovación automática..."
sudo certbot renew --dry-run

echo "HTTPS configurado con Let's Encrypt."
