#!/bin/bash
set -e

echo ">> Starting WordPress entrypoint..."

# echo "A ver si está la chota.."
# cat /var/www/html/wp-config.php

# Database connection check
echo ">> Waiting for MariaDB..."
for i in {1..30}; do
    if mariadb -h mariadb -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" -e "SHOW DATABASES;" &> /dev/null; then
        echo ">> MariaDB is ready."
        break
    fi
    echo "   ➜ Attempt $i failed... retrying..."
    sleep 1
done

# wp-config.php generation
if [ ! -f "/var/www/html/wp-config.php" ]; then
    echo ">> Generating wp-config.php..."
    
    cat << EOF > /var/www/html/wp-config.php
<?php
define( 'DB_NAME', '${MYSQL_DATABASE}' );
define( 'DB_USER', '${MYSQL_USER}' );
define( 'DB_PASSWORD', '${MYSQL_PASSWORD}' );
define( 'DB_HOST', 'mariadb' );
define( 'DB_CHARSET', 'utf8' );
define( 'DB_COLLATE', '' );
define('FS_METHOD','direct');

define('FORCE_SSL_ADMIN', true);
if (isset(\$_SERVER['HTTP_X_FORWARDED_PROTO']) && \$_SERVER['HTTP_X_FORWARDED_PROTO'] == 'https') {
    \$_SERVER['HTTPS'] = 'on';
}

$(curl -s https://api.wordpress.org/secret-key/1.1/salt/)

\$table_prefix = 'wp_';
define( 'WP_DEBUG', false );
if ( ! defined( 'ABSPATH' ) ) {
    define( 'ABSPATH', __DIR__ . '/' );
}
require_once ABSPATH . 'wp-settings.php';
EOF

    chown www-data:www-data /var/www/html/wp-config.php
    echo ">> wp-config.php created successfully."
else
    echo ">> wp-config.php already exists."
fi

# WordPress installation
if ! wp core is-installed --path="/var/www/html" --allow-root; then
    echo ">> Installing WordPress..."
    
    wp core install \
        --url="$WP_URL" \
        --title="$WP_TITLE" \
        --admin_user="$WP_ADMIN_USER" \
        --admin_password="$WP_ADMIN_PASSWORD" \
        --admin_email="$WP_ADMIN_EMAIL" \
        --path="/var/www/html" \
        --allow-root
    
    echo ">> WordPress installed successfully."
else
    echo ">> WordPress is already installed."
fi

# Fix permissions
echo ">> Setting permissions..."
chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html
mkdir -p /var/lib/php/sessions
chown -R www-data:www-data /var/lib/php/sessions

echo ">> Preparing PHP-FPM environment..."
mkdir -p /run/php /var/lib/php/sessions
chown -R www-data:www-data /run/php /var/lib/php/sessions
chmod -R 775 /run/php

# Start PHP-FPM
echo ">> Starting PHP-FPM..."
exec php-fpm7.4 -F