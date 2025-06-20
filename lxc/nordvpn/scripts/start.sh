#!/bin/bash
source ./vars
set -e
info () {
    echo "[INFO] $*"
}
config_mesh() {
    if [ ! -z "$MESHROUTING" ] || [ ! -z "$MESHLOCAL" ]; then
        nordvpn set mesh on
        IFS=';' read -ra HOST <<< "$MESHROUTING"
        for i in "${HOST[@]}"; do
            echo "Adding $i to routing list"
            nordvpn mesh peer routing allow "${i}"
        done
        IFS=';' read -ra HOST <<< "$MESHLOCAL"
        for i in "${HOST[@]}"; do
            echo "Adding $i to local list"
            nordvpn mesh peer local allow "${i}"
        done
    else
        nordvpn set mesh off
    fi
}
delDNSrules() {
    iptables -S |grep 'dport 53'|sed 's/-A/-D/g'| xargs -L 1 iptables
    iptables -S -t mangle |grep 'dport 53'|sed 's/-A/-D/g'| xargs -L 1 iptables -t mangle
}
enableForwarding(){
    subnetNORDVPN=$(ip -o -f inet addr show nordlynx | awk '{print $4;}'|sed 's/\/32/\/16/')
    echo subnetNORDVPN="${subnetNORDVPN}"
    IFS=';' read -ra ADDR <<< "$LOCALNETWORKS"
    for i in "${ADDR[@]}"; do
       echo "Adding $i to whitelist"
       iptables -I FORWARD -i nordlynx -o eth0+ -s "$subnetNORDVPN" -d "${i}" -m conntrack --ctstate NEW -j ACCEPT;
       nordvpn whitelist add subnet "${i}"
    done
    iptables -I FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT;
    iptables -t nat -I POSTROUTING -o eth0+ -s "$subnetNORDVPN" -j MASQUERADE;
    iptables -t nat -A POSTROUTING -o nordlynx -j MASQUERADE

# To allow forwarding of DNS requests from other containers
    iptables -t nat -A POSTROUTING -s "${LXCNETWORK}" -o eth+ -j MASQUERADE
}
appStart() {
    info "start"

    set +e
    # Do nothing if NordVPN isn't available
    while [ ! -S "${SOCKET}" ] ; do
        sleep 1
    done

    nordvpn logout --persist-token
    nordvpn set ipv6 on
    nordvpn login --token "${TOKEN}"

    nordvpn whitelist remove all
    IFS=';' read -ra ADDR <<< "$LOCALNETWORKS"
    for i in "${ADDR[@]}"; do
       echo "Adding $i to whitelist"
       nordvpn whitelist add subnet "${i}"
    done

    config_mesh
    nordvpn connect "${CONNECT}"
    nordvpn status
    delDNSrules
    enableForwarding
    if [ ! -z "${NORDVPNNICKNAME}" ] ; then
        nordvpn mesh peer remove "${NORDVPNNICKNAME}"
        nordvpn mesh set nickname "${NORDVPNNICKNAME}"
    fi
}
ip -o route show | grep default | while read line ; do ip route del $line ; done
ip link set dev eth1 down 
ip link set dev eth1 up
ip route add "${LAN_SUBNET}" via "${OPENWRT_LOCAL_IP}" dev eth0
sleep 2
appStart
