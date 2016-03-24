.PHONY: all dev aws gen-key-pair

CONSUL_AMI_ID ?= "ami-81aa1af2"
OVF_SOURCE_PATH ?= "../consul/builds/consul/consul-packer.ovf"

all: dev

vagrant_private_key:
	@wget --no-check-certificate -q -O ./vagrant_private_key 'https://raw.github.com/mitchellh/vagrant/master/keys/vagrant'
	@chmod 0600 ./vagrant_private_key

vbox: vagrant_private_key
	@if [[ ! -f $(OVF_SOURCE_PATH) ]]; then echo "No such file: $(OVF_SOURCE_PATH). OVF Missing."; exit 1; fi
	@packer-io build -only=vbox -var "ovf-source-path=$(OVF_SOURCE_PATH)" packer.json
	@vagrant box add --force --name swarm-coreos ./builds/swarm-coreos.box

aws:
	@packer-io build -only=aws -var "aws-source-ami=$(CONSUL_AMI_ID)" packer.json
