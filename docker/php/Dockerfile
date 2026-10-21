ARG PHP_VERSION=8.5
FROM composer:2 AS composer

FROM php:${PHP_VERSION}-fpm

COPY --from=composer /usr/bin/composer /usr/local/bin/composer

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends $PHPIZE_DEPS git unzip libonig-dev libxml2-dev libzip-dev; \
    docker-php-ext-install -j"$(nproc)" pdo_mysql mbstring xml zip; \
    pecl install xdebug; \
    docker-php-ext-enable xdebug; \
    apt-get purge -y --auto-remove $PHPIZE_DEPS; \
    rm -rf /var/lib/apt/lists/*

RUN cp /usr/local/etc/php/php.ini-development /usr/local/etc/php/php.ini

WORKDIR /var/www/html
USER www-data
