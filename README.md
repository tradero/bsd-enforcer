bsd enforcer
=======

First, I need to warn You:
 
 - It's work in progress and things can go side ways ;-)
 - This time, it supports only systems with grub2. I don't have any usecase for others atm (like You know extlinux? Welcome!).
 - You need to be sure, that You have ssh keys properly configured.
 - This repo should not be running on target machine! You should run it from your desktop or another server.
 - install.sh contains hardcoded gist urls with ie. pf configuration, it's not smart to leave it like that.
   You should at least, change it to your own file url (You can just clone mine).
 - If You want to install clean freebsd, without my configuration, You need to comment out lines 56-60 in runner.sh

```
git clone https://github.com/tradero/bsd-enforcer.git
cd bsd-enforcer

./runner.sh root@SERVER_IP -p PORT
```

That's pretty it. At this point your server should have installed something like:
```
root@vps284521:~ # uname -a
FreeBSD vps284521.ovh.net 10.3-RELEASE FreeBSD 10.3-RELEASE #0 r297264: Fri Mar 25 02:10:02 UTC 2016     root@releng1.nyi.freebsd.org:/usr/obj/usr/src/sys/GENERIC  amd64

root@vps284521:~ # zpool status
  pool: system
 state: ONLINE
  scan: none requested
config:

        NAME        STATE     READ WRITE CKSUM
        system      ONLINE       0     0     0
          vtbd0p3   ONLINE       0     0     0

errors: No known data errors

root@vps284521:~ # zfs list
NAME                  USED  AVAIL  REFER  MOUNTPOINT
system                661M  5.14G    96K  /system
system/ROOT           482M  5.14G    96K  none
system/ROOT/default   482M  5.14G   481M  /
system/tmp            177M  5.14G   177M  /tmp
system/usr            384K  5.14G    96K  /usr
system/usr/home        96K  5.14G    96K  /usr/home
system/usr/ports       96K  5.14G    96K  /usr/ports
system/usr/src         96K  5.14G    96K  /usr/src
system/var            584K  5.14G    96K  /var
system/var/audit       96K  5.14G    96K  /var/audit
system/var/crash       96K  5.14G    96K  /var/crash
system/var/log         96K  5.14G    96K  /var/log
system/var/mail        96K  5.14G    96K  /var/mail
system/var/tmp        104K  5.14G    96K  /var/tmp

root@vps284521:~ # kldstat
Id Refs Address            Size     Name
 1   17 0xffffffff80200000 17bc680  kernel
 2    1 0xffffffff819bd000 2fc428   zfs.ko
 3    2 0xffffffff81cba000 6040     opensolaris.ko
 4    1 0xffffffff81cc1000 23fb0    geom_mirror.ko
 5    1 0xffffffff81ce5000 55918    pf.ko
 6    1 0xffffffff81e11000 2ba8     uhid.ko

root@vps284521:~ # pkg info
ca_root_nss-3.22.2             Root certificate bundle from the Mozilla Project
pkg-1.7.2                      Package manager
```

