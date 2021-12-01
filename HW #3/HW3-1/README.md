# Install and configure pure-ftpd
## Install from port
```sh
# install pure-ftpd using port
sudo portsnap # get ports tree
cd /usr/port/ftp/pure-ftpd
sudo make install
```
## Configure pure-ftpd
```sh
cd /usr/local/etc
sudo cp pure-ftpd.conf.sample pure-ftpd.conf
sudo ee pure-ftpd.conf
# edit these options and un-comment them
#ChrootEveryone           yes
#VerboseLog               yes
#NoAnonymous              no
#SyslogFacility           ftp
#PureDB                   /usr/local/etc/pureftpd.pdb
#AnonymousCanCreateDirs   no
#AntiWarez                no
#AnonymousCantUpload      no
#CallUploadScript         yes
#CreateHomeDir            no
#TLS                      2
```
## Start the service
```sh
sudo service pure-ftpd enable
sudo service pure-ftpd start
```
# Create Users
## sysadm
```sh
sudo pw groupadd sysadm #add a new group for sysadm
sudo adduser
#Username: sysadm
#Login group: sysadm
#Home directory: /home/ftp

# map the virtual user to system user
pure-pw useradd sysadm -u sysadm -g sysadm -d /home/ftp -m
```
## ftp-vip
```sh
# create two users
sudo pw groupadd ftpuser
sudo pw useradd ftp-vip1 -g ftpuser -d /home/ftp -s /sbin/nologin
sudo pw useradd ftp-vip2 -g ftpuser -d /home/ftp -s /sbin/nologin
# create two virtual user to map to the system user
sudo pure-pw useradd ftp-vip1 -u ftp-vip1 -g ftpuser -d /home/ftp -m
sudo pure-pw useradd ftp-vip2 -u ftp-vip2 -g ftpuser -d /home/ftp -m
```
## Anonymous
```sh
sudo pw groupadd ftp-anony
sudo pw useradd ftp -g ftp-anony -d /home/ftp
```
## Write user information into pureDB
```sh
sudo pure-pw mkdb
sudo service pure-ftpd start
```
# Directory Permission
```sh
su -
chmod 777 /home/ftp/public
chmod 1777 /home/ftp/upload
chown sysadm:ftpuser /home/ftp/hidden
chmod 771 /home/ftp/hidden
mkdir /home/ftp/hidden/treasure
touch /home/ftp/hidden/treasure/secret
```
# TLS
```sh
cd /etc/ssl
sudo mkdir private
cd private
# generate certification
sudo openssl req -x509 -nodes -newkey rsa:2048 -sha256 -keyout \
/etc/ssl/private/pure-ftpd.pem \
-out /etc/ssl/private/pure-ftpd.pem
```
# Syslog
```sh
sudo mkdir /var/log/pureftpd
sudo touch /var/log/pureftpd/pureftpd.log
sudo touch /var/log/pureftpd/login.log
sudo ee /etc/syslog.conf
# add these lines to the configuration file
#ftp.*                      -/var/log/pureftpd/pureftpd.log
#:msg, contains, "logged"
#ftp.*                       /var/log/pureftpd/login.log
sudo service syslogd restart
```
# File Usage

* `/usr/local/etc/pure-ftpd.conf`
* `/etc/syslog.conf`