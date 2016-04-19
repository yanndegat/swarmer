#!/bin/bash
CONSULIP=${CONSULIP:-192.168.101.101}

DOCKER_HOST=
docker kill dnsmasq >/dev/null 2>&1
docker rm dnsmasq >/dev/null 2>&1

docker run -d --name dnsmasq \
       --net host \
       --cap-add NET_ADMIN \
       -e SERVICE_IGNORE=true \
       andyshinn/dnsmasq -S /swarmer/${CONSULIP}#8600 > /dev/null 2>&1

printf "try command: \nexport DOCKER_HOST=swarm-4000.service.swarmer:4000 \ndocker info\n\n or go to http://consul.service.swarmer:8500/ui\n"
