#!/bin/bash -ex

CONSUL_VERSION=0.6.4

#DOWNLOADS
wget -O /tmp/docker2aci.tar.gz https://github.com/appc/docker2aci/releases/download/v0.9.3/docker2aci-v0.9.3.tar.gz
wget -O /tmp/consul.zip https://releases.hashicorp.com/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_linux_amd64.zip
wget -O /tmp/config.yml https://raw.githubusercontent.com/docker/distribution/master/cmd/registry/config-example.yml

#PREPARE IMAGES
pushd "/tmp"
tar -xzf ./docker2aci.tar.gz
for i in ./*.docker; do
    if [ -f "$i" ]; then
        ./docker2aci-v0.9.3/docker2aci "$i"
        rkt fetch --insecure-options=image "${i%*.docker}.aci"
        rm "$i"
    fi
done

#rkt fetch --insecure-options=image docker://flocker-control-service:latest
#rkt fetch --insecure-options=image docker://flocker-container-agent:latest
#rkt fetch --insecure-options=image docker://flocker-dataset-agent:latest
#rkt fetch --insecure-options=image docker://flocker-docker-plugin:latest
popd

#CREATE DIRS
sudo mkdir -p /opt/swarmer
sudo mkdir -p /etc/swarmer/docker.conf.d
sudo mkdir -p /etc/systemd/system/docker.service.d
sudo mkdir -p /etc/docker/registry

#INSTALL FILES
pushd /opt/swarmer
sudo unzip /tmp/consul.zip
sudo rm /tmp/consul.zip
popd

sudo mv /tmp/{consul,registry,registrator,swarm-manager,swarm-agent,flocker-control,flocker-agent}-manage /opt/swarmer/
sudo mv /tmp/dnsmasq-manifest.sh /opt/swarmer/
sudo mv /tmp/docker-configurator /opt/swarmer/
sudo mv /tmp/swarmer-init /opt/swarmer/
sudo chmod +x /opt/swarmer/{consul,registry,registrator,swarm-agent,swarm-manager}-manage
sudo chmod +x /opt/swarmer/docker-configurator
sudo chmod +x /opt/swarmer/swarmer-init
sudo chmod +x /opt/swarmer/dnsmasq-manifest.sh

sudo mv /tmp/{swarmer,consul,dnsmasq,registrator,docker-configurator,swarm-manager,swarm-agent,registry}.service /etc/systemd/system/
sudo mv /tmp/swarmer.path /etc/systemd/system/

sudo mv /tmp/config.yml /etc/docker/registry
sudo mv /tmp/60-swarm.conf /etc/swarmer/docker.conf.d/

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
