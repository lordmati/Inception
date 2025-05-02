FROM debian:bullseye

RUN apt-get update && apt-get install -y mariadb-server

# Crear el directorio del socket y asignar permisos correctos
RUN mkdir -p /run/mysqld && chown -R mysql:mysql /run/mysqld

# ⚠️ Importante: limpiar contenido que MariaDB podría haber generado
RUN rm -rf /var/lib/mysql/*

# Copiar el SQL base y el entrypoint personalizado
COPY ./conf/init.sql /init.sql
COPY ./tools/entrypoint.sh /entrypoint.sh

# Cambiar el bind-address a 0.0.0.0 para aceptar conexiones externas
RUN sed -i 's/^bind-address\s*=.*/bind-address = 0.0.0.0/' /etc/mysql/mariadb.conf.d/50-server.cnf


# Hacer ejecutable el script
RUN chmod +x /entrypoint.sh

EXPOSE 3306

# Usar el script como punto de entrada
ENTRYPOINT ["/entrypoint.sh"]
