FROM debian:bullseye

# Instalar PHP, MariaDB client, wp-cli y herramientas necesarias
RUN apt-get update && apt-get install -y \
    php php-fpm php-mysql curl wget mariadb-client unzip less iputils-ping procps \
 && rm -rf /var/lib/apt/lists/*

# Descargar y mover WordPress
RUN mkdir -p /var/www/html && \
    curl -o wordpress.tar.gz https://wordpress.org/latest.tar.gz && \
    tar -xzf wordpress.tar.gz && \
    rm wordpress.tar.gz && \
    mv wordpress/* /var/www/html && \
    chown -R www-data:www-data /var/www/html

# Instalar wp-cli
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
    chmod +x wp-cli.phar && \
    mv wp-cli.phar /usr/local/bin/wp

# Copiar script de inicialización
COPY ./tools/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Cambiar php-fpm para que escuche en 0.0.0.0:9000 (TCP)
RUN sed -i 's|^listen = .*|listen = 0.0.0.0:9000|' /etc/php/7.4/fpm/pool.d/www.conf


EXPOSE 9000

ENTRYPOINT ["/entrypoint.sh"]
