#!/bin/bash

BASEDIR=$(readlink -f $(dirname $0))/..
source $BASEDIR/scripts/functions.sh
TF_VARFILE=/tmp/terraform.$$.tfvars

show_help() {
cat << EOF
Usage: ${0##*/} [-hv] [options] bootstrap|destroy
a full Multi AZ DC

OPTIONS:
    -a AWS_ACCOUNT           (required)     AWS account number
    -k AWS_ACCESS_KEY_ID     (required)     AWS Access key id
    -h                                      display this help and exit
    -n STACK_NAME            (required)     stack name
    -s AWS_SECRET_ACCESS_KEY (required)     AWS Secret access key
    -r AWS_DEFAULT_REGION    (required)     AWS default region
    -v                                      verbose mode. Can be used multiple
                                            times for increased verbosity.
EOF
}

bootstrap(){
    if [[ $INIT == 1 ]]; then
        init
    fi

    TFCMD="$BASEDIR/scripts/dc-terraform.sh \
        -a "$AWS_ACCOUNT" \
        -k "$AWS_ACCESS_KEY_ID" \
        -n "$STACK_NAME" \
        -r "$AWS_DEFAULT_REGION" \
        -s "$AWS_SECRET_ACCESS_KEY""

    BASTION_VPN_AMI=$(bastion-vpn-ami-id)

    #make swarm cluster
    cat >> $TF_VARFILE <<EOF
aws_bastion_ami = "${BASTION_VPN_AMI}"
bucket = "${BUCKET_NAME}"
EOF

   # make vpc
    $TFCMD -c vpc -i vpc  -f $TF_VARFILE apply
}

destroy(){
    if [[ $INIT == 1 ]]; then
        init-destroy
    fi

    TFCMD="$BASEDIR/scripts/dc-terraform.sh \
        -a "$AWS_ACCOUNT" \
        -k "$AWS_ACCESS_KEY_ID" \
        -n "$STACK_NAME" \
        -r "$AWS_DEFAULT_REGION" \
        -s "$AWS_SECRET_ACCESS_KEY""

    # destroy vpc
    $TFCMD -c vpc -i vpc destroy
}


OPTIND=1 # Reset is necessary if getopts was used previously in the script.  It is a good idea to make this local in a function.
while getopts ":hva:k:r:s:n:" opt; do
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
            show_help
            exit 0
            ;;
        v)  verbose=$((verbose+1))
            ;;
        '?')
            show_help >&2
            exit 1
            ;;
    esac
done

shift "$((OPTIND-1))" # Shift off the options and optional --.

case $1 in
    bootstrap)
        bootstrap
        ;;
    destroy)
        destroy
        ;;
    *)
        echo "unhandled command: $1" >&2
        show_help >&2
        exit 2
        ;;
esac
