#!/bin/bash
if [[ -f "/etc/swarmer/swarmer.conf" ]]; then
    source /etc/swarmer/swarmer.conf
fi

SCRIPT_FILE="$0"
if [[ "$SCRIPT_FILE" == "-bash" ]]; then
    echo "sourcing from bash" >&2
    echo "SERVICE_NAME will be set to bash_$$".
    SERVICE_NAME="bash_$$"
    UUID_FILE=/var/run/"$SERVICE_NAME".uuid
else
    FILENAME="$(basename "$0")"
    SERVICE_NAME="${FILENAME%*-manage}"
    UUID_FILE=/var/run/"$SERVICE_NAME".uuid
fi

ADMIN_NETWORK=${ADMIN_NETWORK:-default}
PUBLIC_NETWORK=${PUBLIC_NETWORK:-default}

STACK_NAME=${STACK_NAME:-swarmer}
DATACENTER=${DATACENTER:-dc1}

log(){
   logger -s -t "$SERVICE_NAME" -p "$@"
}

getipaddrfornetwork(){
    NETWORK="$1"
    # Keep trying to retrieve IP addr until it succeeds. Timeouts after 1m
    now=$(date +%s)
    timeout=$(( now + 60 ))
    set +e
    while :; do
        if [[ $timeout -lt $(date +%s) ]]; then
            log user.error "Could not retrieve IP Address. Exiting"
            exit 5
        fi
        ip route | grep -q "^$NETWORK"
        [ $? -eq 0 ] && break
        sleep 1
    done

    ip route | grep "^$NETWORK" | sed 's/.*src \([0-9\.]*\) .*/\1/g'
}

getpubipaddr(){
    getipaddrfornetwork "$PUBLIC_NETWORK"
}

gethostadminipaddr(){
    getipaddrfornetwork "$ADMIN_NETWORK"
}

stop_rkt() {
    if [ -f "$UUID_FILE" ]; then
        sudo machinectl kill "rkt-$(cat "$UUID_FILE")"
    fi
}

rm_rkt() {
    if [ -f "$UUID_FILE" ]; then
        rkt rm --uuid-file "$UUID_FILE"
    fi
}

run_curl(){
    METHOD=$1
    shift
    /usr/bin/curl --fail \
         --cacert /etc/swarmer/certs/ca.pem \
         --cert /etc/swarmer/certs/client.pem \
         --key /etc/swarmer/certs/client-key.pem \
         -X"$METHOD" "$@"
}

consul() {
    METHOD=$1
    shift
    path=$1
    shift
    run_curl "$METHOD" "https://$(hostname).node.$DATACENTER.$STACK_NAME:8500/v1$path" "$@"
}

consul-unlock(){
    SESSION_ID=$(cat /var/run/"$SERVICE_NAME".session)
    if [ ! -z "$SESSION_ID" ]; then
        consul PUT "/kv/swarmer/$SERVICE_NAME-lock?release=$SESSION_ID" 2>/dev/null
    fi
}

consul-new-session(){
    TMPFILE=$(mktemp)
    cat > "$TMPFILE" <<EOF
{"Name":"$(hostname)", "TTL": "120s", "LockDelay" : "120s"}
EOF
    consul PUT "/session/create" \
           -d @"$TMPFILE" 2>/dev/null | jq '.ID' | sed 's/"//g' > /var/run/"$SERVICE_NAME".session
    rm "$TMPFILE"
    cat /var/run/"$SERVICE_NAME".session
}

consul-lock(){
    touch /var/run/"$SERVICE_NAME".session
    SESSION_ID=$(cat /var/run/"$SERVICE_NAME".session)
    if [ ! -z "$SESSION_ID" ]; then
        consul PUT "/session/renew/$SESSION_ID"
        if [ $? != 0 ]; then
            SESSION_ID=$(consul-new-session)
        fi
    else
        SESSION_ID=$(consul-new-session)
    fi

    LOCKED=$(consul PUT "/kv/swarmer/$SERVICE_NAME-lock?acquire=$SESSION_ID" 2>/dev/null)

    if [[ "$LOCKED" != "true" ]]; then
        log user.error "lock already acquired".
        exit 1
    else
        log user.info "lock acquired for session $SESSION_ID"
    fi
}
