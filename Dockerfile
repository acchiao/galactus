# syntax=docker/dockerfile:1
FROM composer:2.2.7 AS composer

ENV COMPOSER_HOME=/app

WORKDIR ${COMPOSER_HOME}

COPY composer.json composer.lock ${COMPOSER_HOME}/

RUN --mount=type=secret,id=auth,dst=${COMPOSER_HOME}/auth.json \
    composer install \
          --ignore-platform-reqs \
          --prefer-dist \
          --optimize-autoloader \
          --classmap-authoritative \
          --apcu-autoloader \
          --no-dev \
          --no-scripts \
          --no-interaction \
          --no-progress \
      && composer clear-cache

FROM node:lts-gallium AS builder

ENV GALACTUS_HOME=/app

WORKDIR ${GALACTUS_HOME}

COPY --from=composer /app/vendor /app/vendor
COPY package.json yarn.lock ${GALACTUS_HOME}/

RUN yarn install --frozen-lockfile --ignore-scripts --check-files \
      && yarn cache clean --all

COPY webpack.mix.js tailwind.config.js ${GALACTUS_HOME}/
COPY app/ ${GALACTUS_HOME}/app/
COPY public/ ${GALACTUS_HOME}/public/
COPY resources/ ${GALACTUS_HOME}/resources/

RUN yarn run production

FROM php:8.3-fpm-bullseye AS app

ARG GROUP_ID=1000
ARG USER_ID=1000
ARG USER=galactus

ENV DEBIAN_FRONTEND noninteractive

COPY --from=composer /app/vendor /app/vendor

RUN apt-get update \
      && apt-get --yes install --no-install-recommends \
        curl \
        git \
        libonig-dev \
        libpng-dev \
        libpq-dev \
        libxml2-dev \
        libzip-dev \
        unzip \
        zip \
        zlib1g-dev \
      && rm -rf /var/lib/apt/lists/*

RUN pecl channel-update pecl.php.net \
      && pecl install --onlyreqdeps --force redis-5.3.7 \
      && pecl clear-cache \
      && docker-php-ext-configure intl \
      && docker-php-ext-configure opcache \
      && docker-php-ext-configure zip \
      && docker-php-ext-install -j$(nproc) \
        bcmath \
        ctype \
        intl \
        opcache \
        pdo \
        pdo_pgsql \
        zip \
      && docker-php-ext-enable redis \
      && docker-php-ext-enable opcache \
      && docker-php-source delete

RUN groupadd --force -g ${GROUP_ID} ${USER}
RUN useradd --system --create-home --no-log-init --shell /bin/bash --no-user-group --gid ${GROUP_ID} --uid ${USER_ID} ${USER}

USER ${USER}

EXPOSE 8000
