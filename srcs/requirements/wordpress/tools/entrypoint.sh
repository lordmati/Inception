#!/bin/bash

set -e

echo ">> Entrando al entrypoint de WordPress..."

DB_NAME=${MYSQL_DATABASE}
DB_USER=${MYSQL_USER}
DB_PASS=$(cat /run/secrets/db_password)

# Esperar que MariaDB esté listo
echo ">> Esperando conexión con MariaDB..."
for i in {1..30}; do
    if mariadb -h mariadb -u "$DB_USER" -p "$DB_PASS" -e "SHOW DATABASES;" &> /dev/null; then
        echo ">> MariaDB está disponible."
        break
    fi
    echo "   ➜ Intento $i fallido... esperando..."
    sleep 1
done

# Generar wp-config.php si no existe
if [ ! -f /var/www/html/wp-config.php ]; then
    echo ">> Generando wp-config.php..."

    cp /var/www/html/wp-config-sample.php /var/www/html/wp-config.php

    sed -i "s/database_name_here/$DB_NAME/" /var/www/html/wp-config.php
    sed -i "s/username_here/$DB_USER/" /var/www/html/wp-config.php
    sed -i "s/password_here/$DB_PASS/" /var/www/html/wp-config.php
    sed -i "s/localhost/mariadb/" /var/www/html/wp-config.php

    # Agregar claves de seguridad de WordPress
    KEYS=$(curl -s https://api.wordpress.org/secret-key/1.1/salt/)
    echo "$KEYS" >> /var/www/html/wp-config.php

    echo ">> wp-config.php configurado correctamente."
else
    echo ">> wp-config.php ya existe. No se regenera."
fi

echo ">> Lanzando PHP-FPM..."
mkdir -p /run/php
exec php-fpm7.4 -F
