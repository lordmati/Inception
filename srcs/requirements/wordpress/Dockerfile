FROM debian:bullseye

# Instalar dependencias y limpiar caché
RUN apt-get update && apt-get install -y \
    php-fpm \
    php-mysql \
    php-curl \
    php-gd \
    php-mbstring \
    php-xml \
    php-xmlrpc \
    php-soap \
    php-intl \
    php-zip \
    curl \
    tar \
    mariadb-client \
    wget \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Crear directorio para WordPress
RUN mkdir -p /var/www/html

# Descargar e instalar WordPress
RUN curl -o wordpress.tar.gz https://wordpress.org/latest.tar.gz && \
    tar -xzf wordpress.tar.gz -C /var/www/html --strip-components=1 && \
    rm wordpress.tar.gz && \
    chown -R www-data:www-data /var/www/html

# Configurar PHP-FPM
RUN sed -i 's/listen = \/run\/php\/php7.4-fpm.sock/listen = 0.0.0.0:9000/g' /etc/php/*/fpm/pool.d/www.conf && \
    sed -i 's/;listen.allowed_clients/listen.allowed_clients/g' /etc/php/*/fpm/pool.d/www.conf

# Copiar el entrypoint
COPY ./tools/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Health check opcional
HEALTHCHECK --interval=30s --timeout=3s \
    CMD curl -f http://localhost/wp-includes/js/jquery/jquery.js || exit 1

EXPOSE 9000

WORKDIR /var/www/html

ENTRYPOINT ["/entrypoint.sh"]
