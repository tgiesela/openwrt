#!/bin/bash
source ./vars
source ./lxcvars
source ./functions.sh
set -e
#ip -o route show | grep default | while read line ; do ip route del $line ; done
#ip link set dev eth1 down 
#ip link set dev eth1 up
#ip route add "${LAN_SUBNET}" via "${OPENWRT_LOCAL_IP}" dev eth0
sleep 2
appStart
