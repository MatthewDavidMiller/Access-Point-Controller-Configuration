#!/bin/bash

# Script to install some packages I use.

read -r -p "Do you want to install the packages? [y/N] " response
if [[ "${response}" =~ ^([yY][eE][sS]|[yY])+$ ]]
    then
        # Updates package lists
        opkg update

        # Upgrades all installed packages
        opkg install luci-app-upnp ipset luci-ssl
fi