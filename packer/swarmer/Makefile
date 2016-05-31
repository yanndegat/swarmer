.PHONY: all aws vbox files/install.yml vagrant_private_key
PACKER=$(shell (which packer-io || which packer.io || which packer)| tail -1)
DOCKER_IMAGES=swarm:1.2.3 registry:2 cyprien/registrator:latest consul:v0.6.4 clusterhq/flocker-core:1.11.0 clusterhq/flocker-dataset-agent:1.11.0 yanndegat/haproxy-consul:0.5

all: vbox

dl-coreos-box:
	@mkdir -p ./builds/coreos
	@wget -O ./builds/coreos.box http://stable.release.core-os.net/amd64-usr/current/coreos_production_vagrant.box
	@tar -C ./builds/coreos -xzf ./builds/coreos.box

dl-docker-images:
	@./scripts/dl-docker-images.sh $(DOCKER_IMAGES)

vagrant_private_key:
	@wget --no-check-certificate -q -O ./vagrant_private_key 'https://raw.github.com/mitchellh/vagrant/master/keys/vagrant'
	@chmod 0600 ./vagrant_private_key

vbox: vagrant_private_key dl-docker-images
	@$(PACKER) build -only=vbox -force packer.json
	@vagrant box add --force --name swarmer-coreos ./builds/swarmer-coreos.box


aws:
	@DOCKER_IMAGES="$(DOCKER_IMAGES)" $(PACKER) build -only=aws packer.json
