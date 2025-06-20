#!/bin/bash
source ./vars
set -e
info () {
    echo "[INFO] $*"
}
locale-gen
apt update
apt install -y curl

curl -sSf --output installvpn.sh https://downloads.nordcdn.com/apps/linux/install.sh 
chmod +x installvpn.sh
./installvpn.sh -n
rm -f installvpn.sh

cat << EOF >> /etc/systemd/network/eth1.network
[Match]
Name=eth1

[Network]
DHCP=true

[DHCPv4]
UseDomains=true

[DHCP]
ClientIdentifier=mac
EOF