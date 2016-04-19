.PHONY: all aws

PACKER = $(shell which packer.io | which packer | which packer-io)

all: aws

aws:
	@$(PACKER) build packer.json
