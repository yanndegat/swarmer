#!/bin/bash

docker pull andyshinn/dnsmasq


CONSUL_VERSION=0.6.4

sudo mkdir -p /opt/scripts/consul
sudo wget https://releases.hashicorp.com/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_linux_amd64.zip
sudo unzip consul_${CONSUL_VERSION}_linux_amd64.zip
sudo mv consul /opt/scripts/consul/consul
sudo rm consul_${CONSUL_VERSION}_linux_amd64.zip

sudo mv /tmp/consul-manage /opt/scripts/consul/consul-manage
sudo chmod +x /opt/scripts/consul/consul-manage

sudo mv /tmp/consul.service /etc/systemd/system
sudo mv /tmp/consul.path /etc/systemd/system
sudo systemctl enable consul.service

sudo mv /tmp/dnsmasq.service /etc/systemd/system
sudo systemctl enable dnsmasq.service

sudo mv /tmp/docker-configurator.service /etc/systemd/system
sudo systemctl enable docker-configurator.service
sudo mkdir -p /opt/scripts/docker
sudo mv /tmp/docker-configurator /opt/scripts/docker/
sudo chmod +x /opt/scripts/docker/docker-configurator
sudo mkdir -p /etc/systemd/system/docker.service.d
sudo mv /tmp/docker-configurator.path /etc/systemd/system/
sudo mv /tmp/docker.path /etc/systemd/system/

sudo systemctl stop update-engine.service
sudo systemctl disable update-engine.service
sudo systemctl stop locksmithd.service
sudo systemctl disable locksmithd.service
