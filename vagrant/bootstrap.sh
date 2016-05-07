#!/usr/bin/env bash

rm /var/lib/dpkg/lock;

export DEBIAN_FRONTEND=noninteractive
debconf-set-selections <<< 'mysql-server mysql-server/root_password password root'
debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password root'

apt-get update;
apt-get -y dist-upgrade;
apt-get -y install unzip build-essential git php7.0-fpm php7.0-cli php7.0-dev \
mysql-client-5.7 mysql-client-core-5.7 mysql-server-5.7 php7.0-mysql php-radius \
php7.0-sqlite3 php7.0-intl php7.0-imap php7.0-gd php7.0-curl php-imagick php7.0-mcrypt \
php-redis php-pear php-memcached memcached zip nginx;

pecl -q install xdebug;

echo "Setting Up MySql";
sed -i "s/.*bind-address.*/bind-address = 0.0.0.0/" /etc/mysql/my.cnf
service mysql restart;

echo "UPDATE mysql.user SET host='%' WHERE user='root' AND host='$HOSTNAME'; FLUSH PRIVILEGES;" | mysql -u root -proot 2>/dev/null;
echo 'CREATE DATABASE CMS; ' | mysql -u root -proot 2>/dev/null;

echo "Updating Nginx"
sed -i "s/.*user www-data;.*/user vagrant;/" /etc/nginx/nginx.conf
cp /vagrant/vagrant/nginx/sites-available/* /etc/nginx/sites-available

#turn on all sites
SITESAVAILABLE="/etc/nginx/sites-available/";
SITESENABLED="/etc/nginx/sites-enabled/"
FILES="$SITESAVAILABLE*";
for f in $FILES
do
  filename=${f##$SITESAVAILABLE}
  rm "$SITESENABLED$filename";
  ln -s "$f" "$SITESENABLED$filename"
done

service nginx restart;


echo "Updating PHP"
cp /vagrant/vagrant/php/7.0/fpm/pool.d/www.conf /etc/php/7.0/fpm/pool.d/www.conf;
cp /vagrant/vagrant/php/7.0/fpm/php.ini /etc/php/7.0/fpm/php.ini;
cp /vagrant/vagrant/php/7.0/mods-available/xdebug.ini /etc/php/7.0/mods-available/xdebug.ini;
sed -i "s/zend_extension=opcache.so.*/;zend_extension=opcache.so/" /etc/php/7.0/mods-available/opcache.ini
phpenmod xdebug
service php7.0-fpm restart

echo "Installing Node"
wget -q https://nodejs.org/dist/v5.10.1/node-v5.10.1-linux-x64.tar.gz
tar -C /usr/local --strip-components 1 -xzf node-v5.10.1-linux-x64.tar.gz
rm node-v5.10.1-linux-x64.tar.gz

