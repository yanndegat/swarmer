#!/bin/bash -ex

CONSUL_VERSION=0.6.4
WORKDIR=/home/core/src

#DOWNLOADS
wget -O "$WORKDIR"/docker2aci.tar.gz https://github.com/appc/docker2aci/releases/download/v0.9.3/docker2aci-v0.9.3.tar.gz
wget -O "$WORKDIR"/consul.zip https://releases.hashicorp.com/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_linux_amd64.zip
wget -O "$WORKDIR"/config.yml https://raw.githubusercontent.com/docker/distribution/master/cmd/registry/config-example.yml
wget -O "$WORKDIR"/telegraf.tar.gz https://dl.influxdata.com/telegraf/releases/telegraf-0.13.1_linux_amd64.tar.gz
#PREPARE IMAGES

pushd "$WORKDIR"
tar -xzf ./docker2aci.tar.gz
mkdir -p $HOME/acis
for i in ./*.docker; do
    if [ -f "$i" ]; then
        mkdir ./tmp
        TMPDIR=./tmp ./docker2aci-v0.9.3/docker2aci "$i"
        mv "${i%*.docker}.aci" $HOME/acis
        rm -Rf "$i" ./tmp
    fi
done
popd

#CREATE DIRS
sudo mkdir -p /opt/swarmer
sudo mkdir -p /etc/swarmer/docker.conf.d
sudo mkdir -p /etc/systemd/system/docker.service.d
sudo mkdir -p /etc/docker/registry

#INSTALL FILES
pushd /opt/swarmer
sudo unzip "$WORKDIR"/consul.zip
sudo rm "$WORKDIR"/consul.zip
popd

TMPDIR=$(mktemp -d)
pushd $TMPDIR
tar -xzf "$WORKDIR"/telegraf.tar.gz
sudo mv ./telegraf-0.13.1-1/usr/bin/telegraf /opt/swarmer
sudo chmod +x /opt/swarmer/telegraf
popd

sudo mv "$WORKDIR"/{consul,registry,telegraf,haproxy,registrator,swarm-manager,swarm-agent,flocker-control,flocker-container-agent,flocker-dataset-agent,flocker-docker-plugin}-manage /opt/swarmer/
sudo mv "$WORKDIR"/functions.sh /opt/swarmer/
sudo mv "$WORKDIR"/docker-configurator /opt/swarmer/
sudo mv "$WORKDIR"/swarmer-init /opt/swarmer/
sudo mv "$WORKDIR"/journald-forwarder /opt/swarmer/
sudo mv "$WORKDIR"/telegraf.conf /opt/swarmer/telegraf.conf

sudo chmod +x /opt/swarmer/*-manage
sudo chmod +x /opt/swarmer/docker-configurator
sudo chmod +x /opt/swarmer/swarmer-init
sudo chmod +x /opt/swarmer/journald-forwarder

sudo mv "$WORKDIR"/{swarmer,telegraf,haproxy,journald-forwarder,consul,registrator,docker-configurator,swarm-manager,swarm-agent,registry,flocker-control,flocker-dataset-agent,flocker-container-agent,flocker-docker-plugin}.service /etc/systemd/system/
sudo mv "$WORKDIR"/swarmer.path /etc/systemd/system/

sudo mv "$WORKDIR"/config.yml /etc/docker/registry
sudo mv "$WORKDIR"/60-swarm.conf /etc/swarmer/docker.conf.d/

# SETUP SYSTEMD
sudo systemctl enable swarmer.path
sudo systemctl stop update-engine.service
sudo systemctl disable update-engine.service
sudo systemctl stop locksmithd.service
sudo systemctl disable locksmithd.service
sudo systemctl disable docker.service

#cleanup
rm -Rf ~/.ssh/authorized_keys
sudo rm -Rf /etc/docker/key.json
sudo rm -Rf /var/lib/consul
