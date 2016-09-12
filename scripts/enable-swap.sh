#!/usr/bin/env bash

set -e

if test -f /swapfile; then
    sudo swapoff -a
fi
if test -n "$(grep "vm.swappiness = 1" "/etc/sysctl.conf")"; then
    # more info: http://askubuntu.com/questions/103915/how-do-i-configure-swappiness
    sudo sysctl vm.swappiness=1
    echo vm.swappiness = 1 | sudo tee -a /etc/sysctl.conf
fi
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
sudo swapon -s
