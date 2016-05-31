#!/bin/bash
WORKDIR=/home/core/src

rm -Rf ~/.ssh/authorized_keys
sudo mv $WORKDIR/{format-var-lib-docker.service,var-lib-docker.mount,format-var-lib-rkt.service,var-lib-rkt.mount} /etc/systemd/system/
sudo systemctl enable format-var-lib-docker.service
sudo systemctl enable var-lib-docker.mount
sudo systemctl enable format-var-lib-rkt.service
sudo systemctl enable var-lib-rkt.mount
