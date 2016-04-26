#!/bin/bash -ex

CONSUL_VERSION=0.6.4

#DOWNLOADS
/usr/bin/docker pull andyshinn/dnsmasq
/usr/bin/docker pull swarm:1.1.3
/usr/bin/docker pull registry:2
/usr/bin/docker pull gliderlabs/registrator:v6
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

sudo mv /tmp/{consul,registrator,swarm}-manage /opt/swarmer/
sudo mv /tmp/docker-configurator /opt/swarmer/
sudo mv /tmp/start-registry /opt/swarmer/
sudo chmod +x /opt/swarmer/{consul,registrator,swarm}-manage
sudo chmod +x /opt/swarmer/docker-configurator
sudo chmod +x /opt/swarmer/start-registry

sudo mv /tmp/swarmer.service /etc/systemd/system
sudo mv /tmp/swarmer.path /etc/systemd/system
sudo mv /tmp/consul.service /etc/systemd/system
sudo mv /tmp/dnsmasq.service /etc/systemd/system
sudo mv /tmp/registrator.service /etc/systemd/system
sudo mv /tmp/docker-configurator.service /etc/systemd/system
sudo mv /tmp/swarm.service /etc/systemd/system
sudo mv /tmp/registry.service /etc/systemd/system

sudo mv /tmp/config.yml /etc/docker/registry
sudo mv /tmp/60-swarm.conf /etc/swarmer/docker.conf.d/
cat > /tmp/private-registry.conf <<EOF
DOCKER_OPTS="--insecure-registry=registry.service.swarmer:5000"
EOF
sudo mv /tmp/private-registry.conf /etc/swarmer/docker.conf.d/
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
