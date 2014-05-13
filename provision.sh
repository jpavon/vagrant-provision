#!/usr/bin/env bash

# Config
ENVIRONMENT="development" # "development" or "production"
SERVERNAME="192.168.33.10.xip.io"
DOCUMENTROOT="/vagrant/test"
DOCUMENTPUBLICROOT="${DOCUMENTROOT}/public"
MYSQLPASSWORD="123456"
USER="vagrant"




















echo ">>> Installing Base Packages"

# Update
sudo apt-get update

# Install base packages
sudo apt-get install -y unzip git-core ack-grep vim tmux curl wget build-essential python-software-properties




















echo ">>> Installing PHP"

sudo add-apt-repository -y ppa:ondrej/php5

sudo apt-key update
sudo apt-get update

# Install PHP
sudo apt-get install --force-yes -y php5-cli php5-fpm php5-mysql php5-pgsql php5-sqlite php5-curl php5-gd php5-gmp php5-mcrypt php5-xdebug php5-memcached php5-imagick php5-intl

# Set PHP FPM to listen on TCP instead of Socket
sudo sed -i "s/listen =.*/listen = 127.0.0.1:9000/" /etc/php5/fpm/pool.d/www.conf

# Set PHP FPM allowed clients IP address
sudo sed -i "s/;listen.allowed_clients/listen.allowed_clients/" /etc/php5/fpm/pool.d/www.conf


# PHP Error Reporting Config
sudo sed -i "s/log_errors = .*/log_errors = On/" /etc/php5/fpm/php.ini
sudo sed -i "s/error_reporting = .*/error_reporting = E_ALL/" /etc/php5/fpm/php.ini

if [ $ENVIRONMENT == "development" ]; then
    sudo sed -i "s/display_errors = .*/display_errors = On/" /etc/php5/fpm/php.ini
    sudo sed -i "s/display_startup_errors = .*/display_startup_errors = On/" /etc/php5/fpm/php.ini
    sudo sed -i "s/html_errors = .*/html_errors = On/" /etc/php5/fpm/php.ini
fi

if [ $ENVIRONMENT == "production" ]; then
    sudo sed -i "s/display_errors = .*/display_errors = Off/" /etc/php5/fpm/php.ini
    sudo sed -i "s/display_startup_errors = .*/display_startup_errors = Off/" /etc/php5/fpm/php.ini
    sudo sed -i "s/html_errors = .*/html_errors = Off/" /etc/php5/fpm/php.ini
fi

sudo service php5-fpm restart




















echo ">>> Installing Nginx"

# Add repo for latest stable nginx
sudo add-apt-repository -y ppa:nginx/stable

# Update Again
sudo apt-get update

# Install the Rest
sudo apt-get install -y nginx


# Configure nginx.conf
sudo bash -c "cat > /etc/nginx/nginx.conf" << EOF
user www-data;

worker_processes 2;

worker_rlimit_nofile 8192;

events {
    worker_connections 8000;
}

access_log /var/log/nginx/${SERVERNAME}-access.log;
error_log  /var/log/nginx/${SERVERNAME}-error.log error;
pid        /var/run/nginx.pid;

http {
    server_tokens off;

    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    charset_types text/xml text/plain text/vnd.wap.wml application/x-javascript application/rss+xml text/css application/javascript application/json;

    log_format  main  '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                    '\$status \$body_bytes_sent "\$http_referer" '
                    '"\$http_user_agent" "\$http_x_forwarded_for"';

    access_log logs/access.log main;

    keepalive_timeout 20;

    sendfile        on;

    tcp_nopush      on;
    tcp_nodelay     off;

    gzip on;
    gzip_http_version  1.0;
    gzip_comp_level    5;
    gzip_min_length    256;
    gzip_proxied       any;
    gzip_vary          on;
    gzip_types
        application/atom+xml
        application/javascript
        application/json
        application/rss+xml
        application/vnd.ms-fontobject
        application/x-font-ttf
        application/x-web-app-manifest+json
        application/xhtml+xml
        application/xml
        font/opentype
        image/svg+xml
        image/x-icon
        text/css
        text/plain
        text/x-component;

    ssl_protocols              SSLv3 TLSv1 TLSv1.1 TLSv1.2;
    ssl_ciphers                ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-DSS-AES128-GCM-SHA256:kEDH+AESGCM:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-DSS-AES128-SHA256:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA:DHE-RSA-AES256-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:ECDHE-RSA-RC4-SHA:ECDHE-ECDSA-RC4-SHA:AES128:AES256:RC4-SHA:HIGH:!aNULL:!eNULL:!EXPORT:!DES:!3DES:!MD5:!PSK;
    ssl_prefer_server_ciphers  on;

    ssl_session_cache    shared:SSL:10m;
    ssl_session_timeout  10m;

    include sites-enabled/*;
}
EOF



# Configure myme.types
sudo bash -c "cat > /etc/nginx/mime.types" << EOF
types {
    audio/midi                            mid midi kar;
    audio/mp4                             aac f4a f4b m4a;
    audio/mpeg                            mp3;
    audio/ogg                             oga ogg;
    audio/x-realaudio                     ra;
    audio/x-wav                           wav;

    image/bmp                             bmp;
    image/gif                             gif;
    image/jpeg                            jpeg jpg;
    image/png                             png;
    image/tiff                            tif tiff;
    image/vnd.wap.wbmp                    wbmp;
    image/webp                            webp;
    image/x-icon                          ico cur;
    image/x-jng                           jng;

    application/javascript                js;
    application/json                      json;

    application/x-web-app-manifest+json   webapp;
    text/cache-manifest                   manifest appcache;

    application/msword                                                         doc;
    application/vnd.ms-excel                                                   xls;
    application/vnd.ms-powerpoint                                              ppt;
    application/vnd.openxmlformats-officedocument.wordprocessingml.document    docx;
    application/vnd.openxmlformats-officedocument.spreadsheetml.sheet          xlsx;
    application/vnd.openxmlformats-officedocument.presentationml.presentation  pptx;

    video/3gpp                            3gpp 3gp;
    video/mp4                             mp4 m4v f4v f4p;
    video/mpeg                            mpeg mpg;
    video/ogg                             ogv;
    video/quicktime                       mov;
    video/webm                            webm;
    video/x-flv                           flv;
    video/x-mng                           mng;
    video/x-ms-asf                        asx asf;
    video/x-ms-wmv                        wmv;
    video/x-msvideo                       avi;

    application/xml                       atom rdf rss xml;

    application/font-woff                 woff;
    application/vnd.ms-fontobject         eot;
    application/x-font-ttf                ttc ttf;
    font/opentype                         otf;
    image/svg+xml                         svg svgz;

    application/java-archive              jar war ear;
    application/mac-binhex40              hqx;
    application/pdf                       pdf;
    application/postscript                ps eps ai;
    application/rtf                       rtf;
    application/vnd.wap.wmlc              wmlc;
    application/xhtml+xml                 xhtml;
    application/vnd.google-earth.kml+xml  kml;
    application/vnd.google-earth.kmz      kmz;
    application/x-7z-compressed           7z;
    application/x-chrome-extension        crx;
    application/x-opera-extension         oex;
    application/x-xpinstall               xpi;
    application/x-cocoa                   cco;
    application/x-java-archive-diff       jardiff;
    application/x-java-jnlp-file          jnlp;
    application/x-makeself                run;
    application/x-perl                    pl pm;
    application/x-pilot                   prc pdb;
    application/x-rar-compressed          rar;
    application/x-redhat-package-manager  rpm;
    application/x-sea                     sea;
    application/x-shockwave-flash         swf;
    application/x-stuffit                 sit;
    application/x-tcl                     tcl tk;
    application/x-x509-ca-cert            der pem crt;
    application/x-bittorrent              torrent;
    application/zip                       zip;

    application/octet-stream              bin exe dll;
    application/octet-stream              deb;
    application/octet-stream              dmg;
    application/octet-stream              iso img;
    application/octet-stream              msi msp msm;
    application/octet-stream              safariextz;

    text/css                              css;
    text/html                             html htm shtml;
    text/mathml                           mml;
    text/plain                            txt;
    text/vnd.sun.j2me.app-descriptor      jad;
    text/vnd.wap.wml                      wml;
    text/vtt                              vtt;
    text/x-component                      htc;
    text/x-vcard                          vcf;
}
EOF



# Configure Nginx site-available
sudo bash -c "cat > /etc/nginx/sites-available/$SERVERNAME" << EOF
server {
    listen 80;
    server_name www.${SERVERNAME};
    return 301 \$scheme://${SERVERNAME}\$request_uri;
}
server {
    listen 80;

    root $DOCUMENTPUBLICROOT;
    index index.html index.htm index.php;

    server_name $SERVERNAME;

    charset utf-8;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location = /favicon.ico { log_not_found off; access_log off; }
    location = /robots.txt  { access_log off; log_not_found off; }

    error_page 404 /index.php;

    location ~ ^/(index|app|app_dev|config)\.php(/|$) {
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass 127.0.0.1:9000;
        fastcgi_index index.php;
        fastcgi_param LARA_ENV local;
        include fastcgi_params;
    }

    location ~* (?:^|/)\. {
        deny all;
    }
    location ~* (?:\.(?:bak|config|sql|fla|psd|ini|log|sh|inc|swp|dist)|~)$ {
        deny all;
    }
}
EOF

# Create public directory
if [ ! -d $DOCUMENTPUBLICROOT ]; then
    sudo mkdir -p $DOCUMENTPUBLICROOT
fi

# Create logs directory
if [ ! -d $DOCUMENTPUBLICROOT ]; then
    sudo mkdir -p /usr/share/nginx/logs
fi

# Enabling virtual hosts
sudo ln -s /etc/nginx/sites-available/$SERVERNAME /etc/nginx/sites-enabled/$SERVERNAME

# Remove default
sudo rm /etc/nginx/sites-enabled/default


# PHP Config for Nginx
sudo sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" /etc/php5/fpm/php.ini

sudo service php5-fpm restart
sudo service nginx restart




















echo ">>> Installing MySQL Server"

# Update Again
sudo apt-get update

# Install MySQL without password prompt
# Set username and password to 'root'
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password password $MYSQLPASSWORD"
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $MYSQLPASSWORD"

# Install MySQL Server
sudo apt-get install -y mysql-server




















echo ">>> Installing Memcached"

sudo apt-get install -y memcached




















echo ">>> Installing Composer"

curl -sS https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer




















if [ $ENVIRONMENT == "production" ]; then

echo ">>> Installing Git repository"

# Create repo
cd /var
sudo mkdir -p repo && cd repo
sudo mkdir -p ${SERVERNAME}.git && cd ${SERVERNAME}.git
git init --bare


# Hooks
cd hooks

sudo bash -c "cat > /var/repo/${SERVERNAME}.git/hooks/post-receive" << EOF
#!/bin/sh
git --work-tree=${DOCUMENTROOT} --git-dir=/var/repo/${SERVERNAME}.git checkout -f

# Composer install from composer.lock
cd ${DOCUMENTROOT}
composer install

EOF

sudo chmod +x post-receive

fi # [ $ENVIRONMENT == "production" ]




















echo ">>> Installing Oh-My-Zsh"

# https://gist.github.com/tsabat/1498393

# Install zsh
sudo apt-get install -y zsh

# Install oh-my-zsh
sudo su - $USER -c 'wget --no-check-certificate http://install.ohmyz.sh -O - | sh'

# Add /sbin to PATH
sudo sed -i 's=:/bin:=:/bin:/sbin:/usr/sbin:=' /home/${USER}/.zshrc

# Change $USER user's default shell
sudo chsh $USER -s $(which zsh);




















if [ $ENVIRONMENT == "development" ]; then

echo ">>> Installing Mailcatcher"

# Installing dependency
sudo apt-get install -y libsqlite3-dev


# Gem check
if ! gem -v > /dev/null 2>&1; then sudo aptitude install -y libgemplugin-ruby; fi

# Install ruby
sudo apt-get install ruby1.9.1-dev


# Install
gem install --no-rdoc --no-ri mailcatcher


# Make it start on boot
sudo bash -c 'echo "@reboot root $(which mailcatcher) --ip=0.0.0.0" >> /etc/crontab'
sudo update-rc.d cron defaults


# Make php use it to send mail
sudo bash -c 'echo "sendmail_path = /usr/bin/env $(which catchmail)" >> /etc/php5/mods-available/mailcatcher.ini'
sudo php5enmod mailcatcher
sudo service php5-fpm restart


# Start it now
/usr/bin/env $(which mailcatcher) --ip=0.0.0.0

# Add aliases
if [[ -f "/home/${USER}/.zshrc" ]]; then
    sudo bash -c 'echo "alias mailcatcher=\"mailcatcher --ip=0.0.0.0\"" >> /home/${USER}/.zshrc'
fi

fi # [ $ENVIRONMENT == "development" ]
