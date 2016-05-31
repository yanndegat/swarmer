#!/bin/bash

# This script inits the required resources to bootstrap a DC
#  - s3 buckets
#  - ssh key
#  - TLS certs
#  - amis
BASEDIR=$(readlink -f "$(dirname "$0")")
source "$BASEDIR/functions.sh"


OPTIND=1 # Reset is necessary if getopts was used previously in the script.  It is a good idea to make this local in a function.
while getopts ":hvAa:k:s:n:d:" opt; do
    case "$opt" in
        a)  AWS_ACCOUNT=$OPTARG
            ;;
        A)  INIT_AMIS=1
            ;;
        k)  AWS_ACCESS_KEY_ID=$OPTARG
            ;;
        s)  AWS_SECRET_ACCESS_KEY=$OPTARG
            ;;
        n)  STACK_NAME=$OPTARG
            ;;
        d)  DATACENTER=$OPTARG
            ;;
        h)
            show_help_init
            exit 0
            ;;
        v)  verbose=$((verbose+1))
            ;;
        '?')
            show_help_init >&2
            exit 1
            ;;
    esac
done

shift "$((OPTIND-1))" # Shift off the options and optional --.

case $1 in
    keypair)
        generate-keypair
        ;;
    s3bucket)
        create-s3bucket
        ;;
    all-amis)
        all-amis
        ;;
    swarmer-ami)
        swarmer-ami
        ;;
    bastion-ami)
        bastion-vpn-ami
        ;;
    init)
        init
        ;;
    deinit)
        deinit
        ;;
    *)
        echo "unhandled command: $1" >&2
        show_help_init >&2
        exit 2
        ;;
esac
