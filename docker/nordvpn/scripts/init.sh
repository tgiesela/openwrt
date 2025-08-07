#!/bin/bash
. ./functions.sh
set -e

appStartDaemon() {
    [ -f /.alreadysetup ] && echo "Skipping setup..." || appSetup
    echo "[INFO] start"

    trap "appStop" SIGTERM
    trap "appStop" SIGINT
    set +e
    rm -f ${SOCKET}
    rm -f ${PID}
    exec ${DAEMON} &
    DAEMON_PID=$!
    # Do nothing if NordVPN isn't available
    while [ ! -S ${SOCKET} ] ; do
        sleep 1
    done
    info "Starting monitor"
    chmod +x ./monitor.sh
    chmod +x ./forward.sh
    nohup ./monitor.sh 2>&1 & 
#    tail -f /entrypoint.sh
    wait ${DAEMON_PID}
    echo "Wait completed"
}
appStop() {
    echo "TRAP HANDLER" active
    echo "Stopping"
    nordvpn logout --persist-token
    nordvpn disconnect
}

appHelp() {
        echo "Available options:"
        echo " app:start          - Starts nordvpn"
        echo " app:setup          - First time setup."
        echo " app:help           - Displays the help"
        echo " [command]          - Execute the specified linux command eg. /bin/bash."
}

case "$1" in
        app:start)
                appStartDaemon
                ;;
        app:setup)
                appSetup
                ;;
        app:help)
                appHelp
                ;;
        *)
                if [ -x $1 ]; then
                        $1
                else
                        prog=$(which $1)
                        if [ -n "${prog}" ] ; then
                                shift 1
                                $prog $@
                        else
                                appHelp
                        fi
                fi
                ;;
esac
echo "Exiting now"
exit 0
