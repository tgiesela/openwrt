#!/bin/sh
. ./lxcvars
. ./vars
#opkg remove --force-depends procd-ujail
# Temporary fix for dns-resolver which is not yet running
while [ ! -f /etc/resolv.conf ]; do
    echo "Waiting for /etc/resolv.conf to be created..."
    sleep 1
done
INTF=$(ip link | grep 'br-lan')
while [ -z "$INTF" ]; do
    echo "Waiting for br-lan interface to be created..."
    sleep 1
    INTF=$(ip link | grep 'br-lan')
done
INTF=$(ip link | grep 'cnt-br0' | grep 'state UP')
while [ -z "$INTF" ]; do
    echo "Waiting for cnt-br0 interface to become available..."
    sleep 1
    INTF=$(ip link | grep 'cnt-br0' | grep 'state UP')
done
sed -i "s/^nameserver 127.0.0.1/nameserver ${UPSTREAM_DNS_SERVER}/" /etc/resolv.conf

# Set hardcoded IP address for OpenWRT to allow update of packages during install
ip route | grep default | ip route del
ip addr add "${OPENWRT_LOCAL_IP}/${CNTNETWORKMASKLEN}" dev cnt-br0
ip route add default via "${CNTGATEWAY}"
# Update the package list and upgrade all packages
opkg update 
#opkg list-upgradable | awk '{print $1}' | xargs opkg upgrade || true
opkg install nano bash tcpdump curl kmod-mac80211 iwinfo kmod-wireguard luci-proto-wireguard wireguard-tools usbutils hostapd
sed -i "s/^nameserver ${UPSTREAM_DNS_SERVER}/nameserver 127.0.0.1/" /etc/resolv.conf

