#!/bin/sh

########################################################################################################################
#
# Copyright (c) 2015 DD Art Tomasz Duda
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
########################################################################################################################
sudo apt-get update
sudo apt-get upgrade -y


# HTOP #################################################################################################################
sudo apt-get install -y htop


# LINKS ################################################################################################################
sudo apt-get install -y links


# GIT ##################################################################################################################
sudo add-apt-repository ppa:git-core/ppa -y && sudo apt-key update
sudo apt-get update && sudo apt-get install -y git
ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa
eval `ssh-agent -s`
sudo ssh-add ~/.ssh/id_rsa


# RUBY #################################################################################################################
sudo apt-get remove -y ruby
sudo apt-add-repository ppa:brightbox/ruby-ng -y && sudo apt-key update
sudo apt-get update && sudo apt-get install -y ruby2.2


# NODEJS ###############################################################################################################
sudo add-apt-repository ppa:chris-lea/node.js -y && sudo apt-key update
sudo apt-get update && sudo apt-get install -y nodejs
sudo npm install npm -g


# YEOMAN ###############################################################################################################
sudo npm install -g yo bower grunt-cli gulp


# APACHE ###############################################################################################################
sudo add-apt-repository ppa:ondrej/apache2 -y && sudo apt-key update
sudo apt-get update && sudo apt-get install -y apache2 apache2-mpm-worker
sudo bash -c "echo 'ServerName localhost' >> /etc/apache2/apache2.conf"
sudo rm /var/www/html/index.html
sudo bash -c "echo '<?php phpinfo();' >> /var/www/html/index.php"


# PHP ##################################################################################################################
sudo add-apt-repository ppa:ondrej/php5-5.6 -y && sudo apt-key update
multiverse="
    deb http://archive.ubuntu.com/ubuntu trusty multiverse
    deb http://archive.ubuntu.com/ubuntu trusty-updates multiverse
    deb http://security.ubuntu.com/ubuntu trusty-security multiverse
"
sudo bash -c "echo '${multiverse}' > /etc/apt/sources.list.d/trusty.multiverse.list"
sudo apt-get update && sudo apt-get install -y libapache2-mod-fastcgi php5-fpm php5 php5-cli php5-common
sudo bash -c "echo '' >> /etc/apache2/mods-available/fastcgi.conf"
fcgi="
    <IfModule mod_fastcgi.c>
        AddHandler php5-fcgi .php
        Action php5-fcgi /php5-fcgi
        Alias /php5-fcgi /usr/lib/cgi-bin/php5-fcgi
        FastCgiExternalServer /usr/lib/cgi-bin/php5-fcgi -socket /var/run/php5-fpm.sock -pass-header Authorization
        <Directory /usr/lib/cgi-bin>
            Require all granted
        </Directory>
    </Ifmodule>
"
sudo bash -c "echo '${fcgi}' > /etc/apache2/conf-available/php5-fpm.conf"
sudo a2enmod actions fastcgi alias
sudo a2enconf php5-fpm


# CURL #################################################################################################################
sudo apt-get install -y curl php5-curl


# SSL/TLS ##############################################################################################################
sudo apt-get install -y openssl
sudo a2enmod ssl
sudo mkdir /etc/apache2/ssl
sudo openssl genrsa -des3 -passout pass:"123" -out /etc/apache2/ssl/server.key 2048 -noout
sudo openssl rsa -in /etc/apache2/ssl/server.key -passin pass:"123" -out /etc/apache2/ssl/server.key
sudo openssl req -new -key /etc/apache2/ssl/server.key -out /etc/apache2/ssl/server.csr -passin pass:"123" \
    -subj "/C=PL/ST=LOCAL/L=LOCAL/O=LOCAL/OU=LOCAL/CN=localhost/emailAddress=admin@localhost"
sudo openssl x509 -req -days 365 -in /etc/apache2/ssl/server.csr -signkey /etc/apache2/ssl/server.key \
    -out /etc/apache2/ssl/server.crt
sudo sed -i 's/SSLProtocol all/SSLProtocol all -SSLv3/' /etc/apache2/mods-available/ssl.conf


# MCRYPT ###############################################################################################################
sudo apt-get install -y php5-mcrypt
sudo php5enmod mcrypt


# XDEBUG ###############################################################################################################
sudo apt-get install -y php5-xdebug
mkdir /var/www/xdebug
xdebug="
    zend_extension=xdebug.so
    xdebug.remote_enable = 1
    xdebug.remote_handler = \"dbgp\"
    xdebug.remote_connect_back = 1
    xdebug.remote_port = 9000
    xdebug.idekey = \"XDEBUG\"
    xdebug.profiler_enable_trigger = 1
    xdebug.profiler_output_dir = \"/var/www/xdebug\"
    xdebug.trace_enable_trigger = 1
    xdebug.trace_output_dir = \"/var/www/xdebug\"
    xdebug.max_nesting_level = 1000
"
sudo bash -c "echo '${xdebug}' > /etc/php5/fpm/conf.d/20-xdebug.ini"


# REWRITE ##############################################################################################################
sudo a2enmod rewrite


# VHOST ################################################################################################################
vhost="
    <VirtualHost *:80>
        DocumentRoot /var/www/html
        ErrorLog ${APACHE_LOG_DIR}/error.log
        CustomLog /dev/null common
        <Directory /var/www/html>
            Options Indexes FollowSymLinks MultiViews
            AllowOverride All
            Order Deny,Allow
            Allow from all
        </Directory>
    </VirtualHost>
    <VirtualHost _default_:443>
        DocumentRoot /var/www/html
        ErrorLog ${APACHE_LOG_DIR}/error.ssl.log
        CustomLog /dev/null common
        <Directory /var/www/html>
            Options Indexes FollowSymLinks MultiViews
            AllowOverride All
            Order Deny,Allow
            Allow from all
        </Directory>
        SSLEngine on
        SSLCertificateFile /etc/apache2/ssl/server.crt
        SSLCertificateKeyFile /etc/apache2/ssl/server.key
        SetEnvIf User-Agent “.*MSIE.*” nokeepalive ssl-unclean-shutdown
    </VirtualHost>
"
sudo bash -c "echo '${vhost}' > /etc/apache2/sites-available/000-default.conf"


# COMPOSER #############################################################################################################
sudo bash -c "curl -sS https://getcomposer.org/installer | php"
sudo mv composer.phar /usr/local/bin/composer


# SAAS #################################################################################################################
gem install sass


# MONGODB ##############################################################################################################
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 7F0CEB10
echo 'deb http://downloads-distro.mongodb.org/repo/ubuntu-upstart dist 10gen' \
 | sudo tee /etc/apt/sources.list.d/mongodb.list
sudo apt-get update
sudo apt-get install -y mongodb-org


# RESTART ##############################################################################################################
sudo service apache2 restart
sudo service php5-fpm restart