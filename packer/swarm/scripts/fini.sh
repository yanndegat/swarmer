#!/bin/bash

sudo mkdir -p /opt/scripts/{swarm,registrator,registry}

sudo mkdir -p /etc/docker/registry
sudo wget -o /etc/docker/registry/config.yml https://raw.githubusercontent.com/docker/distribution/master/cmd/registry/config-example.yml

#swarm
/usr/bin/docker pull swarm:1.1.3
sudo mv /tmp/swarm-manage /opt/scripts/swarm/swarm-manage
sudo chmod +x /opt/scripts/swarm/swarm-manage
sudo mv /tmp/swarm.service /etc/systemd/system
sudo systemctl enable swarm.service

#registry
/usr/bin/docker pull registry:2
sudo mv /tmp/start-registry /opt/scripts/registry/start-registry
sudo chmod +x /opt/scripts/registry/start-registry
sudo mv /tmp/registry.service /etc/systemd/system
sudo systemctl enable registry.service
cat > /tmp/private-registry.conf <<EOF
DOCKER_OPTS="--insecure-registry=registry.service.swarmer:5000"
EOF
sudo cp /tmp/private-registry.conf /etc/docker.conf.d/

#registrator
/usr/bin/docker pull gliderlabs/registrator:v6
sudo mv /tmp/registrator-manage /opt/scripts/registrator/registrator-manage
sudo chmod +x /opt/scripts/registrator/registrator-manage
sudo mv /tmp/registrator.service /etc/systemd/system
sudo systemctl enable registrator.service
sudo mv /tmp/60-swarm.conf /etc/docker.conf.d/

#cleanup
rm -Rf ~/.ssh/authorized_keys
sudo rm -Rf /etc/docker/key.json
sudo rm -Rf /var/lib/consul
