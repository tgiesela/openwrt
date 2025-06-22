#!/bin/bash

function exists() {
    local name
    name=$(lxc-ls -1 | grep "^$1$")
    if [ "$name" == "$1" ]; then
        echo "true"
    else
        echo "false"
    fi
}
function state() {
    if [ "$(exists "$1")" = "false" ]; then
        return
    fi
    local lxcstate
    lxcstate=$(lxc-info -n "$1" | grep -E 'State:' | awk '{print $2}')
    echo "$lxcstate"
}
function stop() {
    local lxcstate
    lxcstate=$(state "$1")
    if [ "$lxcstate" != "RUNNING" ]; then
        echo "Container $1 is not running."
        return 0
    fi
    lxc-stop -n "$1"
   	echo "WAITING FOR CONTAINER $1 TO STOP"
	lxc-wait --name=$1 --state=STOPPED
	echo "CONTAINER $1 STOPPED"

}
function start() {
    local lxcstate
    lxcstate=$(state "$1")
    if [ "$lxcstate" != "STOPPED" ]; then
        echo "Container $1 is already running."
        stop "$1"
    fi
    echo "Starting container $1"
    rm -rf "$1"/error.log
    lxc-start -o "$1"/error.log -f "$1"/runconfig -c /dev/tty1 "$1"
    echo "WAITING FOR CONTAINER $1 TO START"
    lxc-wait --name="$1" --state=RUNNING
    echo "CONTAINER $1 STARTED"
}
function attach() {
    echo ATTACH $@
    if [ "$(exists "$1")" = "false" ]; then
        echo "Container $1 does not exist."
        return 0
    fi
    lxcstate=$(state "$1")
    if [ "$lxcstate" != "RUNNING" ]; then
        echo "Container $1 is not running."
        return 0
    fi
    local name=$1
    shift 1
    echo lxc-attach "$name" -- /bin/sh -c "$*"
    lxc-attach "$name" -- /bin/sh -c "$*"
}
help() {
        echo "Available options:"
        echo " start          - Starts lxc-container with the specified name."
        echo " stop           - Stops lxc-container with the specified name."
        echo " attach         - Attach to lxc-container and execute a command."
        echo " help           - Displays the help"
}

case "$1" in
        start)
                shift 1
                start "$@"
                ;;
        stop)
                stop "$2"
                ;;
        attach)
                shift 1
                attach "$@"
                ;;
        *)
                help
                ;;
esac
