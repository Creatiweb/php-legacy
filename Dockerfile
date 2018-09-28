FROM buildpack-deps:jessie
#MAINTAINER Eugene Ware <eugene@noblesamurai.com>

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
        apache2-bin \
        apache2-dev \
        apache2.2-common \
    && apt-get clean \
    && rm -r /var/lib/apt/lists/*

##<apache2>##
RUN rm -rf /var/www/html && mkdir -p /var/lock/apache2 /var/run/apache2 /var/log/apache2 /var/www/html && chown -R www-data:www-data /var/lock/apache2 /var/run/apache2 /var/log/apache2 /var/www/html

# Apache + PHP requires preforking Apache for best results
RUN a2dismod mpm_event && a2enmod mpm_prefork

RUN mv /etc/apache2/apache2.conf /etc/apache2/apache2.conf.dist
COPY docker-files/apache2.conf /etc/apache2/apache2.conf
##</apache2>##

RUN gpg --keyserver pgp.mit.edu --recv-keys 0B96609E270F565C13292B24C13C70B87267B52D 0A95E9A026542D53835E3F3A7DEC4E69FC9C83D7

ENV GPG_KEYS 0B96609E270F565C13292B24C13C70B87267B52D 0A95E9A026542D53835E3F3A7DEC4E69FC9C83D7 0E604491
RUN set -xe \
  && for key in $GPG_KEYS; do \
    gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$key"; \
  done

# compile openssl, otherwise --with-openssl won't work
RUN CFLAGS="-fPIC" && OPENSSL_VERSION="1.0.2d" \
      && cd /tmp \
      && mkdir openssl \
      && curl -sL "https://www.openssl.org/source/openssl-$OPENSSL_VERSION.tar.gz" -o openssl.tar.gz \
      && curl -sL "https://www.openssl.org/source/openssl-$OPENSSL_VERSION.tar.gz.asc" -o openssl.tar.gz.asc \
      && gpg --verify openssl.tar.gz.asc \
      && tar -xzf openssl.tar.gz -C openssl --strip-components=1 \
      && cd /tmp/openssl \
      && ./config shared && make && make install \
      && rm -rf /tmp/*

ENV PHP_VERSION 5.3.29

ENV PHP_INI_DIR /usr/local/lib
RUN mkdir -p $PHP_INI_DIR/conf.d

# php 5.3 needs older autoconf
RUN set -x \
	&& apt-get update \
        && apt-get install -y autoconf2.13 \
        && apt-get clean \
        && rm -r /var/lib/apt/lists/* \
	&& curl -SLO http://launchpadlibrarian.net/140087283/libbison-dev_2.7.1.dfsg-1_amd64.deb \
	&& curl -SLO http://launchpadlibrarian.net/140087282/bison_2.7.1.dfsg-1_amd64.deb \
	&& dpkg -i libbison-dev_2.7.1.dfsg-1_amd64.deb \
	&& dpkg -i bison_2.7.1.dfsg-1_amd64.deb \
	&& rm *.deb \
	&& curl -SL "http://php.net/get/php-$PHP_VERSION.tar.bz2/from/this/mirror" -o php.tar.bz2 \
	&& curl -SL "http://php.net/get/php-$PHP_VERSION.tar.bz2.asc/from/this/mirror" -o php.tar.bz2.asc \
	&& gpg --verify php.tar.bz2.asc \
	&& mkdir -p /usr/src/php \
	&& tar -xf php.tar.bz2 -C /usr/src/php --strip-components=1 \
	&& rm php.tar.bz2* \
	&& cd /usr/src/php \
	&& ./buildconf --force \
	&& ./configure --disable-cgi --enable-calendar \
		$(command -v apxs2 > /dev/null 2>&1 && echo '--with-apxs2' || true) \
    --with-config-file-path="$PHP_INI_DIR" \
    --with-config-file-scan-dir="$PHP_INI_DIR/conf.d" \
		--with-mysql \
		--with-mysqli \
		--with-pdo-mysql \
		--with-openssl=/usr/local/ssl \
	&& make -j"$(nproc)" \
	&& make install \
	&& dpkg -r bison libbison-dev \
	&& apt-get purge -y --auto-remove autoconf2.13 \
  && make clean

COPY docker-files/docker-php-* /usr/local/bin/
COPY docker-files/apache2-foreground /usr/local/bin/
COPY docker-files/docker-php-ext-mcrypt.ini /usr/local/etc/php/conf.d/

RUN mkdir /usr/include/freetype2/freetype \
    && ln -s /usr/include/freetype2/freetype.h /usr/include/freetype2/freetype/freetype.h \
    && docker-php-ext-configure mcrypt \
    && docker-php-ext-install \
        iconv mcrypt tidy xmlrpc xsl gettext mbstring \
        intl mysql mysqli pspell recode snmp \
        bcmath bz2 calendar ctype dba dom exif fileinfo ftp \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install gd \
    && docker-php-ext-configure imap --with-kerberos --with-imap-ssl \
    && docker-php-ext-install imap \
    # Necessario per far funzionare mssql e i moduli pdo
    && ln -s /usr/lib/x86_64-linux-gnu/libsybdb.so /usr/lib/ \
    && docker-php-ext-install pcntl mssql \
        pdo_dblib pdo_mysql shmop soap sockets sysvmsg \
        sysvsem sysvshm wddx zip \
    && pecl install apc-3.1.13 \
    # Nota: la versione originale di memcached era la 2.0.1 ma dava errore di compilazione.
    && pecl install memcached-2.1.0 \
    && pecl install memcache-3.0.6 \
    && pecl install ps-1.3.7 \
    && docker-php-ext-enable memcached memcache apc ps \
    # Era 3.1.0 in origine, ma non funziona nessuna versione prima della 3.3.0.
    && pecl install imagick-3.3.0 \
    && docker-php-ext-enable imagick \
    && a2enmod rewrite

# docker entrypoint scripts
COPY docker-files/docker-php-entrypoint /usr/local/bin/
RUN mkdir -p /docker-entrypoint.d
COPY docker-files/docker-entrypoint.d/* /docker-entrypoint.d/
RUN chmod 755 /usr/local/bin/docker-php-entrypoint /docker-entrypoint.d/*

ENTRYPOINT ["docker-php-entrypoint"]
WORKDIR /var/www/html

EXPOSE 80
CMD ["apache2-foreground"]
