#!/bin/bash
if [[ -f "/etc/swarmer/swarmer.conf" ]]; then
    source /etc/swarmer/swarmer.conf
fi
IMAGE_NAME=registry-1.docker.io/andyshinn/dnsmasq:2.75
STACK_NAME=${STACK_NAME:-swarmer}
DNSMASQ_ACI_ID=$(rkt image list --no-legend --fields id,name | grep "$IMAGE_NAME" | awk '{print $1}')
ADMIN_NETWORK=${ADMIN_NETWORK:-default}

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

    ip route | grep "^$ADMIN_NETWORK" | sed 's/.*src \([0-9\.]*\) .*/\1/g'
}

cat > $1 <<EOF
{
  "acVersion": "0.7.4",
  "acKind": "PodManifest",
  "apps": [
    {
      "name": "dnsmasq",
      "image": {
        "id": "$DNSMASQ_ACI_ID"
      },
      "app": {
        "exec": [
          "/usr/sbin/dnsmasq",
          "-k",
          "-S",
          "/$STACK_NAME/$(gethostadminipaddr)#8600"
        ],
        "group": "0",
        "user": "0",
        "isolators": [
           {
             "name": "os/linux/capabilities-retain-set",
             "value": {"set": ["CAP_NET_ADMIN"]}
           }
         ]
      }
    }
  ]
}
EOF
