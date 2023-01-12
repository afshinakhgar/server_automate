#!/bin/bash

domain=$1
has_ssl=$2

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





ismysql=$(which mysql)



if [[ $ismysql == "/usr/bin/mysql" ]]
then
    echo $ismysql
else
    echo "▶ installing mysql ..."
    sudo apt -y install mysql-server
    echo "▶ secure mysql ..."
fi



# sudo mysql_secure_installation
isphp=$(which composer)

if [[ $isphp == "/usr/bin/php" ]]
then
    echo $isphp
else
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

fi





# sudo apt install php-cli unzip
# sudo apt install php-mbstring

iscomposer=$(which composer)


export COMPOSER_ALLOW_SUPERUSER=1;

if [[ $iscomposer == "/usr/local/bin/composer" ]]
then
    echo $iscomposer
else
    cd ~
    curl -sS https://getcomposer.org/installer -o /tmp/composer-setup.php
    HASH=`curl -sS https://composer.github.io/installer.sig`
    echo $HASH
    php -r "if (hash_file('SHA384', '/tmp/composer-setup.php') === '$HASH') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
    sudo php /tmp/composer-setup.php --install-dir=/usr/local/bin --filename=composer 
fi

#ending install tools


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
        $domain = "${domain:4}"
    else
        domain_set_on_block=$domain;

    fi

fi




echo $domainExp;


echo "▶ domain name: $1";

block="/etc/nginx/sites-available/$domain"
domain_folder="/var/www/$domain"


sudo chown -R "$USER":www-data domain_folder
sudo chmod -R 0755 domain_folder



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



rm -rf /etc/nginx/sites-available/default
rm -rf /etc/nginx/sites-enabled/default

sudo ufw allow 'Nginx Full'
sudo ufw allow 'Nginx HTTP'
sudo ufw status
sudo ufw allow OpenSSH
sudo ufw allow ssh
sudo ufw allow 22
sudo ufw  -y enable

if [[ "$has_ssl" == "ssl" ]]
then
    if [[ "$domain" == "main" ]]
    then
        echo "....."   
    else
        echo "▶ certbot"

        if [[ "$subdomain" == "www" ]]; then
            echo "domain and subdomain"
            echo "certbot --nginx -d ${domain:4} -d $domain";

            sudo certbot --nginx -d ${domain:4} -d $domain
        else
            echo "domain only"

            sudo certbot --nginx -d $domain
        fi
        
    fi

    sudo systemctl status certbot.timer

    sudo certbot renew --dry-run

fi



#Link to make it available
echo "▶ Linking Server Blocks"
sudo ln -s $block /etc/nginx/sites-enabled/

#Test configuration and reload if successful
echo "▶ Reloading Server"
sudo nginx -t && sudo service nginx reload



echo "▶ php version ..."


php -v
composer --version


echo "▶ server ip ..."

curl icanhazip.com
sudo tee $domain_public_folder/info.php > /dev/null <<EOF
    <?php
    phpinfo();

EOF


sudo tee $domain_public_folder/index.php > /dev/null <<EOF
    <?php
    echo date("Y-m-d H:i:s",time());
    echo "Hello World!";

EOF
