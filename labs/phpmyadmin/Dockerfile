FROM php:8.4.26-apache

RUN apt-get update && apt-get install -y --no-install-recommends \
    libpng-dev libjpeg62-turbo-dev libfreetype6-dev libzip-dev \
    libonig-dev libxml2-dev unzip curl \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
        mysqli mbstring xml zip gd opcache \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN a2enmod rewrite

ENV PMA_VERSION=5.2.2
RUN curl -o /tmp/pma.tar.gz \
        https://files.phpmyadmin.net/phpMyAdmin/${PMA_VERSION}/phpMyAdmin-${PMA_VERSION}-all-languages.tar.gz \
    && tar -xzf /tmp/pma.tar.gz -C /var/www/html --strip-components=1 \
    && rm /tmp/pma.tar.gz \
    && chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html

COPY php.ini /usr/local/etc/php/conf.d/zz-php2shell.ini
COPY apache.conf /etc/apache2/conf-enabled/zz-php2shell.conf
COPY config.inc.php /var/www/html/config.inc.php

RUN cp /usr/local/etc/php/php.ini-production /usr/local/etc/php/php.ini \
    && mkdir -p /var/www/html/tmp && chown www-data:www-data /var/www/html/tmp

CMD ["apache2-foreground"]
