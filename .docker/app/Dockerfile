ARG version_php

FROM php:${version_php}-fpm
ARG version_php
ARG version_xdebug
ARG version_node
ARG host_uid
ARG host_gid
ENV VERSION_XDEBUG=${version_xdebug}
ENV VERSION_NODE=${version_node}

RUN apt-get update \
    && apt-get install -y \
        git \
        libicu-dev \
        libzip-dev \
        procps \
        rsync \
        unzip \
        sudo

RUN addgroup --gid ${host_gid} nextcloud \
    && adduser --uid ${host_uid} --ingroup nextcloud nextcloud \
    && sed -i "/user =/c\user = nextcloud" /usr/local/etc/php-fpm.d/www.conf \
    && sed -i "/group =/c\group = nextcloud" /usr/local/etc/php-fpm.d/www.conf

# RUN usermod --non-unique --uid ${host_uid} www-data \
#     && groupmod --non-unique --gid ${host_gid} www-data

RUN mv "$PHP_INI_DIR/php.ini-development" "$PHP_INI_DIR/php.ini"

# Install extensions
ADD https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/
RUN chmod uga+x /usr/local/bin/install-php-extensions && sync \
    && install-php-extensions \
    pdo \
    pdo_pgsql \
    pgsql \
    pdo_mysql \
    mysqli \
    apcu \
    bcmath \
    gd \
    gmp \
    imagick \
    intl \
    memcached \
    opcache \
    pcntl \
    redis \
    sockets \
    sysvsem \
    xdebug \
    zip \
    # Configure Imagick
    && sed -i'' 's|.*<policy domain="coder".*"PDF".*|<policy domain="coder" rights="read \| write" pattern="PDF" />|g' /etc/ImageMagick-6/policy.xml \
    && rm /usr/local/bin/install-php-extensions

USER nextcloud

# Install node
ENV NVM_DIR=/home/nextcloud/.nvm
RUN git clone https://github.com/nvm-sh/nvm.git $NVM_DIR \
    && cd $NVM_DIR \
    && git checkout `git describe --abbrev=0 --tags --match "v[0-9]*" $(git rev-list --tags --max-count=1)` \
    && . $NVM_DIR/nvm.sh \
    && nvm install ${VERSION_NODE} \
    && nvm use node \
    && npm install --global npm@8 \
    && npm install --global webpack \
    && npm install --global webpack-cli \
    && echo "source ${NVM_DIR}/nvm.sh" > /home/nextcloud/.bashrc

USER root

COPY --from=composer /usr/bin/composer /usr/bin/composer

COPY config/php.ini /usr/local/etc/php/conf.d/

WORKDIR /nextcloud
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
ENTRYPOINT [ "bash", "/usr/local/bin/entrypoint.sh" ]
