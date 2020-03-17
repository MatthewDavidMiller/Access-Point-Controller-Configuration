#!/bin/bash

# Copyright (c) 2019-2020 Matthew David Miller. All rights reserved.
# Licensed under the MIT License.
# Needs to be run as root. Make sure you are logged in as a user instead of root.
# Configuration script for proxmox. Run after Debian with the install script.

# Get username
user_name=$(logname)

function configure_packages() {
    # Fix all packages
    dpkg --configure -a

    # Install recommended packages
    apt-get update
    apt-get upgrade
    apt-get install -y wget vim git ufw ntp ssh apt-transport-https openssh-server unattended-upgrades
}

function configure_firewall() {
    # Configure ufw
    # Set default inbound to deny
    ufw default deny incoming

    # Set default outbound to allow
    ufw default allow outgoing

    # Limit max connections to ssh server and allow it only on private networks
    ufw limit proto tcp from 10.0.0.0/8 to any port 22
    ufw limit proto tcp from fe80::/10 to any port 22

    # Allow proxmox web interface
    ufw allow proto tcp from 10.0.0.0/8 to any port 8006
    ufw allow proto tcp from fe80::/10 to any port 8006

    # Enable ufw
    systemctl enable ufw.service
    ufw enable
}

function configure_scripts() {
    # Script to archive config files for backup
    wget 'https://raw.githubusercontent.com/MatthewDavidMiller/scripts/stable/linux_scripts/backup_configs.sh'
    mv 'backup_configs.sh' '/usr/local/bin/backup_configs.sh'
    chmod +x '/usr/local/bin/backup_configs.sh'

    # Configure cron jobs
    cat <<EOF >jobs.cron
* 0 * * 1 bash /usr/local/bin/backup_configs.sh &

EOF
    crontab jobs.cron
    rm -f jobs.cron
}

function configure_ssh() {
    # Generate an ecdsa 521 bit key
    ssh-keygen -f "/home/${user_name}/proxmox_key" -t ecdsa -b 521

    # Authorize the key for use with ssh
    mkdir "/home/${user_name}/.ssh"
    chmod 700 "/home/${user_name}/.ssh"
    touch "/home/${user_name}/.ssh/authorized_keys"
    chmod 600 "/home/${user_name}/.ssh/authorized_keys"
    cat "/home/${user_name}/proxmox_key.pub" >>"/home/${user_name}/.ssh/authorized_keys"
    printf '%s\n' '' >>"/home/${user_name}/.ssh/authorized_keys"
    chown -R "${user_name}" "/home/${user_name}"
    python -m SimpleHTTPServer 40080 &
    server_pid=$!
    read -r -p "Copy the key from the webserver on port 40080 before continuing: " >>'/dev/null'
    kill "${server_pid}"

    # Secure ssh access

    # Turn off password authentication
    grep -q ".*PasswordAuthentication" '/etc/ssh/sshd_config' && sed -i "s,.*PasswordAuthentication.*,PasswordAuthentication no," '/etc/ssh/sshd_config' || printf '%s\n' 'PasswordAuthentication no' >>'/etc/ssh/sshd_config'

    # Do not allow empty passwords
    grep -q ".*PermitEmptyPasswords" '/etc/ssh/sshd_config' && sed -i "s,.*PermitEmptyPasswords.*,PermitEmptyPasswords no," '/etc/ssh/sshd_config' || printf '%s\n' 'PermitEmptyPasswords no' >>'/etc/ssh/sshd_config'

    # Turn off PAM
    grep -q ".*UsePAM" '/etc/ssh/sshd_config' && sed -i "s,.*UsePAM.*,UsePAM no," '/etc/ssh/sshd_config' || printf '%s\n' 'UsePAM no' >>'/etc/ssh/sshd_config'

    # Turn off root ssh access
    grep -q ".*PermitRootLogin" '/etc/ssh/sshd_config' && sed -i "s,.*PermitRootLogin.*,PermitRootLogin no," '/etc/ssh/sshd_config' || printf '%s\n' 'PermitRootLogin no' >>'/etc/ssh/sshd_config'

    # Enable public key authentication
    grep -q ".*AuthorizedKeysFile" '/etc/ssh/sshd_config' && sed -i "s,.*AuthorizedKeysFile\s*.ssh/authorized_keys\s*.ssh/authorized_keys2,AuthorizedKeysFile .ssh/authorized_keys," '/etc/ssh/sshd_config' || printf '%s\n' 'AuthorizedKeysFile .ssh/authorized_keys' >>'/etc/ssh/sshd_config'
    grep -q ".*PubkeyAuthentication" '/etc/ssh/sshd_config' && sed -i "s,.*PubkeyAuthentication.*,PubkeyAuthentication yes," '/etc/ssh/sshd_config' || printf '%s\n' 'PubkeyAuthentication yes' >>'/etc/ssh/sshd_config'
}

function configure_auto_updates() {
    rm -f '/etc/apt/apt.conf.d/50unattended-upgrades'
    cat <<\EOF >'/etc/apt/apt.conf.d/50unattended-upgrades'
Unattended-Upgrade::Origins-Pattern {
        "origin=Debian,n=buster,l=Debian";
        "origin=Debian,n=buster,l=Debian-Security";
        "origin=Debian,n=buster-updates";
};

Unattended-Upgrade::Package-Blacklist {

};

// Automatically reboot *WITHOUT CONFIRMATION* if
//  the file /var/run/reboot-required is found after the upgrade
Unattended-Upgrade::Automatic-Reboot "true";

// If automatic reboot is enabled and needed, reboot at the specific
// time instead of immediately
//  Default: "now"
Unattended-Upgrade::Automatic-Reboot-Time "04:00";

EOF
}

function configure_hosts() {
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

    function configure_proxmox_network() {
        #Prompts
        # Set server ip
        read -r -p "Enter server ip address. Example '10.1.10.3': " ip_address
        # Set network
        read -r -p "Enter network ip address. Example '10.1.10.0': " network_address
        # Set subnet mask
        read -r -p "Enter netmask. Example '255.255.255.0': " subnet_mask
        # Set gateway
        read -r -p "Enter gateway ip. Example '10.1.10.1': " gateway_address
        # Set dns server
        read -r -p "Enter dns server ip. Example '10.1.10.5': " dns_address

        # Get the interface name
        interface="$(ip route get 8.8.8.8 | sed -nr 's/.*dev ([^\ ]+).*/\1/p')"
        echo "Interface name is ${interface}"

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

    # Call functions
    configure_proxmox_network
}

# Call functions
configure_packages
configure_ssh
configure_firewall
configure_scripts
configure_auto_updates
configure_hosts
configure_proxmox
