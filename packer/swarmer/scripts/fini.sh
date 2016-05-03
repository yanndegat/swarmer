#!/bin/bash -ex

CONSUL_VERSION=0.6.4

#DOWNLOADS
#rkt fetch --insecure-options=image docker://flocker-control-service:latest
#rkt fetch --insecure-options=image docker://flocker-container-agent:latest
#rkt fetch --insecure-options=image docker://flocker-dataset-agent:latest
#rkt fetch --insecure-options=image docker://flocker-docker-plugin:latest

rkt fetch --insecure-options=image docker://andyshinn/dnsmasq:2.75
rkt fetch --insecure-options=image docker://swarm:1.1.3
rkt fetch --insecure-options=image docker://registry:2
rkt fetch --insecure-options=image docker://cyprien/registrator:latest

wget -O /tmp/consul.zip https://releases.hashicorp.com/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_linux_amd64.zip
wget -O /tmp/config.yml https://raw.githubusercontent.com/docker/distribution/master/cmd/registry/config-example.yml
curl -sSL https://dl.bintray.com/emccode/rexray/install > /tmp/install-rexray.sh

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
chmod +x /tmp/install-rexray.sh
/tmp/install-rexray.sh

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
