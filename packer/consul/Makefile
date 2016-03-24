.PHONY: all aws vbox files/install.yml vagrant_private_key

all: vbox

vagrant_private_key:
	@wget --no-check-certificate -q -O ./vagrant_private_key 'https://raw.github.com/mitchellh/vagrant/master/keys/vagrant'
	@chmod 0600 ./vagrant_private_key

vbox: 
	@packer-io build -only=vbox -force packer.json
	@vagrant box add --force --name consul-coreos ./builds/consul-coreos.box

coreos-ovf: 
	@packer-io build -force packer-coreos-ovf.json

aws:
	@packer-io build -only=aws packer.json
