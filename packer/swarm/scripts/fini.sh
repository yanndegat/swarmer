#!/bin/bash

/usr/bin/docker pull swarm:1.1.3
sudo mkdir -p /opt/scripts/{swarm,registrator}
#swarm
sudo mv /tmp/swarm-manage /opt/scripts/swarm/swarm-manage
sudo chmod +x /opt/scripts/swarm/swarm-manage
sudo mv /tmp/swarm.service /etc/systemd/system
sudo systemctl enable swarm.service

#registrator
sudo mv /tmp/registrator-manage /opt/scripts/registrator/registrator-manage
sudo chmod +x /opt/scripts/registrator/registrator-manage
sudo mv /tmp/registrator.service /etc/systemd/system
sudo systemctl enable registrator.service
sudo mv /tmp/60-swarm.conf /etc/docker.conf.d/

#docker conf
sudo mkdir /etc/docker.conf.d

#cleanup
rm -Rf ~/.ssh/authorized_keys
sudo rm -Rf /etc/docker/key.json
