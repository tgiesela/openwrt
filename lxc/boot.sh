#!/bin/bash
echo "REBOOTING LXC CONTAINERS"
PATH=${PATH}:/usr/sbin/
BRIDGE=lxcbr0
RSLT=$(ip -h link show "${BRIDGE}" type bridge 2>/dev/null)
while [ -z "$RSLT" ] ; do
	sleep 1
	RSLT=$(ip -h link show "${BRIDGE}" type bridge 2>/dev/null)
done
MAKE=$(which make)
cd "$(dirname "$0")" || exit
$MAKE run
echo "REBOOTING LXC CONTAINERS DONE"
