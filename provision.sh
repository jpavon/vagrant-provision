#!/usr/bin/env bash

# Config
ENVIRONMENT="development" # "development" or "production"
WEBSERVER="nginx" # "apache" or "nginx"
SERVERNAME="192.168.33.10.xip.io"
DOCUMENTPUBLICROOT="/vagrant/test/public"
DOCUMENTROOT="/vagrant/test"
MYSQLPASSWORD="123456"







echo ">>> Installing Base Packages"

# Update
sudo apt-get update

# Install base packages
sudo apt-get install -y unzip git-core ack-grep vim tmux curl wget build-essential python-software-properties









echo ">>> Installing PHP"

sudo add-apt-repository -y ppa:ondrej/php5

sudo apt-get update

# Install PHP
sudo apt-get install -y php5-cli php5-fpm php5-mysql php5-pgsql php5-sqlite php5-curl php5-gd php5-gmp php5-mcrypt php5-xdebug php5-memcached php5-imagick php5-intl


# PHP Error Reporting Config
sed -i "s/log_errors = .*/log_errors = On/" /etc/php5/fpm/php.ini
sed -i "s/error_reporting = .*/error_reporting = E_ALL/" /etc/php5/fpm/php.ini

if [ $ENVIRONMENT == "development" ]; then
    sed -i "s/display_errors = .*/display_errors = On/" /etc/php5/fpm/php.ini
    sed -i "s/display_startup_errors = .*/display_startup_errors = On/" /etc/php5/fpm/php.ini
    sed -i "s/html_errors = .*/html_errors = On/" /etc/php5/fpm/php.ini
fi

if [ $ENVIRONMENT == "production" ]; then
    sed -i "s/display_errors = .*/display_errors = Off/" /etc/php5/fpm/php.ini
    sed -i "s/display_startup_errors = .*/display_startup_errors = Off/" /etc/php5/fpm/php.ini
    sed -i "s/html_errors = .*/html_errors = Off/" /etc/php5/fpm/php.ini
fi

sudo service php5-fpm restart









if [ $WEBSERVER == "apache" ]; then

echo ">>> Installing Apache Server"

# Add repo for latest FULL stable Apache
# (Required to remove conflicts with PHP PPA due to partial Apache upgrade within it)
sudo add-apt-repository -y ppa:ondrej/apache2

# Update Again
sudo apt-get update

# Install Apache
sudo apt-get install -y apache2-mpm-event libapache2-mod-fastcgi

echo ">>> Configuring Apache"

# Apache Config
sudo a2enmod actions autoindex deflate expires filter headers include mime rewrite setenvif

cat > /etc/apache2/sites-available/${SERVERNAME}.conf << EOF
<VirtualHost *:80>
    ServerAdmin webmaster@localhost
    ServerName $SERVERNAME

    DocumentRoot $DOCUMENTPUBLICROOT

    <Directory $DOCUMENTPUBLICROOT>
        Options -Indexes +FollowSymLinks +MultiViews
        AllowOverride All
        Order allow,deny
        Allow from all
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/$SERVERNAME-error.log

    # Possible values include: debug, info, notice, warn, error, crit,
    # alert, emerg.
    LogLevel warn

    CustomLog \${APACHE_LOG_DIR}/$SERVERNAME-access.log combined


</VirtualHost>
EOF

if [ ! -d $DOCUMENTPUBLICROOT ]; then
    mkdir -p $DOCUMENTPUBLICROOT
fi

cd /etc/apache2/sites-available/ && a2ensite ${SERVERNAME}.conf
service apache2 reload


# PHP Config for Apache
cat > /etc/apache2/conf-available/php5-fpm.conf << EOF
<IfModule mod_fastcgi.c>
    AddHandler php5-fcgi .php
    Action php5-fcgi /php5-fcgi
    Alias /php5-fcgi /usr/lib/cgi-bin/php5-fcgi
    FastCgiExternalServer /usr/lib/cgi-bin/php5-fcgi -socket /var/run/php5-fpm.sock -pass-header Authorization
    <Directory /usr/lib/cgi-bin>
        Options ExecCGI FollowSymLinks
        SetHandler fastcgi-script
        Require all granted
    </Directory>
</IfModule>
EOF

sudo a2enconf php5-fpm

sudo service apache2 restart

fi # [ $WEBSERVER == "apache" ]














if [ $WEBSERVER == "nginx" ]; then

echo ">>> Installing Nginx"

# Add repo for latest stable nginx
sudo add-apt-repository -y ppa:nginx/stable

# Update Again
sudo apt-get update

# Install the Rest
sudo apt-get install -y nginx

echo ">>> Configuring Nginx"

# Configure Nginx
cat > /etc/nginx/sites-available/$SERVERNAME << EOF
server {
    root $DOCUMENTPUBLICROOT;
    index index.html index.htm index.php;

    # Make site accessible from http://set-ip-address.xip.io
    server_name $SERVERNAME;

    access_log /var/log/nginx/vagrant.com-access.log;
    error_log  /var/log/nginx/vagrant.com-error.log error;

    charset utf-8;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location = /favicon.ico { log_not_found off; access_log off; }
    location = /robots.txt  { access_log off; log_not_found off; }

    error_page 404 /index.php;

    # pass the PHP scripts to php5-fpm
    location ~ ^/(index|app|app_dev|config)\.php(/|$) {
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        # With php5-fpm:
        fastcgi_pass unix:/var/run/php5-fpm.sock;
        fastcgi_index index.php;
        fastcgi_param LARA_ENV local; # Environment variable for Laravel
        include fastcgi_params;
    }

    # Deny .htaccess file access
    location ~ /\.ht {
        deny all;
    }
}
EOF

# Create directory
if [ ! -d $DOCUMENTPUBLICROOT ]; then
    mkdir -p $DOCUMENTPUBLICROOT
fi

# Enabling virtual hosts
ln -s /etc/nginx/sites-available/$SERVERNAME /etc/nginx/sites-enabled/$SERVERNAME

# Remove default
rm /etc/nginx/sites-enabled/default


# PHP Config for Nginx
sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" /etc/php5/fpm/php.ini

sudo service php5-fpm restart
sudo service nginx restart

fi # [ $WEBSERVER == "nginx" ]

















echo ">>> Installing MySQL Server"

# Add repo for MySQL 5.6
sudo add-apt-repository -y ppa:ondrej/mysql-5.6

# Update Again
sudo apt-get update

# Install MySQL without password prompt
# Set username and password to 'root'
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password password $MYSQLPASSWORD"
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $MYSQLPASSWORD"

# Install MySQL Server
sudo apt-get install -y mysql-server-5.6














if [ $ENVIRONMENT == "development" ]; then

echo ">>> Installing Mailcatcher"

# Test if Apache is installed
apache2 -v > /dev/null 2>&1
APACHE_IS_INSTALLED=$?

# Installing dependency
sudo apt-get install -y libsqlite3-dev


# Gem check
if ! gem -v > /dev/null 2>&1; then sudo aptitude install -y libgemplugin-ruby; fi

# Install
gem install --no-rdoc --no-ri mailcatcher


# Make it start on boot
sudo echo "@reboot $(which mailcatcher) --ip=0.0.0.0" >> /etc/crontab
sudo update-rc.d cron defaults


# Make php use it to send mail
sudo echo "sendmail_path = /usr/bin/env $(which catchmail)" >> /etc/php5/mods-available/mailcatcher.ini
sudo php5enmod mailcatcher
sudo service php5-fpm restart


if [[ $APACHE_IS_INSTALLED -eq 0 ]]; then
    sudo service apache2 restart
fi

# Start it now
/usr/bin/env $(which mailcatcher) --ip=0.0.0.0

# Add aliases
if [[ -f "/home/vagrant/.zshrc" ]]; then
    sudo echo "alias mailcatcher=\"mailcatcher --ip=0.0.0.0\"" >> /home/vagrant/.zshrc
    . /home/vagrant/.zshrc
fi

fi # [ $ENVIRONMENT == "development" ]















echo ">>> Installing Memcached"

sudo apt-get install -y memcached









echo ">>> Installing Composer"

curl -sS https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer









if [ $ENVIRONMENT == "production" ]; then

echo ">>> Installing Git repository"

# Create repo
cd /var
mkdir repo && cd repo
mkdir ${SERVERNAME}.git && cd ${SERVERNAME}.git
git init --bare


# Hooks
cd hooks

cat > /var/repo/${SERVERNAME}.git/hooks/post-receive << EOF
#!/bin/sh
git --work-tree=${DOCUMENTROOT} --git-dir=/var/repo/${SERVERNAME}.git checkout -f

# Composer install from composer.lock
cd ${DOCUMENTROOT}
composer install

EOF

chmod +x post-receive

fi # [ $ENVIRONMENT == "production" ]











echo ">>> Installing Oh-My-Zsh"

# https://gist.github.com/tsabat/1498393

# Install zsh
sudo apt-get install -y zsh

# Install oh-my-zsh
sudo su - $USER -c 'wget --no-check-certificate http://install.ohmyz.sh -O - | sh'

# Add /sbin to PATH
sudo sed -i 's=:/bin:=:/bin:/sbin:/usr/sbin:=' /home/vagrant/.zshrc

# Change $USER user's default shell
sudo chsh $USER -s $(which zsh);
