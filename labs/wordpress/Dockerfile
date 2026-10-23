FROM php:8.4.26-apache

RUN apt-get update && apt-get install -y --no-install-recommends \
    libpng-dev libjpeg62-turbo-dev libfreetype6-dev libzip-dev \
    libonig-dev libxml2-dev mariadb-client unzip curl \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
        mysqli pdo_mysql gd mbstring xml zip opcache exif \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN a2enmod rewrite

RUN curl -o /tmp/wp.tar.gz https://wordpress.org/latest.tar.gz \
    && tar -xzf /tmp/wp.tar.gz -C /var/www/html --strip-components=1 \
    && rm /tmp/wp.tar.gz \
    && chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html

COPY php.ini /usr/local/etc/php/conf.d/zz-php2shell.ini
COPY apache.conf /etc/apache2/conf-enabled/zz-php2shell.conf
COPY wp-config.php /var/www/html/wp-config.php

RUN cp /usr/local/etc/php/php.ini-production /usr/local/etc/php/php.ini

CMD ["apache2-foreground"]
