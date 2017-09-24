FROM php:5.6-apache
MAINTAINER Klinnex

# Install required deb packages
RUN apt-get update && \ 
	apt-get install -y\
	git\
	php-pear\
	php5-curl\
	php5-mysql\
	php5-json\
	php5-gmp\
	php5-mcrypt\
	php5-ldap\
	libpng-dev\
	libgmp-dev\
	libmcrypt-dev && \
	rm -rf /var/lib/apt/lists/*

# Configure apache and required PHP modules 
RUN docker-php-ext-configure mysqli --with-mysqli=mysqlnd && \
	docker-php-ext-install mysqli && \
	docker-php-ext-install pdo_mysql && \
	docker-php-ext-install pcntl && \
        docker-php-ext-install gettext && \ 
	docker-php-ext-install sockets && \
	docker-php-ext-install gd && \
	ln -s /usr/include/x86_64-linux-gnu/gmp.h /usr/include/gmp.h && \
	docker-php-ext-configure gmp --with-gmp=/usr/include/x86_64-linux-gnu && \
	docker-php-ext-install gmp && \
        docker-php-ext-install mcrypt && \
	echo ". /etc/environment" >> /etc/apache2/envvars && \
	a2enmod rewrite

ENV PHPIPAM_SOURCE "https://github.com/phpipam/phpipam/archive"
ENV PHPIPAM_VERSION "1.3"
ENV MYSQL_HOST "mysql"
ENV MYSQL_USER "phpipam"
ENV MYSQL_PASSWORD "phpipamadmin"
ENV MYSQL_DB "phpipam"
ENV MYSQL_PORT "3306"
ENV SSL "false"
ENV SSL_KEY "/path/to/cert.key"
ENV SSL_CERT "/path/to/cert.crt"
ENV SSL_CA "/path/to/ca.crt"
ENV SSL_CAPATH "/path/to/ca_certs"
ENV SSL_CIPHER "DHE-RSA-AES256-SHA:AES128-SHA"

COPY php.ini /usr/local/etc/php/


# copy phpipam sources to web dir
RUN echo "$PHPIPAM_SOURCE"/"$PHPIPAM_VERSION".tar.gz
ADD "$PHPIPAM_SOURCE"/"$PHPIPAM_VERSION".tar.gz /tmp/
RUN tar -xzf /tmp/$PHPIPAM_VERSION.tar.gz -C /var/www/html/ --strip-components=1 && \
    cp /var/www/html/config.dist.php /var/www/html/config.php

# Use system environment variables into config.php
RUN sed -i \ 
	-e "s/\['host'\] = 'localhost'/\['host'\] = \"$MYSQL_HOST"/" \ 
        -e "s/\['user'\] = 'phpipam'/\['user'\] = \"$MYSQL_USER"/" \ 
        -e "s/\['pass'\] = 'phpipamadmin'/\['pass'\] = \"$MYSQL_PASSWORD"/" \ 
        -e "s/\['name'\] = 'phpipam'/\['name'\] = \"$MYSQL_DB"/" \ 
        -e "s/\['port'\] = 3306/\['port'\] = \"$MYSQL_PORT"/" \ 
        -e "s/\['ssl'\] *= false/\['ssl'\] = $SSL" \ 
#        -e "s/\['ssl_key'\] *= \"\/path\/to\/cert.key\"/['ssl_key'\] = $SSL_KEY/" \ 
#        -e "s/\['ssl_cert'\] *= \"\/path\/to\/cert.crt\"/['ssl_cert'\] = $SSL_CERT/" \ 
#        -e "s/\['ssl_ca'\] *= \"\/path\/to\/ca.crt\"/['ssl_ca'\] = $SSL_CA/" \ 
#        -e "s/\['ssl_capath'\] *= \"\/path\/to\/ca_certs\"/['ssl_capath'\] = $SSL_CAPATH/" \ 
#        -e "s/\['ssl_cipher'\] *= \"DHE-RSA-AES256-SHA:AES128-SHA\"/['ssl_cipher'\] = $SSL_CIPHER/" \
        /var/www/html/config.php


EXPOSE 80
