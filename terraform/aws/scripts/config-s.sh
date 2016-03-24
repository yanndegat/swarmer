#!/bin/bash
BASEDIR=$(dirname $(readlink -f $0))

HEAD_DF_HOSTS="## DF PROXY COMMAND DO NOT EDIT !! HEAD ##"
TAIL_DF_HOSTS="## DF PROXY COMMAND DO NOT EDIT !! TAIL ##"
TMPFILE=/tmp/sshconfig.$$.tmp
STACK_NAME=${STACK_NAME:-swarmer}

if [[ -z $KEYPAIR_PASSPHRASE ]]; then
    echo "You must set your keypair passphrase in the env var KEYPAIR_PASSPHRASE.">&2
    exit 1
fi

terraform_output(){
    echo $(terraform output | grep "^$1 = " | sed "s#$1 = \(.*\)#\1#g") \
        || (echo "DC not terraformed! Exiting." && exit 1)
}

ssh_config(){
    echo $HEAD_DF_HOSTS 
    cat $TMPFILE
    echo $TAIL_DF_HOSTS
}

append_ssh_config(){
    ssh_config >> ~/.ssh/config
}

insert_ssh_config(){
    [ ! -f ~/.ssh/config ] && (append_ssh_config && exit 0)

    cp ~/.ssh/config ~/.ssh/config.$$.bak

    HEAD_LINE=$(grep -n "$HEAD_DF_HOSTS" ~/.ssh/config| cut -d':' -f1) || (append_ssh_config && exit 0)
    TAIL_LINE=$(grep -n "$TAIL_DF_HOSTS" ~/.ssh/config | cut -d':' -f1)
    NB_LINE=$(wc -l ~/.ssh/config | cut -d' ' -f1)

    head -$(( $HEAD_LINE - 1 )) ~/.ssh/config.$$.bak > ~/.ssh/config
    append_ssh_config
    tail -$(( $NB_LINE - $TAIL_LINE )) ~/.ssh/config.$$.bak >> ~/.ssh/config
}

BASTION_IP=$(terraform_output "bastion_ip")
CONSUL_IP=$(terraform_output "consul_joinipaddr")

ssh-keygen -R $BASTION_IP
ssh-keygen -R $CONSUL_IP

gpg -d $BASEDIR/../$STACK_NAME.keypair.gpg --batch --passphrase "$KEYPAIR_PASSPHRASE" > ~/.ssh/$STACK_NAME.key
chmod 0600 ~/.ssh/$STACK_NAME.key

SSH_OPTS="-oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null"
SSH_PROXY_COMMAND="ProxyCommand ssh -l ec2-user -i ~/.ssh/$STACK_NAME.key $SSH_OPTS $BASTION_IP nc %h %p"

for host in $(ssh -q -o "$SSH_PROXY_COMMAND" $SSH_OPTS -i ~/.ssh/$STACK_NAME.key core@$CONSUL_IP "docker exec consul consul members" | tail -n+2 | tr -s ' ' '|' | cut -d'|' -f1,2); do
    HOSTNAME=$(echo $host | cut -d'|' -f1 | sed "s/'//g")
    HOSTIP=$(echo $host | cut -d'|' -f2 | cut -d':' -f1)
    printf "Host %s\n   HostName %s\n   IdentityFile ~/.ssh/$STACK_NAME.key \n   %s\n\n" "$HOSTNAME" "$HOSTIP" "$SSH_PROXY_COMMAND" >> $TMPFILE
done

#General block
WILDCARD="$(echo $CONSUL_IP | cut -d. -f1,2 ).*"
printf "Host %s\n   IdentityFile ~/.ssh/$STACK_NAME.key \n   %s\n\n" "$WILDCARD" "$SSH_PROXY_COMMAND" >> $TMPFILE

insert_ssh_config
rm $TMPFILE

exit 0
