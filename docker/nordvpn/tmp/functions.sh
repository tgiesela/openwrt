#!/bin/bash

set -e
NAME=nordvpn
RUN_DIR=/run/$NAME
SOCKET=${RUN_DIR}/nordvpnd.sock
PID=${RUN_DIR}/nordvpnd.pid
DAEMON=/usr/sbin/nordvpnd
NORDVPN_GROUP="nordvpn"
info () {
    echo "[INFO] $@"
}

create_socket_dir() {
  if [[ -d "$RUN_DIR" ]]; then
    return
  fi
  mkdir -m 0750 "$RUN_DIR"
  chown root:"$NORDVPN_GROUP" "$RUN_DIR"
}

config_mesh() {
    if [ -n "$MESHROUTING" ] || [ ! -z "$MESHLOCAL" ]; then
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
appSetup() {
    info "setup"
    create_socket_dir
}
delDNSrules() {
    iptables -S |grep 'dport 53'|sed 's/-A/-D/g'| xargs -L 1 iptables
    iptables -S -t mangle |grep 'dport 53'|sed 's/-A/-D/g'| xargs -L 1 iptables -t mangle
}
enableForwarding(){
    subnetNORDVPN=$(ip -o -f inet addr show nordlynx | awk '{print $4;}'|sed 's/\/32/\/16/')
    IFS=';' read -ra ADDR <<< "$NETWORK"
    for i in "${ADDR[@]}"; do
       echo "Adding $i to whitelist"
       iptables -I FORWARD -i nordlynx -o eth0+ -s "$subnetNORDVPN" -d ${i} -m conntrack --ctstate NEW -j ACCEPT;
       nordvpn whitelist add subnet "${i}"
    done
    iptables -I FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT;
    iptables -t nat -I POSTROUTING -o eth0+ -s "$subnetNORDVPN" -j MASQUERADE;
    iptables -t nat -A POSTROUTING -o nordlynx -j MASQUERADE

# To allow forwarding of DNS requests from other containers
    iptables -t nat -A POSTROUTING -s "${CNTNETWORK}" -o eth+ -j MASQUERADE
}

appStart() {
    [ -f /.alreadysetup ] && echo "Skipping setup..." || appSetup
    echo "[INFO] start"

    trap "appStop" SIGTERM
    trap "appStop" SIGINT
    set +e

    # Do nothing if NordVPN isn't available
    while [ ! -S ${SOCKET} ] ; do
        sleep 1
    done

    nordvpn logout --persist-token
    echo "LOGGING IN"
    nordvpn login --token "${TOKEN}"

    IFS=';' read -ra ADDR <<< "$LOCALNETWORKS"
    for i in "${ADDR[@]}"; do
       echo "Adding $i to whitelist"
       nordvpn whitelist add subnet "${i}"
    done

    config_mesh
    info "LOGGED IN"
    nordvpn connect "${COUNTRY}"
    info "CONNECTED"
    nordvpn status
    delDNSrules
    enableForwarding
    if [ -n "$NORDVPNNICKNAME}" ] ; then
        nordvpn mesh peer remove "${NORDVPNNICKNAME}"
        nordvpn mesh set nickname "${NORDVPNNICKNAME}"
    fi
}
appStop() {
    info "Stopping"
    nordvpn logout --persist-token
    nordvpn disconnect
}
