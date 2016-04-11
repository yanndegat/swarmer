#!/bin/bash

docker pull busybox
docker pull kylemanna/openvpn

sudo mkdir /opt

sudo mv /tmp/init-ovpndata.sh /opt
sudo mv /tmp/ovpn-client-config.sh /opt

sudo chmod +x /opt/*sh

sudo mv /tmp/openvpn.service /etc/systemd/system
sudo systemctl enable openvpn.service

rm -Rf ~/.ssh/authorized_keys

sudo systemctl stop update-engine.service
sudo systemctl disable update-engine.service
sudo systemctl stop locksmithd.service
sudo systemctl disable locksmithd.service
