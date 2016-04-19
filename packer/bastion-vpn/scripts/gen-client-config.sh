#!/bin/bash

OVPN_DATA="OVPN_DATA"
source /etc/stack.conf

exists(){
    ID=$(docker ps -q -a --filter label=$OVPN_DATA)
    [[ $? -eq 0 ]] && [[ ! -z $ID ]]
}

if [ -z $ADMIN_NETWORK ]; then
    log "error: ADMIN_NETWORK is not set."
    exit 1
fi

if [ -z $1 ]; then
    "Usage $(basename $0) NAME" >&2
    exit 1
fi

if ! exists; then
    echo "VPN hasn't been configured." >&2
    exit 1
fi

docker run --volumes-from $OVPN_DATA --rm -it kylemanna/openvpn:latest easyrsa build-client-full $1 nopass
docker run --volumes-from $OVPN_DATA --rm kylemanna/openvpn:latest ovpn_getclient $1
