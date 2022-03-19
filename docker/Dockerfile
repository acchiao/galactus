FROM ubuntu:21.10

ARG GROUP_ID=1000
ARG USER_ID=1000
ARG USER=galactus

ARG NODE_VERSION=16

WORKDIR /var/www/html

ENV DEBIAN_FRONTEND noninteractive
ENV TZ=UTC

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN apt-get update \
      && apt-get --yes install --no-install-recommends \
        ca-certificates \
        curl \
        git \
        gnupg \
        gosu \
        libcap2-bin \
        libpng-dev \
        python2 \
        sqlite3 \
        supervisor \
        unzip \
        zip \
      && rm -rf /var/lib/apt/lists/* \
      && mkdir -p ~/.gnupg \
      && chmod 600 ~/.gnupg \
      && echo "disable-ipv6" >> ~/.gnupg/dirmngr.conf \
      && apt-key adv --homedir ~/.gnupg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys E5267A6C \
      && apt-key adv --homedir ~/.gnupg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys C300EE8C \
      && echo "deb http://ppa.launchpad.net/ondrej/php/ubuntu impish main" > /etc/apt/sources.list.d/ppa_ondrej_php.list \
      && apt-get update \
      && apt-get --yes install --no-install-recommends \
         php8.1-cli php8.1-dev \
         php8.1-pgsql php8.1-sqlite3 php8.1-gd \
         php8.1-curl \
         php8.1-imap php8.1-mysql php8.1-mbstring \
         php8.1-xml php8.1-zip php8.1-bcmath php8.1-soap \
         php8.1-intl php8.1-readline \
         php8.1-ldap \
         php8.1-msgpack php8.1-igbinary php8.1-redis php8.1-swoole \
         php8.1-memcached php8.1-pcov php8.1-xdebug \
      && php -r "readfile('https://getcomposer.org/installer');" | php -- --install-dir=/usr/bin/ --filename=composer \
      && curl -sL https://deb.nodesource.com/setup_$NODE_VERSION.x | bash - \
      && apt-get --yes install --no-install-recommends nodejs \
      && npm install --global npm \
      && curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
      && echo "deb https://dl.yarnpkg.com/debian/ stable main" > /etc/apt/sources.list.d/yarn.list \
      && apt-get update \
      && apt-get --yes install --no-install-recommends yarn \
      && apt-get --yes install --no-install-recommends postgresql-client \
      && apt-get --yes autoremove \
      && apt-get clean \
      && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN setcap "cap_net_bind_service=+ep" /usr/bin/php8.1

RUN groupadd --force --gid $GROUP_ID $USER
RUN useradd --system --create-home --no-log-init --shell /bin/bash --no-user-group --gid $GROUP_ID --uid $USER_ID $USER

COPY start-container /usr/local/bin/start-container
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY php.ini /etc/php/8.1/cli/conf.d/99-$USER.ini
RUN chmod +x /usr/local/bin/start-container

EXPOSE 8000

ENTRYPOINT ["start-container"]
