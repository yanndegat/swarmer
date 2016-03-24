#!/bin/bash

# This script allows you to handle the lifecylce of the available terraform components
#  - vpc
#  - docker-registry
#  - consul
#  - swarm
#  - vm

BASEDIR=$(readlink -f $(dirname $0))
source $BASEDIR/functions.sh

OPTIND=1 # Reset is necessary if getopts was used previously in the script.  It is a good idea to make this local in a function.
while getopts ":hva:k:r:s:n:c:i:f:" opt; do
    case "$opt" in
        a)  AWS_ACCOUNT=$OPTARG
            ;;
        k)  AWS_ACCESS_KEY_ID=$OPTARG
            ;;
        r)  AWS_DEFAULT_REGION=$OPTARG
            ;;
        s)  AWS_SECRET_ACCESS_KEY=$OPTARG
            ;;
        n)  STACK_NAME=$OPTARG
            ;;
        h)
            show_help_terraform
            exit 0
            ;;
        v)  verbose=$((verbose+1))
            ;;
        c)  TF_COMPONENT=$OPTARG
            ;;
        i)  TF_ID=$OPTARG
            ;;
        f)  TF_VARFILE=$OPTARG
            ;;
        '?')
            show_help_terraform >&2
            exit 1
            ;;
    esac
done
shift "$((OPTIND-1))" # Shift off the options and optional --.

case $1 in
    apply)
        TF_COMMAND="apply"
        terraform-cmd
        ;;
    destroy)
        TF_COMMAND="destroy"
        terraform-cmd
        ;;
    plan)
        TF_COMMAND="plan"
        terraform-cmd
        ;;
    output)
        TF_COMMAND="output"
        terraform-output
        ;;
    *)
        echo "unhandled command: $1" >&2
        show_help_terraform >&2
        exit 2
        ;;
esac
