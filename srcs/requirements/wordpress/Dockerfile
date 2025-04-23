FROM debian:bullseye

RUN apt-get update && apt-get install -y \
    php php-fpm php-mysql curl wget mariadb-client unzip less

RUN apt-get update && apt-get install -y iputils-ping && rm -rf /var/lib/apt/lists/*

# COMPROBAR QUE PHP TENGO
RUN ls /usr/sbin/php-fpm*

# Crear carpeta destino antes de mover WordPress
RUN mkdir -p /var/www/html && \
    curl -o wordpress.tar.gz https://wordpress.org/latest.tar.gz && \
    tar -xzf wordpress.tar.gz && \
    rm wordpress.tar.gz && \
    mv wordpress/* /var/www/html && \
    chown -R www-data:www-data /var/www/html

COPY ./tools/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 9000

ENTRYPOINT ["/entrypoint.sh"]
