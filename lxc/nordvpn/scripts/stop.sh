#!/bin/bash
source ./vars
set -e
appStop() {
    nordvpn logout --persist-token
    nordvpn disconnect
}
appStop