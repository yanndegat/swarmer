#!/bin/bash -e

OVPN_DATA="OVPN_DATA"
source /etc/environment
source /etc/stack.conf

exists(){
    ID=$(docker ps -q -a --filter label=$OVPN_DATA)
    [[ $? -eq 0 ]] && [[ ! -z $ID ]]
}

if [ -z $STACK_NAME ]; then
    logger -s -p user.error "error: STACK_NAME is not set."
    exit 1
fi

if [ -z $ADMIN_NETWORK ]; then
    logger -s -p user.error "error: ADMIN_NETWORK is not set."
    exit 1
fi

if ! exists; then
    docker run -l $OVPN_DATA --name $OVPN_DATA -v /etc/openvpn busybox
    docker run --volumes-from $OVPN_DATA --rm kylemanna/openvpn:latest ovpn_genconfig -u udp://${COREOS_PUBLIC_IPV4} -p "route ${ADMIN_NETWORK%/*} 255.255.0.0"  -d -N
    docker run --volumes-from $OVPN_DATA --rm kylemanna/openvpn:latest /bin/bash -c "echo $STACK_NAME | ovpn_initpki nopass"
fi
