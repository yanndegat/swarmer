#!/bin/bash

BASEDIR=$(readlink -f $(dirname $0))/..
source $BASEDIR/scripts/functions.sh

TF_VARFILE=/tmp/terraform.vpc.$$.tfvars
TF_SWARM_VARFILE=/tmp/terraform.swarm.$$.tfvars

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
        -s "$AWS_SECRET_ACCESS_KEY""


    # get vpc vars
    $TFCMD -c vpc -i vpc output > $TF_VARFILE


    #make consul cluster zone a
    cp $TF_VARFILE $TF_CONSUL_VARFILE
    cat >> $TF_CONSUL_VARFILE <<EOF
servers = "3"
name = "zonea"
subnet_id = $(grep "^subnet_id_zone_a =" $TF_VARFILE | cut -d= -f2)
EOF

    $TFCMD -c mod-consul -i zonea -f $TF_CONSUL_VARFILE apply

    JOINADDRESS=$($TFCMD -c mod-consul -i zonea output | grep "^join_address = " | cut -d= -f2)

    #make consul cluster zone b
    cp $TF_VARFILE $TF_CONSUL_VARFILE
    cat >> $TF_CONSUL_VARFILE <<EOF
servers = "3"
name = "zoneb"
subnet_id = $(grep "^subnet_id_zone_b =" $TF_VARFILE | cut -d= -f2)
joinaddress = $JOINADDRESS
EOF

    $TFCMD -c mod-consul -i zoneb -f $TF_CONSUL_VARFILE apply


    #make swarm cluster zone a
    cp $TF_VARFILE $TF_SWARM_VARFILE
    cat >> $TF_SWARM_VARFILE <<EOF
nodes = "2"
name = "zonea"
subnet_id = $(grep "^subnet_id_zone_a =" $TF_VARFILE | cut -d= -f2)
consul_joinaddress = $JOINADDRESS
node_instance_type = "t2.micro"
node_datasize = "10"
node_ebs_optimized = "false"
EOF

    $TFCMD -c mod-swarm -i zonea -f $TF_SWARM_VARFILE apply


    #make swarm cluster zone b
    cp $TF_VARFILE $TF_SWARM_VARFILE
    cat >> $TF_SWARM_VARFILE <<EOF
nodes = "2"
name = "zoneb"
subnet_id = $(grep "^subnet_id_zone_b =" $TF_VARFILE | cut -d= -f2)
consul_joinaddress = $JOINADDRESS
node_instance_type = "t2.micro"
node_datasize = "10"
node_ebs_optimized = "false"
EOF

    $TFCMD -c mod-swarm -i zoneb -f $TF_SWARM_VARFILE apply
}


destroy(){
    if [[ $INIT == 1 ]]; then
        init-destroy
    fi

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
subnet_ids = ""
vpc_id = ""
additional_docker_opts = ""
nodes = "0"
server ="0"
name = ""
subnet_id =  ""
consul_joinaddress =  ""
node_instance_type = ""
node_datasize = "0"
node_ebs_optimized = ""
EOF

    #destroy swarm cluster zone b
    $TFCMD -c mod-swarm -i zoneb -f $TF_VARFILE destroy

    #destroy swarm cluster zone a
    $TFCMD -c mod-swarm -i zonea -f $TF_VARFILE destroy

    #destroy consul cluster zone b
    $TFCMD -c mod-consul -i zoneb -f $TF_VARFILE destroy

    #destroy consul cluster zone a
    $TFCMD -c mod-consul -i zonea -f $TF_VARFILE destroy

    #destroy docker registry
    $TFCMD -c docker-registry -i priv -f $TF_VARFILE destroy

    # destroy vpc
    $TFCMD -c vpc -i vpc -f $TF_VARFILE destroy
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
    destroy)
        destroy
        ;;
    *)
        echo "unhandled command: $1" >&2
        show_help >&2
        exit 2
        ;;
esac
