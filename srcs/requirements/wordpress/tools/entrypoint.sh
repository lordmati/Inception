#!/bin/bash

set -e

echo ">> Entrando al entrypoint de WordPress..."

DB_NAME=${MYSQL_DATABASE}
DB_USER=${MYSQL_USER}
DB_PASS=${MYSQL_PASSWORD}

echo "ENTRY.SH"
echo "Nombre base datos": ${DB_NAME}
echo "USER: " ${DB_USER}
echo "PASS: " ${DB_PASS}

echo "WP-CONFIG"
cat /var/www/html/wp-config.php

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

# # Generar wp-config.php si no existe
# if [ ! -f /var/www/html/wp-config.php ]; then
#     echo ">> Generando wp-config.php..."

#     cp /var/www/html/wp-config-sample.php /var/www/html/wp-config.php

#     sed -i "s/database_name_here/$DB_NAME/" /var/www/html/wp-config.php
#     sed -i "s/username_here/$DB_USER/" /var/www/html/wp-config.php
#     sed -i "s/password_here/$DB_PASS/" /var/www/html/wp-config.php
#     sed -i "s/localhost/mariadb/" /var/www/html/wp-config.php

#     # Reemplazar claves de seguridad por las nuevas
#     sed -i "/AUTH_KEY/d;/SECURE_AUTH_KEY/d;/LOGGED_IN_KEY/d;/NONCE_KEY/d;/AUTH_SALT/d;/SECURE_AUTH_SALT/d;/LOGGED_IN_SALT/d;/NONCE_SALT/d" /var/www/html/wp-config.php
#     KEYS=$(curl -s https://api.wordpress.org/secret-key/1.1/salt/)
#     echo "$KEYS" >> /var/www/html/wp-config.php

#     echo ">> wp-config.php configurado correctamente."
# else
#     echo ">> wp-config.php ya existe. No se regenera."
# fi

# Instalar WordPress si no está instalado
if ! wp core is-installed --path="/var/www/html" --allow-root; then
    echo ">> Instalando WordPress..."

    if ! wp core install \
        --url="$WP_URL" \
        --title="$WP_TITLE" \
        --admin_user="$WP_ADMIN_USER" \
        --admin_password="$WP_ADMIN_PASSWORD" \
        --admin_email="$WP_ADMIN_EMAIL" \
        --path="/var/www/html" \
        --allow-root; then
        echo "❌ ERROR: Falló la instalación de WordPress"
        exit 1
    fi
    echo $WP_ADMIN_USER
    echo $(cat /run/secrets/wp_admin_password)
    echo $WP_ADMIN_PASSWORD
    echo "✅ WordPress instalado correctamente."
else
    echo "✅ WordPress ya estaba instalado."
fi

echo ">> Lanzando PHP-FPM..."
echo ">> Corrigiendo permisos de WordPress..."
chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html
mkdir -p /var/lib/php/sessions
chown -R www-data:www-data /var/lib/php/sessions
mkdir -p /run/php
exec php-fpm7.4 -F
