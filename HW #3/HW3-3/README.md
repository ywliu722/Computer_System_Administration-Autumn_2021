# ZFS
* You should add two disks on the virtual machine
```sh
sudo zfs enable
sudo zpool create mypool mirror /dev/dev1 /dev/dev2 # change 'dev1' and 'dev2' to your device name
# create datasets
sudo zfs create mypool/public
sudo zfs create mypool/upload
sudo zfs create mypool/hidden

# dataset configuration
sudo zfs set compression=lz4 mypool
sudo zfs set compression=lz4 mypool/public
sudo zfs set compression=lz4 mypool/upload
sudo zfs set compression=lz4 mypool/hidden

sudo zfs set atime=off mypool
sudo zfs set atime=off mypool/public
sudo zfs set atime=off mypool/upload
sudo zfs set atime=off mypool/hidden

# copy the directory permission and mount zfs pool on /home/ftp
sudo zfs set mountpoint=/mypool mypool
sudo cp -rp /home/ftp /mypool
sudo zfs set mountpoint=/home/ftp mypool
```

# Usage

```sh
# copy the script to $PATH
sudo cp zfsbak.sh /usr/local/bin/zfsbak
```