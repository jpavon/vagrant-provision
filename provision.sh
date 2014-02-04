#!/usr/bin/env bash

# Config
ENVIRONMENT="development" # "development" or "production"
SERVERNAME="192.168.33.10.xip.io"
DOCUMENTROOT="/vagrant"
MYSQLPASSWORD="123456"







echo ">>> Installing Base Packages"

# Update
sudo apt-get update

# Install base packages
sudo apt-get install -y git-core ack-grep vim tmux curl wget build-essential python-software-properties










echo ">>> Installing PHP"

sudo add-apt-repository -y ppa:ondrej/php5

sudo apt-get update

# Install PHP
sudo apt-get install -y php5-cli php5-fpm php5-mysql php5-pgsql php5-sqlite php5-curl php5-gd php5-gmp php5-mcrypt php5-memcached php5-imagick

if [ $ENVIRONMENT == "development" ]; then
    # PHP Error Reporting Config
    sed -i "s/error_reporting = .*/error_reporting = E_ALL/" /etc/php5/fpm/php.ini
    sed -i "s/display_errors = .*/display_errors = On/" /etc/php5/fpm/php.ini
    sed -i "s/display_startup_errors = .*/display_startup_errors = On/" /etc/php5/fpm/php.ini
    sed -i "s/log_errors = .*/log_errors = On/" /etc/php5/fpm/php.ini
fi

if [ $ENVIRONMENT == "production" ]; then
    # PHP Error Reporting Config
    sed -i "s/error_reporting = .*/error_reporting = E_ALL/" /etc/php5/fpm/php.ini
    sed -i "s/display_errors = .*/display_errors = Off/" /etc/php5/fpm/php.ini
    sed -i "s/display_startup_errors = .*/display_startup_errors = Off/" /etc/php5/fpm/php.ini
    sed -i "s/log_errors = .*/log_errors = On/" /etc/php5/fpm/php.ini
fi

sudo service php5-fpm restart











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

    DocumentRoot $DOCUMENTROOT

    <Directory $DOCUMENTROOT>
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

if [ ! -d $DOCUMENTROOT ]; then
    mkdir -p $DOCUMENTROOT
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













echo ">>> Installing Memcached"

sudo apt-get install -y memcached









echo ">>> Installing Composer"

curl -sS https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer
