#!/bin/bash
source ./vars
set -e
appStop() {
    echo "STOP" > ./wantedstate
    nordvpn logout --persist-token
    nordvpn disconnect
}
appStop
