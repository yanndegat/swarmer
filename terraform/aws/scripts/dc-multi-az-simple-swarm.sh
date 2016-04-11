#!/bin/bash

BASEDIR=$(readlink -f $(dirname $0))/..
source $BASEDIR/scripts/functions.sh
ADDITIONAL_NODES=${ADDITIONAL_NODES:-0}
TF_VARFILE=/tmp/terraform.$$.tfvars

show_help() {
cat << EOF
Usage: ${0##*/} [-hv] [options] bootstrap|destroy|config-ssh
a full Multi AZ Swarm Cluster

OPTIONS:
    -a AWS_ACCOUNT           (required)     AWS account number
    -k AWS_ACCESS_KEY_ID     (required)     AWS Access key id
    -h                                      display this help and exit
    -n STACK_NAME            (required)     stack name
    -s AWS_SECRET_ACCESS_KEY (required)     AWS Secret access key
    -v                                      verbose mode. Can be used multiple
                                            times for increased verbosity.
EOF
}

config-ssh(){
    TFCMD="$BASEDIR/scripts/dc-terraform.sh \
        -a "$AWS_ACCOUNT" \
        -k "$AWS_ACCESS_KEY_ID" \
        -n "$STACK_NAME" \
        -s "$AWS_SECRET_ACCESS_KEY""

    # get vpc variables
    $TFCMD -c vpc -i vpc output > $TF_VARFILE
    $TFCMD -c swarm-simple-multi-az -i swarm-multiaz output >> $TF_VARFILE

    BASTION_IP=$(grep "^bastion_ip =" $TF_VARFILE | sed 's/^[^ =]*[ ]*=[ ]*\(.*\)/\1/g')
    CONSUL_IP=$(grep "^join_address =" $TF_VARFILE | sed 's/^[^ =]*[ ]*=[ ]*\(.*\)/\1/g')

    get-keypair
    cp ~/.ssh/$STACK_NAME.key /output
    SSH_CONFIG_FILE=/output/config

    SSH_OPTS="-oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null"
    SSH_PROXY_COMMAND="ProxyCommand ssh -l core -i ~/.ssh/$STACK_NAME.key $SSH_OPTS $BASTION_IP ncat %h %p"

    for host in $(ssh -q -o "$SSH_PROXY_COMMAND" $SSH_OPTS -i ~/.ssh/$STACK_NAME.key core@$CONSUL_IP "/opt/scripts/consul/consul members" | tail -n+2 | tr -s ' ' '|' | cut -d'|' -f1,2); do
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
    gpg --batch --passphrase "$KEYPAIR_PASSPHRASE" -d ./$STACK_NAME.keypair.gpg > ~/.ssh/$STACK_NAME.key
    chmod 0600 ~/.ssh/$STACK_NAME.key
}

bootstrap(){
    TFCMD="$BASEDIR/scripts/dc-terraform.sh \
        -a "$AWS_ACCOUNT" \
        -k "$AWS_ACCESS_KEY_ID" \
        -n "$STACK_NAME" \
        -s "$AWS_SECRET_ACCESS_KEY""

    # get vpc variables
    $TFCMD -c vpc -i vpc output > $TF_VARFILE

    SWARM_AMI=$(swarm-ami-id)

    #make swarm cluster
    cat >> $TF_VARFILE <<EOF
additional_nodes = "$ADDITIONAL_NODES"
name = "swarm"
stack_name = "${STACK_NAME}"
EOF

    $TFCMD -c swarm-simple-multi-az -i swarm-multiaz -f $TF_VARFILE apply
}


destroy(){
    TFCMD="$BASEDIR/scripts/dc-terraform.sh \
        -a "$AWS_ACCOUNT" \
        -k "$AWS_ACCESS_KEY_ID" \
        -n "$STACK_NAME" \
        -s "$AWS_SECRET_ACCESS_KEY""

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
EOF

    # destroy vpc
    $TFCMD -c swarm-simple-multi-az -i swarm-multiaz -f $TF_VARFILE destroy
}

OPTIND=1 # Reset is necessary if getopts was used previously in the script.  It is a good idea to make this local in a function.
while getopts ":hva:k:s:n:" opt; do
    case "$opt" in
        a)  AWS_ACCOUNT=$OPTARG
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
        bootstrap
        ;;
    config-ssh)
        config-ssh
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
