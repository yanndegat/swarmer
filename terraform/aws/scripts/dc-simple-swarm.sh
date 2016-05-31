#!/bin/bash

BASEDIR=$(readlink -f "$(dirname "$0")")/..
source "$BASEDIR/scripts/functions.sh"
ADDITIONAL_NODES=${ADDITIONAL_NODES:-0}
TF_VARFILE=/tmp/terraform.$$.tfvars

show_help() {
cat << EOF
Usage: ${0##*/} [-hv] [options] bootstrap id key1=val,key2=val,...|destroy id|config-ssh id
a full Single AZ Swarm Cluster

OPTIONS:
    -a AWS_ACCOUNT           (required)     AWS account number
    -d DATACENTER            (required)     datacenter
    -k AWS_ACCESS_KEY_ID     (required)     AWS Access key id
    -h                                      display this help and exit
    -n STACK_NAME            (required)     stack name
    -s AWS_SECRET_ACCESS_KEY (required)     AWS Secret access key
    -v                                      verbose mode. Can be used multiple
                                            times for increased verbosity.
EOF
}

config-ssh(){
    ID=$2

    TFCMD="$BASEDIR/scripts/dc-terraform.sh \
        -a $AWS_ACCOUNT \
        -k $AWS_ACCESS_KEY_ID \
        -n $STACK_NAME \
        -s $AWS_SECRET_ACCESS_KEY"

    # get vpc variables
    $TFCMD -c vpc -i vpc output > $TF_VARFILE
    $TFCMD -c swarm-simple-single-az -i $ID output >> $TF_VARFILE

    BASTION_IP=$(grep "^bastion_ip =" $TF_VARFILE | sed 's/^[^ =]*[ ]*=[ ]*\(.*\)/\1/g')
    CONSUL_IP=$(grep "^join_address =" $TF_VARFILE | sed 's/^[^ =]*[ ]*=[ ]*\(.*\)/\1/g')

    get-keypair
    cp ~/.ssh/$STACK_NAME.key /output
    SSH_CONFIG_FILE=/output/config

    SSH_OPTS="-oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null"
    SSH_PROXY_COMMAND="ProxyCommand ssh -l core -i ~/.ssh/$STACK_NAME.key $SSH_OPTS $BASTION_IP ncat %h %p"

    for host in $(ssh -q -o "$SSH_PROXY_COMMAND" $SSH_OPTS -i ~/.ssh/$STACK_NAME.key core@$CONSUL_IP "/opt/swarmer/consul members" | tail -n+2 | tr -s ' ' '|' | cut -d'|' -f1,2); do
        HOSTNAME=$(echo $host | cut -d'|' -f1 | sed "s/'//g")
        HOSTIP=$(echo $host | cut -d'|' -f2 | cut -d':' -f1)

        cat >> $SSH_CONFIG_FILE <<EOF
Host $HOSTNAME
   HostName $HOSTIP
   IdentityFile ~/.ssh/$STACK_NAME.key
   $SSH_PROXY_COMMAND

EOF
    done

    #Bastion block
        cat >> $SSH_CONFIG_FILE <<EOF
Host ${STACK_NAME}-bastion
   HostName $BASTION_IP
   User core
   IdentityFile ~/.ssh/$STACK_NAME.key

EOF

    #General block
    WILDCARD="$(echo $CONSUL_IP | sed 's/\([0-9]*\.[0-9]*\)\.[0-9]*\.[0-9]*/\1.*/g' )"
        cat >> $SSH_CONFIG_FILE <<EOF
Host $WILDCARD
   IdentityFile ~/.ssh/$STACK_NAME.key
   $SSH_PROXY_COMMAND

EOF
}

get-keypair(){
    dl-keypair
    mkdir -p ~/.ssh
    gpg --batch --passphrase "$KEYPAIR_PASSPHRASE" -d "./$STACK_NAME.keypair.gpg" > "$HOME/.ssh/$STACK_NAME.key"
    chmod 0600 "$HOME/.ssh/$STACK_NAME.key"
}

get-cacert(){
    dl-cacert
    CERTDIR="$HOME/.swarmer/$STACK_NAME/$DATACENTER"
    mkdir -p "$CERTDIR"
    gpg --batch --passphrase "$KEYPAIR_PASSPHRASE" -d "./cacert.$DATACENTER.$STACK_NAME.tar.base64.gpg" > "$CERTDIR/cacert.tar.base64"
    (cd "$CERTDIR" && base64 -d "$CERTDIR/cacert.tar.base64" | tar -xf - )
}

gen-tls-nodes-certs(){
    log "generates tls nodes cert"
    CERTDIR=$(mktemp -d)
    ID=$1
    TYPE=$2
    NB=$3
    NODES=""
    for ((i=0;i<NB;i++)); do
        NODES="$NODES $ID-$TYPE-$i"
    done

    export CERTDIR
    "$BASEDIR/../../bin/nodes-certs" "$STACK_NAME" "$DATACENTER" $NODES
}


bootstrap(){
    ID=$2
    shift 2
    VARS=($@)
    masters=4
    nodes=0
    instance="m4.large"
    disk=100

    for v in "${VARS[@]}"; do
        eval "$v"
    done

    if ((masters>0)); then
        gen-tls-nodes-certs "$ID" "master" "$masters"
    fi

    if ((nodes>0)); then
        gen-tls-nodes-certs "$ID" "node" "$nodes"
    fi

    TFCMD="$BASEDIR/scripts/dc-terraform.sh \
        -a $AWS_ACCOUNT \
        -k $AWS_ACCESS_KEY_ID \
        -n $STACK_NAME \
        -s $AWS_SECRET_ACCESS_KEY"

    # get vpc variables
    "$TFCMD" -c vpc -i vpc output > "$TF_VARFILE"

    SWARMER_AMI=$(swarmer-ami-id)
    SUBNET_ID=$(grep "^subnet_id_zone_${zone:-a} = " "$TF_VARFILE" | sed 's/\(.*\) = \(.*\)/\2/g')
    ADMIN_NETWORK=$(grep "^subnet_network_zone_${zone:-a} = " "$TF_VARFILE" | sed 's/\(.*\) = \(.*\)/\2/g')

    #make swarm cluster
    cat $ >> "$TF_VARFILE" <<EOF
name = "${ID}"
stack_name = "${STACK_NAME}"
datacenter = "${DATACENTER}"
bucket = "${BUCKET_NAME}"
aws_region = "${AWS_DEFAULT_REGION}"
swarmer_ami = "${SWARMER_AMI}"
subnet_id = "${SUBNET_ID}"
admin_network = "${ADMIN_NETWORK}"
node_datasize = "${disk}"
instance_type="${instance}"
count = "${masters}"
additional_nodes = "${nodes}"
EOF

    "$TFCMD" -c swarm-simple-single-az -i "$ID" -f "$TF_VARFILE" apply
}


destroy(){
    TFCMD="$BASEDIR/scripts/dc-terraform.sh \
        -a $AWS_ACCOUNT \
        -k $AWS_ACCESS_KEY_ID \
        -n $STACK_NAME \
        -s $AWS_SECRET_ACCESS_KEY"

    #create required var file with fake values
    cat >> $TF_VARFILE <<EOF
availability_zones = ""
bastion_ip = ""
dns_domain_name = ""
dns_zone_id = "fake"
key_name = ""
security_group = ""
subnet_id_zone_a = ""
subnet_id_zone_b = ""
subnet_network_zone_a = ""
subnet_network_zone_b = ""
subnet_ids = ""
vpc_id = ""
additional_docker_opts = ""
nodes = "0"
server ="0"
name = ""
subnet_id =  ""
instance_type = ""
node_datasize = "0"
node_ebs_optimized = ""
registry_access_key_id = ""
registry_access_key_secret = ""
bucket = ""
aws_region = ""
EOF

    # destroy vpc
    $TFCMD -c swarm-simple-single-az -i swarm-single -f $TF_VARFILE destroy
}

OPTIND=1 # Reset is necessary if getopts was used previously in the script.  It is a good idea to make this local in a function.
while getopts ":hva:d:k:s:n:" opt; do
    case "$opt" in
        a)  AWS_ACCOUNT=$OPTARG
            ;;
        d)  DATACENTER=$OPTARG
            ;;
        k)  AWS_ACCESS_KEY_ID=$OPTARG
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
        bootstrap "$@"
        ;;
    config-ssh)
        config-ssh "$@"
        ;;
    destroy)
        destroy "$@"
        ;;
    *)
        echo "unhandled command: $1" >&2
        show_help >&2
        exit 2
        ;;
esac
