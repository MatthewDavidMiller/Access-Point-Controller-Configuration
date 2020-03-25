#!/bin/bash
# Script to configure Windows Subsystem for Linux
# Do not run as root

# Get username
user_name=$(whoami)

function setup_wsl_gui() {
    bash -c "echo export DISPLAY=localhost:0.0" >>~/.bashrc
}

function configure_bashrc() {
    cat <<\EOF >>"/home/${user_name}/.bashrc"

# Mount network drives
sudo mount -t drvfs N: /mnt/matt_files

# Aliases
alias sudo='sudo '
alias ssh_nas="ssh -i '.ssh/nas_key' matthew@matt-nas.miller.lan"
alias ssh_openwrt="ssh -i '.ssh/openwrt_key' matthew@mattopenwrt.miller.lan"
alias ssh_proxmox="ssh -i '.ssh/proxmox_key' matthew@matt-prox.miller.lan"
alias ssh_vpn="ssh -i '.ssh/vpn_key' matthew@matt-vpn.miller.lan"
alias ssh_pihole="ssh -i '.ssh/pihole_key' matthew@matt-pihole.miller.lan"
alias cd_git='cd /mnt/matt_files/Matthew_Cloud/git'

EOF
}

function copy_ssh_keys() {
    # Mount network drives
    sudo mkdir /mnt/matt_files
    sudo mount -t drvfs N: /mnt/matt_files

    # Copy ssh keys
    mkdir -p '.ssh'
    sudo cp '/mnt/matt_files/SSHConfigs/matt_homelab/nas_key' '.ssh/nas_key'
    sudo cp '/mnt/matt_files/SSHConfigs/matt_homelab/openwrt_key' '.ssh/openwrt_key'
    sudo cp '/mnt/matt_files/SSHConfigs/matt_homelab/proxmox_key' '.ssh/proxmox_key'
    sudo cp '/mnt/matt_files/SSHConfigs/matt_homelab/vpn_key' '.ssh/vpn_key'
    sudo cp '/mnt/matt_files/SSHConfigs/matt_homelab/pihole_key' '.ssh/pihole_key'
}

function install_packages() {
    sudo apt-get update
    sudo apt-get upgrade
    sudo apt-get install git ssh
}

# Call functions
setup_wsl_gui
configure_bashrc
copy_ssh_keys
install_packages
