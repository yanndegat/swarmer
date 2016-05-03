#!/bin/bash
log(){
   logger -s -t "flocker-init" -p $@
}

gethostadminipaddr(){
    # Keep trying to retrieve IP addr until it succeeds. Timeouts after 1m
    now=$(date +%s)
    timeout=$(( now + 60 ))
    set +e
    while :; do
        if [[ $timeout -lt $(date +%s) ]]; then
            logger -t "$SERVICE_NAME" "Could not retrieve IP Address. Exiting"
            exit 5
        fi
        ip route | grep -q "^$ADMIN_NETWORK"
        [ $? -eq 0 ] && break
        sleep 1
    done

    printf "$(ip route | grep "^$ADMIN_NETWORK" | sed 's/.*src \([0-9\.]*\) .*/\1/g')"
}


if [ ! /etc/swarmer/swarmer.conf ]; then
    log user.error "couldn't find configuration file"
    exit 1
fi

source /etc/swarmer/swarmer.conf

STACK_NAME=${STACK_NAME:-swarmer}
ADMIN_NETWORK=${ADMIN_NETWORK:-"default"}

if [ $FLOCKER != "1" ]; then
    exit 0
fi

if [ $SWARM_MODE == "manager" ] || [ $SWARM_MODE == "both" ]; then
    log user.info "generate flocker certificates"
    sudo mkdir /etc/flocker
    RKT_FLOCKER_OPTS="--insecure-options=image run --volume conf,kind=host,source=/etc/flocker docker://yanndegat/flocker-tools --mount volume=conf,target=/flocker --exec /bin/bash"

    #Generates certificates for Control service
    sudo rkt $RKT_FLOCKER_OPTS -- -c "cd /flocker && /usr/local/bin/flocker-ca initialize ${STACK_NAME}"
    sudo rkt $RKT_FLOCKER_OPTS -- -c "cd /flocker && /usr/local/bin/flocker-ca create-control-certificate flocker-control.service.${STACK_NAME}"
    sudo mv /etc/flocker/control-flocker-control.service.swarmer.key /etc/flocker/control-service.key
    sudo mv /etc/flocker/control-flocker-control.service.swarmer.crt /etc/flocker/control-service.crt
    sudo rm /etc/flocker/cluster.key


    #Upload cluster certificate to consul to make it available for agent nodes
    CONSUL_SESSION_ID=$(curl -XPUT "http://localhost:8500/v1/session/create" \
                             -d '{"Name":"'$(hostname)'", "TTL": "120s", "LockDelay" : "120s"}' 2>/dev/null | jq '.ID' | sed 's/"//g' || exit 1)

    LOCKED=$(cat /etc/flocker/cluster.crt | curl -XPUT "http://localhost:8500/v1/kv/swarmer/flocker-cluster-crt?acquire=$CONSUL_SESSION_ID" -d - 2>/dev/null || exit 1)

    if [[ "$LOCKED" != "true" ]]; then
        logger -s -p user.error "flocker-cluster-crt lock already acquired".
        exit 1
    fi

    #runs services
    docker run --name=flocker-control-volume -v /var/lib/flocker clusterhq/flocker-control-service true

    #registers in consul
    cat > /tmp/flocker-control.json <<EOF
{
  "ID": "flocker-control",
  "Name": "flocker-control",
  "Tags": [ "flocker-control", "${STACK_NAME}" ],
  "Address": "$(gethostadminipaddr)",
  "Port": 4523,
  "Check": {
    "Script": "/opt/swarmer/check_flocker.sh",
    "Interval": "10s",
    "TTL": "15s"
  }
}

EOF
    cat /tmp/flocker-contron.json | curl -XPUT "http://localhost:8500/v1/agent/service/register" -d - 2>/dev/null

fi



if [ $SWARM_MODE == "agent" ] || [ $SWARM_MODE == "both" ]; then
    consul watch -type service -service flocker-control /opt/swarmer/flocker-init-agent.sh

    #agent
    sudo rkt $RKT_FLOCKER_OPTS -- -c "cd /flocker && /usr/local/bin/flocker-ca create-node-certificate"
    sudo rkt $RKT_FLOCKER_OPTS -- -c "cd /flocker && /usr/local/bin/flocker-ca create-api-certificate plugin"
    sudo mv /etc/flocker/????????-????-????-????-????????????.key /etc/flocker/node.key
    sudo mv /etc/flocker/????????-????-????-????-????????????.crt /etc/flocker/node.crt
fi

sudo chmod 0700 /etc/flocker
sudo chmod 0600 /etc/flocker/*.key

#clean images
rkt list --no-legend | grep flocker-tools | awk '{print $1}' | xargs sudo rkt rm
