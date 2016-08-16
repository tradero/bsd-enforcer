#!/bin/sh

pkg upgrade -f
pkg install -y ca_root_nss

DISTRIBUTIONS="MANIFEST kernel.txz base.txz lib32.txz"
RELEASE="10.3"
nonInteractive="YES"
NONINTERACTIVE="YES"

export DISTRIBUTIONS
export RELEASE
export nonInteractive
export NONINTERACTIVE

export ZFSBOOT_DISKS=vtbd0
export ZFSBOOT_POOL_NAME=system
export ZFSBOOT_VDEV_TYPE="stripe"
export ZFSBOOT_FORCE_4K_SECTORS="1"
export ZFSBOOT_CONFIRM_LAYOUT=0
export ZFSBOOT_POOL_CREATE_OPTIONS="-O compress=lz4 -O checksum=fletcher4"

export ZFSBOOT_SWAP_SIZE="4g"
export ZFSBOOT_SWAP_MIRROR="1"

# CONFIGURE ZFS
bsdinstall zfsboot

export BSDINSTALL_TMPBOOT=/tmp/bsdinstall_boot
export BSDINSTALL_TMPETC=/tmp/bsdinstall_etc

export BSDINSTALL_CHROOT=/mnt
export BSDINSTALL_DISTSITE_BASE="http://ftp.freebsd.org/pub/FreeBSD/releases"
export BSDINSTALL_DISTSITE="${BSDINSTALL_DISTSITE_BASE}/$(uname -m)/$(uname -p)/${RELEASE}-RELEASE"
export BSDINSTALL_DISTDIR=/mnt/tmp/setup/${RELEASE}-RELEASE

mkdir -p $BSDINSTALL_DISTDIR > /dev/null

# CREATE TEMP SWAP - to help with extraction process - out of swap is a common problem on low memory machines (like 512mb-2G)
dd if=/dev/zero of=/mnt/swap0 bs=1m count=4000
chmod 0600 /mnt/swap0
echo 'md99	none	swap	sw,file=/mnt/swap0,late	0	0' > /etc/fstab
swapon -aL

# INSTALL SYSTEM
distfetch()
{
    bsdinstall distfetch
    bsdinstall checksum || distfetch
}

distfetch

DISTRIBUTIONS="kernel.txz base.txz lib32.txz"
export DISTRIBUTIONS
bsdinstall distextract

cat ${BSDINSTALL_TMPETC}/fstab >> /mnt/etc/fstab
chmod 600 /mnt/etc/fstab

zpool set autoexpand=on $ZFSBOOT_POOL_NAME

# POST INSTALLATION
cat ${BSDINSTALL_TMPBOOT}/loader.conf.* >>/mnt/boot/loader.conf
sysrc -f /mnt/boot/loader.conf zfs_load="YES"
sysrc -f /mnt/boot/loader.conf autoboot_delay="1"
chmod 600 /mnt/boot/loader.conf

# NEW SYSTEM SNAPSHOT
zfs snap -r $ZFSBOOT_POOL_NAME@new_install
# DNS
cat /etc/resolv.conf > /mnt/etc/resolv.conf
# RC
cat /etc/rc.conf > /mnt/etc/rc.conf
cp /etc/rc.conf.d/* /mnt/etc/rc.conf.d/

# users
cp /etc/master.passwd /mnt/etc/master.passwd

# JAIL RELATED
sysrc -f /mnt/etc/rc.conf cloned_interfaces="vlan0"
sysrc -f /mnt/etc/rc.conf ifconfig_vlan0="inet 172.23.0.1 netmask 255.255.255.0"

# COPY SSH CONFIG
cp -R /root/.ssh /mnt/root/.ssh

chroot /mnt /bin/sh -c 'export ASSUME_ALWAYS_YES=YES; pkg update; pkg install -y ca_root_nss'

# PF
sysrc -f /mnt/boot/loader.conf pf_load=YES
sysrc -f /mnt/etc/rc.conf pf_enable="YES"
fetch https://gist.githubusercontent.com/krzysztofantczak/70f9c0994804e2ebade9659bd082f7d1/raw/109c2ff3add735cda525f9694124a48c9f2e5e55/gistfile1.txt -o /mnt/etc/pf.conf

# SYSCTL
fetch https://gist.githubusercontent.com/krzysztofantczak/76d2b42ff45f9e4aa4e8fbfc0e79c532/raw/64e3498a6aba3a9fed3f5d39ba8aeae809ff1f23/gistfile1.txt -o /mnt/etc/sysctl.conf

# enable root login
chroot /mnt /bin/sh -c 'cat /etc/ssh/sshd_config | sed "s/#PermitRoot.*/PermitRootLogin yes/" > ttmp; mv ttmp /etc/ssh/sshd_config'
# disable login using passwords
chroot /mnt /bin/sh -c 'cat /etc/ssh/sshd_config | sed "s/#PasswordAuthentication.*/PasswordAuthentication no/" > ttmp; mv ttmp /etc/ssh/sshd_config'
chroot /mnt /bin/sh -c 'cat /etc/ssh/sshd_config | sed "s/#PermitEmptyPasswords.*/PermitEmptyPasswords no/" > ttmp; mv ttmp /etc/ssh/sshd_config'
