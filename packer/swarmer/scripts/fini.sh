#!/bin/bash

DOCKER_TAG_NAME=swarmer

#build swarmer images
mkdir /tmp/swarmer
pushd /tmp/swarmer
tar -xzf /tmp/src.tar.gz
/usr/bin/docker build -t $DOCKER_TAG_NAME .
popd

sudo mkdir -p /opt/scripts/registrator
#registrator
sudo mv /tmp/registrator-manage /opt/scripts/registrator/registrator-manage
sudo chmod +x /opt/scripts/registrator/registrator-manage
sudo mv /tmp/registrator.service /etc/systemd/system
sudo systemctl enable registrator.service

#cleanup
rm -Rf ~/.ssh/authorized_keys
sudo rm -Rf /etc/docker/key.json
