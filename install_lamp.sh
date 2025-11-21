#!/usr/bin/env bash
set -euo pipefail

# Cargar variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/.env"

echo "Actualizando índices de paquetes..."
sudo apt-get update -y

echo "Instalando Apache, MySQL y PHP..."
sudo apt-get install -y apache2 mysql-server \
  php php-cli php-common php-mysql php-gd php-curl php-xml php-mbstring php-zip

echo "Habilitando módulos necesarios de Apache..."
sudo a2enmod rewrite ssl

echo " Configurando virtual host básico..."
VHOST_CONF="/etc/apache2/sites-available/000-default.conf"
sudo tee "${VHOST_CONF}" >/dev/null <<EOF
<VirtualHost *:80>
    ServerName ${APACHE_VHOST_SERVER_NAME}
    DocumentRoot ${APACHE_VHOST_DOCROOT}

    <Directory ${APACHE_VHOST_DOCROOT}>
        AllowOverride All
        Options Indexes FollowSymLinks
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF

echo "Reiniciando Apache..."
sudo systemctl enable apache2
sudo systemctl restart apache2

echo "Asegurando MySQL (ajuste básico no interactivo)..."
sudo systemctl enable mysql
sudo systemctl start mysql

sudo mysql -u root <<MYSQL_EOF
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '${DB_PASS}';
FLUSH PRIVILEGES;
MYSQL_EOF

echo " Creando base de datos y usuario de WordPress..."
sudo mysql -u root -p"${DB_PASS}" <<MYSQL_EOF
CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';
GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'localhost';
FLUSH PRIVILEGES;
MYSQL_EOF

echo "Instalando WP-CLI..."
curl -sS -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x wp-cli.phar
sudo mv wp-cli.phar /usr/local/bin/wp

echo " Comprobando WP-CLI..."
wp --info || { echo "WP-CLI no instalado correctamente"; exit 1; }

echo "Preparando directorio de WordPress: ${WP_PATH}"
sudo mkdir -p "${WP_PATH}"
sudo chown -R "${WWW_USER}:${WWW_GROUP}" "${WP_PATH}"

echo " LAMP y WP-CLI instalados."
