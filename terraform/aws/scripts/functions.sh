#!/bin/bash

## This file contains all the functions
## handling the lifecycle of a DC
BASEDIR=$(readlink -f $(dirname $0))/..
BUCKET_NAME="swarmer-${AWS_ACCOUNT}-${STACK_NAME}"
PACKER_SWARMER_DIR=$BASEDIR/../../packer/swarmer
PACKER_BASTION_VPN_DIR=$BASEDIR/../../packer/bastion-vpn
OUTPUT_DIR=/tmp/output


SWARMER_AMI_NAME="swarmer"
BASTION_VPN_AMI_NAME="bastion-vpn"

INIT_AMIS=0

TF_COMPONENT=
TF_COMMAND=
TF_ID=
TF_VARFILE=

verbose=0

if [ ! -d $OUTPUT_DIR ]; then
    mkdir $OUTPUT_DIR
fi


debug(){
    if [[ $verbose == 2 ]]; then
        echo "$@" >&2
    fi
}

log(){
    if [[ $verbose == 1 ]]; then
        echo "$@" >&2
    fi
}

fatal(){
    echo $1 >&2
    exit 1
}

show_help_init() {
cat << EOF
Usage: ${0##*/} [-hv] [options] init|s3bucket|keypair|...
Handles the creation of the required resources to bootstrap a DC

COMMANDS:
    init               Plays all required resources init
    deinit             Desrtoys all resources
    s3bucket           Create the required s3bucket
    s3bucket           Create the required s3bucket
    keypair            Generates an ssh keypair

    swarmer-ami        Builds the swarmer ami
    bastion-ami        Builds the bastion ami
    all-amis           Builds all amis

OPTIONS:
    -a AWS_ACCOUNT              AWS account number
    -A                          Destroys/Builds Amis ( default false )
    -k AWS_ACCESS_KEY_ID        AWS Access key id
    -h                          display this help and exit
    -n STACK_NAME               stack name
    -s AWS_SECRET_ACCESS_KEY    AWS Secret access key
    -v                          verbose mode. Can be used multiple
                                times for increased verbosity.
EOF
}

show_help_terraform() {
cat << EOF
Usage: ${0##*/} [-hv] [options] plan|apply|destroy|output
Handles the creation of the required resources to bootstrap a DC

COMMANDS:
    apply     apply changes the component of your DC
    destroy   destroy the component of your DC
    plan      output the changes that will be performed
              on the component of your DC
    output    output the attributes of your component

OPTIONS:
    -a AWS_ACCOUNT           (required)     AWS account number
    -k AWS_ACCESS_KEY_ID     (required)     AWS Access key id
    -h                                      display this help and exit
    -n STACK_NAME            (required)     stack name
    -r AWS_DEFAULT_REGION    (required)     AWS default region
    -s AWS_SECRET_ACCESS_KEY (required)     AWS Secret access key
    -v                                      verbose mode. Can be used multiple
                                            times for increased verbosity.
    -c TF_COMPONENT          (required)     the component to handle
    -i TF_ID                 (required)     the logical id of the component
    -f TF_VARFILE                           a custom input varfile

Available Components:
    vpc               the aws vpc
    docker-registry   an insecure docker registry
    swarmer           a swarmer cluster
EOF
}

_checks(){
    if [[ -z $AWS_ACCOUNT ]]; then
        fatal "the env var AWS_ACCOUNT must be set."
    fi
    if [[ -z $AWS_ACCESS_KEY_ID ]]; then
        fatal "the env var AWS_ACCESS_KEY_ID must be set."
    fi
    if [[ -z $AWS_SECRET_ACCESS_KEY ]]; then
        fatal "the env var AWS_SECRET_ACCESS_KEY must be set."
    fi
    if [[ -z $AWS_DEFAULT_REGION ]]; then
        fatal "the env var AWS_DEFAULT_REGION must be set."
    fi
    if [[ -z $STACK_NAME ]]; then
        fatal "the env var STACK_NAME must be set."
    fi
    if [[ -z $KEYPAIR_PASSPHRASE ]]; then
        fatal "the env var KEYPAIR_PASSPHRASE must be set."
    fi
}

_check-s3bucket(){
    _exists-s3bucket
    if [[ $? != 0 ]]; then
        fatal "s3://${BUCKET_NAME} is not a valid s3 bucket."
    fi
}

_exists-s3bucket(){
    aws s3 ls s3://${BUCKET_NAME} >/dev/null 2>&1
}


init(){
    create-s3bucket
    generate-keypair

    if [[ $INIT_AMIS == 1 ]]; then
        all-amis
    fi
}

deinit(){
    echo "WARNING: you will loose terraform state and your ssh keypair, continue ?"
    read OK

    if [[ $OK =~ y|Y|yes|Yes|YES ]]; then
        if [[ $INIT_AMIS == 1 ]]; then
            _deregister_amis
        fi
        _exists-s3bucket
        if [[ $? == 0 ]]; then
            aws s3 rb --force s3://${BUCKET_NAME}
        fi
    fi
}

generate-keypair(){
    _check-s3bucket
    log "generates keypair, encrypts en pushes it to s3://${BUCKET}"
    ssh-keygen -t rsa -P '' -f $OUTPUT_DIR/${STACK_NAME}.keypair >&2
    gpg --textmode --batch --passphrase "$KEYPAIR_PASSPHRASE" -c $OUTPUT_DIR/${STACK_NAME}.keypair >&2
    aws s3 cp $OUTPUT_DIR/${STACK_NAME}.keypair.gpg s3://${BUCKET_NAME}/ >&2
    aws s3 cp $OUTPUT_DIR/${STACK_NAME}.keypair.pub s3://${BUCKET_NAME}/ >&2
}

dl-keypair(){
   _checks
   _check-s3bucket
    log "get keypair from s3://${BUCKET_NAME}/${STACK_NAME}.keypair to ${PWD}"
    aws s3 cp s3://${BUCKET_NAME}/${STACK_NAME}.keypair.gpg ./ >&2
    aws s3 cp s3://${BUCKET_NAME}/${STACK_NAME}.keypair.pub ./ >&2
}

create-s3bucket(){
    _checks
    _exists-s3bucket
    if [[ $? != 0 ]]; then
        aws s3 mb s3://$BUCKET_NAME > /dev/null 2>&1
    else
        log "bucket s3://$BUCKET_NAME already exists."
    fi
}
_describe_private_amis_tsv() {
    aws ec2 describe-images --owners self \
        --query 'Images[*].{id:ImageId,name:Name,date:CreationDate}' \
        | jq 'sort_by(.date)| reverse | .[] |[.id, .name, .date ] | @tsv' \
        | sed 's/"//g'
}

_lastamiid(){
    printf "$(_describe_private_amis_tsv)" | grep -i "$1" | head -1 | awk '{print $1}'
}

swarmer-ami(){
   make -C $PACKER_SWARMER_DIR aws
}

bastion-vpn-ami(){
   make -C $PACKER_BASTION_VPN_DIR
}

swarmer-ami-id(){
   _lastamiid $SWARMER_AMI_NAME
}

bastion-vpn-ami-id(){
   _lastamiid $BASTION_VPN_AMI_NAME
}

all-amis(){
    swarmer-ami
    bastion-vpn-ami
}

_deregister_amis(){
    AMIS=$(_describe_private_amis_tsv)
    if [[ ! -z $AMIS ]]; then
        printf "$AMIS" | awk '{print $1}' | xargs -n 1 aws ec2 deregister-image --image-id
    fi
}

_check-terraform-component(){
    if [[ -z $TF_COMPONENT ]]; then
        show_help_terraform
        fatal "You must precise a component".
    fi
}

_terraform-remote-state(){
    _checks
    _check-s3bucket
    _check-terraform-component

    if [[ -z $TF_ID ]]; then
        show_help_terraform
        fatal "You must precise an ID".
    fi

    terraform remote config -backend=s3 -backend-config="bucket=${BUCKET_NAME}" -backend-config="key=swarmer/${STACK_NAME}-${TF_COMPONENT}-${TF_ID}.tfstate" -backend-config="region=${AWS_DEFAULT_REGION}"
}


_check-terraform-command(){
    if [[ -z $TF_COMMAND ]]; then
        show_help_terraform
        fatal "You must precise a valid command".
    fi

    case $TF_COMMAND in
        plan|apply|destroy|output)
        ;;
        *)
            fatal "unknown command $TF_COMMAND"
            ;;
    esac
}

_terraform-gen-varfile(){
    if [[ -f $TF_VARFILE ]]; then
        cat $TF_VARFILE
    fi

    cat << EOF
aws_region = "$AWS_DEFAULT_REGION"
stack_name = "$STACK_NAME"
swarmer_ami = "$(_lastamiid $SWARMER_AMI_NAME)"
EOF
}

_terraform-make-builddir(){
    TMPDIR=/tmp/terraform.$$
    cp -Rf $BASEDIR $TMPDIR
    cp -Rf $TMPDIR/$TF_COMPONENT $TMPDIR/$TF_COMPONENT.$TF_ID
    printf "%s/%s.%s" $TMPDIR $TF_COMPONENT $TF_ID
}

terraform-cmd(){
    # check
    (_checks && _check-terraform-component && _check-terraform-command) >&2

    #prepare
    BUILDDIR=$(_terraform-make-builddir)

    pushd $BUILDDIR >&2
    terraform get >&2
    (_terraform-remote-state && terraform remote pull) >&2

    dl-keypair

    #perform
    _terraform-gen-varfile > $BUILDDIR/terraform.tfvars && terraform $TF_COMMAND -input=true

    #clean
    popd >&2 && rm -Rf $TMPDIR >&2
}

terraform-output(){
    # check
    (_checks && _check-terraform-component && _check-terraform-command) >&2

    #prepare
    BUILDDIR=$(_terraform-make-builddir)
    pushd $BUILDDIR >&2
    terraform get >&2
    (_terraform-remote-state && terraform remote pull) >&2

    #perform
    _terraform-gen-varfile > $BUILDDIR/terraform.tfvars && terraform output | sed 's/^\([^=]*\) = \(.*\)$/\1 = "\2"/g'

    #clean
    popd >&2 && rm -Rf $TMPDIR >&2
}
