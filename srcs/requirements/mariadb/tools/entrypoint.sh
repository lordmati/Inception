#!/bin/bash

set -e

echo ">> Entrando al entrypoint de MariaDB"

DB_PASS=$(cat /run/secrets/db_password)
ROOT_PASS=$(cat /run/secrets/db_root_password)

# Inicializar la base de datos si está vacía
if [ ! -d /var/lib/mysql/mysql ]; then
    echo ">> Inicializando base de datos..."
    mariadb-install-db --user=mysql --basedir=/usr --datadir=/var/lib/mysql > /dev/null

    mysqld_safe --skip-networking &
    sleep 5

    echo ">> Ejecutando SQL de inicialización..."
    sed "s/replace_this/$DB_PASS/g" /init.sql > /tmp/init.sql
    mariadb -u root < /tmp/init.sql

    echo ">> Configurando contraseña de root..."
    echo "SET PASSWORD FOR 'root'@'localhost' = PASSWORD('$ROOT_PASS'); FLUSH PRIVILEGES;" | mariadb -u root

    killall mysqld
    sleep 5
else
    echo ">> La base de datos ya existe, saltando inicialización."
fi

echo ">> Lanzando servidor MariaDB..."
exec mysqld
