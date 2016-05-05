.PHONY: all aws vbox files/install.yml vagrant_private_key
PACKER=$(shell (which packer-io || which packer.io || which packer)| tail -1)

all: vbox

dl-coreos-box:
	@mkdir -p ./builds/coreos
	@wget -O ./builds/coreos.box http://alpha.release.core-os.net/amd64-usr/current/coreos_production_vagrant.box
	@tar -C ./builds/coreos -xzf ./builds/coreos.box

dl-docker-images:
	@./scripts/dl-docker-images.sh "andyshinn/dnsmasq:2.75" "swarm:1.2.1" "registry:2" "cyprien/registrator:latest"

vagrant_private_key:
	@wget --no-check-certificate -q -O ./vagrant_private_key 'https://raw.github.com/mitchellh/vagrant/master/keys/vagrant'
	@chmod 0600 ./vagrant_private_key

vbox: vagrant_private_key dl-docker-images
	@$(PACKER) build -only=vbox -force packer.json
	@vagrant box add --force --name swarmer-coreos ./builds/swarmer-coreos.box

aws: dl-docker-images
	@$(PACKER) build -only=aws packer.json
