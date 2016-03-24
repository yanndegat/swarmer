#!/bin/bash

BASEDIR=$(readlink -f $(dirname $0))

if [[ -z $AWS_ACCOUNT ]]; then
    echo "You must set an aws account in \$AWS_ACCOUNT" >&2
    exit 1
fi

CONSUL_AMI_ID=$($BASEDIR/lastamiid.sh "consul-coreos")
SWARM_AMI_ID=$($BASEDIR/lastamiid.sh "swarm-coreos")
SWARMER_AMI_ID=$($BASEDIR/lastamiid.sh "swarmer-coreos")

aws ec2 modify-image-attribute --image-id "$CONSUL_AMI_ID" --launch-permission "{\"Add\":[{\"UserId\":\"$AWS_ACCOUNT\"}]}"

aws ec2 modify-image-attribute --image-id "$SWARM_AMI_ID" --launch-permission "{\"Add\":[{\"UserId\":\"$AWS_ACCOUNT\"}]}"

aws ec2 modify-image-attribute --image-id "$SWARMER_AMI_ID" --launch-permission "{\"Add\":[{\"UserId\":\"$AWS_ACCOUNT\"}]}"
