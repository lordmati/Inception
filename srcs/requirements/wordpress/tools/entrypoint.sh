#!/bin/bash

set -e

echo ">> Configurando WordPress..."

# Corregir la ruta del secreto
if [ -f /run/secrets/db_password ]; then
    DB_PASS=$(cat /run/secrets/db_password)
elif [ -f /srcs/secrets/db_password.txt ]; then
    DB_PASS=$(cat /srcs/secrets/db_password.txt)
else
    echo "ADVERTENCIA: No se encontró el archivo de contraseña. Usando MYSQL_PASSWORD de variable de entorno."
    DB_PASS=$MYSQL_PASSWORD
fi

# Incrementar tiempo de espera y no salir con error
echo ">> Esperando que MariaDB esté disponible..."
for i in {1..60}; do
    if mariadb -h mariadb -u$MYSQL_USER -p$DB_PASS -e "SHOW DATABASES;" &> /dev/null; then
        echo ">> MariaDB está disponible"
        DB_CONNECTED=true
        break
    fi
    echo "Esperando MariaDB ($i)..."
    sleep 2
done

if [ -z "$DB_CONNECTED" ]; then
    echo "ADVERTENCIA: No se pudo conectar a MariaDB, pero continuaremos..."
    # NO usar exit 1 aquí para evitar reinicio
fi

# Resto del script...
# Verificar si WordPress ya está configurado
if [ ! -f /var/www/html/wp-config.php ]; then
    # Configurar wp-config.php
    cp /var/www/html/wp-config-sample.php /var/www/html/wp-config.php

    sed -i "s/database_name_here/$MYSQL_DATABASE/" /var/www/html/wp-config.php
    sed -i "s/username_here/$MYSQL_USER/" /var/www/html/wp-config.php
    sed -i "s/password_here/$DB_PASS/" /var/www/html/wp-config.php
    sed -i "s/localhost/mariadb/" /var/www/html/wp-config.php
    
    # Generar claves de seguridad
    KEYS=$(curl -s https://api.wordpress.org/secret-key/1.1/salt/)
    sed -i "/put your unique phrase here/d" /var/www/html/wp-config.php
    sed -i "/AUTH_KEY/i\\$KEYS" /var/www/html/wp-config.php
else
    echo ">> wp-config.php ya existe, omitiendo configuración"
fi

# Arrancar PHP-FPM
echo ">> Lanzando PHP-FPM"
exec php-fpm7.4 -F