# Some configuration
## Create violated file directory and generate pureftpd.viofile
```sh
mkdir /home/ftp/hidden/.exe
touch /home/ftp/public/pureftpd.viofile
```
# Usage

* `/usr/local/etc/rc.d/ftp-watchd`
* `/etc/syslog.d/ftpuscr.conf`
* `/etc/rc.conf`
* `/usr/local/bin/uploadscript.sh`