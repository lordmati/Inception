#!/bin/bash

set -e

echo ">> Entrando al entrypoint de MariaDB"

DB_PASS=$(cat /run/secrets/db_password)
ROOT_PASS=$(cat /run/secrets/db_root_password)

if [ ! -d /var/lib/mysql/mysql ]; then
    echo ">> Inicializando base de datos..."
    mariadb-install-db --user=mysql --basedir=/usr --datadir=/var/lib/mysql > /dev/null

    echo ">> Reemplazando variables en init.sql..."
    sed "s/__DB_NAME__/${MYSQL_DATABASE}/g; \
         s/__DB_USER__/${MYSQL_USER}/g; \
         s/__DB_PASS__/${DB_PASS}/g" /init.sql > /tmp/init.sql

    echo ">> Lanzando MariaDB en segundo plano..."
    mysqld --skip-networking --socket=/tmp/mysql.sock &
    pid="$!"

    echo ">> Esperando que MariaDB esté listo..."
    for i in {30..0}; do
        if mariadb -u root --socket=/tmp/mysql.sock -e "SELECT 1;" &> /dev/null; then
            break
        fi
        echo "   ➜ Esperando $i..."
        sleep 1
    done

    if [ "$i" = 0 ]; then
        echo "❌ Error: MariaDB no inició correctamente"
        exit 1
    fi

    echo ">> Ejecutando script de inicialización..."
    cat /tmp/init.sql
    mariadb -u root --socket=/tmp/mysql.sock < /tmp/init.sql


    echo ">> Configurando contraseña de root..."
    echo "ALTER USER 'root'@'localhost' IDENTIFIED BY '${ROOT_PASS}'; FLUSH PRIVILEGES;" | \
        mariadb -u root --socket=/tmp/mysql.sock

    echo ">> Deteniendo proceso temporal de MariaDB..."
    kill "$pid"
    wait "$pid"
else
    echo ">> La base de datos ya existe, saltando inicialización."
fi

echo ">> Lanzando servidor MariaDB..."
exec mysqld
