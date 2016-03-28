#!/bin/bash

BASEDIR="$(readlink -f $(dirname $0))"
BUILDDIR=$BASEDIR/../builds
INSTANCE_ID=${INSTANCE_ID:-"myinstance"}
CONSUL_JOINIPADDR=${JOINIPADDR:-""}
CLUSTER_SIZE=${CLUSTER_SIZE:-3}
HOST_IP="$(ip route | grep default | sed 's/.*src \([0-9\.]*\).*$/\1/g')"
DOCKER_REGISTRY=${DOCKER_REGISTRY:-"$HOST_IP:5000"}
IMG=$BUILDDIR/$INSTANCE_ID/cloudinit.img
VDI=$BUILDDIR/$INSTANCE_ID/cloudinit.vdi
CLOUDINITDIR=$BUILDDIR/$INSTANCE_ID/openstack/latest
USERDATA=$CLOUDINITDIR/user_data
INSTANCE_IP=${INSTANCE_IP}
ADMIN_NETWORK=${ADMIN_NETWORK:-""}

if [[ ! -d $BUILDIR ]]; then
    mkdir -p $BUILDDIR
fi

if [[ -z $INSTANCE_IP ]]; then
    echo "IP required."
    exit 1
fi

if [[ ! -d $BUILDDIR/$INSTANCE_ID ]]; then
    mkdir -p $BUILDDIR/$INSTANCE_ID
fi

if [[ ! -d $CLOUDINITDIR ]]; then
    mkdir -p $CLOUDINITDIR
fi

#generate userdata
cat > $USERDATA <<EOF
#cloud-config
ssh_authorized_keys:
  - ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA6NF8iallvQVp22WDkTkyrtvp9eWW6A8YVr+kz4TjGYe7gHzIw+niNltGEFHzD8+v1I2YJ6oXevct1YeS0o9HZyN1Q9qgCgzUFtdOKLv6IedplqoPkcmF0aYet2PkEDo3MlTBckFXPITAMzF8dJSIFo9D8HfdOV0IAdx4O7PtixWKn5y2hMNG0zQPyUecp4pzC6kivAIhyfHilFR61RGL+GPXQ2MWZWFYbAGjyiYJnAmCP3NOTd0jMZEnDkbUvxhMmBYSdETk1rRgm+R4LOzFUGaHqHDLKLX+FIPKcF96hrucXzcWyLbIbEgE98OHlnVYCzRdK8jlqm8tehUc9c9WhQ== vagrant insecure public key
write_files:
  - path: "/etc/consul/consul.conf"
    permissions: "0644"
    owner: "root"
    content: |
      export JOINIPADDR=${CONSUL_JOINIPADDR}
      export CLUSTER_SIZE=${CLUSTER_SIZE}
      export CONSUL_OPTS="\$CONSUL_OPTS -node='${INSTANCE_ID}' -dc=vagrant"
      export ADMIN_NETWORK="${ADMIN_NETWORK}"
  - path: "/etc/swarm/swarm.conf"
    permissions: "0644"
    owner: "root"
    content: |
      export SWARM_MODE="both"
      export ADMIN_NETWORK="${ADMIN_NETWORK}"
  - path: "/etc/registrator/registrator.conf"
    permissions: "0644"
    owner: "root"
    content: |
      export ADMIN_NETWORK="${ADMIN_NETWORK}"
  - path: "/etc/docker.conf.d/51-additional-docker-opts.conf"
    permissions: "0644"
    owner: "root"
    content: |
             DOCKER_OPTS="--insecure-registry=$DOCKER_REGISTRY"
EOF

dd if=/dev/zero of=$IMG bs=1k count=256 >&2
mkfs.vfat -n config-2 $IMG >&2
(cd $BUILDDIR/$INSTANCE_ID && mcopy -soi $IMG openstack ::) >&2

#genisoimage -output "$img" -volid config-2 -joliet -rock "$USERDATA" "$METADATA" >&2
qemu-img convert -f raw $IMG -O vdi $VDI

printf $(readlink -f $VDI)
