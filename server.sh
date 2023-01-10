#!/bin/bash


#installing tools
if [ "$EUID" -ne 0 ];then
  >&2 echo "This script requires root level access to run"
  exit 1
fi
echo "▶ updating linux ..."

sudo apt -y update

echo "▶ installing nginx ..."

sudo apt -y install nginx


echo "▶ app list ufw ..."

sudo ufw app list
sudo ufw status



echo "▶ installing mysql ..."

sudo apt -y install mysql-server

echo "▶ secure mysql ..."

# sudo mysql_secure_installation

echo "▶ installing php ..."
apt-get install -y unzip
apt-get install -y curl

apt-get -qq install -y  --no-install-recommends  \
  php8.1-fpm \
  certbot \
  python3-certbot-nginx \
  php-cli \
  php-common \
  php-bcmath \
  php-curl \
  php-gd \
  php-imagick \
  php-mbstring \
  php-mysql \
  php-opcache \
  php-xml \
  php-zip 
    

  echo "▶  php installed ..."


# sudo apt install php-cli unzip
# sudo apt install php-mbstring

export COMPOSER_ALLOW_SUPERUSER=1;

cd ~
curl -sS https://getcomposer.org/installer -o /tmp/composer-setup.php
HASH=`curl -sS https://composer.github.io/installer.sig`
echo $HASH
php -r "if (hash_file('SHA384', '/tmp/composer-setup.php') === '$HASH') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
sudo php /tmp/composer-setup.php --install-dir=/usr/local/bin --filename=composer

#ending install tools
domain=$1
user=$2


domain_set_on_block=$domain
currentIp="$(curl icanhazip.com)"

if [[ "$domain" == "main" ]]
then
  domain_set_on_block=$currentIp
else
    # set domnain expression 
    subdomain=${domain:0:3}
    if [[ "$subdomain" == "www" ]]; then
        domain_set_on_block="${domain:4} $domain";
    else
        domain_set_on_block=$domain;
    fi

fi


echo $domainExp;


echo "▶ domain name: $1";

block="/etc/nginx/sites-available/$domain"
domain_folder="/var/www/$domain"
domain_public_folder="$domain_folder/public"
echo $domain_folder;
#Create site dir
echo "▶ creating  site dir !"
#sudo mkdir $domain
sudo mkdir -p $domain_public_folder
echo "▶ site directory created successfully !"

mkdir -p "$domain_folder/logs/"

touch "$domain_folder/logs/error.log"
chmod 777 "$domain_folder/logs/error.log"
touch "$domain_folder/logs/access.log"
chmod 777 "$domain_folder/logs/access.log"
echo "▶ Updating NGINX Server Block"
sudo tee $block > /dev/null <<EOF
    server {
    listen 80;
    server_name $domain_set_on_block;
    index index.html index.htm index.php;
    error_log $domain_folder/logs/error.log;
    access_log $domain_folder/logs/access.log;
    root $domain_public_folder;

    location / {
        try_files \$uri /index.php\$is_args$args;
    }

    location ~ \.php {
        try_files \$uri =404;
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$realpath_root\$fastcgi_script_name;
        fastcgi_param SCRIPT_NAME \$fastcgi_script_name;
        fastcgi_index index.php;
        fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
    }
}


EOF




#Link to make it available
echo "▶ Linking Server Blocks"



rm -rf /etc/nginx/sites-available/default
rm -rf /etc/nginx/sites-enabled/default



#Link to make it available
echo "▶ Linking Server Blocks"
sudo ln -s $block /etc/nginx/sites-enabled/

#Test configuration and reload if successful
echo "▶ Reloading Server"
sudo nginx -t && sudo service nginx reload



echo "▶ php version ..."


php -v
composer -v


echo "▶ server ip ..."

curl icanhazip.com
sudo tee $domain_public_folder/info.php > /dev/null <<EOF
    <?php
    phpinfo();

EOF

