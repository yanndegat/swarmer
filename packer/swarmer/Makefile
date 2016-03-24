.PHONY: all dev aws gen-key-pair src-archive builds

CONSUL_AMI_ID ?= "ami-81aa1af2"

all: dev

gen-key-pair:
	@./keypair.sh

dev:
	@rm -Rf builds/coreos/
	@packer-io build -only=dev packer.json

iso: dev
	@qemu-img convert -f qcow2 -O raw ./builds/coreos/swarm ./builds/coreos/swarm.iso

builds:
	@mkdir -p ./builds

src-archive: builds
	@(cd .. && git archive --format=tar master) | gzip > ./builds/src.tar.gz

aws: src-archive
	@packer-io build -only=aws -var "src=./builds/src.tar.gz" -var "aws-source-ami=$(CONSUL_AMI_ID)" packer.json
