FROM php:5.4-apache

# Install required extension/packages
RUN apt-get update && apt-get install -y --no-install-recommends \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libmcrypt-dev \
        libpng-dev \
        libtidy-dev \
        libxml2-dev \
        libxslt1-dev \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libmcrypt-dev \
        libpng-dev \
        libbz2-dev \
        libcurl4-gnutls-dev \
        libxml2-dev \
        libenchant-dev \
        libssl-dev \
        libc-client-dev \
        libkrb5-dev \
        zlib1g-dev \
        libicu-dev \
        g++ \
        git \
        libsqlite3-dev \
        libpspell-dev \
        libreadline-dev \
        libedit-dev \
        librecode-dev \
        libsnmp-dev \
        libsnmp30 \
        libtidy-dev \
        libxslt1.1 \
        libxslt1-dev \
        ssmtp \
        snmp \
        libgmp-dev \
        libldb-dev \
        libldap2-dev \
        libsodium-dev \
        gnupg2 \
        wget \
        freetds-bin \
        freetds-dev \
        freetds-common \
        libsybdb5 \
        libmemcached-dev \
        zlib1g-dev \
        pslib-dev \
        libmagickwand-dev \
        libmagickcore-dev \
    && docker-php-ext-install \
        iconv mcrypt tidy xmlrpc xsl gettext mbstring \
        intl mysql mysqli pspell recode snmp \
        bcmath bz2 calendar ctype dba dom exif fileinfo ftp \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install gd \
    && docker-php-ext-configure imap --with-kerberos --with-imap-ssl \
    && docker-php-ext-install imap \
    # For mssql and pdo modules
    && ln -s /usr/lib/x86_64-linux-gnu/libsybdb.so /usr/lib/ \
    && docker-php-ext-install pcntl mssql \
        pdo_dblib pdo_mysql shmop soap sockets sysvmsg \
        sysvsem sysvshm wddx zip \
    && pecl install apc-3.1.13 \
    && pecl install memcached-2.1.0 \
    && pecl install memcache-3.0.6 \
    && pecl install ps-1.3.7 \
    && docker-php-ext-enable memcached memcache apc ps \
    && pecl install imagick-3.3.0 \
    && docker-php-ext-enable imagick \
    && pecl install mysqlnd_ms-1.5.2 \
    && docker-php-ext-enable mysqlnd_ms \
    && a2enmod rewrite
