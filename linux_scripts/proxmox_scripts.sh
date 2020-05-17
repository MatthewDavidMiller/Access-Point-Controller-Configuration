#!/bin/bash

# Copyright (c) Matthew David Miller. All rights reserved.
# Licensed under the MIT License.

# Compilation of functions for the Proxmox Server.

function install_proxmox_packages() {
    apt-get update
    apt-get upgrade
    apt-get install -y wget vim git ufw ntp ssh apt-transport-https openssh-server unattended-upgrades
}

function configure_proxmox_scripts() {
    # Script to archive config files for backup
    wget 'https://raw.githubusercontent.com/MatthewDavidMiller/scripts/stable/linux_scripts/backup_configs.sh'
    mv 'backup_configs.sh' '/usr/local/bin/backup_configs.sh'
    chmod +x '/usr/local/bin/backup_configs.sh'

    # Script to backup vms
    cat <<EOF >'/usr/local/bin/vm_backup.sh'
#!/bin/bash
PATH="/usr/sbin:/usr/bin:/sbin:/bin"

vzdump 100 101 102 --mode snapshot --quiet 1 --mailnotification always --compress lzo --storage vm_backups

EOF
    chmod +x '/usr/local/bin/vm_backup.sh'

    # Configure cron jobs
    cat <<EOF >jobs.cron
* 0 * * 1 bash /usr/local/bin/backup_configs.sh &
0 0 * * 6 bash /usr/local/bin/vm_backup.sh &

EOF
    crontab jobs.cron
    rm -f jobs.cron
}

function configure_proxmox_hosts() {
    cat <<EOF >'/etc/hosts'
${ip_address} matt-prox.local matt-prox
EOF
}

function configure_proxmox() {
    # Add repository
    echo "deb http://download.proxmox.com/debian/pve buster pve-no-subscription" >/etc/apt/sources.list.d/pve-install-repo.list
    # Add repository gpg key
    wget 'http://download.proxmox.com/debian/proxmox-ve-release-6.x.gpg' -O '/etc/apt/trusted.gpg.d/proxmox-ve-release-6.x.gpg'
    chmod +r '/etc/apt/trusted.gpg.d/proxmox-ve-release-6.x.gpg'
    # Update repository, install and remove packages
    apt-get update
    apt-get full-upgrade
    apt-get install proxmox-ve postfix open-iscsi
    apt-get remove os-prober
    apt-get remove linux-image-amd64
    update-grub
}

function configure_proxmox_network() {
    # Parameters
    local ip_address=${1}
    local network_address=${2}
    local subnet_mask=${3}
    local gateway_address=${4}
    local dns_address=${5}
    local interface=${6}

    # Configure network
    rm -f '/etc/network/interfaces'
    cat <<EOF >'/etc/network/interfaces'
auto lo
iface lo inet loopback

iface ${interface} inet manual

auto vmbr0
iface vmbr0 inet static
        address  ${ip_address}
        network ${network_address}
        netmask  ${subnet_mask}
        gateway  ${gateway_address}
        dns-nameservers ${dns_address}
        bridge-ports ${interface}
        bridge-stp off
        bridge-fd 0
EOF

    # Restart network interface
    ifdown "${interface}" && ifup "${interface}"
}

function configure_proxmox_storage() {
    rm -f '/etc/pve/storage.cfg'
    cat <<EOF >'/etc/pve/storage.cfg'
dir: local
        path /var/lib/vz
        content vztmpl,iso
        shared 0

lvmthin: local-lvm
        thinpool data
        vgname pve
        content images,rootdir

cifs: vm_backups
        path /mnt/pve/vm_backups
        server 10.1.10.4
        share vm_backup
        content backup
        domain matt-nas.miller.lan
        maxfiles 3
        username matthew
EOF
}

# Work in progress function
function configure_proxmox_vms() {
    # ISO location
    debian_iso='local:iso/debian_standard.iso'
    # ISO checksum
    debian_checksum='3019ed00dfffa992066dcf4eada6b9270687345e709d4c6f07fee63f85e8bafc'

    # Get debian iso
    wget 'https://cdimage.debian.org/debian-cd/current-live/amd64/iso-hybrid/debian-live-10.3.0-amd64-standard.iso' -O '/var/lib/vz/template/iso/debian_standard.iso'
    # Verify Image
    if sha256sum '/var/lib/vz/template/iso/debian_standard.iso' | awk "${1}"=="${debian_checksum}"; then
        print 'Image Verified'
    else
        read -r -p "Image is not valid, exiting script: "
        exit
    fi

    # Configure nas vm
    qm create 100 -scsi0 local-lvm:13 -net0 virtio -balloon 512 -bios ovmf -cores 1 -cpu host -bootdisk scsi0 -efidisk0 local-lvm: -name matt-nas -memory 4096 -numa 0 -onboot 1 -ostype l26 -sockets 1 -cdrom ${debian_iso}

    # Configure pihole vm
    qm create 101 -scsi0 local-lvm:13 -net0 virtio -balloon 512 -bios ovmf -cores 1 -cpu host -bootdisk scsi0 -efidisk0 local-lvm: -name matt-pihole -memory 4096 -numa 0 -onboot 1 -ostype l26 -sockets 1 -cdrom ${debian_iso}

    # Configure vpn vm
    qm create 102 -scsi0 local-lvm:13 -net0 virtio -balloon 512 -bios ovmf -cores 1 -cpu host -bootdisk scsi0 -efidisk0 local-lvm: -name matt-vpn -memory 2048 -numa 0 -onboot 1 -ostype l26 -sockets 1 -cdrom ${debian_iso}
}

function set_proxmox_auto_update_reboot_time() {
    grep -q ".*Automatic-Reboot-Time" '/etc/apt/apt.conf.d/50unattended-upgrades' && sed -i "s,.*Automatic-Reboot-Time.*,Automatic-Reboot-Time \"02:00\"," '/etc/apt/apt.conf.d/50unattended-upgrades' || printf '%s\n' 'Automatic-Reboot-Time "02:00"' >>'/etc/apt/apt.conf.d/50unattended-upgrades'
    Automatic-Reboot-Time "02:00"
}
