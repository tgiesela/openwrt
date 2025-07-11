#!/bin/bash
echo "REBOOTING DOCKER CONTAINERS"
. ../config/vars
. ../config/dockervars
PATH=${PATH}:/usr/sbin/
BRIDGE=docker0
RSLT=$(ip -h link show "${BRIDGE}" type bridge 2>/dev/null)
while [ -z "$RSLT" ] ; do
	sleep 1
	RSLT=$(ip -h link show "${BRIDGE}" type bridge 2>/dev/null)
done
echo "Bridge available"
RSLT=$(docker network ls|grep ${LAN_NETWORK} 2>/dev/null)
while [ -z "$RSLT" ] ; do
	sleep 1
	RSLT=$(docker network ls|grep ${LAN_NETWORK} 2>/dev/null)
done
echo "${LAN_NETWORK} available"
RSLT=$(docker network ls|grep ${WAN_NETWORK} 2>/dev/null)
while [ -z "$RSLT" ] ; do
	sleep 1
	RSLT=$(docker network ls|grep ${WAN_NETWORK} 2>/dev/null)
done
echo "${WAN_NETWORK} available"
docker network disconnect ow-wan ${CONTAINERWRT}
sleep 2
MAKE=$(which make)
cd "$(dirname "$0")" 
$MAKE run 2>&1
echo "REBOOTING DOCKER CONTAINERS DONE"
