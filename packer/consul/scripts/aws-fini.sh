#!/bin/bash

sudo sed -i 's/user-config.target/system-config.target/ig' /etc/systemd/system/docker-configurator.service
sudo sed -i 's/user-config.target/system-config.target/ig' /etc/systemd/system/consul.service
rm -Rf ~/.ssh/authorized_keys
