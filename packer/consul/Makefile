.PHONY: all aws vbox files/install.yml vagrant_private_key

all: vbox

dl-coreos-box:
	@mkdir -p ./builds/coreos
	@wget -O ./builds/coreos.box http://alpha.release.core-os.net/amd64-usr/current/coreos_production_vagrant.box
	@tar -C ./builds/coreos -xzf ./builds/coreos.box

vagrant_private_key:
	@wget --no-check-certificate -q -O ./vagrant_private_key 'https://raw.github.com/mitchellh/vagrant/master/keys/vagrant'
	@chmod 0600 ./vagrant_private_key

vbox: vagrant_private_key
	@packer-io build -only=vbox -force packer.json
	@vagrant box add --force --name consul-coreos ./builds/consul-coreos.box

coreos-ovf: vagrant_private_key
	@packer-io build -force packer-coreos-ovf.json

aws:
	@packer-io build -only=aws packer.json
