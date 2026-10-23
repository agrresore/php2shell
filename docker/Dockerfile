FROM php:8.4.26-apache

COPY www/index.php /var/www/html/index.php
COPY php.ini /usr/local/etc/php/conf.d/zz-php2shell.ini
COPY apache.conf /etc/apache2/conf-enabled/zz-php2shell.conf

RUN cp /usr/local/etc/php/php.ini-production /usr/local/etc/php/php.ini \
    && chown -R www-data:www-data /var/www/html \
    && chmod 755 /var/www/html \
    && a2enmod rewrite

CMD ["apache2-foreground"]
