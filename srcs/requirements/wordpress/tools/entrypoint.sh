#!/bin/bash

set -e

echo ">> Entrando al entrypoint de WordPress..."

DB_NAME=${MYSQL_DATABASE}
DB_USER=${MYSQL_USER}
DB_PASS=$(cat /run/secrets/db_password)

# Esperar que MariaDB esté listo
echo ">> Esperando conexión con MariaDB..."
for i in {1..30}; do
    if mariadb -h mariadb -u "$DB_USER" -p"$DB_PASS" -e "SHOW DATABASES;" &> /dev/null; then
        echo ">> MariaDB está disponible."
        break
    fi
    echo "   ➜ Intento $i fallido... esperando..."
    sleep 1
done

# Cargar variables de credentials.txt si existe
if [ -f /run/secrets/credentials ]; then
    echo ">> Cargando variables desde credentials.txt..."
    source /run/secrets/credentials
else
    echo "❌ ERROR: No se encontró /run/secrets/credentials"
    exit 1
fi

# Verificar estado de conexión
echo "🧩 Verificando variables de conexión:"
echo "   DB_NAME=$DB_NAME"
echo "   DB_USER=$DB_USER"
echo "   DB_HOST=mariadb"
echo "   WP_ADMIN_USER=$WP_ADMIN_USER"
echo "   WP_URL=$WP_URL"

# Generar wp-config.php si no existe
if [ ! -f /var/www/html/wp-config.php ]; then
    echo ">> Generando wp-config.php..."

    cp /var/www/html/wp-config-sample.php /var/www/html/wp-config.php

    sed -i "s/database_name_here/$DB_NAME/" /var/www/html/wp-config.php
    sed -i "s/username_here/$DB_USER/" /var/www/html/wp-config.php
    sed -i "s/password_here/$DB_PASS/" /var/www/html/wp-config.php
    sed -i "s/localhost/mariadb/" /var/www/html/wp-config.php

    # Reemplazar claves de seguridad por las nuevas
    sed -i "/AUTH_KEY/d;/SECURE_AUTH_KEY/d;/LOGGED_IN_KEY/d;/NONCE_KEY/d;/AUTH_SALT/d;/SECURE_AUTH_SALT/d;/LOGGED_IN_SALT/d;/NONCE_SALT/d" /var/www/html/wp-config.php
    KEYS=$(curl -s https://api.wordpress.org/secret-key/1.1/salt/)
    echo "$KEYS" >> /var/www/html/wp-config.php

    echo ">> wp-config.php configurado correctamente."
else
    echo ">> wp-config.php ya existe. No se regenera."
fi

# Instalar WordPress si no está instalado
if ! wp core is-installed --path="/var/www/html" --allow-root; then
    echo ">> Instalando WordPress..."

    if ! wp core install \
        --url="$WP_URL" \
        --title="$WP_TITLE" \
        --admin_user="$WP_ADMIN_USER" \
        --admin_password="$(cat /run/secrets/wp_admin_password)" \
        --admin_email="$WP_ADMIN_EMAIL" \
        --path="/var/www/html" \
        --allow-root; then
        echo "❌ ERROR: Falló la instalación de WordPress"
        exit 1
    fi

    echo "✅ WordPress instalado correctamente."
else
    echo "✅ WordPress ya estaba instalado."
fi

echo ">> Lanzando PHP-FPM..."
mkdir -p /run/php
exec php-fpm7.4 -F
