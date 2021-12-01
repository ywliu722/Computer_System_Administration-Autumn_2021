# Homework 4
## HTTP server using nginx
### Nginx Setup
```sh
sudo pkg install nginx
sudo service nginx enable
sudo ee /usr/local/www/html/index.html # in files/
sudo ee /usr/local/etc/nginx/nginx.conf # in files/
sudo service nginx start
```
### HTTPS certification
```sh
mkdir /etc/nginx/ssl
cd /etc/nginx/ssl
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/nginx/ssl/nginx.key -out /etc/nginx/ssl/nginx.crt

# add html file and configure nginx
sudo ee /usr/local/www/html/vhost.html # in files/
sudo ee /usr/local/etc/nginx/nginx.conf # in files/
sudo service nginx restart
```
### PHP-FPM
```sh
sudo pkg install php80
sudo cp /usr/local/etc/php.ini-production /usr/local/etc/php.ini
sudo ee /usr/local/etc/php.ini
# edit these options
#   cgi.fix_pathinfo=0
#   expose_php = Off
sudo ee /usr/local/etc/php-fpm.d/www.conf
# edit these options
#   listen.owner = www
#   listen.group = www
#   listen.mode = 0660
#   ;listen = 127.0.0.1:9000
#   listen = /var/run/php-fpm.sock
sudo ee /usr/local/www/html/info-20.php # in files/
sudo service php-fpm enable
sudo service php-fpm start

# configure nginx
sudo ee /usr/local/etc/nginx/nginx.conf # in files/
sudo service nginx restart
```
### Private page and its authentication
```sh
cd /usr/local/etc/nginx
sudo ee passwd_setup.sh
sudo chmod +x passwd_setup.sh
sudo ./passwd_setup.sh

# add private directory and html file
sudo mkdir /usr/local/www/private
sudo ee /usr/local/www/private/secret.html # in files/

# configure nginx
sudo ee /usr/local/etc/nginx/nginx.conf # in files/
sudo service nginx restart
```
```sh
# passwd_setup.sh
# Replace USER and PASSWORD for your user and password
printf "USER:$(openssl passwd -crypt PASSWORD)\n" >> .htpasswd
```
## Database using MySQL 8
### MySQL
```sh
sudo pkg install mysql80-server
sudo service mysql-server enable
sudo service mysql-server start
mysql_secure_installation
/usr/local/bin/mysql -u root -p # next section
```
```sql
root@localhost> CREATE USER 'judge'@'%' IDENTIFIED BY '<PASSWORD>';
root@localhost> CREATE DATABASE `judge`;
root@localhost> GRANT ALL PRIVILEGES ON judge.* TO 'root'@'localhost';
root@localhost> GRANT SELECT ON judge.* TO 'judge'@'%';
root@localhost> FLUSH PRIVILEGES;
root@localhost> quit
```
### phpMyAdmin
```sh
# install phpMyAdmin
sudo pkg install phpMyAdmin-php80
ln -s /usr/local/www/phpMyAdmin/ /usr/local/www/html/phpmyadmin

# configure nginx
sudo ee /usr/local/etc/nginx/nginx.conf # in files/
sudo service nginx restart

# change MySQL password setting if you use MySQL 8
mysql -u root -p # next section
sudo service mysql-server restart
```
```sql
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'PASSWORD';
ALTER USER 'judge'@'%' IDENTIFIED WITH mysql_native_password BY 'PASSWORD';
```
### DB Maintenance
```sh
# dump remote server database
mysqldump --host=<IP> --port=<port> --column-statistics=0 --lock-tables=false -u <ID> -p <DB_NAME> > PrivKeys.sql

# backup to local database
mysql -u root -p judge < PrivKeys.sql
```
## Kernel Module and Websocket
### Kernel module compilation and load
```sh
# fetch freebsd source code
git clone -b releng/13.0 --depth 1 https://git.freebsd.org/src.git /usr/src

# compile kernel module
cd /home/judge/hw4
fetch https://nasa.cs.nctu.edu.tw/sa/2021/sockn.c # in files/
ee Makefile # in files/
make

# load kernel module
cd /home/judge/hw4
sudo kldload -v ./sockn.ko
```
### Websocket
```sh
# download websocketd
cd /home/judge/hw4
curl -LO https://github.com/joewalnes/websocketd/releases/download/v0.4.1/websocketd-0.4.1-freebsd_amd64.zip
unzip -d websocketd websocketd-0.4.1-freebsd_amd64.zip
cd websocketd

# add script for websocketd
ee script.sh # in files/
chmod +x script.sh

# add html file and configure nginx
sudo ee /usr/local/www/html/wsdemo.html # in files/
sudo ee /usr/local/etc/nginx/nginx.conf # in files/
sudo service nginx restart

# run websocketd (in two terminal)
./websocketd --port=8010 ./script.sh
sudo ./websocketd --ssl --sslcert="/usr/local/etc/nginx/ssl/nginx.crt" --sslkey="/usr/local/etc/nginx/ssl/nginx.key" --port=8020 ./script.sh
```

## File structure
* /usr/local
    * etc/
        * php.ini
        * nginx/
            * nginx.conf
            * ssl/
                * nginx.cert
                * nginx.key
        * php-fpm.d
            * www.conf
        * mysql/
            * my.cnf
    * www/
        * html/
            * index.html
            * vhost.html
            * info-20.php
            * wsdemo.html
            * phpmyadmin -> /usr/local/www/phpMyAdmin/
            * private/
                * secret.html
            
        * phpMyAdmin/
            * index.php
* /home/judge
    * PrivKeys.sql
    * hw4/
        * sockn.c
        * sockn.ko
        * Makefile
        * websocketd/
            * websocketd
            * script.sh