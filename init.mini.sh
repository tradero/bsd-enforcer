#!/bin/sh

RELEASE="10.3"
ISO_URL="http://mfsbsd.vx.sk/files/iso/10/amd64/mfsbsd-$RELEASE-RELEASE-amd64.iso"

# ===

find_unix_network_interfaces () {
    ifconfig | egrep -oi '^([a-z0-9]+)[: ]' | sed 's/://' | grep -v 'lo[0-9]*' | grep -v 'vlan[0-9]*'
}

find_unix_gateway () {
    netstat -rn4 | awk '/UG/{print $2}'
}

find_unix_nameservers () {
    cat /etc/resolv.conf | awk '/^nameserver/{print $2}' | uniq | tr '\n' ' ' | sed "s/ *$//"
}

find_unix_iface_mac () {
    ifconfig $1 | grep -o -E '([[:xdigit:]]{1,2}:){5}[[:xdigit:]]{1,2}'
}

find_unix_iface_addr () {
    ifconfig $1 | grep "inet " | head -n 1 | awk '{ print $2 }' | sed "s/addr://"
}

find_unix_iface_netmask () {
    mask=$(ifconfig $1 | egrep -io "mask[: ]([^ ]+)" | sed "s/mask[: ]//i");

    # convert hex mask
    if [ $(echo $mask | grep "^0x" | wc -l) -gt 0 ]; then
        mask=$(mask=$(echo $mask | sed "s/^0x//");
        for n in 1 2 3 4; do
            dec=$(echo "$mask" | cut -c$(( $n*2-1 ))-$(( $n*2 )));
            printf "%d." 0x$dec;
        done | sed "s/\.$//");
    fi;

    echo "$mask";
}

# ===

download_mfsbsd_iso () {
    if [ ! -f /boot/mfsbsd-$RELEASE.iso ]; then /usr/bin/env $1 $ISO_URL -O /boot/mfsbsd-$RELEASE.iso; fi
}

# ===

inject_grub2 () {
        if [ $(cat /boot/grub/grub.cfg | grep menuentry | grep mfsbsd | wc -l) -eq 0 ]; then
                echo "[DEBUG] mfsbsd grub2 entry is missing, injecting..."

                grub_size=$(cat $grub_file | wc -l)

                first_entry=$(grep -n "^menuentry" $grub_file|cut -d":" -f1 | head -n 1)
                first_part=$(head -n $(( $first_entry-1 )) $grub_file)
                second_part=$(tail -n $(( $grub_size-$first_entry+1)) $grub_file)

                echo "${first_part}"           > /tmp/grub
                echo "\n\n${grub2_entry}\n\n" >> /tmp/grub
                echo "${second_part}"         >> /tmp/grub

                if [ ! -e "${grub_file}_backup" ]; then cp $grub_file "${grub_file}_backup"; fi
                mv /tmp/grub $grub_file
        else
                echo "[DEBUG] mfsbsd grub2 entry already injected..."
        fi
}

enforce_from_debian_grub () {
    echo "[DEBUG] enforcing from debian - grub2"

    grub_file="/boot/grub/grub.cfg"
    first_iface=$(find_unix_network_interfaces | head -n 1)

    address=$(find_unix_iface_addr $first_iface)
    netmask=$(find_unix_iface_netmask $first_iface)
    macaddr=$(find_unix_iface_mac $first_iface)

    gateway=$(find_unix_gateway)
    dns=$(find_unix_nameservers)

    hostname=$(hostname)
    grub2_entry=$(cat <<EOF

menuentry "mfsbsd-$RELEASE.iso" {
        set isofile=/boot/mfsbsd-$RELEASE.iso
        loopback loop (hd0,1)\$isofile

        kfreebsd (loop)/boot/kernel/kernel.gz -v
        kfreebsd_module (loop)/boot/kernel/ahci.ko
        kfreebsd_module (loop)/mfsroot.gz type=mfs_root

        set kFreeBSD.vfs.root.mountfrom="ufs:/dev/md0"
        set kFreeBSD.mfsbsd.autodhcp="NO"
        set kFreeBSD.mfsbsd.rootpw="1.root"
        set kFreeBSD.mfsbsd.hostname="$hostname"
        set kFreeBSD.mfsbsd.defaultrouter="$gateway"
        set kFreeBSD.mfsbsd.mac_interfaces="ext1"
        set kFreeBSD.mfsbsd.ifconfig_ext1_mac="$macaddr"
        set kFreeBSD.mfsbsd.ifconfig_ext1="inet $address netmask $netmask"
        set kFreeBSD.mfsbsd.nameservers="$dns"

        set kFreeBSD.mfsbsd.static_routes="r1 r2"
        set kFreeBSD.mfsbsd.route_r1="-inet $gateway -link -iface vtnet0"
        set kFreeBSD.mfsbsd.route_r2="default $gateway"
}

EOF
)
    inject_grub2

    echo "[DEBUG] done."
}

main () {
    download_mfsbsd_iso "wget"
    enforce_from_debian_grub
}

main && exit 0
