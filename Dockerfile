FROM debian:6
MAINTAINER Massimiliano Ferrero <m.ferrero@cognitio.it>

ADD sources.list /etc/apt/sources.list

RUN apt-get -o Acquire::Check-Valid-Until=false update \
    && apt-get -o Acquire::Check-Valid-Until=false -y --force-yes install vim openssl php5 \
         php5-imap php5-mysql php5-gd php5-imap php5-intl php5-mcrypt php5-pspell php5-recode \
         php5-snmp php5-tidy php5-xsl php-apc php5-memcache php5-memcached php5-ps php5-imagick \
         php-soap php5-adodb php5-sybase php5-odbc php5-curl php5-gmp \
    && apt-get clean \
    && rm -r /var/lib/apt/lists/*

RUN a2enmod rewrite
RUN a2enmod headers

RUN rm -f /var/www/index.html
RUN mkdir -p /var/www/html
ADD apache/default /etc/apache2/sites-available/default

# docker entrypoint scripts
COPY docker-files/docker-php-entrypoint /usr/local/bin/
COPY docker-files/apache2-foreground /usr/local/bin/
RUN mkdir -p /docker-entrypoint.d
COPY docker-files/docker-entrypoint.d/* /docker-entrypoint.d/
RUN chmod 755 /usr/local/bin/docker-php-entrypoint /usr/local/bin/apache2-foreground /docker-entrypoint.d/*

ENTRYPOINT ["docker-php-entrypoint"]
WORKDIR /var/www/html

EXPOSE 80
CMD ["apache2-foreground"]
