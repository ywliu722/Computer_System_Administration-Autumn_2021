# Homework 5
## NFS
### NFS server

```sh
# create directories
sudo mkdir /vol
sudo mkdir /vol/public1
sudo mkdir /vol/public2
sudo mkdir /vol/stu20
# let nobody and other user can write this directory
sudo chmod 777 /vol/stu20

sudo ee /etc/exports # in files/
```
Some configuration
```sh
sudo ee /etc/rc.conf
# rpcbind_enable="YES"
# mountd_enable="YES"
# mountd_flags="-p 87"
# nfs_server_enable="YES"
# nfsv4_server_enable="YES"
# nfs_server_flags="-u -t -n 4"
# nfs_reserved_port_only="YES"

# set the minimum version of NFS server
sudo ee /etc/sysctl.conf
# add `vfs.nfsd.server_min_nfsvers=4`
```
### NFS client
```sh
sudo ee /etc/rc.conf
# nfs_client_enable="YES"
# autofs_enable="YES"

sudo ee /etc/auto_master
# add `/-              /etc/auto.direct -intr,nosuid`

sudo ee /etc/auto.direct # in files/
```
## Firewall
### PF
```sh
sudo ee /etc/rc.conf
# pf_enable="YES"
# pflog_enable="YES"
# pfsync_enable="YES"

sudo ee /etc/pf.conf # in files/
```
### Blacklistd
```sh
sudo ee /etc/rc.conf
# blacklistd_enable="YES"

sudo ee /etc/ssh/sshd.conf
# uncomment and set to yes `UseBlacklist yes`

sudo ee /etc/blacklistd.conf
# edit `ssh             stream  *       *               *       3       60`
```