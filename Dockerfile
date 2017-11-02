FROM php:5.6-apache
MAINTAINER Klinnex

#ENV PHPIPAM_SOURCE https://github.com/phpipam/phpipam/archive/
ENV PHPIPAM_VERSION 1.3
ENV WEB_REPO /var/www/html

# Install apt-utils before other packages
RUN apt-get update && \
    apt-get install -y apt-utils
    
# Install required deb packages
RUN apt-get update && \
    apt-get install -y\
    dialog\
    git\
    php-pear\
    nmap\
    php5-curl\
    php5-mysql\
    php5-json\
    php5-gmp\
    php5-mcrypt\
    php5-ldap\
    php5-gd\
    php-net-socket\
    libgmp-dev\
    libmcrypt-dev\
    libpng12-dev\
    libfreetype6-dev\
    libjpeg-dev\
    libpng-dev\
    libldap2-dev && \
    rm -rf /var/lib/apt/lists/*

# Install ssl-cert for autogenerate ssl certificates

RUN apt-get update && \
        apt-get install -y ssl-cert

# Configure apache and required PHP modules
RUN docker-php-ext-configure mysqli --with-mysqli=mysqlnd && \
    docker-php-ext-install mysqli && \
    docker-php-ext-configure gd --enable-gd-native-ttf --with-freetype-dir=/usr/include/freetype2 --with-png-dir=/usr/include --with-jpeg-dir=/usr/include && \
    docker-php-ext-install gd && \
    docker-php-ext-install sockets && \
    docker-php-ext-install pdo_mysql && \
    docker-php-ext-install gettext && \
    ln -s /usr/include/x86_64-linux-gnu/gmp.h /usr/include/gmp.h && \
    docker-php-ext-configure gmp --with-gmp=/usr/include/x86_64-linux-gnu && \
    docker-php-ext-install gmp && \
    docker-php-ext-install mcrypt && \
    docker-php-ext-install pcntl && \
    docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu && \
    docker-php-ext-install ldap && \
    echo ". /etc/environment" >> /etc/apache2/envvars && \
    a2enmod rewrite && \
		a2enmod ssl && \
    a2ensite default-ssl
        
#COPY php.ini /usr/local/etc/php/

# copy phpipam sources to web dir
RUN git clone https://github.com/phpipam/phpipam.git ${WEB_REPO} &&\
    cd ${WEB_REPO} &&\
    git checkout ${PHPIPAM_VERSION} &&\
    git submodule update --init --recursive &&\
# Use system environment variables into config.php
# use MYSQL ENV MYSQL receive on docker-compose
    cp ${WEB_REPO}/config.dist.php ${WEB_REPO}/config.php && \
    sed -i -e "s/\['host'\] = 'localhost'/\['host'\] = 'mysql'/" \
    -e "s/\['user'\] = 'phpipam'/\['user'\] = 'root'/" \
    -e "s/\['pass'\] = 'phpipamadmin'/\['pass'\] = getenv(\"MYSQL_ENV_MYSQL_ROOT_PASSWORD\")/" \
    ${WEB_REPO}/config.php && \
    sed -i -e "s/\['port'\] = 3306;/\['port'\] = 3306;\n\n\$password_file = getenv(\"MYSQL_ENV_MYSQL_ROOT_PASSWORD\");\nif(file_exists(\$password_file))\n\$db\['pass'\] = preg_replace(\"\/\\\\s+\/\", \"\", file_get_contents(\$password_file));/" \
    ${WEB_REPO}/config.php && \
    echo "date_default_timezone_set(getenv('TIMEZONE'));" >> ${WEB_REPO}/config.php

EXPOSE 443
