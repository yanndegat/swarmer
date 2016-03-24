#!/bin/bash

sudo mkdir -p /opt/scripts/consul
sudo wget https://releases.hashicorp.com/consul/0.6.3/consul_0.6.3_linux_amd64.zip
sudo unzip consul_0.6.3_linux_amd64.zip
sudo mv consul /opt/scripts/consul/consul
sudo rm consul_0.6.3_linux_amd64.zip

sudo mv /tmp/consul-manage /opt/scripts/consul/consul-manage
sudo chmod +x /opt/scripts/consul/consul-manage

sudo mv /tmp/consul.service /etc/systemd/system
sudo mv /tmp/consul.path /etc/systemd/system
sudo systemctl enable consul.service

sudo mv /tmp/consul-members.service /etc/systemd/system
sudo mv /tmp/consul-members.timer /etc/systemd/system
sudo systemctl enable consul-members.service
sudo systemctl enable consul-members.timer

sudo mv /tmp/docker-configurator.service /etc/systemd/system
sudo systemctl enable docker-configurator.service
sudo mkdir -p /opt/scripts/docker
sudo mv /tmp/docker-configurator /opt/scripts/docker/
sudo chmod +x /opt/scripts/docker/docker-configurator
sudo mkdir -p /etc/systemd/system/docker.service.d
sudo mv /tmp/docker-configurator.path /etc/systemd/system/
sudo mv /tmp/docker.path /etc/systemd/system/
