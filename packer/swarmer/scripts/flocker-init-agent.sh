#!/bin/bash -e
log(){
   logger -s -t "flocker-agent" -p $@
}

if [ ! /etc/swarmer/swarmer.conf ]; then
    log user.error "couldn't find configuration file"
    exit 1
fi

source /etc/swarmer/swarmer.conf

STACK_NAME=${STACK_NAME:-swarmer}

log user.info "generate flocker agent certificates"
sudo mkdir /etc/flocker

TMPFILE=$(mktemp)

curl -XGET --fail "http://localhost:8500/v1/kv/swarmer/flocker-ca.pem" | jq '.[0].Value' | sed 's/"//g"' | base64 -d > $TMPFILE || exit 1

sudo mv $TMPFILE /etc/flocker/ca.pem

RKT_FLOCKER_OPTS="--insecure-options=image run --volume conf,kind=host,source=/etc/flocker docker://yanndegat/flocker-tools --mount volume=conf,target=/flocker --exec /bin/bash"
sudo rkt $RKT_FLOCKER_OPTS -- -c "cd /flocker && /usr/local/bin/flocker-ca create-node-certificate"
sudo rkt $RKT_FLOCKER_OPTS -- -c "cd /flocker && /usr/local/bin/flocker-ca create-api-certificate plugin"
sudo mv /etc/flocker/????????-????-????-????-????????????.key /etc/flocker/node.key
sudo mv /etc/flocker/????????-????-????-????-????????????.crt /etc/flocker/node.crt

sudo chmod 0700 /etc/flocker
sudo chmod 0600 /etc/flocker/*.key

#clean images
rkt list --no-legend | grep flocker-tools | awk '{print $1}' | xargs sudo rkt rm
