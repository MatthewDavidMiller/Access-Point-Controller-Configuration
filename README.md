# Scripts
This repository contains scripts I have created.

Copyright (c) 2019 Matthew David Miller. All rights reserved.

Licensed under the MIT License.

# Linux Scripts:

arch_linux_install.sh - A bash script I wrote to automate my install of Arch Linux.

backup_configs.sh - A bash script I wrote to tar the /etc directory.  Used to automate backing up config files.

delete_logs.py - Simple python script to delete some logs files after going over a certain size.

email_ip_address.py - A simple python script to send an email with the ip address of the device that ran the script.

email_on_vpn_connections.py - A python script that it paired with my bash script to send an email when there is a connection on my openvpn server.

email_on_vpn_connections.sh - A bash script that checks the openvpn log file for a certain keyword so I know if a vpn connection was established on my server.

network_reconnect.sh - A bash script that restarts a network interface if it can't ping the gateway.  Utilizes ifdown and ifup commands.

network_reconnect_buster.sh - A bash script that restarts a network interface if it can't ping the gateway.  Utilizes iplink command.

openwrt_install_packages.sh - Simple script to install some packages in OpenWrt.

openwrt_restrict_luci_access.sh - Simple script to limit access to luci gui as well as redirect http to https.

setup wsl gui.sh - Simple bash script to setup the xserver in Windows Subsystem for Linux.

setup_fwupd.sh - Bash script to setup fwupd in Arch Linux.

update_openwrt.sh - A simple script to update packages in OpenWrt.

updates.py - Python script to update packages with the apt-get package manager.

# Windows Scripts:

batch_process_hard_links.bat - Simple script to make hard links of all files from where the script is run from.

get_file_hash.ps1 - Powershell script to get the file hashes of all files from where the script is run from.

printer_restart.bat - Script to restart print spooler and clear temporary files from the spooler.

tar_batch_process_files.bat - Places all folders in a tar archive from where the script is run from.

uninstall_default_applications.ps1 - Simple powershell script to remove some of the default apps installed in Windows 10.

view_hard_links.bat - Simple script to see all the hard links of files from where the script is run from.

wsl restart.bat - Simple script to restart Windows Subsystem for Linux.