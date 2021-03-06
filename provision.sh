#!/usr/bin/env bash

# Config
SSL=true
ENVIRONMENT="development" # "development" or "production"
SERVERNAME="192.168.33.10.xip.io"
DOCUMENTROOT="/vagrant/test"
DOCUMENTPUBLICROOT="${DOCUMENTROOT}/public"
MYSQLPASSWORD="123456"
ENV_USER="vagrant"




















echo ">>> Installing Base Packages"

# Update
sudo apt-get update

# Install base packages
sudo apt-get install -qq unzip git-core ack-grep vim tmux curl wget build-essential python-software-properties




















echo ">>> Installing PHP"

sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 4F4EA0AAE5267A6C
sudo add-apt-repository -y ppa:ondrej/php5-5.6

sudo apt-key update
sudo apt-get update

# Install PHP
sudo apt-get install -qq php5-cli php5-fpm php5-mysql php5-pgsql php5-sqlite php5-curl php5-gd php5-gmp php5-mcrypt php5-memcached php5-imagick php5-intl

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

# Timezone
sudo sed -i "s/;date.timezone =.*/date.timezone = UTC/" /etc/php5/fpm/php.ini
sudo sed -i "s/;date.timezone =.*/date.timezone = UTC/" /etc/php5/cli/php.ini

sudo service php5-fpm restart




















echo ">>> Installing Nginx"

SSL_CONF=""
SSL_SERVER_BLOCK=""
NO_SSL_SERVER_BLOCK=""

if [ $SSL == true ]; then

read -r -d '' SSL_CONF <<EOF
    ssl    on;
    ssl_protocols              TLSv1 TLSv1.1 TLSv1.2;
    ssl_ciphers                ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-DSS-AES128-GCM-SHA256:kEDH+AESGCM:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-DSS-AES128-SHA256:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA:DHE-RSA-AES256-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:AES:CAMELLIA:DES-CBC3-SHA:!aNULL:!eNULL:!EXPORT:!DES:!RC4:!MD5:!PSK:!aECDH:!EDH-DSS-DES-CBC3-SHA:!EDH-RSA-DES-CBC3-SHA:!KRB5-DES-CBC3-SHA;
    ssl_prefer_server_ciphers  on;


    ssl_session_cache    shared:SSL:10m;
    ssl_session_timeout  24h;

    keepalive_timeout 300;

    ssl_certificate      /etc/nginx/ssl.crt;
    ssl_certificate_key  /etc/nginx/ssl.key;


    spdy_keepalive_timeout 300;
    spdy_headers_comp 6;
EOF
read -r -d '' SSL_SERVER_BLOCK <<EOF
server {
    listen [::]:80;
    listen 80;
    ssl off;
    server_name ${SERVERNAME} www.${SERVERNAME};
    return 301 https://www.${SERVERNAME}\$request_uri;
}
server {
    listen [::]:443 ssl spdy;
    listen 443 ssl spdy;
    server_name www.${SERVERNAME};
    return 301 \$scheme://${SERVERNAME}\$request_uri;
}
server {
    listen [::]:443 ssl spdy;
    listen 443 ssl spdy;
EOF

fi #if [ $SSL == true ];

if [ $SSL == false ]; then

read -r -d '' NO_SSL_SERVER_BLOCK <<EOF
server {
    listen [::]:80;
    listen 80;
    server_name www.${SERVERNAME};
    return 301 \$scheme://${SERVERNAME}\$request_uri;
}
server {
    listen [::]:80;
    listen 80;
EOF

fi #if [ $SSL == false ];



# Add repo for latest stable nginx
sudo add-apt-repository -y ppa:nginx/stable

# Update Again
sudo apt-get update

# Install the Rest
sudo apt-get install -qq nginx


# Configure nginx.conf
sudo bash -c "cat > /etc/nginx/nginx.conf" << EOF
user www-data;

worker_processes 2;

worker_rlimit_nofile 8192;

events {
    worker_connections 8000;
}

error_log  /var/log/nginx/error.log warn;
pid        /var/run/nginx.pid;

http {
    server_tokens off;

    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    charset_types text/xml text/plain text/vnd.wap.wml application/x-javascript application/rss+xml text/css application/javascript application/json;

    log_format  main  '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                    '\$status \$body_bytes_sent "\$http_referer" '
                    '"\$http_user_agent" "\$http_x_forwarded_for"';

    access_log /var/log/nginx/access.log main;

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
        application/ld+json
        application/manifest+json
        application/rdf+xml
        application/rss+xml
        application/schema+json
        application/vnd.geo+json
        application/vnd.ms-fontobject
        application/x-font-ttf
        application/x-javascript
        application/x-web-app-manifest+json
        application/xhtml+xml
        application/xml
        font/eot
        font/opentype
        image/bmp
        image/svg+xml
        image/vnd.microsoft.icon
        image/x-icon
        text/cache-manifest
        text/css
        text/javascript
        text/plain
        text/vcard
        text/vnd.rim.location.xloc
        text/vtt
        text/x-component
        text/x-cross-domain-policy
        text/xml;


    $SSL_CONF

    include sites-enabled/*;
}
EOF



# Configure myme.types
sudo bash -c "cat > /etc/nginx/mime.types" << EOF
types {
    # Data interchange

    application/atom+xml                  atom;
    application/json                      json map topojson;
    application/ld+json                   jsonld;
    application/rss+xml                   rss;
    application/vnd.geo+json              geojson;
    application/xml                       rdf xml;


    # JavaScript

    # Normalize to standard type.
    # https://tools.ietf.org/html/rfc4329#section-7.2
    application/javascript                js;


    # Manifest files

    application/x-web-app-manifest+json   webapp;
    text/cache-manifest                   appcache;


    # Media files

    audio/midi                            mid midi kar;
    audio/mp4                             aac f4a f4b m4a;
    audio/mpeg                            mp3;
    audio/ogg                             oga ogg opus;
    audio/x-realaudio                     ra;
    audio/x-wav                           wav;
    image/bmp                             bmp;
    image/gif                             gif;
    image/jpeg                            jpeg jpg;
    image/png                             png;
    image/svg+xml                         svg svgz;
    image/tiff                            tif tiff;
    image/vnd.wap.wbmp                    wbmp;
    image/webp                            webp;
    image/x-jng                           jng;
    video/3gpp                            3gpp 3gp;
    video/mp4                             f4v f4p m4v mp4;
    video/mpeg                            mpeg mpg;
    video/ogg                             ogv;
    video/quicktime                       mov;
    video/webm                            webm;
    video/x-flv                           flv;
    video/x-mng                           mng;
    video/x-ms-asf                        asx asf;
    video/x-ms-wmv                        wmv;
    video/x-msvideo                       avi;

    # Serving `.ico` image files with a different media type
    # prevents Internet Explorer from displaying then as images:
    # https://github.com/h5bp/html5-boilerplate/commit/37b5fec090d00f38de64b591bcddcb205aadf8ee

    image/x-icon                          cur ico;


    # Microsoft Office

    application/msword                                                         doc;
    application/vnd.ms-excel                                                   xls;
    application/vnd.ms-powerpoint                                              ppt;
    application/vnd.openxmlformats-officedocument.wordprocessingml.document    docx;
    application/vnd.openxmlformats-officedocument.spreadsheetml.sheet          xlsx;
    application/vnd.openxmlformats-officedocument.presentationml.presentation  pptx;


    # Web fonts

    application/font-woff                 woff;
    application/font-woff2                woff2;
    application/vnd.ms-fontobject         eot;

    # Browsers usually ignore the font media types and simply sniff
    # the bytes to figure out the font type.
    # https://mimesniff.spec.whatwg.org/#matching-a-font-type-pattern
    #
    # However, Blink and WebKit based browsers will show a warning
    # in the console if the following font types are served with any
    # other media types.

    application/x-font-ttf                ttc ttf;
    font/opentype                         otf;


    # Other

    application/java-archive              jar war ear;
    application/mac-binhex40              hqx;
    application/octet-stream              bin deb dll dmg exe img iso msi msm msp safariextz;
    application/pdf                       pdf;
    application/postscript                ps eps ai;
    application/rtf                       rtf;
    application/vnd.google-earth.kml+xml  kml;
    application/vnd.google-earth.kmz      kmz;
    application/vnd.wap.wmlc              wmlc;
    application/x-7z-compressed           7z;
    application/x-bb-appworld             bbaw;
    application/x-bittorrent              torrent;
    application/x-chrome-extension        crx;
    application/x-cocoa                   cco;
    application/x-java-archive-diff       jardiff;
    application/x-java-jnlp-file          jnlp;
    application/x-makeself                run;
    application/x-opera-extension         oex;
    application/x-perl                    pl pm;
    application/x-pilot                   prc pdb;
    application/x-rar-compressed          rar;
    application/x-redhat-package-manager  rpm;
    application/x-sea                     sea;
    application/x-shockwave-flash         swf;
    application/x-stuffit                 sit;
    application/x-tcl                     tcl tk;
    application/x-x509-ca-cert            der pem crt;
    application/x-xpinstall               xpi;
    application/xhtml+xml                 xhtml;
    application/xslt+xml                  xsl;
    application/zip                       zip;
    text/css                              css;
    text/html                             html htm shtml;
    text/mathml                           mml;
    text/plain                            txt;
    text/vcard                            vcard vcf;
    text/vnd.rim.location.xloc            xloc;
    text/vnd.sun.j2me.app-descriptor      jad;
    text/vnd.wap.wml                      wml;
    text/vtt                              vtt;
    text/x-component                      htc;
}
EOF



# Configure Nginx site-available
sudo bash -c "cat > /etc/nginx/sites-available/$SERVERNAME" << EOF
$SSL_SERVER_BLOCK
$NO_SSL_SERVER_BLOCK

    root $DOCUMENTPUBLICROOT;
    index index.html index.htm index.php;

    server_name $SERVERNAME;

    charset utf-8;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    if (!-d \$request_filename) {
        rewrite ^/(.+)/$ /\$1 permanent;
    }


    location = /favicon.ico { log_not_found off; access_log off; }
    location = /robots.txt  { access_log off; log_not_found off; }

    error_page 404 /index.php;

    location ~ ^/(index|app|app_dev|config)\.php(/|$) {
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass 127.0.0.1:9000;
        fastcgi_index index.php;
        fastcgi_param APP_ENV local;
        include fastcgi.conf;
    }

    location ~* (?:^|/)\. {
        deny all;
    }
    location ~* (?:\.(?:bak|config|sql|fla|psd|ini|log|sh|inc|swp|dist)|~)$ {
        deny all;
    }
}
EOF

# Create public directory / index file
if [ ! -d $DOCUMENTPUBLICROOT ]; then
    sudo mkdir -p $DOCUMENTPUBLICROOT
    sudo bash -c 'echo "Works!" >> '"$DOCUMENTPUBLICROOT"'/index.php'
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
sudo apt-get install -qq mysql-server




















echo ">>> Installing Memcached"

sudo apt-get install -qq memcached




















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
sudo apt-get install -qq zsh

# Install oh-my-zsh
sudo su - $ENV_USER -c 'wget --no-check-certificate http://install.ohmyz.sh -O - | sh'

# Add /sbin to PATH
sudo sed -i 's=:/bin:=:/bin:/sbin:/usr/sbin:=' /home/${ENV_USER}/.zshrc

# Change $ENV_USER user's default shell
sudo chsh $ENV_USER -s $(which zsh);




















if [ $ENVIRONMENT == "development" ]; then

echo ">>> Installing Mailcatcher"

# Installing dependency
sudo apt-get install -qq libsqlite3-dev ruby1.9.1-dev

# Gem check
if ! gem -v > /dev/null 2>&1; then sudo aptitude install -qq libgemplugin-ruby; fi

# Install mailcatcher
gem install --no-rdoc --no-ri mailcatcher

# Make it start on boot
sudo bash -c 'echo "@reboot root $(which mailcatcher) --ip=0.0.0.0" >> /etc/cron.d/'"$ENV_USER"''

# Make php use it to send mail
sudo bash -c 'echo "sendmail_path = /usr/bin/env $(which catchmail)" >> /etc/php5/mods-available/mailcatcher.ini'
sudo php5enmod mailcatcher
sudo service php5-fpm restart

# Start it now
/usr/bin/env $(which mailcatcher) --ip=0.0.0.0

# Add aliases
if [[ -f "/home/${ENV_USER}/.zshrc" ]]; then
    sudo bash -c 'echo "alias mailcatcher=\"mailcatcher --ip=0.0.0.0\"" >> /home/'"$ENV_USER"'/.zshrc'
fi

fi # [ $ENVIRONMENT == "development" ]




















echo ">>> Installing UFW"

# sudo ufw reset

sudo apt-get install ufw

sudo ufw allow 22/tcp    # ssh
sudo ufw allow 80/tcp    # http
sudo ufw allow 443/tcp   # https
sudo ufw allow 3306/tcp  # mysql
sudo ufw allow 11211/tcp # memcached

yes y | sudo ufw enable




















echo ">>> Installing Swap file"

sudo fallocate -l 1G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo "/swapfile   none    swap    sw    0   0" | sudo tee -a /etc/fstab
echo "vm.swappiness=10" | sudo tee -a /etc/sysctl.conf
echo "vm.vfs_cache_pressure=50" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
