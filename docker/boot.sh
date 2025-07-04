#!/bin/bash
echo "REBOOTING DOCKER CONTAINERS"
PATH=${PATH}:/usr/sbin/
BRIDGE=docker0
RSLT=$(ip -h link show "${BRIDGE}" type bridge 2>/dev/null)
while [ -z "$RSLT" ] ; do
	sleep 1
	RSLT=$(ip -h link show "${BRIDGE}" type bridge 2>/dev/null)
done
MAKE=$(which make)
cd "$(dirname "$0")" || exit
$MAKE run
echo "REBOOTING DOCKER CONTAINERS DONE"
